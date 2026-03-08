import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/app_design.dart';
import '../models/home_tab.dart';

class HomeTabBar extends StatelessWidget {
  const HomeTabBar({
    super.key,
    required this.selectedTab,
    required this.maxWidth,
    required this.onSelect,
  });

  final HomeTab selectedTab;
  final double maxWidth;
  final ValueChanged<HomeTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final barWidth = math.min(363.0, math.max(280.0, maxWidth - 30));
    final highlightWidth = barWidth >= 363
        ? 118.0
        : math.min(118.0, (barWidth / 3) - 4);

    return Container(
      width: barWidth,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFFD9D9D9), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.25),
            blurRadius: 2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              alignment: _alignmentFor(selectedTab),
              child: Container(
                width: highlightWidth,
                height: 55,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(80),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.fromRGBO(7, 115, 241, 0.33),
                      Color.fromRGBO(31, 182, 237, 0.14),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: HomeTab.values.map((tab) {
              final isSelected = tab == selectedTab;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onSelect(tab),
                  behavior: HitTestBehavior.opaque,
                  child: _HomeTabBarItem(tab: tab, isSelected: isSelected),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Alignment _alignmentFor(HomeTab tab) {
    switch (tab) {
      case HomeTab.schedule:
        return Alignment.centerLeft;
      case HomeTab.pharmacy:
        return Alignment.center;
      case HomeTab.stats:
        return Alignment.centerRight;
    }
  }
}

class HomeTabBarHost extends StatelessWidget {
  const HomeTabBarHost({
    super.key,
    required this.selectedTab,
    required this.onSelect,
  });

  final HomeTab selectedTab;
  final ValueChanged<HomeTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(bottom: math.max(12, safeBottom)),
      child: Center(
        heightFactor: 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width;
            return HomeTabBar(
              selectedTab: selectedTab,
              maxWidth: maxWidth,
              onSelect: onSelect,
            );
          },
        ),
      ),
    );
  }
}

class _HomeTabBarItem extends StatelessWidget {
  const _HomeTabBarItem({required this.tab, required this.isSelected});

  final HomeTab tab;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 29,
          child: Center(
            child: Transform.translate(
              offset: Offset(0, tab == HomeTab.pharmacy ? -3 : 0),
              child: Opacity(
                opacity: isSelected ? 1 : 0.65,
                child: Image.asset(
                  tab.assetPath,
                  height: tab == HomeTab.pharmacy ? 29 : 27,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 15,
          child: Center(
            child: Text(
              tab.title,
              style: TextStyle(
                fontFamily: 'Commissioner',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppPalette.blueMain.withValues(
                  alpha: isSelected ? 1 : 0.65,
                ),
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
