import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/pharmacy_reminder.dart';
import '../models/pharmacy_reminder_input.dart';
import '../models/pharmacy_vitamin.dart';
import '../models/vitamin_catalog_item.dart';
import '../models/weekday.dart';

abstract class PharmacyRepository {
  Future<List<PharmacyVitamin>> fetchVitamins();

  Future<List<PharmacyReminder>> fetchReminders();

  Future<PharmacyReminder?> fetchReminder(String reminderId);

  Future<String> createReminder(PharmacyReminderInput input);

  Future<void> updateReminder(String reminderId, PharmacyReminderInput input);

  Future<void> deleteReminder(String reminderId);

  Future<List<VitaminCatalogItem>> fetchCatalog([String query = '']);
}

class FirestorePharmacyRepository implements PharmacyRepository {
  FirestorePharmacyRepository({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String userId;
  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();

  static const List<String> _rootCollectionCandidates = ['reminders'];
  static const List<String> _catalogCollectionCandidates = [
    'vitamins',
    'catalog',
    'vitamin_catalog',
    'vitaminCatalog',
    'vitamins_catalog',
  ];
  static const List<String> _ownerFieldCandidates = [
    'userId',
    'user_id',
    'uid',
    'ownerId',
  ];

  CollectionReference<Map<String, dynamic>> get _userRemindersCollection =>
      _firestore.collection('users').doc(userId).collection('reminders');

  @override
  Future<List<PharmacyVitamin>> fetchVitamins() async {
    final reminders = await fetchReminders();
    final vitamins =
        reminders
            .where((reminder) => reminder.isActive)
            .map(
              (reminder) => PharmacyVitamin(
                id: reminder.id,
                title: reminder.title,
                isActive: reminder.isActive,
              ),
            )
            .toList()
          ..sort(
            (left, right) =>
                left.title.toLowerCase().compareTo(right.title.toLowerCase()),
          );
    return vitamins;
  }

  @override
  Future<List<PharmacyReminder>> fetchReminders() {
    return _loadReminders();
  }

  @override
  Future<PharmacyReminder?> fetchReminder(String reminderId) async {
    final docs = await _loadReminderDocuments();
    for (final doc in docs) {
      final reminder = _parseReminder(doc.id, doc.data());
      if (reminder.id == reminderId) {
        return reminder;
      }
    }
    return null;
  }

  @override
  Future<String> createReminder(PharmacyReminderInput input) async {
    final reminderId = _uuid.v4();
    await _userRemindersCollection
        .doc(reminderId)
        .set(_encodeReminder(id: reminderId, input: input));
    return reminderId;
  }

  @override
  Future<void> updateReminder(
    String reminderId,
    PharmacyReminderInput input,
  ) async {
    final ref =
        await _findReminderReference(reminderId) ??
        _userRemindersCollection.doc(reminderId);
    await ref.set(
      _encodeReminder(id: reminderId, input: input),
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> deleteReminder(String reminderId) async {
    final ref = await _findReminderReference(reminderId);
    if (ref == null) {
      return;
    }
    await ref.delete();
  }

  @override
  Future<List<VitaminCatalogItem>> fetchCatalog([String query = '']) async {
    final normalizedQuery = query.trim().toLowerCase();
    List<VitaminCatalogItem> items;
    try {
      items = await _loadCatalogItems();
    } on FirebaseException {
      items = _fallbackCatalog;
    }
    final filtered = normalizedQuery.isEmpty
        ? items
        : items.where((item) {
            final haystacks = [
              item.resolvedName,
              item.code ?? '',
              item.defaultUnit ?? '',
            ];
            return haystacks.any(
              (value) => value.toLowerCase().contains(normalizedQuery),
            );
          }).toList();

    filtered.sort(
      (left, right) => left.resolvedName.toLowerCase().compareTo(
        right.resolvedName.toLowerCase(),
      ),
    );
    return filtered;
  }

  Future<List<PharmacyReminder>> _loadReminders() async {
    final docs = await _loadReminderDocuments();
    return docs.map((doc) => _parseReminder(doc.id, doc.data())).toList();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _loadReminderDocuments() async {
    try {
      final nestedSnapshot = await _userRemindersCollection.get();
      if (nestedSnapshot.docs.isNotEmpty) {
        return nestedSnapshot.docs;
      }
    } on FirebaseException {
      return const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    }

    final documents = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    final seenPaths = <String>{};

    for (final collection in _rootCollectionCandidates) {
      for (final ownerField in _ownerFieldCandidates) {
        QuerySnapshot<Map<String, dynamic>> snapshot;
        try {
          snapshot = await _firestore
              .collection(collection)
              .where(ownerField, isEqualTo: userId)
              .get();
        } on FirebaseException {
          continue;
        }
        for (final doc in snapshot.docs) {
          if (seenPaths.add(doc.reference.path)) {
            documents.add(doc);
          }
        }
      }
    }

    return documents;
  }

  Future<DocumentReference<Map<String, dynamic>>?> _findReminderReference(
    String reminderId,
  ) async {
    try {
      final nestedByDocId = await _userRemindersCollection
          .doc(reminderId)
          .get();
      if (nestedByDocId.exists) {
        return nestedByDocId.reference;
      }
    } on FirebaseException {
      return null;
    }

    try {
      final nestedSnapshot = await _userRemindersCollection
          .where('id', isEqualTo: reminderId)
          .get();
      if (nestedSnapshot.docs.isNotEmpty) {
        return nestedSnapshot.docs.first.reference;
      }
    } on FirebaseException {
      return null;
    }

    final rootDocs = await _loadReminderDocuments();
    for (final doc in rootDocs) {
      final reminder = _parseReminder(doc.id, doc.data());
      if (reminder.id == reminderId) {
        return doc.reference;
      }
    }

    return null;
  }

  Future<List<VitaminCatalogItem>> _loadCatalogItems() async {
    final items = <VitaminCatalogItem>[];
    final seenIds = <String>{};

    for (final collectionName in _catalogCollectionCandidates) {
      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await _firestore.collection(collectionName).limit(300).get();
      } on FirebaseException {
        continue;
      }
      if (snapshot.docs.isEmpty) {
        continue;
      }

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (!_looksLikeCatalogDocument(data)) {
          continue;
        }
        final item = VitaminCatalogItem.fromMap({'id': doc.id, ...data});
        if (item.id.isNotEmpty && seenIds.add(item.id)) {
          items.add(item);
        }
      }

      if (items.isNotEmpty) {
        return items;
      }
    }

    return _fallbackCatalog;
  }

  bool _looksLikeCatalogDocument(Map<String, dynamic> data) {
    const catalogFields = [
      'Supplement',
      'supplement',
      'displayName',
      'display_name',
      'name',
      'title',
      'Compatibility',
      'compatibility_text',
      'Interactions',
      'interaction_text',
      'Contraindications',
      'contraindications_text',
      'Timing',
      'defaultCondition',
      'default_condition',
    ];

    return catalogFields.any((field) {
      final value = data[field];
      return value is String && value.trim().isNotEmpty;
    });
  }

  PharmacyReminder _parseReminder(
    String fallbackId,
    Map<String, dynamic> data,
  ) {
    final rawCatalog = data['catalog'];
    final catalogMap = rawCatalog is Map<String, dynamic>
        ? rawCatalog
        : rawCatalog is Map
        ? rawCatalog.cast<String, dynamic>()
        : <String, dynamic>{};
    final catalogId =
        _readString(data['catalog_id']) ?? _readString(data['catalogId']);
    final catalog = catalogMap.isEmpty
        ? null
        : VitaminCatalogItem.fromMap({
            'id': catalogMap['id'] ?? catalogId ?? '',
            ...catalogMap,
          });

    final title =
        _firstNonEmpty([
          catalog?.displayName,
          _readString(data['title']),
          _readString(data['name']),
          _readString(data['displayName']),
          _readString(data['display_name']),
          _readString(data['catalogDisplayName']),
        ]) ??
        'Витамин';
    final id = _readString(data['id']) ?? fallbackId;
    final courseMap = _toMap(data['course']);
    final scheduleMap = _toMap(data['schedule']);
    final preferencesMap = _toMap(
      data['notification_preferences'] ?? data['notificationPreferences'],
    );
    final overridesMap = _toMap(
      data['content_overrides'] ?? data['contentOverrides'],
    );
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startDate =
        _parseDate(
          _readString(courseMap['start_date']) ??
              _readString(courseMap['startDate']),
        ) ??
        startOfDay;
    final endDate = _parseDate(
      _readString(courseMap['end_date']) ?? _readString(courseMap['endDate']),
    );
    final days = _readStringList(
      scheduleMap['days'],
    ).map(Weekday.fromApiCode).whereType<Weekday>().toList();
    final times = _readStringList(
      scheduleMap['times'],
    ).map((value) => value.trim()).where((value) => value.isNotEmpty).toList();

    return PharmacyReminder(
      id: id,
      title: title,
      isActive:
          _readBool(data['isActive']) ?? _readBool(data['is_active']) ?? true,
      form: _readString(data['form']) ?? 'capsule',
      dose: _readString(data['dose']),
      condition: _readString(data['condition']),
      note: _readString(data['note']),
      catalogId: catalogId,
      catalog: catalog,
      course: ReminderCourse(
        startDate: startDate,
        endDate: endDate,
        timezone: _readString(courseMap['timezone']),
      ),
      schedule: ReminderSchedule(
        days: days.isEmpty ? Weekday.values : days,
        times: times.isEmpty ? [_currentTimeString()] : times,
      ),
      notificationPreferences: ReminderNotificationPreferences(
        includeDose:
            _readBool(preferencesMap['include_dose']) ??
            _readBool(preferencesMap['includeDose']) ??
            true,
        includeFrequency:
            _readBool(preferencesMap['include_frequency']) ??
            _readBool(preferencesMap['includeFrequency']) ??
            true,
        includeInteraction:
            _readBool(preferencesMap['include_interaction']) ??
            _readBool(preferencesMap['includeInteraction']) ??
            true,
        includeCompatibility:
            _readBool(preferencesMap['include_compatibility']) ??
            _readBool(preferencesMap['includeCompatibility']) ??
            true,
        includeCondition:
            _readBool(preferencesMap['include_condition']) ??
            _readBool(preferencesMap['includeCondition']) ??
            true,
        includeContraindications:
            _readBool(preferencesMap['include_contraindications']) ??
            _readBool(preferencesMap['includeContraindications']) ??
            true,
      ),
      contentOverrides: ReminderContentOverrides(
        interactionTextOverride:
            _readString(overridesMap['interaction_text_override']) ??
            _readString(overridesMap['interactionTextOverride']),
        compatibilityTextOverride:
            _readString(overridesMap['compatibility_text_override']) ??
            _readString(overridesMap['compatibilityTextOverride']),
        contraindicationsTextOverride:
            _readString(overridesMap['contraindications_text_override']) ??
            _readString(overridesMap['contraindicationsTextOverride']),
      ),
    );
  }

  Map<String, dynamic> _encodeReminder({
    required String id,
    required PharmacyReminderInput input,
  }) {
    return {
      'id': id,
      'userId': userId,
      'name': input.title.trim(),
      'form': input.form,
      'dose': input.dose.trim(),
      'condition': input.condition,
      'note': input.note.trim(),
      'is_active': true,
      'catalog_id': input.catalogId,
      'catalog': input.catalog?.toMap(),
      'course': {
        'start_date': _formatDate(input.courseStartDate),
        'end_date': input.courseEndDate == null
            ? null
            : _formatDate(input.courseEndDate!),
        'timezone': input.timezone,
      },
      'schedule': {
        'days': input.days.map((day) => day.apiCode).toList(),
        'times': input.times,
      },
      'notification_preferences': {
        'include_dose': input.includeDose,
        'include_frequency': input.includeFrequency,
        'include_interaction': input.includeInteraction,
        'include_compatibility': input.includeCompatibility,
        'include_condition': input.includeCondition,
        'include_contraindications': input.includeContraindications,
      },
      'content_overrides': {
        'interaction_text_override': _normalizeNullableText(
          input.interactionTextOverride,
        ),
        'compatibility_text_override': _normalizeNullableText(
          input.compatibilityTextOverride,
        ),
        'contraindications_text_override': _normalizeNullableText(
          input.contraindicationsTextOverride,
        ),
      },
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  String _formatDate(DateTime value) {
    final normalized = DateTime(value.year, value.month, value.day);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  String _currentTimeString() {
    final now = DateTime.now();
    final hours = now.hour.toString().padLeft(2, '0');
    final minutes = now.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  String? _normalizeNullableText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  Map<String, dynamic> _toMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.cast<String, dynamic>();
    }
    return <String, dynamic>{};
  }

  List<String> _readStringList(Object? value) {
    if (value is Iterable) {
      return value
          .map((entry) => _readString(entry))
          .whereType<String>()
          .toList();
    }
    return const [];
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final normalized = value?.trim();
      if (normalized != null && normalized.isNotEmpty) {
        return normalized;
      }
    }
    return null;
  }

  String? _readString(Object? value) {
    if (value is String) {
      return value;
    }
    if (value is num) {
      return value.toString();
    }
    return null;
  }

  bool? _readBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      switch (value.trim().toLowerCase()) {
        case 'true':
        case '1':
        case 'yes':
          return true;
        case 'false':
        case '0':
        case 'no':
          return false;
      }
    }
    return null;
  }

  static const List<VitaminCatalogItem> _fallbackCatalog = [
    VitaminCatalogItem(
      id: 'vit-a',
      code: 'A',
      displayName: 'Витамин A',
      defaultUnit: 'капсула',
      interactionText:
          'Принимайте согласно инструкции и не превышайте дозировку.',
      compatibilityText: 'Подходит для ежедневного приёма в составе курса.',
      contraindicationsText: 'Проверьте индивидуальную переносимость.',
      defaultCondition: 'after_meal',
    ),
    VitaminCatalogItem(
      id: 'vit-b',
      code: 'B',
      displayName: 'Витамин B',
      defaultUnit: 'таблетка',
      interactionText:
          'Сочетайте с назначенной схемой врача при необходимости.',
      compatibilityText: 'Можно включать в комплексную витаминную программу.',
      contraindicationsText: 'Учитывайте чувствительность к компонентам.',
      defaultCondition: 'after_meal',
    ),
    VitaminCatalogItem(
      id: 'vit-c',
      code: 'C',
      displayName: 'Витамин C',
      defaultUnit: 'таблетка',
      interactionText:
          'Не комбинируйте с другими средствами без необходимости.',
      compatibilityText: 'Хорошо подходит для регулярного контроля курса.',
      contraindicationsText: 'Сверьтесь с рекомендациями по дозировке.',
      defaultCondition: 'after_meal',
    ),
    VitaminCatalogItem(
      id: 'vit-d',
      code: 'D',
      displayName: 'Витамин D',
      defaultUnit: 'капсула',
      interactionText: 'Следите за регулярностью приёма в одно и то же время.',
      compatibilityText: 'Часто используется длительными курсами.',
      contraindicationsText: 'Уточните подходящую дозу у специалиста.',
      defaultCondition: 'after_meal',
    ),
    VitaminCatalogItem(
      id: 'magnesium',
      code: 'Mg',
      displayName: 'Магний',
      defaultUnit: 'таблетка',
      interactionText: 'Не принимайте одновременно с неподходящими добавками.',
      compatibilityText: 'Удобно включать в вечерний режим.',
      contraindicationsText: 'Проверьте ограничения по текущему состоянию.',
      defaultCondition: 'after_meal',
    ),
    VitaminCatalogItem(
      id: 'omega-3',
      code: 'Omega-3',
      displayName: 'Омега-3',
      defaultUnit: 'капсула',
      interactionText: 'Соблюдайте рекомендованную частоту приёма.',
      compatibilityText: 'Часто сочетается с базовыми витаминами курса.',
      contraindicationsText: 'Учитывайте противопоказания к жирным кислотам.',
      defaultCondition: 'during_meal',
    ),
    VitaminCatalogItem(
      id: 'zinc',
      code: 'Zn',
      displayName: 'Цинк',
      defaultUnit: 'таблетка',
      interactionText: 'Соблюдайте интервалы с другими минералами.',
      compatibilityText: 'Подходит для курсового приема по графику.',
      contraindicationsText: 'Не превышайте рекомендованные значения.',
      defaultCondition: 'after_meal',
    ),
    VitaminCatalogItem(
      id: 'iron',
      code: 'Fe',
      displayName: 'Железо',
      defaultUnit: 'капсула',
      interactionText: 'Следуйте назначенной схеме и времени приема.',
      compatibilityText: 'Требует аккуратного сочетания с другими добавками.',
      contraindicationsText: 'При необходимости проконсультируйтесь с врачом.',
      defaultCondition: 'before_meal',
    ),
  ];
}
