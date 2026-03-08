import 'package:flutter/material.dart';

class HomeOnboardingOverlay extends StatelessWidget {
  const HomeOnboardingOverlay({
    super.key,
    required this.step,
    required this.onClose,
    required this.onNext,
    required this.onPrevious,
  });

  final HomeOnboardingStep step;
  final VoidCallback onClose;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: mediaQuery.padding.top + 72),
                Expanded(
                  child: Container(
                    color: const Color(0xFFEFEFEF).withValues(alpha: 0.9),
                  ),
                ),
                SizedBox(height: mediaQuery.padding.bottom + 68),
              ],
            ),
            switch (step) {
              HomeOnboardingStep.schedule => Positioned(
                  left: 16,
                  right: 16,
                  bottom: 100,
                  child: Row(
                    children: [
                      Expanded(child: _OnboardingBubble(step: step, onClose: onClose)),
                      const SizedBox(width: 16),
                      _OnboardingCircleButton(
                        assetPath: 'assets/images/onboarding/back_button.png',
                        rotationQuarterTurns: 2,
                        onTap: onNext,
                      ),
                    ],
                  ),
                ),
              HomeOnboardingStep.pharmacy || HomeOnboardingStep.stats => Positioned(
                  left: 12,
                  right: 12,
                  bottom: 100,
                  child: Row(
                    children: [
                      _OnboardingCircleButton(
                        assetPath: 'assets/images/onboarding/back_button.png',
                        onTap: onPrevious,
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: _OnboardingBubble(step: step, onClose: onClose)),
                      const SizedBox(width: 14),
                      _OnboardingCircleButton(
                        assetPath: 'assets/images/onboarding/back_button.png',
                        rotationQuarterTurns: 2,
                        onTap: onNext,
                      ),
                    ],
                  ),
                ),
              HomeOnboardingStep.profile => Positioned(
                  left: 8,
                  right: 8,
                  top: mathMax(mediaQuery.padding.top + 28, 74),
                  child: Row(
                    children: [
                      _OnboardingCircleButton(
                        assetPath: 'assets/images/onboarding/back_button.png',
                        onTap: onPrevious,
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: _OnboardingBubble(step: step)),
                      const SizedBox(width: 14),
                      _OnboardingCircleButton(
                        assetPath: 'assets/images/onboarding/mark_onboarding.png',
                        iconSize: 26,
                        onTap: onClose,
                      ),
                    ],
                  ),
                ),
            },
          ],
        ),
      ),
    );
  }

  double mathMax(double left, double right) => left > right ? left : right;
}

enum HomeOnboardingStep {
  schedule(
    title: 'Расписание:',
    message: 'Здесь можно посмотреть и отредактировать расписание приема витаминов',
    imagePath: 'assets/images/onboarding/onboarding_1.png',
    progress: '1/4',
  ),
  pharmacy(
    title: 'Аптечка:',
    message:
        'Здесь будут все ваши витамины и информация о них, которую вы можете редактировать',
    imagePath: 'assets/images/onboarding/onboarding_2.png',
    progress: '2/4',
  ),
  stats(
    title: 'Статистика:',
    message: 'Здесь можно посмотреть на статистику приема витаминов за определенный период',
    imagePath: 'assets/images/onboarding/onboarding_3.png',
    progress: '3/4',
  ),
  profile(
    title: 'Профиль:',
    message:
        'Здесь можно настроить вид приложения, напоминания, а также подключить семейный аккаунт (можно нажать на плюс)',
    imagePath: 'assets/images/onboarding/onboarding_4.png',
    progress: '4/4',
  );

  const HomeOnboardingStep({
    required this.title,
    required this.message,
    required this.imagePath,
    required this.progress,
  });

  final String title;
  final String message;
  final String imagePath;
  final String progress;

  HomeOnboardingStep? get next {
    final index = values.indexOf(this);
    if (index >= values.length - 1) {
      return null;
    }
    return values[index + 1];
  }

  HomeOnboardingStep? get previous {
    final index = values.indexOf(this);
    if (index <= 0) {
      return null;
    }
    return values[index - 1];
  }
}

class _OnboardingBubble extends StatelessWidget {
  const _OnboardingBubble({
    required this.step,
    this.onClose,
  });

  final HomeOnboardingStep step;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: step == HomeOnboardingStep.profile ? 248 : 246,
      child: Stack(
        children: [
          Image.asset(step.imagePath, fit: BoxFit.contain),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                step == HomeOnboardingStep.schedule ? 23 : (step == HomeOnboardingStep.profile ? 17 : 15),
                step == HomeOnboardingStep.profile ? 36 : 17,
                step == HomeOnboardingStep.profile ? 21 : (step == HomeOnboardingStep.schedule ? 19 : 15),
                12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          step.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Commissioner',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      if (onClose != null)
                        GestureDetector(
                          onTap: onClose,
                          child: Image.asset(
                            'assets/images/onboarding/close.png',
                            width: 20,
                            height: 20,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  Text(
                    step.message,
                    style: const TextStyle(
                      fontFamily: 'Commissioner',
                      fontSize: 13.54,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      height: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: step == HomeOnboardingStep.schedule ||
                                step == HomeOnboardingStep.profile
                            ? 6
                            : 0,
                      ),
                      child: Text(
                        step.progress,
                        style: const TextStyle(
                          fontFamily: 'Commissioner',
                          fontSize: 16.38,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingCircleButton extends StatelessWidget {
  const _OnboardingCircleButton({
    required this.assetPath,
    required this.onTap,
    this.rotationQuarterTurns = 0,
    this.iconSize = 22,
  });

  final String assetPath;
  final VoidCallback onTap;
  final int rotationQuarterTurns;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: RotatedBox(
          quarterTurns: rotationQuarterTurns,
          child: Image.asset(
            assetPath,
            width: iconSize,
            height: iconSize,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
