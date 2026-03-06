import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app_theme.dart';
import '../../../core/app_design.dart';
import '../../../core/validation.dart';
import '../auth_service.dart';
import '../widgets/auth_ui.dart';
import '../widgets/error_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.authService,
    required this.onLogin,
    required this.onForgotPassword,
    required this.onRegisterTap,
  });

  final AuthService authService;
  final Future<void> Function(String email, String password) onLogin;
  final VoidCallback onForgotPassword;
  final VoidCallback onRegisterTap;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;
  String? _authError;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _authError = null;
      _emailError = Validation.email(_emailController.text);
      _passwordError = Validation.password(_passwordController.text);
    });
    if (_emailError != null || _passwordError != null) {
      return;
    }

    setState(() => _loading = true);
    try {
      await widget.onLogin(_emailController.text, _passwordController.text);
    } catch (e) {
      setState(() {
        _authError = widget.authService.mapAuthException(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageScaffold(
      showBackButton: true,
      onBack: () => context.pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Войдите в аккаунт',
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
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: widget.onForgotPassword,
              child: const Text(
                'Забыли пароль?',
                style: TextStyle(
                  fontFamily: 'Commissioner',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppPalette.blueSecondary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
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
            label: 'Войти',
            loading: _loading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
