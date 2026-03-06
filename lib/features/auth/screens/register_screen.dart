import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app_theme.dart';
import '../../../core/app_design.dart';
import '../auth_service.dart';
import '../widgets/error_text_field.dart';
import '../../../core/validation.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.authService,
    required this.onRegister,
    required this.onLoginTap,
  });

  final AuthService authService;
  final Future<void> Function(String email, String password, String repeatPassword) onRegister;
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
    if (_emailError != null || _passwordError != null || _repeatPasswordError != null) {
      return;
    }
    setState(() => _loading = true);
    if (!context.mounted) return;
    final router = GoRouter.of(context);
    router.push('/creating');
    try {
      await widget.onRegister(
        _emailController.text,
        _passwordController.text,
        _repeatPasswordController.text,
      );
      if (!context.mounted) return;
      router.pop();
      router.push('/account-created');
    } catch (e) {
      if (!context.mounted) return;
      router.pop();
      setState(() {
        _authError = widget.authService.mapAuthException(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              Text(
                'Создайте аккаунт',
                style: GoogleFonts.commissioner(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.blueTitle,
                  letterSpacing: 0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ErrorTextField(
                  controller: _emailController,
                  hint: 'E-mail',
                  keyboardType: TextInputType.emailAddress,
                  errorText: _emailError,
                  onChanged: (_) => setState(() => _emailError = null),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ErrorTextField(
                  controller: _passwordController,
                  hint: 'Пароль',
                  obscureText: true,
                  errorText: _passwordError,
                  onChanged: (_) => setState(() => _passwordError = null),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ErrorTextField(
                  controller: _repeatPasswordController,
                  hint: 'Повторите пароль',
                  obscureText: true,
                  errorText: _repeatPasswordError,
                  onChanged: (_) => setState(() => _repeatPasswordError = null),
                ),
              ),
              if (_authError != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error, size: 14, color: AppTheme.errorRed),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _authError!,
                          style: GoogleFonts.commissioner(
                            fontSize: 12,
                            color: AppTheme.errorRed,
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(29),
                  boxShadow: [
                    BoxShadow(
                      color: AppPalette.blueDark.withOpacity(0.2),
                      offset: const Offset(0, 9),
                      blurRadius: 11.6,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.blueButton,
                    foregroundColor: AppPalette.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(29),
                    ),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Зарегистрироваться',
                          style: GoogleFonts.commissioner(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: _loading ? null : widget.onLoginTap,
                  child: Text.rich(
                    TextSpan(
                      text: 'Уже есть аккаунт? ',
                      style: GoogleFonts.commissioner(
                        color: AppPalette.grayDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      children: [
                        TextSpan(
                          text: 'Войти',
                          style: GoogleFonts.commissioner(
                            color: AppPalette.blueTitle,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                            decorationColor: AppPalette.blueTitle,
                          ),
                        ),
                      ],
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
