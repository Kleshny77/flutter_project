import 'dart:math' as math;

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = _OnboardingOverlayLayout.resolve(
            step: step,
            size: constraints.biggest,
            padding: mediaQuery.padding,
          );

          return Material(
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
                if (layout.showLeftButton)
                  Positioned(
                    left: layout.sideInset,
                    top: layout.buttonTop,
                    child: _OnboardingCircleButton(
                      assetPath: 'assets/images/onboarding/back_button.png',
                      onTap: onPrevious,
                    ),
                  ),
                Positioned(
                  left: layout.bubbleLeft,
                  top: layout.bubbleTop,
                  child: _OnboardingBubble(
                    step: step,
                    width: layout.bubbleWidth,
                    onClose: step.showsCloseButton ? onClose : null,
                  ),
                ),
                if (layout.showRightButton)
                  Positioned(
                    right: layout.sideInset,
                    top: layout.buttonTop,
                    child: _OnboardingCircleButton(
                      assetPath: layout.rightButtonAssetPath,
                      rotationQuarterTurns:
                          layout.rightButtonRotationQuarterTurns,
                      iconSize: layout.rightButtonIconSize,
                      onTap: layout.rightButtonCompletesFlow ? onClose : onNext,
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

enum HomeOnboardingStep {
  schedule(
    title: 'Расписание:',
    message:
        'Здесь можно посмотреть и отредактировать расписание приема витаминов',
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
    message:
        'Здесь можно посмотреть на статистику приема витаминов за определенный период',
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

  double get aspectRatio => switch (this) {
    HomeOnboardingStep.schedule => 228 / 144,
    HomeOnboardingStep.pharmacy => 232 / 166,
    HomeOnboardingStep.stats => 228 / 156,
    HomeOnboardingStep.profile => 228 / 170,
  };

  bool get showsCloseButton => this != HomeOnboardingStep.profile;

  EdgeInsets get contentPadding => switch (this) {
    HomeOnboardingStep.schedule => const EdgeInsets.fromLTRB(24, 24, 48, 44),
    HomeOnboardingStep.pharmacy => const EdgeInsets.fromLTRB(22, 22, 18, 52),
    HomeOnboardingStep.stats => const EdgeInsets.fromLTRB(22, 22, 56, 52),
    HomeOnboardingStep.profile => const EdgeInsets.fromLTRB(24, 46, 24, 54),
  };

  double get bubbleWidth => switch (this) {
    HomeOnboardingStep.schedule => 282,
    HomeOnboardingStep.pharmacy => 286,
    HomeOnboardingStep.stats => 282,
    HomeOnboardingStep.profile => 274,
  };

  double get titleFontSize => switch (this) {
    HomeOnboardingStep.profile => 15,
    _ => 17,
  };

  double get bodyFontSize => switch (this) {
    HomeOnboardingStep.profile => 13.5,
    _ => 14,
  };

  double get bodyMinFontSize => switch (this) {
    HomeOnboardingStep.profile => 10.8,
    _ => 11.2,
  };

  double get bodyTopSpacing => switch (this) {
    HomeOnboardingStep.profile => 18,
    _ => 14,
  };

  double get closeTop => switch (this) {
    HomeOnboardingStep.schedule => 18,
    HomeOnboardingStep.pharmacy => 16,
    HomeOnboardingStep.stats => 14,
    HomeOnboardingStep.profile => 0,
  };

  double get closeRight => switch (this) {
    HomeOnboardingStep.schedule => 18,
    HomeOnboardingStep.pharmacy => 18,
    HomeOnboardingStep.stats => 20,
    HomeOnboardingStep.profile => 0,
  };

  double get progressRight => switch (this) {
    HomeOnboardingStep.schedule => 24,
    HomeOnboardingStep.pharmacy => 22,
    HomeOnboardingStep.stats => 24,
    HomeOnboardingStep.profile => 22,
  };

  double get progressBottom => switch (this) {
    HomeOnboardingStep.schedule => 30,
    HomeOnboardingStep.pharmacy => 44,
    HomeOnboardingStep.stats => 40,
    HomeOnboardingStep.profile => 26,
  };
}

class _OnboardingOverlayLayout {
  const _OnboardingOverlayLayout({
    required this.bubbleLeft,
    required this.bubbleTop,
    required this.bubbleWidth,
    required this.buttonTop,
    required this.sideInset,
    required this.showLeftButton,
    required this.showRightButton,
    required this.rightButtonAssetPath,
    required this.rightButtonRotationQuarterTurns,
    required this.rightButtonIconSize,
    required this.rightButtonCompletesFlow,
  });

  final double bubbleLeft;
  final double bubbleTop;
  final double bubbleWidth;
  final double buttonTop;
  final double sideInset;
  final bool showLeftButton;
  final bool showRightButton;
  final String rightButtonAssetPath;
  final int rightButtonRotationQuarterTurns;
  final double rightButtonIconSize;
  final bool rightButtonCompletesFlow;

  static _OnboardingOverlayLayout resolve({
    required HomeOnboardingStep step,
    required Size size,
    required EdgeInsets padding,
  }) {
    final maxBubbleWidth = size.width - 158;
    final bubbleWidth = math.min(step.bubbleWidth, maxBubbleWidth);
    final bubbleHeight = bubbleWidth / step.aspectRatio;
    final bubbleLeft = (size.width - bubbleWidth) / 2;
    final bubbleTop = switch (step) {
      HomeOnboardingStep.schedule =>
        size.height - padding.bottom - 82 - bubbleHeight,
      HomeOnboardingStep.pharmacy =>
        size.height - padding.bottom - 98 - bubbleHeight,
      HomeOnboardingStep.stats =>
        size.height - padding.bottom - 104 - bubbleHeight,
      HomeOnboardingStep.profile => padding.top + 136,
    };
    final buttonTop = bubbleTop + (bubbleHeight - 46) / 2;

    return _OnboardingOverlayLayout(
      bubbleLeft: bubbleLeft,
      bubbleTop: bubbleTop,
      bubbleWidth: bubbleWidth,
      buttonTop: buttonTop,
      sideInset: 24,
      showLeftButton: step != HomeOnboardingStep.schedule,
      showRightButton: true,
      rightButtonAssetPath: step == HomeOnboardingStep.profile
          ? 'assets/images/onboarding/mark_onboarding.png'
          : 'assets/images/onboarding/back_button.png',
      rightButtonRotationQuarterTurns: step == HomeOnboardingStep.profile
          ? 0
          : 2,
      rightButtonIconSize: step == HomeOnboardingStep.profile ? 26 : 22,
      rightButtonCompletesFlow: step == HomeOnboardingStep.profile,
    );
  }
}

class _OnboardingBubble extends StatelessWidget {
  const _OnboardingBubble({
    required this.step,
    required this.width,
    this.onClose,
  });

  final HomeOnboardingStep step;
  final double width;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final height = width / step.aspectRatio;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Positioned.fill(child: Image.asset(step.imagePath, fit: BoxFit.fill)),
          Padding(
            padding: step.contentPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    fontFamily: 'Commissioner',
                    fontSize: step.titleFontSize,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF303030),
                    height: 1.05,
                  ),
                ),
                SizedBox(height: step.bodyTopSpacing),
                Expanded(
                  child: _OnboardingFittedText(
                    text: step.message,
                    maxFontSize: step.bodyFontSize,
                    minFontSize: step.bodyMinFontSize,
                  ),
                ),
              ],
            ),
          ),
          if (onClose != null)
            Positioned(
              top: step.closeTop,
              right: step.closeRight,
              child: GestureDetector(
                onTap: onClose,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: Center(
                    child: Image.asset(
                      'assets/images/onboarding/close.png',
                      width: 22,
                      height: 22,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            right: step.progressRight,
            bottom: step.progressBottom,
            child: Text(
              step.progress,
              style: const TextStyle(
                fontFamily: 'Commissioner',
                fontSize: 16.38,
                fontWeight: FontWeight.w400,
                color: Colors.black,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingFittedText extends StatelessWidget {
  const _OnboardingFittedText({
    required this.text,
    required this.maxFontSize,
    required this.minFontSize,
  });

  final String text;
  final double maxFontSize;
  final double minFontSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var resolvedFontSize = maxFontSize;
        final textDirection = Directionality.of(context);

        while (resolvedFontSize > minFontSize) {
          final painter = TextPainter(
            text: TextSpan(
              text: text,
              style: TextStyle(
                fontFamily: 'Commissioner',
                fontSize: resolvedFontSize,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF303030),
                height: 1.24,
              ),
            ),
            textDirection: textDirection,
          )..layout(maxWidth: constraints.maxWidth);

          if (painter.height <= constraints.maxHeight) {
            break;
          }
          resolvedFontSize -= 0.2;
        }

        return Text(
          text,
          style: TextStyle(
            fontFamily: 'Commissioner',
            fontSize: resolvedFontSize,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF303030),
            height: 1.24,
          ),
        );
      },
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
      behavior: HitTestBehavior.opaque,
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
