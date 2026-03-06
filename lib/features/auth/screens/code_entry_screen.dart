import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_theme.dart';
import '../../../core/app_design.dart';
import '../widgets/auth_ui.dart';

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
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _resendSeconds = 0;
  bool _codeError = false;
  bool _verified = false;

  @override
  void initState() {
    super.initState();
    for (final node in _focusNodes) {
      node.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
    }
    _focusNodes.first.requestFocus();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((controller) => controller.text).join();

  void _startResendTimer() {
    setState(() => _resendSeconds = 40);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) {
        return false;
      }
      setState(() => _resendSeconds = (_resendSeconds - 1).clamp(0, 40));
      return _resendSeconds > 0;
    });
  }

  void _onDigitChanged(int index, String value) {
    final filtered = value.replaceAll(RegExp(r'\D'), '');

    if (filtered.length > 1) {
      for (
        var offset = 0;
        offset < filtered.length && index + offset < 6;
        offset++
      ) {
        _controllers[index + offset].text = filtered[offset];
      }
      final target = (index + filtered.length).clamp(0, 5);
      if (target < 6) {
        _focusNodes[target].requestFocus();
      }
    } else {
      final digit = filtered.isEmpty
          ? ''
          : filtered.substring(filtered.length - 1);
      _controllers[index].value = TextEditingValue(
        text: digit,
        selection: TextSelection.collapsed(offset: digit.length),
      );
      if (digit.isNotEmpty) {
        if (index < 5) {
          _focusNodes[index + 1].requestFocus();
        } else {
          _focusNodes[index].unfocus();
        }
      } else if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }

    setState(() {
      _codeError = false;
      _verified = false;
    });
    _checkComplete();
  }

  void _checkComplete() {
    if (_code.length == 6 && RegExp(r'^\d{6}$').hasMatch(_code)) {
      widget.onCodeVerified(_code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageScaffold(
      showBackButton: true,
      onBack: widget.onBack,
      child: Column(
        children: [
          const Text(
            'Введите код из e-mail',
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
          Text(
            'Отправили его на ${widget.email}',
            style: const TextStyle(
              fontFamily: 'Commissioner',
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppPalette.authSubtitle,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, _buildCodeField),
          ),
          const SizedBox(height: 10),
          Opacity(
            opacity: _codeError ? 1 : 0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(Icons.error, size: 12, color: AppTheme.errorRed),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Неверный код',
                  style: TextStyle(
                    fontFamily: 'Commissioner',
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.errorRed,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          if (_resendSeconds > 0)
            Text(
              'Получить код ещё раз через $_resendSeconds сек.',
              style: const TextStyle(
                fontFamily: 'Commissioner',
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AppPalette.authSubtitle,
              ),
              textAlign: TextAlign.center,
            )
          else
            GestureDetector(
              onTap: () async {
                await widget.onResendCode();
                _startResendTimer();
              },
              child: const Text(
                'Получить код ещё раз',
                style: TextStyle(
                  fontFamily: 'Commissioner',
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppPalette.blueMain,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCodeField(int index) {
    final isFocused = _focusNodes[index].hasFocus;
    final borderColor = _codeError
        ? (isFocused ? AppPalette.authCodeBorderFocus : AppPalette.errorRed)
        : isFocused
        ? AppPalette.authCodeBorderFocus
        : _verified
        ? AppPalette.authCodeBorderSuccess
        : AppPalette.authSubtitle;

    return Padding(
      padding: EdgeInsets.only(right: index == 5 ? 0 : 10),
      child: SizedBox(
        width: 50,
        height: 75,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppPalette.authCodeBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.16),
                    blurRadius: 4,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),
            if (_controllers[index].text.isEmpty)
              const Text(
                '0',
                style: TextStyle(
                  fontFamily: 'Commissioner',
                  fontSize: 36.6,
                  fontWeight: FontWeight.w400,
                  color: Color.fromRGBO(117, 117, 117, 0.4),
                ),
              ),
            TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              textInputAction: TextInputAction.next,
              style: const TextStyle(
                fontFamily: 'Commissioner',
                fontSize: 36.6,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
              cursorColor: Colors.transparent,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) => _onDigitChanged(index, value),
            ),
          ],
        ),
      ),
    );
  }
}
