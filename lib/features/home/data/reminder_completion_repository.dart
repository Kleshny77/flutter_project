import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'home_preferences.dart';

class ReminderCompletionRepository {
  ReminderCompletionRepository({
    required this.userId,
    FirebaseFirestore? firestore,
    ReminderCompletionStorage? localStorage,
  }) : _firestore = firestore,
       _localStorage = localStorage ?? ReminderCompletionStorage();

  final String userId;
  final FirebaseFirestore? _firestore;
  final ReminderCompletionStorage _localStorage;

  Future<Set<String>> loadTakenIds() async {
    final local = await _localStorage.load();
    final firestore = _resolveFirestore();
    if (firestore == null) {
      return local;
    }

    try {
      final snapshot = await firestore.collection('users').doc(userId).get();
      final remote = _readRemoteIds(snapshot.data()?['takenEntryIds']);
      if (remote.isEmpty && local.isNotEmpty) {
        await firestore.collection('users').doc(userId).set(<String, Object?>{
          'takenEntryIds': local.toList()..sort(),
        }, SetOptions(merge: true));
        return local;
      }

      if (!_sameSets(local, remote)) {
        await _localStorage.save(remote);
      }
      return remote;
    } on FirebaseException {
      return local;
    }
  }

  Future<void> markTaken(String entryId) async {
    final current = await _localStorage.load();
    current.add(entryId);
    await _localStorage.save(current);

    final firestore = _resolveFirestore();
    if (firestore == null) {
      return;
    }

    try {
      await firestore.collection('users').doc(userId).set(<String, Object?>{
        'takenEntryIds': FieldValue.arrayUnion(<String>[entryId]),
      }, SetOptions(merge: true));
    } on FirebaseException {
      // Local cache is enough to keep the UI responsive.
    }
  }

  Future<void> unmarkTaken(String entryId) async {
    final current = await _localStorage.load();
    current.remove(entryId);
    await _localStorage.save(current);

    final firestore = _resolveFirestore();
    if (firestore == null) {
      return;
    }

    try {
      await firestore.collection('users').doc(userId).set(<String, Object?>{
        'takenEntryIds': FieldValue.arrayRemove(<String>[entryId]),
      }, SetOptions(merge: true));
    } on FirebaseException {
      // Local cache is enough to keep the UI responsive.
    }
  }

  FirebaseFirestore? _resolveFirestore() {
    if (_firestore != null) {
      return _firestore;
    }
    if (Firebase.apps.isEmpty) {
      return null;
    }
    return FirebaseFirestore.instance;
  }

  Set<String> _readRemoteIds(Object? raw) {
    if (raw is! List) {
      return <String>{};
    }
    return raw
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
  }

  bool _sameSets(Set<String> left, Set<String> right) {
    if (left.length != right.length) {
      return false;
    }
    for (final value in left) {
      if (!right.contains(value)) {
        return false;
      }
    }
    return true;
  }
}
