import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_design.dart';

/// Вводный экран: готовый фон, персонаж Kodee, приветствие, кнопка «Далее».
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.onNext});

  final VoidCallback onNext;

  static const String _assetBackground = 'assets/Rectangle_1972-1f08dae6-9e9b-4423-88ae-f08ec3d810b5.png';
  static const String _assetKodee = 'assets/Kodee-4c925e8d-a60e-4c13-8ebc-518e4d23dbfb.png';

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Готовый фон
        Positioned.fill(
          child: Image.asset(
            _assetBackground,
            fit: BoxFit.cover,
          ),
        ),
        // Персонаж Kodee — слева, как на макете (верхний левый угол, рука в центр)
        Positioned(
          left: -24,
          top: MediaQuery.of(context).padding.top + 8,
          width: 280,
          height: 320,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Image.asset(
              _assetKodee,
              fit: BoxFit.contain,
              height: 300,
            ),
          ),
        ),
        // Текст и кнопка
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(),
                Text(
                  'Добро пожаловать в ваш персональный трекер витаминов',
                  style: GoogleFonts.commissioner(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.white,
                    height: 1.25,
                    letterSpacing: 0,
                    decoration: TextDecoration.none,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Отслеживайте приём и сохраняйте баланс каждый день.',
                  style: GoogleFonts.commissioner(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppPalette.white.withOpacity(0.9),
                    height: 1.35,
                    letterSpacing: 0,
                    decoration: TextDecoration.none,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(14),
                    shadowColor: AppPalette.blueDark.withOpacity(0.25),
                    child: ElevatedButton(
                      onPressed: onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPalette.white,
                        foregroundColor: AppPalette.blueDark,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Далее',
                        style: GoogleFonts.commissioner(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
