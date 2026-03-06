import 'package:flutter/material.dart';
import '../../../app_theme.dart';

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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Проверьте почту',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryDarkBlue,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Мы отправили ссылку для сброса пароля на $email. Перейдите по ссылке из письма, затем войдите с новым паролем.',
                style: const TextStyle(fontSize: 16, color: AppTheme.textGrey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onLogin,
                  child: const Text('Войти'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
