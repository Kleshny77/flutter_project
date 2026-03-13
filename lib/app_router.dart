import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/app_analytics.dart' show AppAnalytics, AppAnalyticsInterface;
import 'domain/repositories/auth_repository.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/creating_account_screen.dart';
import 'features/auth/screens/account_created_screen.dart';
import 'features/auth/screens/error_screen.dart';
import 'features/auth/screens/forgot_password_email_screen.dart';
import 'features/auth/screens/forgot_password_sent_screen.dart';
import 'features/home/data/home_preferences.dart';
import 'features/home/data/reminder_notification_service.dart';
import 'features/home/screens/home_screen.dart';
import 'features/profile/data/user_profile_repository.dart';

/// Централизованная композиция маршрутов. Зависимости передаются из main.
class AppRouter {
  AppRouter(
    this._authRepository, {
    required UserProfileRepository profileRepository,
    required PostRegistrationOnboardingStorage onboardingStorage,
    AppAnalyticsInterface? analytics,
  }) : _profileRepository = profileRepository,
       _onboardingStorage = onboardingStorage,
       _analytics = analytics ?? AppAnalytics();

  final AuthRepository _authRepository;
  final UserProfileRepository _profileRepository;
  final PostRegistrationOnboardingStorage _onboardingStorage;
  final AppAnalyticsInterface _analytics;

  static const String welcome = '/';
  static const String register = '/register';
  static const String login = '/login';
  static const String creating = '/creating';
  static const String accountCreated = '/account-created';
  static const String error = '/error';
  static const String forgotPassword = '/forgot-password';
  static const String forgotPasswordSent = '/forgot-password-sent';
  static const String home = '/home';

  GoRouter get router => _router;
  late final GoRouter _router = GoRouter(
    initialLocation: welcome,
    refreshListenable: _AuthRefresh(_authRepository),
    redirect: (context, state) {
      final user = _authRepository.currentUser;
      final onAuth =
          state.matchedLocation == welcome ||
          state.matchedLocation == register ||
          state.matchedLocation == login ||
          state.matchedLocation.startsWith(forgotPassword);
      if (user != null &&
          onAuth &&
          state.matchedLocation != accountCreated &&
          state.matchedLocation != creating) {
        return home;
      }
      if (user == null && state.matchedLocation == home) {
        return welcome;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: welcome,
        builder: (context, _) =>
            WelcomeScreen(onNext: () => context.push(register)),
      ),
      GoRoute(
        path: register,
        builder: (context, _) => RegisterScreen(
          authRepository: _authRepository,
          analytics: _analytics,
          onRegister: _onRegister,
          onLoginTap: () => context.push(login),
        ),
      ),
      GoRoute(
        path: login,
        builder: (context, _) => LoginScreen(
          authRepository: _authRepository,
          analytics: _analytics,
          onLogin: _onLogin,
          onForgotPassword: () => context.push(forgotPassword),
          onRegisterTap: () => context.push(register),
        ),
      ),
      GoRoute(
        path: creating,
        builder: (_, __) => const CreatingAccountScreen(),
      ),
      GoRoute(
        path: accountCreated,
        builder: (context, _) =>
            AccountCreatedScreen(onGoToHome: () => context.go(home)),
      ),
      GoRoute(
        path: error,
        builder: (context, state) {
          final message =
              state.extra as String? ??
              'Не получилось войти в аккаунт. Попробуйте выйти из приложения и повторите попытку.';
          return ErrorScreen(message: message, onRetry: () => context.pop());
        },
      ),
      GoRoute(
        path: forgotPassword,
        builder: (context, _) => ForgotPasswordEmailScreen(
          authRepository: _authRepository,
          onSendCode: _onSendResetCode,
          onBack: () => context.pop(),
        ),
      ),
      GoRoute(
        path: forgotPasswordSent,
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return ForgotPasswordSentScreen(
            email: email,
            onLogin: () => context.go(login),
          );
        },
      ),
      GoRoute(
        path: home,
        builder: (context, _) {
          final user = _authRepository.currentUser;
          if (user == null) {
            return const SizedBox.shrink();
          }
          return HomeScreen(
            userId: user.id,
            userEmail: user.email,
            onSignOut: _onSignOut,
            authRepository: _authRepository,
          );
        },
      ),
    ],
  );

  Future<void> _onRegister(
    String email,
    String password,
    String repeatPassword,
  ) async {
    await _authRepository.signUp(email, password);
    final user = _authRepository.currentUser;
    if (user != null) {
      await _profileRepository.upsertEmail(userId: user.id, email: email);
    }
    await _onboardingStorage.markPending();
    await _analytics.logSignUpSuccess();
  }

  Future<void> _onLogin(String email, String password) async {
    await _authRepository.signIn(email, password);
    await _analytics.logLoginSuccess();
  }

  Future<void> _onSendResetCode(String email) async {
    await _authRepository.sendPasswordResetEmail(email);
  }

  Future<void> _onSignOut() async {
    await ReminderNotificationService.instance.cancelAll();
    await _authRepository.signOut();
  }
}

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(AuthRepository authRepository) {
    authRepository.authStateChanges.listen((_) => notifyListeners());
  }
}
