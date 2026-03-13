#!/usr/bin/env python3
r"""
Загрузка каталога добавок из Excel «БД для MVP.xlsx» в Firestore (коллекция vitamins).

Требования:
  pip install openpyxl firebase-admin

Использование:
  1. В Firebase Console: Project settings → Service accounts → Generate new private key.
  2. Сохраните JSON ключ (например, в scripts/serviceAccountKey.json).
  3. Запуск:
     export GOOGLE_APPLICATION_CREDENTIALS="scripts/serviceAccountKey.json"
     python3 scripts/upload_catalog_to_firestore.py "path/to/БД для MVP.xlsx"

  Или указать ключ явно:
     python3 scripts/upload_catalog_to_firestore.py "path/to/БД для MVP.xlsx" --credentials scripts/serviceAccountKey.json
"""

import argparse
import re
import sys
from pathlib import Path

def slug(s: str) -> str:
    """Генерирует id документа из названия добавки."""
    s = (s or "").strip().lower()
    # Транслитерация частых букв для читаемых id
    tr = {
        'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd', 'е': 'e', 'ё': 'e',
        'ж': 'zh', 'з': 'z', 'и': 'i', 'й': 'y', 'к': 'k', 'л': 'l', 'м': 'm',
        'н': 'n', 'о': 'o', 'п': 'p', 'р': 'r', 'с': 's', 'т': 't', 'у': 'u',
        'ф': 'f', 'х': 'h', 'ц': 'ts', 'ч': 'ch', 'ш': 'sh', 'щ': 'sch',
        'ъ': '', 'ы': 'y', 'ь': '', 'э': 'e', 'ю': 'yu', 'я': 'ya',
        ' ': '_', '-': '_', '(': '_', ')': '_',
    }
    for k, v in tr.items():
        s = s.replace(k, v)
    s = re.sub(r'[^a-z0-9_]', '', s)
    s = re.sub(r'_+', '_', s).strip('_')
    return s or 'item'


def normalize_condition(value: str | None) -> str | None:
    """Приводит «Когда принимать» к значению для приложения (before_meal, after_meal, during_meal, any)."""
    if not value or not str(value).strip():
        return None
    v = str(value).strip().lower()
    if 'до еды' in v or 'натощак' in v:
        return 'before_meal'
    if 'после еды' in v:
        return 'after_meal'
    if 'во время еды' in v or 'с едой' in v or 'во время или после' in v or 'во время или сразу после' in v:
        return 'during_meal'
    if 'неважно' in v:
        return 'any'
    return value.strip()


def str_or_none(val) -> str | None:
    if val is None:
        return None
    s = str(val).strip()
    return s if s else None


def main() -> int:
    parser = argparse.ArgumentParser(description='Upload vitamin catalog from Excel to Firestore')
    parser.add_argument('xlsx_path', type=Path, help='Path to БД для MVP.xlsx')
    parser.add_argument('--credentials', '-c', type=Path, help='Path to Firebase service account JSON')
    parser.add_argument('--dry-run', action='store_true', help='Only print what would be uploaded')
    parser.add_argument('--collection', default='vitamins', help='Firestore collection name (default: vitamins)')
    parser.add_argument('--project', type=str, help='Firebase project ID (e.g. flutter-project-801d9); if not set, taken from credentials')
    args = parser.parse_args()

    if not args.xlsx_path.exists():
        print(f'File not found: {args.xlsx_path}', file=sys.stderr)
        return 1

    try:
        import openpyxl
    except ImportError:
        print('Install: pip install openpyxl', file=sys.stderr)
        return 1

    wb = openpyxl.load_workbook(args.xlsx_path, read_only=True, data_only=True)
    ws = wb.active
    rows = list(ws.iter_rows(values_only=True))
    wb.close()

    if not rows:
        print('Excel file is empty.', file=sys.stderr)
        return 1

    # Заголовки: Добавка, Условия приёма, Совместимость, Взаимодействие, Противопоказания, Когда принимать
    headers = [str_or_none(c) or '' for c in rows[0]]
    idx_supplement = 0
    idx_timing_reminder = 1
    idx_compatibility = 2
    idx_interaction = 3
    idx_contraindications = 4
    idx_timing_display = 5
    for i, h in enumerate(headers):
        h_lower = (h or '').lower()
        if 'добавка' in h_lower:
            idx_supplement = i
        elif 'условия приёма' in h_lower:
            idx_timing_reminder = i
        elif 'совместимость' in h_lower:
            idx_compatibility = i
        elif 'взаимодействие' in h_lower:
            idx_interaction = i
        elif 'противопоказания' in h_lower:
            idx_contraindications = i
        elif 'когда принимать' in h_lower and 'первого экрана' in h_lower:
            idx_timing_display = i

    documents = []
    for row in rows[1:]:
        supplement = str_or_none(row[idx_supplement] if idx_supplement < len(row) else None)
        if not supplement:
            continue
        doc_id = slug(supplement)
        when_display = str_or_none(row[idx_timing_display] if idx_timing_display < len(row) else None)
        default_condition = normalize_condition(when_display)
        doc = {
            'display_name': supplement,
            'compatibility_text': str_or_none(row[idx_compatibility] if idx_compatibility < len(row) else None),
            'interaction_text': str_or_none(row[idx_interaction] if idx_interaction < len(row) else None),
            'contraindications_text': str_or_none(row[idx_contraindications] if idx_contraindications < len(row) else None),
            'default_condition': default_condition,
        }
        # Убираем None, чтобы не писать пустые поля
        doc = {k: v for k, v in doc.items() if v is not None}
        documents.append((doc_id, doc))

    if args.dry_run:
        for doc_id, doc in documents:
            print(doc_id, doc)
        print(f'\nDry run: {len(documents)} documents would be written to collection "{args.collection}".')
        return 0

    try:
        import firebase_admin
        from firebase_admin import credentials, firestore
    except ImportError:
        print('Install: pip install firebase-admin', file=sys.stderr)
        return 1

    cred_path = args.credentials or Path(__file__).resolve().parent / 'serviceAccountKey.json'
    if not cred_path.exists():
        import os
        cred_path = os.environ.get('GOOGLE_APPLICATION_CREDENTIALS')
        if not cred_path or not Path(cred_path).exists():
            print(
                'Firebase credentials not found. Either:\n'
                '  1. Save service account JSON as scripts/serviceAccountKey.json\n'
                '  2. Or set GOOGLE_APPLICATION_CREDENTIALS to its path\n'
                '  3. Or pass --credentials path/to/key.json',
                file=sys.stderr,
            )
            return 1
        cred_path = Path(cred_path)

    if not firebase_admin._apps:
        opts = {'projectId': args.project} if args.project else None
        firebase_admin.initialize_app(credentials.Certificate(str(cred_path)), options=opts)
    db = firestore.client()
    col = db.collection(args.collection)

    for doc_id, doc in documents:
        col.document(doc_id).set(doc)
        print(f'Written: {doc_id}')

    print(f'\nDone. Uploaded {len(documents)} documents to collection "{args.collection}".')
    return 0


if __name__ == '__main__':
    sys.exit(main())
