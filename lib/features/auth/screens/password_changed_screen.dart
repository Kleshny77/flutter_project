import 'package:flutter/material.dart';

import '../../../core/app_design.dart';

class PasswordChangedScreen extends StatelessWidget {
  const PasswordChangedScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  static Future<void> show(BuildContext context, VoidCallback onContinue) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: AppPalette.authCodeBorderSuccess,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Пароль успешно изменён!',
              style: TextStyle(
                fontFamily: 'Commissioner',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppPalette.blueTitle,
                height: 1.05,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onContinue();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.blueButton,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: const Text(
                  'Продолжить',
                  style: TextStyle(
                    fontFamily: 'Commissioner',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
