import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'app_router.dart';
import 'features/auth/auth_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } on FirebaseException catch (e) {
    // Уже инициализирован нативной частью (macOS/iOS) — запускаем приложение
    if (e.code == 'duplicate-app') {
      _logFirebaseProject();
      runApp(MyApp(router: AppRouter(AuthService())));
      return;
    }
    runApp(_FirebaseNotConfiguredApp(message: e.toString()));
    return;
  } catch (e) {
    runApp(_FirebaseNotConfiguredApp(message: e.toString()));
    return;
  }
  _logFirebaseProject();
  runApp(MyApp(router: AppRouter(AuthService())));
}

void _logFirebaseProject() {
  final app = Firebase.app();
  debugPrint('Firebase: проект ${app.options.projectId}, appId: ${app.options.appId}');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.router});

  final AppRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Трекер витаминов',
      theme: AppTheme.theme,
      routerConfig: router.router,
    );
  }
}

class _FirebaseNotConfiguredApp extends StatelessWidget {
  const _FirebaseNotConfiguredApp({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.theme,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, size: 64, color: AppTheme.primaryBlue),
                const SizedBox(height: 24),
                const Text(
                  'Настройте Firebase',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryDarkBlue,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'В терминале выполните: flutterfire configure\n\nСоздайте проект в Firebase Console (firebase.google.com), затем запустите команду и выберите проект.',
                  style: TextStyle(fontSize: 14, color: AppTheme.textGrey),
                  textAlign: TextAlign.center,
                ),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    message!,
                    style: const TextStyle(fontSize: 12, color: AppTheme.errorRed),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
