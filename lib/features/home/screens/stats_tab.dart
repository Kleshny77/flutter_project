import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/app_design.dart';
import '../data/pharmacy_repository.dart';
import '../data/reminder_completion_repository.dart';
import '../data/reminder_statistics_service.dart';
import '../models/monthly_vitamin_stats.dart';

class StatsTab extends StatefulWidget {
  const StatsTab({
    super.key,
    required this.repository,
    required this.completionRepository,
    required this.bottomInset,
  });

  final PharmacyRepository repository;
  final ReminderCompletionRepository completionRepository;
  final double bottomInset;

  @override
  State<StatsTab> createState() => StatsTabState();
}

class StatsTabState extends State<StatsTab> {
  final ReminderStatisticsService _statisticsService =
      const ReminderStatisticsService();
  final Duration _switchDuration = const Duration(milliseconds: 420);

  List<MonthlyVitaminStats> _stats = const <MonthlyVitaminStats>[];
  bool _loading = true;
  bool _failed = false;
  int _selectedIndex = 0;
  int _direction = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void reload() {
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _failed = false;
      });
    }

    try {
      final reminders = await widget.repository.fetchReminders();
      final takenIds = await widget.completionRepository.loadTakenIds();
      final stats = _statisticsService.buildMonthlyStats(
        reminders: reminders,
        takenIds: takenIds,
      );
      if (!mounted) {
        return;
      }

      final previousReminderId = _stats.isEmpty
          ? null
          : _stats[_selectedIndex.clamp(0, _stats.length - 1)].reminder.id;
      var nextIndex = 0;
      if (previousReminderId != null) {
        final foundIndex = stats.indexWhere(
          (item) => item.reminder.id == previousReminderId,
        );
        if (foundIndex >= 0) {
          nextIndex = foundIndex;
        }
      }

      setState(() {
        _stats = stats;
        _selectedIndex = stats.isEmpty
            ? 0
            : nextIndex.clamp(0, stats.length - 1);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  void _switchBy(int delta) {
    if (_stats.length <= 1) {
      return;
    }
    setState(() {
      _direction = delta >= 0 ? 1 : -1;
      _selectedIndex = (_selectedIndex + delta + _stats.length) % _stats.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppPalette.blueMain),
      );
    }

    if (_failed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Не удалось загрузить статистику',
              style: TextStyle(
                fontFamily: 'Commissioner',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF656565),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('Повторить')),
          ],
        ),
      );
    }

    if (_stats.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28),
          child: Text(
            'Добавьте витамины и отмечайте приёмы, чтобы увидеть статистику за месяц.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Commissioner',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF656565),
              height: 1.35,
            ),
          ),
        ),
      );
    }

    final stats = _stats[_selectedIndex];

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 32, 24, widget.bottomInset + 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: _switchDuration,
            transitionBuilder: (child, animation) {
              final curved = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              );
              return FadeTransition(
                opacity: curved,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(_direction * 0.12, 0),
                    end: Offset.zero,
                  ).animate(curved),
                  child: child,
                ),
              );
            },
            child: Text(
              stats.displayName,
              key: ValueKey<String>('title-${stats.reminder.id}'),
              style: const TextStyle(
                fontFamily: 'Commissioner',
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3B3B3B),
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: const Color(0xFFD9D9D9)),
          const SizedBox(height: 26),
          Text(
            stats.monthLabel,
            style: const TextStyle(
              fontFamily: 'Commissioner',
              fontSize: 26,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: _switchDuration,
                  child: Column(
                    key: ValueKey<String>('progress-${stats.reminder.id}'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stats.progressTitle,
                        style: const TextStyle(
                          fontFamily: 'Commissioner',
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFC2C2C2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${stats.progressPercent}%',
                        style: const TextStyle(
                          fontFamily: 'Commissioner',
                          fontSize: 30,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Icon(
                stats.isProgress
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                size: 38,
                color: Colors.black,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatsArrowButton(
                icon: Icons.chevron_left_rounded,
                onTap: _stats.length > 1 ? () => _switchBy(-1) : null,
              ),
              Expanded(
                child: Center(
                  child: AnimatedSwitcher(
                    duration: _switchDuration,
                    transitionBuilder: (child, animation) {
                      final curved = CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      );
                      return FadeTransition(
                        opacity: curved,
                        child: RotationTransition(
                          turns: Tween<double>(
                            begin: _direction * 0.12,
                            end: 0,
                          ).animate(curved),
                          child: child,
                        ),
                      );
                    },
                    child: _StatsDonutChart(
                      key: ValueKey<String>('chart-${stats.reminder.id}'),
                      stats: stats,
                    ),
                  ),
                ),
              ),
              _StatsArrowButton(
                icon: Icons.chevron_right_rounded,
                onTap: _stats.length > 1 ? () => _switchBy(1) : null,
                muted: true,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _StatsCounter(
                  value: stats.takenCount,
                  color: const Color(0xFF87DCC7),
                  lines: const ['Отмеченных', 'приемов'],
                ),
              ),
              Expanded(
                child: _StatsCounter(
                  value: stats.missedCount,
                  color: const Color(0xFFF34545),
                  lines: const ['Приема', 'пропущено'],
                ),
              ),
              Expanded(
                child: _StatsCounter(
                  value: stats.remainingCount,
                  color: const Color(0xFF4B82FF),
                  lines: const ['Приемов', 'осталось'],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsArrowButton extends StatelessWidget {
  const _StatsArrowButton({
    required this.icon,
    required this.onTap,
    this.muted = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 46,
      child: IconButton(
        onPressed: onTap,
        splashRadius: 26,
        icon: Icon(
          icon,
          size: 44,
          color: onTap == null
              ? const Color(0xFFD0D0D0)
              : muted
              ? const Color(0xFFA7A7A7)
              : Colors.black,
        ),
      ),
    );
  }
}

class _StatsDonutChart extends StatelessWidget {
  const _StatsDonutChart({super.key, required this.stats});

  final MonthlyVitaminStats stats;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 276,
      height: 276,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 520),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => CustomPaint(
              size: const Size.square(276),
              painter: _DonutChartPainter(
                takenFraction: stats.totalCount == 0
                    ? 0
                    : (stats.takenCount / stats.totalCount) * value,
                missedFraction: stats.totalCount == 0
                    ? 0
                    : (stats.missedCount / stats.totalCount) * value,
                remainingFraction: stats.totalCount == 0
                    ? 0
                    : (stats.remainingCount / stats.totalCount) * value,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${stats.totalCount}',
                style: const TextStyle(
                  fontFamily: 'Commissioner',
                  fontSize: 44,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF202020),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({
    required this.takenFraction,
    required this.missedFraction,
    required this.remainingFraction,
  });

  final double takenFraction;
  final double missedFraction;
  final double remainingFraction;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 46.0;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final ringRect = Rect.fromCircle(center: center, radius: radius);
    const gap = 0.11;
    var startAngle = -math.pi / 2;

    final segments = <({double fraction, Color color})>[
      (fraction: takenFraction, color: const Color(0xFF4FC4AC)),
      (fraction: remainingFraction, color: const Color(0xFF2E9DE3)),
      (fraction: missedFraction, color: const Color(0xFFF25A5A)),
    ];

    for (final segment in segments) {
      if (segment.fraction <= 0) {
        continue;
      }
      final sweep = math
          .max(0.0, (math.pi * 2 * segment.fraction) - gap)
          .toDouble();
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt
        ..strokeWidth = strokeWidth
        ..color = segment.color;
      canvas.drawArc(ringRect, startAngle, sweep, false, paint);
      startAngle += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.takenFraction != takenFraction ||
        oldDelegate.missedFraction != missedFraction ||
        oldDelegate.remainingFraction != remainingFraction;
  }
}

class _StatsCounter extends StatelessWidget {
  const _StatsCounter({
    required this.value,
    required this.color,
    required this.lines,
  });

  final int value;
  final Color color;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          child: Text(
            '$value',
            key: ValueKey<int>(value),
            style: TextStyle(
              fontFamily: 'Commissioner',
              fontSize: 42,
              fontWeight: FontWeight.w500,
              color: color,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 18),
        ...lines.map(
          (line) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              line,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Commissioner',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF656565),
                height: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
