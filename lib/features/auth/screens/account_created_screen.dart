import 'package:flutter/material.dart';
import '../../../app_theme.dart';

class AccountCreatedScreen extends StatefulWidget {
  const AccountCreatedScreen({super.key, required this.onGoToHome});

  final VoidCallback onGoToHome;

  @override
  State<AccountCreatedScreen> createState() => _AccountCreatedScreenState();
}

class _AccountCreatedScreenState extends State<AccountCreatedScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _pulseController;
  late Animation<double> _contentFade;
  late Animation<double> _checkScale;
  late Animation<double> _titleFade;
  late Animation<double> _subtitleFade;
  late Animation<double> _buttonFade;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _contentFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0, 0.4, curve: Curves.easeOut),
      ),
    );
    _checkScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.15, 0.6, curve: Curves.elasticOut),
      ),
    );
    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.7, curve: Curves.easeOut),
      ),
    );
    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.45, 0.8, curve: Curves.easeOut),
      ),
    );
    _buttonFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.6, 1, curve: Curves.easeOut),
      ),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    _pulseScale = Tween<double>(begin: 0.9, end: 1.4).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.5, end: 0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.welcomeGradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              AnimatedBuilder(
                animation: _entranceController,
                builder: (context, _) {
                  return FadeTransition(
                    opacity: _titleFade,
                    child: const Text(
                      'Аккаунт создан!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              AnimatedBuilder(
                animation: _entranceController,
                builder: (context, _) {
                  return FadeTransition(
                    opacity: _subtitleFade,
                    child: const Text(
                      'Теперь вы можете перейти в свою аптечку.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFFBFDBFE),
                        decoration: TextDecoration.none,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) {
                        return Transform.scale(
                          scale: _pulseScale.value,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(_pulseOpacity.value),
                                width: 2,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) {
                        return Transform.scale(
                          scale: _pulseScale.value,
                          child: Container(
                            width: 170,
                            height: 170,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(_pulseOpacity.value * 0.7),
                                width: 2,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    ScaleTransition(
                      scale: _checkScale,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: _entranceController,
                builder: (context, _) {
                  return FadeTransition(
                    opacity: _buttonFade,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: widget.onGoToHome,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primaryDarkBlue,
                        ),
                        child: const Text('Перейти в аптечку'),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
