import '../entities/auth_user.dart';

/// Абстракция репозитория авторизации (Domain layer).
/// Реализация в Data layer подключается через DI.
abstract class AuthRepository {
  Stream<AuthUser?> get authStateChanges;
  AuthUser? get currentUser;

  Future<void> signUp(String email, String password);
  Future<void> signIn(String email, String password);
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> confirmPasswordReset(String code, String newPassword);

  /// Преобразует исключение авторизации в сообщение для пользователя.
  String? mapAuthException(Object e);
}
