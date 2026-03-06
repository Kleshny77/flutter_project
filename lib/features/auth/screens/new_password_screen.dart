import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../widgets/error_text_field.dart';
import '../../../core/validation.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({
    super.key,
    required this.onSubmit,
  });

  final Future<void> Function(String newPassword, String repeatPassword) onSubmit;

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
    if (_passwordError != null || _repeatError != null) return;
    setState(() => _loading = true);
    try {
      await widget.onSubmit(_passwordController.text, _repeatController.text);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
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
                'Восстановление пароля',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryDarkBlue,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Придумайте новый пароль',
                style: TextStyle(fontSize: 14, color: AppTheme.textGrey),
              ),
              const SizedBox(height: 24),
              ErrorTextField(
                controller: _passwordController,
                hint: 'Новый пароль',
                obscureText: true,
                errorText: _passwordError,
                onChanged: (_) => setState(() => _passwordError = null),
              ),
              const SizedBox(height: 20),
              ErrorTextField(
                controller: _repeatController,
                hint: 'Повторите пароль',
                obscureText: true,
                errorText: _repeatError,
                onChanged: (_) => setState(() => _repeatError = null),
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
                      : const Text('Продолжить'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
