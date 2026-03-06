import 'package:flutter/material.dart';
import '../../../app_theme.dart';

class PasswordChangedScreen extends StatelessWidget {
  const PasswordChangedScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  static Future<void> show(BuildContext context, VoidCallback onContinue) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: AppTheme.successGreen,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Пароль успешно изменён!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryDarkBlue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onContinue();
                },
                child: const Text('Продолжить'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
