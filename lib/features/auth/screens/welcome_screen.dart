import 'dart:math' as math;

import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(1.05, 0.1),
            end: Alignment(-0.05, 1.1),
            colors: [
              Color(0xFFD6FEC2),
              Color(0xFF6C94FC),
              Color(0xFF0E75F2),
              Color(0xFFD6FEC2),
            ],
            stops: [0.0739, 0.3153, 0.8206, 0.9768],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final imageSize = math.min(520.0, constraints.maxWidth * 1.34);
              final headerHeight = math.min(
                360.0,
                math.max(250.0, constraints.maxHeight * 0.39),
              );

              return Column(
                children: [
                  SizedBox(
                    height: headerHeight,
                    width: double.infinity,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Transform.translate(
                        offset: const Offset(-50, 10),
                        child: Opacity(
                          opacity: 0.92,
                          child: Image.asset(
                            'assets/images/auth/kodee.png',
                            width: imageSize,
                            height: imageSize,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 41),
                            child: Text.rich(
                              TextSpan(
                                text: 'Добро пожаловать\nв ваш персональный\n',
                                children: const [
                                  TextSpan(
                                    text: 'трекер',
                                    style: TextStyle(color: Color(0xFFD6FEC2)),
                                  ),
                                  TextSpan(text: '\u00A0витаминов'),
                                ],
                              ),
                              style: const TextStyle(
                                fontFamily: 'Commissioner',
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Отслеживайте приём и сохраняйте\nбаланс каждый день.',
                            style: TextStyle(
                              fontFamily: 'Commissioner',
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 60),
                    child: SizedBox(
                      width: 260,
                      child: ElevatedButton(
                        onPressed: onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          minimumSize: const Size.fromHeight(56),
                          elevation: 0,
                          shadowColor: Colors.black.withValues(alpha: 0.18),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text(
                          'Далее',
                          style: TextStyle(
                            fontFamily: 'Commissioner',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
