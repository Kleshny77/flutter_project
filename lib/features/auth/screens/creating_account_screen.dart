import 'package:flutter/material.dart';

class CreatingAccountScreen extends StatefulWidget {
  const CreatingAccountScreen({super.key});

  @override
  State<CreatingAccountScreen> createState() => _CreatingAccountScreenState();
}

class _CreatingAccountScreenState extends State<CreatingAccountScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(0.0, 1.08),
          end: Alignment(0.0, -0.08),
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFDEFFCE),
            Color(0xFF6F95FC),
            Color(0xFF0773F1),
          ],
          stops: [0.0, 0.02, 0.55, 0.99],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 72),
              const Text(
                'Создаём аккаунт...',
                style: TextStyle(
                  fontFamily: 'Commissioner',
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              RotationTransition(
                turns: _rotationController,
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: CircularProgressIndicator(
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                    strokeWidth: 6,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.white.withValues(alpha: 0),
                  ),
                ),
              ),
              const Spacer(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
