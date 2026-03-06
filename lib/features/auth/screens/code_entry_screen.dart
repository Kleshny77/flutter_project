import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app_theme.dart';

class CodeEntryScreen extends StatefulWidget {
  const CodeEntryScreen({
    super.key,
    required this.email,
    required this.onCodeVerified,
    required this.onResendCode,
    required this.onBack,
  });

  final String email;
  final void Function(String code) onCodeVerified;
  final Future<void> Function() onResendCode;
  final VoidCallback onBack;

  @override
  State<CodeEntryScreen> createState() => _CodeEntryScreenState();
}

class _CodeEntryScreenState extends State<CodeEntryScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _resendSeconds = 0;
  bool _codeError = false;
  final bool _verified = false;

  @override
  void initState() {
    super.initState();
    _focusNodes[0].requestFocus();
    _startResendTimer();
  }

  void _startResendTimer() {
    setState(() => _resendSeconds = 40);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendSeconds = (_resendSeconds - 1).clamp(0, 40));
      return _resendSeconds > 0;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '').split('');
      for (var i = 0; i < digits.length && index + i < 6; i++) {
        _controllers[index + i].text = digits[i];
        if (index + i < 5) _focusNodes[index + i + 1].requestFocus();
      }
      _checkComplete();
      return;
    }
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {
      _codeError = false;
      _checkComplete();
    });
  }

  void _checkComplete() {
    if (_code.length == 6 && RegExp(r'^\d{6}$').hasMatch(_code)) {
      widget.onCodeVerified(_code);
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Введите код из e-mail',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryDarkBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Отправили его на ${widget.email}',
                style: const TextStyle(fontSize: 14, color: AppTheme.textGrey),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) {
                  return SizedBox(
                    width: 44,
                    child: TextField(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (v) => _onDigitChanged(i, v),
                      decoration: InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _codeError
                                ? AppTheme.errorRed
                                : (_verified ? AppTheme.successGreen : AppTheme.borderGrey),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              if (_codeError) ...[
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.error, size: 14, color: AppTheme.errorRed),
                    SizedBox(width: 6),
                    Text('Неверный код', style: TextStyle(fontSize: 12, color: AppTheme.errorRed, fontStyle: FontStyle.italic)),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              Text(
                _resendSeconds > 0
                    ? 'Получить код ещё раз через $_resendSeconds сек.'
                    : 'Получить код ещё раз',
                style: const TextStyle(fontSize: 14, color: AppTheme.textGrey),
              ),
              if (_resendSeconds == 0) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    await widget.onResendCode();
                    _startResendTimer();
                  },
                  child: const Text(
                    'Отправить снова',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
