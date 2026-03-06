import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signUp(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> confirmPasswordReset(String code, String newPassword) async {
    await _auth.confirmPasswordReset(code: code, newPassword: newPassword);
  }

  String? mapAuthException(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'Этот аккаунт уже зарегистрирован';
        case 'invalid-email':
          return 'Проверьте формат: name@domain.com';
        case 'weak-password':
          return 'Ненадежный пароль. Пароль должен быть не менее 8 символов, включать буквы в верхнем и нижнем регистре, содержать цифры и другие знаки';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Неверный e-mail или пароль';
        case 'user-disabled':
          return 'Аккаунт отключён';
        case 'invalid-verification-code':
          return 'Неверный код';
        case 'expired-action-code':
          return 'Ссылка для сброса устарела. Запросите новый код.';
        case 'operation-not-allowed':
          return 'Вход по почте и паролю отключён. В Firebase Console → Authentication → Sign-in method включите «Email/Password».';
        case 'internal-error':
          return 'Ошибка Firebase. Включите в Firebase Console → Authentication → Sign-in method метод «Email/Password» и проверьте интернет.';
        default:
          final msg = e.message ?? '';
          if (msg.contains('internal error') || e.code == 'internal-error') {
            return 'Ошибка Firebase. В Firebase Console откройте Authentication → Sign-in method и включите «Email/Password».';
          }
          return msg.isNotEmpty ? msg : 'Что-то пошло не так';
      }
    }
    return 'Что-то пошло не так';
  }
}
