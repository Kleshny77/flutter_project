import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_design.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../core/validation.dart';
import '../widgets/auth_ui.dart';
import '../widgets/error_text_field.dart';

class ForgotPasswordEmailScreen extends StatefulWidget {
  const ForgotPasswordEmailScreen({
    super.key,
    required this.authRepository,
    required this.onSendCode,
    required this.onBack,
    this.initialEmail,
    this.onSent,
  });

  final AuthRepository authRepository;
  final Future<void> Function(String email) onSendCode;
  final VoidCallback onBack;
  final String? initialEmail;
  final Future<void> Function(String email)? onSent;

  @override
  State<ForgotPasswordEmailScreen> createState() =>
      _ForgotPasswordEmailScreenState();
}

class _ForgotPasswordEmailScreenState extends State<ForgotPasswordEmailScreen> {
  final _emailController = TextEditingController();
  String? _emailError;
  String? _authError;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail?.trim() ?? '';
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _authError = null;
      _emailError = Validation.email(_emailController.text);
    });
    if (_emailError != null) {
      return;
    }

    setState(() => _loading = true);
    try {
      await widget.onSendCode(_emailController.text);
      if (!mounted) {
        return;
      }
      if (widget.onSent != null) {
        await widget.onSent!(_emailController.text.trim());
        if (mounted) {
          widget.onBack();
        }
        return;
      }
      GoRouter.of(
        context,
      ).push('/forgot-password-sent', extra: _emailController.text);
    } catch (e) {
      setState(() {
        _authError = widget.authRepository.mapAuthException(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageScaffold(
      showBackButton: true,
      onBack: widget.onBack,
      horizontalPadding: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Введите email',
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
          const SizedBox(height: 8),
          const Text(
            'Укажите почту, которую использовали\nпри регистрации. На нее отправим код\nдля восстановления доступа',
            style: TextStyle(
              fontFamily: 'Commissioner',
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppPalette.authSubtitle,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ErrorTextField(
            controller: _emailController,
            hint: 'E-mail',
            keyboardType: TextInputType.emailAddress,
            errorText: _emailError ?? _authError,
            onChanged: (_) => setState(() {
              _emailError = null;
              _authError = null;
            }),
          ),
          const SizedBox(height: 22),
          AuthPrimaryButton(
            label: 'Продолжить',
            loading: _loading,
            onPressed: _submit,
          ),
          const SizedBox(height: 16),
          const Text(
            'Письмо с кодом приходит в течение нескольких минут',
            style: TextStyle(
              fontFamily: 'Commissioner',
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppPalette.authInfo,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
