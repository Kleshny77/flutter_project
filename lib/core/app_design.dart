// Гайдлайн по дизайну приложения.
// Шрифт: Commissioner. Заголовки — SemiBold, основной текст — Regular, акценты — Medium.
// Кёрнинг 0%. Не выделять текст размером или капсом; не оставлять одно слово на строке и висячие предлоги.
// На цветном фоне под текст — подложка. Не более 1–2 акцентных цветов и 1 фона на экране.
// Не комбинировать #0773F1 и #00FFCC рядом без нейтральных элементов.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Палитра: сине-зелёная гамма
class AppPalette {
  AppPalette._();

  // Синие
  static const Color blueDark = Color(0xFF14305F);
  static const Color blueDeep = Color(0xFF104F9D);
  static const Color blueMain = Color(0xFF0773F1);
  /// Заголовки и ссылки на экранах авторизации (макет Figma)
  static const Color blueTitle = Color(0xFF7298FA);
  /// Кнопка «Зарегистрироваться» (макет: Fill 0E75F2, corner 29)
  static const Color blueButton = Color(0xFF0E75F2);
  /// Фон полей ввода (макет F8FAFB)
  static const Color inputBg = Color(0xFFF8FAFB);
  /// Плейсхолдер в полях (макет 8093A6)
  static const Color placeholder = Color(0xFF8093A6);
  /// Обводка полей ввода: 7298FA 57%, weight 1
  static Color get inputBorder => blueTitle.withOpacity(0.57);
  static const Color blueAccent = Color(0xFF1578F3);
  static const Color blueLight = Color(0xFF8FC3FF);
  static const Color blueBg = Color(0xFF6F95FC);

  // Зелёные
  static const Color greenDark = Color(0xFF08AD9F);
  static const Color greenBright = Color(0xFF00FFCC);
  static const Color greenMain = Color(0xFFD6FEC2);
  static const Color greenAccent = Color(0xFF81F1B2);
  static const Color greenLight = Color(0xFFA9FFDD);

  // Чёрно-белая гамма
  static const Color darkMain = Color(0xFF141414);
  static const Color grayDark = Color(0xFF454545);
  static const Color grayMid = Color(0xFF898989);
  static const Color grayLight = Color(0xFFC4C4C4);
  static const Color bgLight = Color(0xFFF4F4F4);
  static const Color white = Color(0xFFFFFFFF);

  // Семантика
  static const Color errorRed = Color(0xFFDC2626);
  static const Color successGreen = Color(0xFF16A34A);
}

/// Градиент для вводного экрана: синий → светло-зелёный
class AppGradients {
  static const LinearGradient intro = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1578F3),
      Color(0xFF6F95FC),
      Color(0xFF81F1B2),
      Color(0xFFD6FEC2),
    ],
    stops: [0.0, 0.4, 0.7, 1.0],
  );
}

/// Типографика: Commissioner
class AppTypography {
  static TextTheme get commissioner {
    return GoogleFonts.commissionerTextTheme().copyWith(
      headlineMedium: GoogleFonts.commissioner(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppPalette.white,
        letterSpacing: 0,
        decoration: TextDecoration.none,
      ),
      headlineSmall: GoogleFonts.commissioner(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppPalette.darkMain,
        letterSpacing: 0,
        decoration: TextDecoration.none,
      ),
      bodyLarge: GoogleFonts.commissioner(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppPalette.darkMain,
        letterSpacing: 0,
        decoration: TextDecoration.none,
      ),
      bodyMedium: GoogleFonts.commissioner(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppPalette.grayMid,
        letterSpacing: 0,
        decoration: TextDecoration.none,
      ),
      labelLarge: GoogleFonts.commissioner(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        decoration: TextDecoration.none,
      ),
    ).apply(decoration: TextDecoration.none, decorationColor: null);
  }
}
