import 'package:flutter/material.dart';

import '../../../core/app_design.dart';
import '../../../core/validation.dart';
import '../widgets/auth_ui.dart';
import '../widgets/error_text_field.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key, required this.onSubmit});

  final Future<void> Function(String newPassword, String repeatPassword)
  onSubmit;

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _passwordController = TextEditingController();
  final _repeatController = TextEditingController();

  String? _passwordError;
  String? _repeatError;
  bool _loading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _repeatController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _passwordError = Validation.passwordRegister(_passwordController.text);
      _repeatError = Validation.repeatPassword(
        _repeatController.text,
        _passwordController.text,
      );
    });
    if (_passwordError != null || _repeatError != null) {
      return;
    }

    setState(() => _loading = true);
    try {
      await widget.onSubmit(_passwordController.text, _repeatController.text);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageScaffold(
      showBackButton: true,
      onBack: () => Navigator.of(context).pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Восстановление\nпароля',
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
          const Text(
            'Придумайте новый пароль',
            style: TextStyle(
              fontFamily: 'Commissioner',
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppPalette.authSubtitle,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ErrorTextField(
            controller: _passwordController,
            hint: 'Новый пароль',
            obscureText: true,
            errorText: _passwordError,
            onChanged: (_) => setState(() => _passwordError = null),
          ),
          const SizedBox(height: 9),
          ErrorTextField(
            controller: _repeatController,
            hint: 'Повторите пароль',
            obscureText: true,
            errorText: _repeatError,
            onChanged: (_) => setState(() => _repeatError = null),
          ),
          const SizedBox(height: 22),
          AuthPrimaryButton(
            label: 'Продолжить',
            loading: _loading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
