import 'package:flutter/material.dart';

import 'app_design.dart';

/// Общие диалоги приложения в едином стиле (Commissioner, синий акцент).
class AppDialog {
  AppDialog._();

  static const _titleStyle = TextStyle(
    fontFamily: 'Commissioner',
    fontWeight: FontWeight.w700,
    color: Color(0xFF3B3B3B),
  );

  static const _contentStyle = TextStyle(
    fontFamily: 'Commissioner',
    fontSize: 15,
    color: Color(0xFF656565),
  );

  static const _actionStyle = TextStyle(
    fontFamily: 'Commissioner',
    fontWeight: FontWeight.w600,
    color: AppPalette.blueMain,
  );

  /// Показать информационный диалог с кнопкой «Ок».
  static Future<void> showInfo(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: _titleStyle),
        content: Text(message, style: _contentStyle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Ок', style: _actionStyle),
          ),
        ],
      ),
    );
  }

  /// Показать диалог подтверждения. Возвращает true при нажатии «подтвердить», false при «отмена», null при закрытии.
  static Future<bool?> showConfirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Да',
    String cancelText = 'Отмена',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: _titleStyle),
        content: Text(message, style: _contentStyle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelText, style: _actionStyle),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmText, style: _actionStyle),
          ),
        ],
      ),
    );
  }
}
