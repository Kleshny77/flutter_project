import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../features/auth/auth_service.dart';

/// Реализация AuthRepository через Firebase (Data layer).
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl([AuthService? authService])
    : _auth = authService ?? AuthService();

  final AuthService _auth;

  @override
  Stream<AuthUser?> get authStateChanges =>
      _auth.authStateChanges.map(_userToAuthUser);

  @override
  AuthUser? get currentUser => _userToAuthUser(_auth.currentUser);

  static AuthUser? _userToAuthUser(firebase_auth.User? user) {
    if (user == null) return null;
    return AuthUser(id: user.uid, email: user.email);
  }

  @override
  Future<void> signUp(String email, String password) =>
      _auth.signUp(email, password);

  @override
  Future<void> signIn(String email, String password) =>
      _auth.signIn(email, password);

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email);

  @override
  Future<void> confirmPasswordReset(String code, String newPassword) =>
      _auth.confirmPasswordReset(code, newPassword);

  @override
  String? mapAuthException(Object e) => _auth.mapAuthException(e);
}
