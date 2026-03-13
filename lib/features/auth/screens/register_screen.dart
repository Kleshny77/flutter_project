import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app_theme.dart';
import '../../../core/app_design.dart';
import '../../../core/validation.dart';
import '../auth_service.dart';
import '../widgets/auth_ui.dart';
import '../widgets/error_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.authService,
    required this.onRegister,
    required this.onLoginTap,
  });

  final AuthService authService;
  final Future<void> Function(
    String email,
    String password,
    String repeatPassword,
  )
  onRegister;
  final VoidCallback onLoginTap;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repeatPasswordController = TextEditingController();

  String? _emailError;
  String? _passwordError;
  String? _repeatPasswordError;
  String? _authError;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _repeatPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _authError = null;
      _emailError = Validation.email(_emailController.text);
      _passwordError = Validation.passwordRegister(_passwordController.text);
      _repeatPasswordError = Validation.repeatPasswordLabel(
        _repeatPasswordController.text,
        _passwordController.text,
      );
    });
    if (_emailError != null ||
        _passwordError != null ||
        _repeatPasswordError != null) {
      return;
    }

    setState(() => _loading = true);
    if (!context.mounted) {
      return;
    }

    final router = GoRouter.of(context);
    router.push('/creating');
    try {
      await widget.onRegister(
        _emailController.text,
        _passwordController.text,
        _repeatPasswordController.text,
      );
      if (!context.mounted) {
        return;
      }
      router.go('/account-created');
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      router.pop();
      setState(() {
        _authError = widget.authService.mapAuthException(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Создайте аккаунт',
            style: TextStyle(
              fontFamily: 'Commissioner',
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppPalette.blueTitle,
              letterSpacing: 0,
              height: 1.05,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ErrorTextField(
            controller: _emailController,
            hint: 'E-mail',
            keyboardType: TextInputType.emailAddress,
            errorText: _emailError,
            onChanged: (_) => setState(() {
              _emailError = null;
              _authError = null;
            }),
          ),
          const SizedBox(height: 9),
          ErrorTextField(
            controller: _passwordController,
            hint: 'Пароль',
            obscureText: true,
            errorText: _passwordError,
            onChanged: (_) => setState(() {
              _passwordError = null;
              _authError = null;
            }),
          ),
          const SizedBox(height: 9),
          ErrorTextField(
            controller: _repeatPasswordController,
            hint: 'Повторите пароль',
            obscureText: true,
            errorText: _repeatPasswordError,
            onChanged: (_) => setState(() {
              _repeatPasswordError = null;
              _authError = null;
            }),
          ),
          if (_authError != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(Icons.error, size: 12, color: AppTheme.errorRed),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _authError!,
                    style: const TextStyle(
                      fontFamily: 'Commissioner',
                      fontSize: 9,
                      color: AppTheme.errorRed,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 22),
          AuthPrimaryButton(
            label: 'Зарегистрироваться',
            loading: _loading,
            onPressed: _submit,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Уже есть аккаунт?',
                style: TextStyle(
                  fontFamily: 'Commissioner',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                  decoration: TextDecoration.underline,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: _loading ? null : widget.onLoginTap,
                child: const Text(
                  'Войти',
                  style: TextStyle(
                    fontFamily: 'Commissioner',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppPalette.blueSecondary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
