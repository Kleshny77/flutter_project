import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';

class UserProfileRepository {
  UserProfileRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore,
       _storage = storage;

  final FirebaseFirestore? _firestore;
  final FirebaseStorage? _storage;

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
      final avatarBytes = await _resolveAvatarBytes(
        userId: userId,
        remoteValue: (data['avatarUrl'] as String? ?? '').trim(),
        fallbackBytes: local.avatarBytes,
      );
      return UserProfile(
        firstName: (data['firstName'] as String? ?? local.firstName).trim(),
        lastName: (data['lastName'] as String? ?? local.lastName).trim(),
        email: (data['email'] as String? ?? local.email).trim().isEmpty
            ? (fallbackEmail ?? local.email).trim()
            : (data['email'] as String).trim(),
        avatarBytes: avatarBytes,
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
      try {
        final remoteJson = Map<String, Object?>.from(profile.toRemoteJson());
        final avatarUrl = await _uploadAvatar(userId, profile.avatarBytes);
        if (avatarUrl != null && avatarUrl.isNotEmpty) {
          remoteJson['avatarUrl'] = avatarUrl;
        } else if (profile.avatarBytes == null ||
            profile.avatarBytes!.isEmpty) {
          remoteJson['avatarUrl'] = FieldValue.delete();
        }

        await firestore
            .collection('users')
            .doc(userId)
            .set(remoteJson, SetOptions(merge: true));
      } on FirebaseException {
        // Keep local profile working even if Firestore rules are not configured yet.
      }
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
      try {
        await firestore.collection('users').doc(userId).set(<String, Object?>{
          'email': cleanEmail,
        }, SetOptions(merge: true));
      } on FirebaseException {
        // Keep local email working even if Firestore rules are not configured yet.
      }
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
      return UserProfile(
        firstName: '',
        lastName: '',
        email: '',
        avatarBytes: avatarBytes,
      );
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return UserProfile.fromMap(decoded, avatarBytes: avatarBytes);
    } catch (_) {
      return UserProfile(
        firstName: '',
        lastName: '',
        email: '',
        avatarBytes: avatarBytes,
      );
    }
  }

  Future<void> _saveLocalProfile(String userId, UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _profileKey(userId),
      jsonEncode(profile.toLocalJson()),
    );
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

  Future<Uint8List?> _resolveAvatarBytes({
    required String userId,
    required String remoteValue,
    required Uint8List? fallbackBytes,
  }) async {
    if (remoteValue.isEmpty) {
      return fallbackBytes;
    }

    try {
      final bytes = await _downloadAvatarBytes(remoteValue);
      if (bytes != null && bytes.isNotEmpty) {
        await _writeAvatarBytes(userId, bytes);
        return bytes;
      }
    } catch (_) {
      // Ignore remote avatar failures and keep local cache.
    }

    return fallbackBytes;
  }

  Future<String?> _uploadAvatar(String userId, Uint8List? avatarBytes) async {
    if (avatarBytes == null || avatarBytes.isEmpty) {
      return null;
    }

    final storage = _resolveStorage();
    if (storage != null) {
      try {
        return await _uploadAvatarToStorage(
          storage: storage,
          userId: userId,
          avatarBytes: avatarBytes,
        );
      } on FirebaseException {
        // Fallback to inline data below.
      }
    }

    return _buildInlineAvatarData(avatarBytes);
  }

  Future<String> _uploadAvatarToStorage({
    required FirebaseStorage storage,
    required String userId,
    required Uint8List avatarBytes,
  }) async {
    final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'users/$userId/profile/$fileName';
    final downloadToken = _generateDownloadToken();
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: <String, String>{
        'firebaseStorageDownloadTokens': downloadToken,
      },
    );

    final candidates = <FirebaseStorage>[storage];
    final fallbackStorage = _fallbackStorage(storage);
    if (fallbackStorage != null &&
        fallbackStorage.bucket.replaceFirst('gs://', '') !=
            storage.bucket.replaceFirst('gs://', '')) {
      candidates.add(fallbackStorage);
    }

    Object? lastError;
    for (final candidate in candidates) {
      final ref = candidate.ref().child(path);
      try {
        await ref.putData(avatarBytes, metadata);
        return _downloadUrlAfterUpload(
          ref: ref,
          path: path,
          downloadToken: downloadToken,
        );
      } on FirebaseException catch (error) {
        lastError = error;
        if (!_shouldRetryWithFallback(error)) {
          rethrow;
        }
      }
    }

    if (lastError is FirebaseException) {
      throw lastError;
    }
    throw StateError('Не удалось загрузить фото профиля в Storage');
  }

  Future<String> _downloadUrlAfterUpload({
    required Reference ref,
    required String path,
    required String downloadToken,
  }) async {
    try {
      return await _getDownloadUrlWithRetry(ref);
    } on FirebaseException catch (error) {
      if (error.code == 'object-not-found' ||
          error.code == 'unauthorized' ||
          error.code == 'permission-denied' ||
          error.code == 'unauthenticated') {
        return _buildTokenizedDownloadUrl(
          bucket: ref.bucket,
          path: path,
          downloadToken: downloadToken,
        );
      }
      rethrow;
    }
  }

  Future<String> _getDownloadUrlWithRetry(Reference ref) async {
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        return await ref.getDownloadURL();
      } catch (error) {
        lastError = error;
        if (error is! FirebaseException || error.code != 'object-not-found') {
          rethrow;
        }
        await Future<void>.delayed(Duration(milliseconds: 250 * (attempt + 1)));
      }
    }

    if (lastError is FirebaseException) {
      throw lastError;
    }
    throw StateError('Не удалось получить URL фото после загрузки');
  }

  Future<Uint8List?> _downloadAvatarBytes(String remoteValue) async {
    final value = remoteValue.trim();
    if (value.isEmpty) {
      return null;
    }

    if (value.startsWith('data:')) {
      return _decodeInlineAvatar(value);
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return _downloadBytesFromUrl(value);
    }

    final storage = _resolveStorage();
    if (storage == null) {
      return null;
    }

    final isUrl = value.startsWith('gs://');
    final ref = isUrl ? storage.refFromURL(value) : storage.ref().child(value);
    return ref.getData(5 * 1024 * 1024);
  }

  Future<Uint8List?> _downloadBytesFromUrl(String value) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(value));
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final bytes = await consolidateHttpClientResponseBytes(response);
      if (bytes.isEmpty) {
        return null;
      }
      return bytes;
    } finally {
      client.close(force: true);
    }
  }

  String? _buildInlineAvatarData(Uint8List avatarBytes) {
    if (avatarBytes.length > 700 * 1024) {
      return null;
    }
    final base64 = base64Encode(avatarBytes);
    return 'data:image/jpeg;base64,$base64';
  }

  Uint8List? _decodeInlineAvatar(String value) {
    final commaIndex = value.indexOf(',');
    if (commaIndex < 0 || commaIndex == value.length - 1) {
      return null;
    }
    return base64Decode(value.substring(commaIndex + 1));
  }

  FirebaseStorage? _fallbackStorage(FirebaseStorage storage) {
    final bucket = storage.bucket.replaceFirst('gs://', '');
    String? altBucket;
    if (bucket.endsWith('.firebasestorage.app')) {
      altBucket = bucket.replaceFirst('.firebasestorage.app', '.appspot.com');
    } else if (bucket.endsWith('.appspot.com')) {
      altBucket = bucket.replaceFirst('.appspot.com', '.firebasestorage.app');
    }
    if (altBucket == null) {
      return null;
    }
    return FirebaseStorage.instanceFor(
      app: storage.app,
      bucket: 'gs://$altBucket',
    );
  }

  bool _shouldRetryWithFallback(FirebaseException error) {
    return error.code == 'object-not-found' ||
        error.code == 'bucket-not-found' ||
        error.code == 'project-not-found';
  }

  String _buildTokenizedDownloadUrl({
    required String bucket,
    required String path,
    required String downloadToken,
  }) {
    final normalizedBucket = bucket.replaceFirst('gs://', '');
    final encodedPath = Uri.encodeComponent(path);
    return 'https://firebasestorage.googleapis.com/v0/b/'
        '$normalizedBucket/o/$encodedPath?alt=media&token=$downloadToken';
  }

  String _generateDownloadToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
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

  FirebaseStorage? _resolveStorage() {
    if (_storage != null) {
      return _storage;
    }
    if (Firebase.apps.isEmpty) {
      return null;
    }
    return FirebaseStorage.instance;
  }

  String _profileKey(String userId) => 'user_profile_v1_$userId';
}
