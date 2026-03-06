import 'package:flutter/material.dart';

import '../../../core/app_design.dart';
import '../widgets/auth_ui.dart';

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AuthPageScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.settings, size: 72, color: AppPalette.authSubtitle),
          const SizedBox(height: 24),
          const Text(
            'Что-то пошло не так...',
            style: TextStyle(
              fontFamily: 'Commissioner',
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppPalette.blueTitle,
              height: 1.05,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Commissioner',
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppPalette.authSubtitle,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          AuthPrimaryButton(label: 'Попробовать снова', onPressed: onRetry),
        ],
      ),
    );
  }
}
