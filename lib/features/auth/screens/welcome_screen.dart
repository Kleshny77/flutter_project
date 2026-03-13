import 'dart:math' as math;

import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          final safeTop = MediaQuery.paddingOf(context).top;
          final safeBottom = MediaQuery.paddingOf(context).bottom;
          final imageWidth = math.min(412.0, screenWidth * 0.86);
          final titleFontSize = (screenWidth * 0.088).clamp(24.0, 34.0);
          final subtitleFontSize = (screenWidth * 0.041).clamp(14.0, 16.0);
          final titleBottom = math.max(safeBottom + 186, screenHeight * 0.195);
          final buttonBottom = math.max(safeBottom + 18, 34.0);

          return DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-0.88, 0.9),
                end: Alignment(1.0, -0.94),
                colors: [
                  Color(0xFF0E75F2),
                  Color(0xFF5C8FFB),
                  Color(0xFF8CACFF),
                  Color(0xFFD6FEC2),
                ],
                stops: [0.0, 0.44, 0.76, 1.0],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: -screenHeight * 0.06,
                  right: -screenWidth * 0.1,
                  child: const _WelcomeGlow(
                    size: 430,
                    colors: [
                      Color(0x99D6FEC2),
                      Color(0x3DFFFFFF),
                      Color(0x00FFFFFF),
                    ],
                  ),
                ),
                Positioned(
                  left: -screenWidth * 0.22,
                  bottom: -screenWidth * 0.28,
                  child: const _WelcomeGlow(
                    size: 420,
                    colors: [
                      Color(0x99B8FFE0),
                      Color(0x1BFFFFFF),
                      Color(0x00FFFFFF),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  top: safeTop + 28,
                  child: Image.asset(
                    'assets/images/auth/kodee.png',
                    width: imageWidth,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                Positioned(
                  left: 52,
                  right: 52,
                  bottom: titleBottom,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text.rich(
                        TextSpan(
                          text: 'Добро пожаловать\nв ваш персональный\n',
                          children: const [
                            TextSpan(
                              text: 'трекер',
                              style: TextStyle(color: Color(0xFFD6FEC2)),
                            ),
                            TextSpan(text: ' витаминов'),
                          ],
                        ),
                        style: TextStyle(
                          fontFamily: 'Commissioner',
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.04,
                        ),
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.only(right: 18),
                        child: Text(
                          'Отслеживайте приём и сохраняйте\nбаланс каждый день.',
                          style: TextStyle(
                            fontFamily: 'Commissioner',
                            fontSize: subtitleFontSize,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.96),
                            height: 1.14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 64,
                  right: 64,
                  bottom: buttonBottom,
                  child: SizedBox(
                    height: 60,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Далее',
                          style: TextStyle(
                            fontFamily: 'Commissioner',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WelcomeGlow extends StatelessWidget {
  const _WelcomeGlow({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: colors,
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
      ),
    );
  }
}
