import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app_theme.dart';
import '../../../core/app_design.dart';
import '../auth_service.dart';
import '../widgets/error_text_field.dart';
import '../../../core/validation.dart';

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
    if (_emailError != null || _passwordError != null) return;
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
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 80,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(23),
            onTap: () => context.pop(),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    offset: const Offset(0, 1),
                    blurRadius: 3.3,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back,
                  color: Color(0xFF333333),
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              Text(
                'Войдите в аккаунт',
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
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: widget.onForgotPassword,
                  child: Text(
                    'Забыли пароль?',
                    style: GoogleFonts.commissioner(
                      fontSize: 14,
                      color: AppPalette.blueTitle,
                      fontWeight: FontWeight.w500,
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
                    const Icon(Icons.error, size: 14, color: AppTheme.errorRed),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _authError!,
                        style: const TextStyle(fontSize: 12, color: AppTheme.errorRed, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
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
                          'Войти',
                          style: GoogleFonts.commissioner(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
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
