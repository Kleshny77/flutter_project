import 'dart:typed_data';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Верхняя шапка домашнего экрана: аватар и кнопка «+».
class HomeTopHeader extends StatelessWidget {
  const HomeTopHeader({
    super.key,
    required this.safeTop,
    required this.onPlusTap,
    required this.onProfileTap,
    this.avatarBytes,
  });

  final double safeTop;
  final VoidCallback onPlusTap;
  final VoidCallback onProfileTap;
  final Uint8List? avatarBytes;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: safeTop + 72,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7087FF).withValues(alpha: 0.2),
            blurRadius: 18,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: EdgeInsets.only(top: safeTop + 10, right: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HomeProfileCircleButton(
                onTap: onProfileTap,
                avatarBytes: avatarBytes,
              ),
              const SizedBox(width: 12),
              HomeSmallPlusCircleButton(onTap: onPlusTap),
            ],
          ),
        ),
      ),
    );
  }
}

/// Круглая кнопка с аватаром в шапке дома.
class HomeProfileCircleButton extends StatelessWidget {
  const HomeProfileCircleButton({super.key, this.onTap, this.avatarBytes});

  final VoidCallback? onTap;
  final Uint8List? avatarBytes;

  @override
  Widget build(BuildContext context) {
    const size = 46.0;
    final borderRadius = BorderRadius.circular(size / 2);
    final imageSize = math.max(0.0, size - 2);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              const Color.fromRGBO(231, 240, 255, 0.52),
              const Color(0xFF88A4FF),
              const Color.fromRGBO(180, 210, 255, 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7087FF).withValues(alpha: 0.25),
              blurRadius: 30.1,
              offset: const Offset(0, -14),
            ),
          ],
        ),
        padding: const EdgeInsets.all(1),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: avatarBytes == null
              ? Image.asset(
                  'assets/images/home/profile.png',
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.cover,
                )
              : Image.memory(
                  avatarBytes!,
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.cover,
                ),
        ),
      ),
    );
  }
}

/// Круглая кнопка «+» в шапке дома.
class HomeSmallPlusCircleButton extends StatelessWidget {
  const HomeSmallPlusCircleButton({super.key, required this.onTap});

  final VoidCallback onTap;

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
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: SvgPicture.asset(
          'assets/images/home/plus.svg',
          width: 18,
          height: 18,
        ),
      ),
    );
  }
}
