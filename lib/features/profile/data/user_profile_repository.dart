import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';

class UserProfileRepository {
  UserProfileRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  Future<UserProfile> loadProfile({
    required String userId,
    String? fallbackEmail,
  }) async {
    final local = await _loadLocalProfile(userId);
    final firestore = _resolveFirestore();

    if (firestore == null) {
      if ((fallbackEmail ?? '').trim().isNotEmpty && local.email.isEmpty) {
        return local.copyWith(email: fallbackEmail!.trim());
      }
      return local;
    }

    try {
      final snapshot = await firestore.collection('users').doc(userId).get();
      if (!snapshot.exists) {
        if ((fallbackEmail ?? '').trim().isNotEmpty && local.email.isEmpty) {
          return local.copyWith(email: fallbackEmail!.trim());
        }
        return local;
      }

      final data = snapshot.data() ?? const <String, Object?>{};
      return UserProfile(
        firstName: (data['firstName'] as String? ?? local.firstName).trim(),
        lastName: (data['lastName'] as String? ?? local.lastName).trim(),
        email: (data['email'] as String? ?? local.email).trim().isEmpty
            ? (fallbackEmail ?? local.email).trim()
            : (data['email'] as String).trim(),
        avatarBytes: local.avatarBytes,
      );
    } catch (_) {
      if ((fallbackEmail ?? '').trim().isNotEmpty && local.email.isEmpty) {
        return local.copyWith(email: fallbackEmail!.trim());
      }
      return local;
    }
  }

  Future<void> saveProfile({
    required String userId,
    required UserProfile profile,
  }) async {
    await _saveLocalProfile(userId, profile);

    final firestore = _resolveFirestore();
    if (firestore != null) {
      await firestore.collection('users').doc(userId).set(
        profile.toRemoteJson(),
        SetOptions(merge: true),
      );
    }
  }

  Future<void> upsertEmail({
    required String userId,
    required String email,
  }) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) {
      return;
    }

    final local = await _loadLocalProfile(userId);
    final updated = local.copyWith(email: cleanEmail);
    await _saveLocalProfile(userId, updated);

    final firestore = _resolveFirestore();
    if (firestore != null) {
      await firestore.collection('users').doc(userId).set(
        <String, Object?>{'email': cleanEmail},
        SetOptions(merge: true),
      );
    }
  }

  Future<void> clearLocalProfile(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey(userId));

    final avatarFile = await _avatarFile(userId);
    if (await avatarFile.exists()) {
      await avatarFile.delete();
    }
  }

  Future<UserProfile> _loadLocalProfile(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey(userId));
    final avatarBytes = await _readAvatarBytes(userId);

    if (raw == null || raw.isEmpty) {
      return UserProfile( firstName: '', lastName: '', email: '', avatarBytes: avatarBytes);
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return UserProfile.fromMap(decoded, avatarBytes: avatarBytes);
    } catch (_) {
      return UserProfile( firstName: '', lastName: '', email: '', avatarBytes: avatarBytes);
    }
  }

  Future<void> _saveLocalProfile(String userId, UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey(userId), jsonEncode(profile.toLocalJson()));
    await _writeAvatarBytes(userId, profile.avatarBytes);
  }

  Future<void> _writeAvatarBytes(String userId, Uint8List? bytes) async {
    final avatarFile = await _avatarFile(userId);
    if (bytes == null || bytes.isEmpty) {
      if (await avatarFile.exists()) {
        await avatarFile.delete();
      }
      return;
    }

    if (!await avatarFile.parent.exists()) {
      await avatarFile.parent.create(recursive: true);
    }
    await avatarFile.writeAsBytes(bytes, flush: true);
  }

  Future<Uint8List?> _readAvatarBytes(String userId) async {
    final avatarFile = await _avatarFile(userId);
    if (!await avatarFile.exists()) {
      return null;
    }
    return avatarFile.readAsBytes();
  }

  Future<File> _avatarFile(String userId) async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/user_profile/$userId/avatar.jpg');
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

  String _profileKey(String userId) => 'user_profile_v1_$userId';
}
