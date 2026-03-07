import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/pharmacy_vitamin.dart';

abstract class PharmacyRepository {
  Future<List<PharmacyVitamin>> fetchVitamins();
}

class FirestorePharmacyRepository implements PharmacyRepository {
  FirestorePharmacyRepository({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String userId;
  final FirebaseFirestore _firestore;

  static const List<String> _rootCollectionCandidates = [
    'reminders',
    'vitamins',
  ];
  static const List<String> _ownerFieldCandidates = [
    'userId',
    'user_id',
    'uid',
    'ownerId',
  ];

  @override
  Future<List<PharmacyVitamin>> fetchVitamins() async {
    final docs = await _loadUserDocuments();
    final vitamins =
        docs
            .map((doc) => _parseDocument(doc.id, doc.data()))
            .where((vitamin) => vitamin.isActive)
            .toList()
          ..sort(
            (left, right) =>
                left.title.toLowerCase().compareTo(right.title.toLowerCase()),
          );
    return vitamins;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _loadUserDocuments() async {
    final nestedSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('reminders')
        .get();
    if (nestedSnapshot.docs.isNotEmpty) {
      return nestedSnapshot.docs;
    }

    for (final collection in _rootCollectionCandidates) {
      for (final field in _ownerFieldCandidates) {
        final snapshot = await _firestore
            .collection(collection)
            .where(field, isEqualTo: userId)
            .get();
        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs;
        }
      }
    }

    return const [];
  }

  PharmacyVitamin _parseDocument(String fallbackId, Map<String, dynamic> data) {
    final rawCatalog = data['catalog'];
    final catalog = rawCatalog is Map<String, dynamic>
        ? rawCatalog
        : rawCatalog is Map
        ? rawCatalog.cast<String, dynamic>()
        : const <String, dynamic>{};

    final title =
        _firstNonEmpty([
          _readString(catalog['displayName']),
          _readString(catalog['display_name']),
          _readString(data['title']),
          _readString(data['name']),
          _readString(data['displayName']),
          _readString(data['display_name']),
          _readString(data['catalogDisplayName']),
        ]) ??
        'Витамин';

    final id = _readString(data['id']) ?? fallbackId;
    final isActive =
        _readBool(data['isActive']) ?? _readBool(data['is_active']) ?? true;

    return PharmacyVitamin(id: id, title: title, isActive: isActive);
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
}
