import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app_theme.dart';
import '../auth_service.dart';
import '../widgets/error_text_field.dart';
import '../../../core/validation.dart';

class ForgotPasswordEmailScreen extends StatefulWidget {
  const ForgotPasswordEmailScreen({
    super.key,
    required this.authService,
    required this.onSendCode,
    required this.onBack,
  });

  final AuthService authService;
  final Future<void> Function(String email) onSendCode;
  final VoidCallback onBack;

  @override
  State<ForgotPasswordEmailScreen> createState() => _ForgotPasswordEmailScreenState();
}

class _ForgotPasswordEmailScreenState extends State<ForgotPasswordEmailScreen> {
  final _emailController = TextEditingController();
  String? _emailError;
  String? _authError;
  bool _loading = false;

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
    if (_emailError != null) return;
    setState(() => _loading = true);
    try {
      await widget.onSendCode(_emailController.text);
      if (!mounted) return;
      final router = GoRouter.of(context);
      router.push('/forgot-password-sent', extra: _emailController.text);
    } catch (e) {
      setState(() {
        _authError = widget.authService.mapAuthException(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Введите e-mail',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryDarkBlue,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Укажите почту, которую используете для регистрации. На нее отправим ссылку для восстановления доступа.',
                style: TextStyle(fontSize: 14, color: AppTheme.textGrey),
              ),
              const SizedBox(height: 24),
              ErrorTextField(
                controller: _emailController,
                hint: 'E-mail',
                keyboardType: TextInputType.emailAddress,
                errorText: _emailError ?? _authError,
                onChanged: (_) => setState(() => _emailError = _authError = null),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Получить код'),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: _loading ? null : widget.onBack,
                  child: const Text(
                    'Помню пароль',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.primaryBlue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
