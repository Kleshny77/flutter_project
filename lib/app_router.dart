import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/auth_service.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/creating_account_screen.dart';
import 'features/auth/screens/account_created_screen.dart';
import 'features/auth/screens/error_screen.dart';
import 'features/auth/screens/forgot_password_email_screen.dart';
import 'features/auth/screens/forgot_password_sent_screen.dart';
import 'home_screen.dart';

class AppRouter {
  AppRouter(this._authService);

  final AuthService _authService;

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
    refreshListenable: _AuthRefresh(_authService),
    redirect: (context, state) {
      final user = _authService.currentUser;
      final onAuth = state.matchedLocation == welcome ||
          state.matchedLocation == register ||
          state.matchedLocation == login ||
          state.matchedLocation.startsWith(forgotPassword);
      if (user != null && onAuth && state.matchedLocation != accountCreated && state.matchedLocation != creating) {
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
        builder: (context, _) => WelcomeScreen(
          onNext: () => context.push(register),
        ),
      ),
      GoRoute(
        path: register,
        builder: (context, _) => RegisterScreen(
          authService: _authService,
          onRegister: _onRegister,
          onLoginTap: () => context.push(login),
        ),
      ),
      GoRoute(
        path: login,
        builder: (context, _) => LoginScreen(
          authService: _authService,
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
        builder: (context, _) => AccountCreatedScreen(
          onGoToHome: () => context.go(home),
        ),
      ),
      GoRoute(
        path: error,
        builder: (context, state) {
          final message = state.extra as String? ?? 'Не получилось войти в аккаунт. Попробуйте выйти из приложения и повторите попытку.';
          return ErrorScreen(
            message: message,
            onRetry: () => context.pop(),
          );
        },
      ),
      GoRoute(
        path: forgotPassword,
        builder: (context, _) => ForgotPasswordEmailScreen(
          authService: _authService,
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
        builder: (context, _) => HomeScreen(
          user: _authService.currentUser!,
          onSignOut: _onSignOut,
        ),
      ),
    ],
  );

  Future<void> _onRegister(String email, String password, String repeatPassword) async {
    await _authService.signUp(email, password);
  }

  Future<void> _onLogin(String email, String password) async {
    await _authService.signIn(email, password);
  }

  Future<void> _onSendResetCode(String email) async {
    await _authService.sendPasswordResetEmail(email);
  }

  Future<void> _onSignOut() async {
    await _authService.signOut();
  }
}

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(AuthService auth) {
    auth.authStateChanges.listen((_) => notifyListeners());
  }
}
