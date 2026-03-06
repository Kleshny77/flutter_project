import 'package:flutter/material.dart';

import '../../../core/app_design.dart';
import '../widgets/auth_ui.dart';

class ForgotPasswordSentScreen extends StatelessWidget {
  const ForgotPasswordSentScreen({
    super.key,
    required this.email,
    required this.onLogin,
  });

  final String email;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return AuthPageScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Проверьте почту',
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
            'Мы отправили ссылку для сброса пароля на\n$email',
            style: const TextStyle(
              fontFamily: 'Commissioner',
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppPalette.authSubtitle,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Перейдите по ссылке из письма,\nзатем войдите с новым паролем.',
            style: TextStyle(
              fontFamily: 'Commissioner',
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppPalette.authSubtitle,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          AuthPrimaryButton(label: 'Войти', onPressed: onLogin),
        ],
      ),
    );
  }
}
