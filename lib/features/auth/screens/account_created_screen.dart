import 'package:flutter/material.dart';

class AccountCreatedScreen extends StatefulWidget {
  const AccountCreatedScreen({super.key, required this.onGoToHome});

  final VoidCallback onGoToHome;

  @override
  State<AccountCreatedScreen> createState() => _AccountCreatedScreenState();
}

class _AccountCreatedScreenState extends State<AccountCreatedScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  bool _didNavigate = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _scale = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack),
    );
    _opacity = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _entranceController.forward();
    _scheduleAutoTransition();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _scheduleAutoTransition() async {
    await Future<void>.delayed(const Duration(milliseconds: 1550));
    _goToHome();
  }

  void _goToHome() {
    if (_didNavigate || !mounted) {
      return;
    }
    _didNavigate = true;
    widget.onGoToHome();
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
                'Аккаунт создан!',
                style: TextStyle(
                  fontFamily: 'Commissioner',
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Теперь вы можете перейти\nв свою аптечку.',
                style: TextStyle(
                  fontFamily: 'Commissioner',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.86),
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              FadeTransition(
                opacity: _opacity,
                child: ScaleTransition(
                  scale: _scale,
                  child: const _SuccessGraphic(),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 52),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _goToHome,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(56),
                      shape: const StadiumBorder(),
                      elevation: 0,
                      shadowColor: Colors.black.withValues(alpha: 0.18),
                    ),
                    child: const Text(
                      'Перейти в аптечку',
                      style: TextStyle(
                        fontFamily: 'Commissioner',
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessGraphic extends StatelessWidget {
  const _SuccessGraphic();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: const [
          _CircleStroke(size: 240, opacity: 0.12),
          _CircleStroke(size: 190, opacity: 0.16),
          _CircleStroke(size: 145, opacity: 0.24),
          _CircleStroke(size: 138, opacity: 1, width: 10),
          Icon(Icons.check, color: Colors.white, size: 56, weight: 700),
        ],
      ),
    );
  }
}

class _CircleStroke extends StatelessWidget {
  const _CircleStroke({
    required this.size,
    required this.opacity,
    this.width = 2,
  });

  final double size;
  final double opacity;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: opacity),
          width: width,
        ),
      ),
    );
  }
}
