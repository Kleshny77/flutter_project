import 'package:firebase_analytics/firebase_analytics.dart';

/// Абстракция аналитики (для тестов подменяется заглушкой).
abstract class AppAnalyticsInterface {
  Future<void> logSignUpSuccess();
  Future<void> logSignUpError(String message);
  Future<void> logLoginSuccess();
  Future<void> logLoginError(String message);
}

/// Обёртка над Firebase Analytics для единообразной отправки событий.
/// Регистрация и вход: успех (рекомендуемые события) и ошибка (кастомное событие).
class AppAnalytics implements AppAnalyticsInterface {
  AppAnalytics([FirebaseAnalytics? analytics])
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  static const String _methodEmail = 'email';

  /// Успешная регистрация (рекомендуемое событие sign_up).
  @override
  Future<void> logSignUpSuccess() async {
    await _analytics.logSignUp(signUpMethod: _methodEmail);
  }

  /// Ошибка при регистрации.
  @override
  Future<void> logSignUpError(String message) async {
    await _analytics.logEvent(
      name: 'auth_error',
      parameters: <String, Object>{
        'type': 'sign_up',
        'message': _truncate(message, 100),
      },
    );
  }

  /// Успешный вход (рекомендуемое событие login).
  @override
  Future<void> logLoginSuccess() async {
    await _analytics.logLogin(loginMethod: _methodEmail);
  }

  /// Ошибка при входе.
  @override
  Future<void> logLoginError(String message) async {
    await _analytics.logEvent(
      name: 'auth_error',
      parameters: <String, Object>{
        'type': 'login',
        'message': _truncate(message, 100),
      },
    );
  }

  static String _truncate(String s, int maxLength) {
    if (s.length <= maxLength) return s;
    return '${s.substring(0, maxLength)}…';
  }
}
