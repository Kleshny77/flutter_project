import 'package:flutter/material.dart';
import 'core/app_design.dart';

class AppTheme {
  AppTheme._();

  static const Color primaryBlue = AppPalette.blueMain;
  static const Color primaryDarkBlue = AppPalette.blueDark;
  static const Color lightBlue = AppPalette.blueAccent;
  static const Color errorRed = AppPalette.errorRed;
  static const Color successGreen = AppPalette.successGreen;
  static const Color borderGrey = AppPalette.grayLight;
  static const Color textGrey = AppPalette.grayMid;

  static LinearGradient get welcomeGradient => AppGradients.intro;

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          primary: primaryBlue,
          error: errorRed,
          surface: AppPalette.white,
        ),
        scaffoldBackgroundColor: AppPalette.white,
        textTheme: AppTypography.commissioner,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: primaryDarkBlue),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppPalette.inputBg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppPalette.inputBorder, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryBlue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: errorRed),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          hintStyle: const TextStyle(color: AppPalette.placeholder),
        ),
      );
}
