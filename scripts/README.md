# Скрипты

## Загрузка каталога добавок в Firestore

Скрипт `upload_catalog_to_firestore.py` читает Excel «БД для MVP.xlsx» и загружает данные в коллекцию Firestore `vitamins` (совместимо с каталогом в приложении).

### Требования

- Python 3.10+
- Виртуальное окружение проекта (уже есть: `.venv`)

```bash
.venv/bin/pip install -r scripts/requirements.txt
```

### Ключ Firebase

Нужен **сервисный ключ именно того проекта, к которому подключено приложение** (в проекте это `flutter-project-801d9`).

1. [Firebase Console](https://console.firebase.google.com) → проект **flutter-project-801d9**
2. ⚙️ Project settings → вкладка **Service accounts**
3. **Generate new private key** → сохраните JSON (например `scripts/serviceAccountKey.json`)
4. Не коммитьте этот файл в git (добавьте в `.gitignore`)

### Запуск

**Проверка без записи в БД (dry-run):**

```bash
.venv/bin/python3 scripts/upload_catalog_to_firestore.py "/Users/kleshny/Downloads/БД для MVP.xlsx" --dry-run
```

**Загрузка в Firestore:**

```bash
export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/scripts/serviceAccountKey.json"
.venv/bin/python3 scripts/upload_catalog_to_firestore.py "/Users/kleshny/Downloads/БД для MVP.xlsx"
```

Или указать ключ явно:

```bash
.venv/bin/python3 scripts/upload_catalog_to_firestore.py "/Users/kleshny/Downloads/БД для MVP.xlsx" --credentials scripts/serviceAccountKey.json
```

Если ключ от другого проекта, укажите project ID приложения:

```bash
.venv/bin/python3 scripts/upload_catalog_to_firestore.py "/Users/kleshny/Downloads/БД для MVP.xlsx" --credentials path/to/key.json --project flutter-project-801d9
```

После загрузки в приложении в разделе «Аптечка» каталог добавок будет подтягиваться из коллекции `vitamins`.
