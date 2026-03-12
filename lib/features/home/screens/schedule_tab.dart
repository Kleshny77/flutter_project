import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/pharmacy_repository.dart';
import '../data/reminder_completion_repository.dart';
import '../data/reminder_content_builder.dart';
import '../models/pharmacy_reminder.dart';
import '../models/pharmacy_reminder_input.dart';
import '../models/weekday.dart';

class ScheduleTab extends StatefulWidget {
  const ScheduleTab({
    super.key,
    required this.repository,
    required this.completionRepository,
    required this.onAdd,
    required this.bottomInset,
    this.onRemindersChanged,
  });

  final PharmacyRepository repository;
  final ReminderCompletionRepository completionRepository;
  final VoidCallback onAdd;
  final double bottomInset;
  final Future<void> Function()? onRemindersChanged;

  @override
  State<ScheduleTab> createState() => ScheduleTabState();
}

class ScheduleTabState extends State<ScheduleTab> {
  static const double _calendarCellWidth = 72;
  static const double _calendarCellHeight = 112;
  static const double _calendarCellGap = 14;
  static const double _calendarHorizontalPadding = 16;

  final ScrollController _calendarScrollController = ScrollController();

  DateTime _selectedDate = _normalizeDate(DateTime.now());
  List<PharmacyReminder> _reminders = const <PharmacyReminder>[];
  Set<String> _takenIds = const <String>{};
  bool _hasLoaded = false;
  bool _hasAnyReminders = false;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerSelectedDate(animated: false);
    });
  }

  void reload() {
    _load();
  }

  @override
  void dispose() {
    _calendarScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entriesForSelectedDate;
    final floatingButtonBottom = MediaQuery.paddingOf(context).bottom + 72;
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Stack(
      fit: StackFit.expand,
      children: [
        RefreshIndicator(
          color: const Color(0xFF0773F1),
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(bottom: widget.bottomInset + 84),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 32, 24, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Расписание',
                      style: TextStyle(
                        fontFamily: 'Commissioner',
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3B3B3B),
                        height: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: screenWidth,
                  height: _calendarCellHeight + 12,
                  child: ListView.separated(
                    controller: _calendarScrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(
                      _calendarHorizontalPadding,
                      6,
                      _calendarHorizontalPadding,
                      6,
                    ),
                    itemBuilder: (context, index) {
                      final date = _monthDays[index];
                      final isSelected = _isSameDay(date, _selectedDate);
                      return _DateCell(
                        width: _calendarCellWidth,
                        date: date,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedDate = date;
                          });
                          _centerSelectedDate(index: index);
                        },
                      );
                    },
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: _calendarCellGap),
                    itemCount: _monthDays.length,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_hasLoaded) const _ScheduleLoadingState(),
                      if (_hasLoaded && entries.isEmpty)
                        _hasAnyReminders
                            ? const _ScheduleEmptyDayState()
                            : const _ScheduleEmptyState(),
                      if (_hasLoaded && entries.isNotEmpty)
                        ..._ScheduleDayPart.values.map((part) {
                          final grouped = entries
                              .where((entry) => entry.dayPart == part)
                              .toList();
                          if (grouped.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: _DayPartSection(
                              part: part,
                              entries: grouped,
                              onToggle: _toggleTaken,
                              onLongPress: _showReminderActions,
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_hasLoaded && !_hasAnyReminders)
          Positioned(
            right: 30,
            bottom: floatingButtonBottom,
            child: _FloatingPlusButton(onTap: widget.onAdd),
          ),
      ],
    );
  }

  Future<void> _load() async {
    final takenIds = await widget.completionRepository.loadTakenIds();

    try {
      final reminders = await widget.repository.fetchReminders();
      if (!mounted) {
        return;
      }

      setState(() {
        _takenIds = takenIds;
        _reminders = reminders;
        _hasLoaded = true;
        _hasAnyReminders = reminders.any(
          (reminder) => reminder.isActive && reminder.schedule.times.isNotEmpty,
        );
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _takenIds = takenIds;
        _reminders = const <PharmacyReminder>[];
        _hasLoaded = true;
        _hasAnyReminders = false;
      });
    }
  }

  Future<void> _toggleTaken(_ScheduleEntry entry) async {
    final updated = Set<String>.from(_takenIds);
    if (updated.contains(entry.id)) {
      updated.remove(entry.id);
      await widget.completionRepository.unmarkTaken(entry.id);
    } else {
      updated.add(entry.id);
      await widget.completionRepository.markTaken(entry.id);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _takenIds = updated;
    });
    await widget.onRemindersChanged?.call();
  }

  Future<void> _showReminderActions(_ScheduleEntry entry) async {
    await showGeneralDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (dialogContext, _, __) {
        return _ReminderActionOverlay(
          entry: entry,
          onAction: (action) => _applyAction(action, entry),
        );
      },
    );
  }

  Future<bool> _applyAction(
    _ScheduleAction action,
    _ScheduleEntry entry,
  ) async {
    try {
      switch (action) {
        case _ScheduleAction.markTaken:
        case _ScheduleAction.unmarkTaken:
          await _toggleTaken(entry);
          break;
        case _ScheduleAction.snooze15:
          await _snooze(entry, 15);
          break;
        case _ScheduleAction.snooze60:
          await _snooze(entry, 60);
          break;
      }

      if (!mounted) {
        return false;
      }
      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Не удалось обновить напоминание: $error',
            style: const TextStyle(fontFamily: 'Commissioner'),
          ),
        ),
      );
      return false;
    }
  }

  Future<void> _snooze(_ScheduleEntry entry, int minutes) async {
    final reminder = entry.reminder;
    final times = reminder.schedule.times.toList();
    final currentIndex = math.min(entry.scheduleTimeIndex, times.length - 1);
    times[currentIndex] = _shiftTime(times[currentIndex], minutes);

    final input = PharmacyReminderInput(
      title: reminder.title,
      form: reminder.form,
      dose: reminder.dose ?? '1 капсула',
      condition: reminder.condition ?? 'after_meal',
      note: reminder.note ?? '',
      catalogId: reminder.catalogId,
      catalog: reminder.catalog,
      courseStartDate: reminder.course.startDate,
      courseEndDate: reminder.course.endDate,
      timezone: reminder.course.timezone ?? 'Europe/Moscow',
      days: reminder.schedule.days,
      times: times,
      includeDose: reminder.notificationPreferences.includeDose,
      includeFrequency: reminder.notificationPreferences.includeFrequency,
      includeInteraction: reminder.notificationPreferences.includeInteraction,
      includeCompatibility:
          reminder.notificationPreferences.includeCompatibility,
      includeCondition: reminder.notificationPreferences.includeCondition,
      includeContraindications:
          reminder.notificationPreferences.includeContraindications,
      interactionTextOverride:
          reminder.contentOverrides.interactionTextOverride,
      compatibilityTextOverride:
          reminder.contentOverrides.compatibilityTextOverride,
      contraindicationsTextOverride:
          reminder.contentOverrides.contraindicationsTextOverride,
    );

    await widget.repository.updateReminder(reminder.id, input);
    await _load();
    await widget.onRemindersChanged?.call();
  }

  List<DateTime> get _monthDays {
    final monthStart = DateTime(_selectedDate.year, _selectedDate.month);
    final monthEnd = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    return List<DateTime>.generate(
      monthEnd.day,
      (index) => DateTime(monthStart.year, monthStart.month, index + 1),
    );
  }

  void _centerSelectedDate({int? index, bool animated = true}) {
    if (!_calendarScrollController.hasClients) {
      return;
    }

    final monthDays = _monthDays;
    if (monthDays.isEmpty) {
      return;
    }

    final targetIndex =
        index ??
        monthDays.indexWhere((date) => _isSameDay(date, _selectedDate));
    if (targetIndex < 0) {
      return;
    }

    final viewportWidth = _calendarScrollController.position.viewportDimension;
    final itemExtent = _calendarCellWidth + _calendarCellGap;
    final targetOffset =
        _calendarHorizontalPadding +
        (targetIndex * itemExtent) +
        (_calendarCellWidth / 2) -
        (viewportWidth / 2);
    final clampedOffset = targetOffset.clamp(
      0.0,
      _calendarScrollController.position.maxScrollExtent,
    );

    if (animated) {
      _calendarScrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    _calendarScrollController.jumpTo(clampedOffset);
  }

  List<_ScheduleEntry> get _entriesForSelectedDate {
    final selected = _normalizeDate(_selectedDate);
    final scheduleDateKey = _isoDate(selected);
    final entries = <_ScheduleEntry>[];

    for (final reminder in _reminders) {
      if (!reminder.isActive || !_appliesToDate(reminder, selected)) {
        continue;
      }

      final times = _normalizedTimes(reminder.schedule.times);
      final displayName =
          reminder.catalog?.displayName?.trim().isNotEmpty == true
          ? reminder.catalog!.displayName!.trim()
          : reminder.title;
      final notificationContent = ReminderContentBuilder.build(reminder);

      for (var index = 0; index < times.length; index++) {
        final time = times[index];
        final id = '${reminder.id}-$scheduleDateKey-$time-$index';
        entries.add(
          _ScheduleEntry(
            id: id,
            reminder: reminder,
            scheduleTimeIndex: index,
            vitaminName: displayName,
            intakeType: _ScheduleIntakeType.fromCondition(reminder.condition),
            time: time,
            count: _countFromDose(reminder.dose),
            infoSections: notificationContent.sections,
            isTaken: _takenIds.contains(id),
          ),
        );
      }
    }

    entries.sort(
      (left, right) => _minutes(left.time).compareTo(_minutes(right.time)),
    );
    return entries;
  }

  bool _appliesToDate(PharmacyReminder reminder, DateTime selectedDate) {
    if (selectedDate.isBefore(_normalizeDate(reminder.course.startDate))) {
      return false;
    }

    final endDate = reminder.course.endDate;
    if (endDate != null && selectedDate.isAfter(_normalizeDate(endDate))) {
      return false;
    }

    final weekday = Weekday.fromDate(selectedDate);
    return reminder.schedule.days.contains(weekday);
  }

  List<String> _normalizedTimes(List<String> rawTimes) {
    final normalized = <String>{};
    for (final time in rawTimes) {
      final parts = time.split(':');
      if (parts.length < 2) {
        continue;
      }
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) {
        continue;
      }
      normalized.add(
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
      );
    }
    return normalized.isEmpty
          ? <String>[_timeString(DateTime.now())]
          : normalized.toList()
      ..sort((a, b) => _minutes(a).compareTo(_minutes(b)));
  }

  int _countFromDose(String? dose) {
    final match = RegExp(r'\d+').firstMatch(dose ?? '');
    return int.tryParse(match?.group(0) ?? '') ?? 1;
  }

  String _shiftTime(String time, int minutesDelta) {
    final total = (_minutes(time) + minutesDelta + 1440) % 1440;
    final hour = total ~/ 60;
    final minute = total % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  static DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  static String _isoDate(DateTime value) {
    final normalized = _normalizeDate(value);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

  static int _minutes(String time) {
    final parts = time.split(':');
    final hour = int.tryParse(parts.elementAt(0)) ?? 0;
    final minute = int.tryParse(parts.elementAt(1)) ?? 0;
    return hour * 60 + minute;
  }

  static String _timeString(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
}

class _DateCell extends StatelessWidget {
  const _DateCell({
    required this.width,
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  final double width;
  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: width,
        height: ScheduleTabState._calendarCellHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Colors.white, Color(0xFF4E73FB), Color(0xFF0773F1)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
          color: isSelected ? null : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 3,
              offset: const Offset(-1, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _weekdayLabel(date.weekday),
                style: const TextStyle(
                  fontFamily: 'Commissioner',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    fontFamily: 'Commissioner',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _weekdayLabel(int weekday) {
    return switch (weekday) {
      DateTime.monday => 'Пн',
      DateTime.tuesday => 'Вт',
      DateTime.wednesday => 'Ср',
      DateTime.thursday => 'Чт',
      DateTime.friday => 'Пт',
      DateTime.saturday => 'Сб',
      DateTime.sunday => 'Вс',
      _ => '',
    };
  }
}

class _ScheduleLoadingState extends StatelessWidget {
  const _ScheduleLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 72),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: Color(0xFF0773F1)),
            SizedBox(height: 14),
            Text(
              'Загружаем расписание...',
              style: TextStyle(
                fontFamily: 'Commissioner',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xCC3B3B3B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleEmptyState extends StatelessWidget {
  const _ScheduleEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Center(
        child: Column(
          children: [
            Image.asset(
              'assets/images/pharmacy/calendar.png',
              width: 142,
              height: 168.62,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            const Text(
              'В расписании пока ничего нет...',
              style: TextStyle(
                fontFamily: 'Commissioner',
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Color(0xCC3B3B3B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'Добавьте витамины в аптечку\nи отслеживайте каждый прием',
              style: TextStyle(
                fontFamily: 'Commissioner',
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Color(0xCC3B3B3B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleEmptyDayState extends StatelessWidget {
  const _ScheduleEmptyDayState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 80),
      child: Center(
        child: Text(
          'На выбранный день приёмов нет',
          style: TextStyle(
            fontFamily: 'Commissioner',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xCC3B3B3B),
          ),
        ),
      ),
    );
  }
}

class _DayPartSection extends StatelessWidget {
  const _DayPartSection({
    required this.part,
    required this.entries,
    required this.onToggle,
    required this.onLongPress,
  });

  final _ScheduleDayPart part;
  final List<_ScheduleEntry> entries;
  final ValueChanged<_ScheduleEntry> onToggle;
  final ValueChanged<_ScheduleEntry> onLongPress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            part.icon,
            const SizedBox(width: 8),
            Text(
              part.title,
              style: const TextStyle(
                fontFamily: 'Commissioner',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3B3B3B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ReminderCard(
              entry: entry,
              onToggle: () => onToggle(entry),
              onLongPress: () => onLongPress(entry),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.entry,
    required this.onToggle,
    required this.onLongPress,
  });

  final _ScheduleEntry entry;
  final VoidCallback onToggle;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: entry.isTaken ? 0.68 : 1,
        child: Container(
          height: 120,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFF2C86FF), Color(0xFF4D92FF), Color(0xFF8EC3DD)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              _ToggleCircle(isOn: entry.isTaken, onTap: onToggle),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.vitaminName,
                      style: const TextStyle(
                        fontFamily: 'Commissioner',
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${entry.intakeType.description} — ${entry.time}',
                      style: const TextStyle(
                        fontFamily: 'Commissioner',
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${entry.count}',
                    style: const TextStyle(
                      fontFamily: 'Commissioner',
                      fontSize: 47.23,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  const Text(
                    'шт',
                    style: TextStyle(
                      fontFamily: 'Commissioner',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleCircle extends StatelessWidget {
  const _ToggleCircle({required this.isOn, required this.onTap});

  final bool isOn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.9),
          border: Border.all(color: Colors.white, width: 1.2),
        ),
        alignment: Alignment.center,
        child: isOn
            ? Image.asset(
                'assets/images/schedule/mark.png',
                width: 14,
                height: 14,
                fit: BoxFit.contain,
              )
            : null,
      ),
    );
  }
}

class _FloatingPlusButton extends StatelessWidget {
  const _FloatingPlusButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: SvgPicture.asset(
          'assets/images/home/plus.svg',
          width: 22,
          height: 22,
        ),
      ),
    );
  }
}

class _ReminderActionOverlay extends StatefulWidget {
  const _ReminderActionOverlay({required this.entry, required this.onAction});

  final _ScheduleEntry entry;
  final Future<bool> Function(_ScheduleAction action) onAction;

  @override
  State<_ReminderActionOverlay> createState() => _ReminderActionOverlayState();
}

class _ReminderActionOverlayState extends State<_ReminderActionOverlay> {
  bool _isSubmitting = false;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isVisible = true;
      });
    });
  }

  void _dismiss() {
    if (_isSubmitting) {
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _handleAction(_ScheduleAction action) async {
    if (_isSubmitting) {
      return;
    }
    setState(() {
      _isSubmitting = true;
    });
    final success = await widget.onAction(action);
    if (!mounted) {
      return;
    }
    if (success) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _dismiss,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                opacity: _isVisible ? 1 : 0,
                child: Container(color: Colors.black.withValues(alpha: 0.38)),
              ),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {},
                        child: AnimatedSlide(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          offset: _isVisible
                              ? Offset.zero
                              : const Offset(0, 0.05),
                          child: AnimatedScale(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                            scale: _isVisible ? 1 : 0.96,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 180),
                              opacity: _isVisible ? 1 : 0,
                              child: Container(
                                width: 340,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Image.asset(
                                          'assets/images/schedule/capsule.png',
                                          width: 36,
                                          height: 40,
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Text(
                                            entry.vitaminName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontFamily: 'Commissioner',
                                              fontSize: 32,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    ...entry.infoSections.expand(
                                      (section) => [
                                        _InfoBlock(
                                          title: section.title,
                                          text: section.text,
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                    ),
                                    if (entry.infoSections.isNotEmpty)
                                      const SizedBox(height: 12),
                                    Center(
                                      child: _PrimaryOverlayButton(
                                        title: entry.isTaken
                                            ? 'Снять прием'
                                            : 'Отметить прием',
                                        loading: _isSubmitting,
                                        onTap: () => _handleAction(
                                          entry.isTaken
                                              ? _ScheduleAction.unmarkTaken
                                              : _ScheduleAction.markTaken,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (!entry.isTaken) ...[
                        const SizedBox(height: 16),
                        AnimatedSlide(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          offset: _isVisible
                              ? Offset.zero
                              : const Offset(0, 0.07),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 220),
                            opacity: _isVisible ? 1 : 0,
                            child: _SecondaryOverlayButton(
                              title: 'Отложить на 15 мин',
                              enabled: !_isSubmitting,
                              onTap: () =>
                                  _handleAction(_ScheduleAction.snooze15),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        AnimatedSlide(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          offset: _isVisible
                              ? Offset.zero
                              : const Offset(0, 0.08),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 240),
                            opacity: _isVisible ? 1 : 0,
                            child: _SecondaryOverlayButton(
                              title: 'Отложить на 1 ч',
                              enabled: !_isSubmitting,
                              onTap: () =>
                                  _handleAction(_ScheduleAction.snooze60),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryOverlayButton extends StatelessWidget {
  const _PrimaryOverlayButton({
    required this.title,
    required this.loading,
    required this.onTap,
  });

  final String title;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(100);

    return SizedBox(
      width: 238,
      height: 56,
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFA6C4DD), Color(0xFF1F7CF4)],
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
            ),
            borderRadius: borderRadius,
          ),
          child: InkWell(
            onTap: loading ? null : onTap,
            borderRadius: borderRadius,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Commissioner',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryOverlayButton extends StatelessWidget {
  const _SecondaryOverlayButton({
    required this.title,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 54,
      child: OutlinedButton(
        onPressed: enabled ? onTap : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFF88A4FF), width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          shadowColor: Colors.black.withValues(alpha: 0.25),
          elevation: 4,
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: const TextStyle(
            fontFamily: 'Commissioner',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.1,
            color: Color(0xFF0773F1),
          ),
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'Commissioner',
          fontSize: 14,
          color: Colors.black,
          height: 1.2,
        ),
        children: [
          TextSpan(
            text: '$title: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          TextSpan(
            text: text,
            style: const TextStyle(fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }
}

enum _ScheduleAction { markTaken, unmarkTaken, snooze15, snooze60 }

enum _ScheduleDayPart {
  morning('Утро'),
  day('День'),
  evening('Вечер'),
  night('Ночь');

  const _ScheduleDayPart(this.title);

  final String title;

  Widget get icon {
    switch (this) {
      case _ScheduleDayPart.morning:
        return Image.asset(
          'assets/images/schedule/rising_sun.png',
          width: 22,
          height: 22,
          fit: BoxFit.contain,
        );
      case _ScheduleDayPart.day:
        return const Icon(Icons.sunny, size: 22, color: Color(0xFF3B3B3B));
      case _ScheduleDayPart.evening:
        return Image.asset(
          'assets/images/schedule/moon.png',
          width: 22,
          height: 22,
          fit: BoxFit.contain,
        );
      case _ScheduleDayPart.night:
        return const Icon(
          Icons.nights_stay_rounded,
          size: 22,
          color: Color(0xFF3B3B3B),
        );
    }
  }
}

enum _ScheduleIntakeType {
  beforeMeal('До еды'),
  afterMeal('После еды'),
  duringMeal('Во время еды');

  const _ScheduleIntakeType(this.description);

  final String description;

  factory _ScheduleIntakeType.fromCondition(String? condition) {
    return switch (condition?.toLowerCase()) {
      'before_meal' => _ScheduleIntakeType.beforeMeal,
      'during_meal' => _ScheduleIntakeType.duringMeal,
      _ => _ScheduleIntakeType.afterMeal,
    };
  }
}

class _ScheduleEntry {
  const _ScheduleEntry({
    required this.id,
    required this.reminder,
    required this.scheduleTimeIndex,
    required this.vitaminName,
    required this.intakeType,
    required this.time,
    required this.count,
    required this.infoSections,
    required this.isTaken,
  });

  final String id;
  final PharmacyReminder reminder;
  final int scheduleTimeIndex;
  final String vitaminName;
  final _ScheduleIntakeType intakeType;
  final String time;
  final int count;
  final List<ReminderInfoSection> infoSections;
  final bool isTaken;

  _ScheduleDayPart get dayPart {
    final totalMinutes = ScheduleTabState._minutes(time);
    if (totalMinutes <= 240) {
      return _ScheduleDayPart.night;
    }
    if (totalMinutes <= 720) {
      return _ScheduleDayPart.morning;
    }
    if (totalMinutes <= 960) {
      return _ScheduleDayPart.day;
    }
    return _ScheduleDayPart.evening;
  }

  _ScheduleEntry copyWith({bool? isTaken}) {
    return _ScheduleEntry(
      id: id,
      reminder: reminder,
      scheduleTimeIndex: scheduleTimeIndex,
      vitaminName: vitaminName,
      intakeType: intakeType,
      time: time,
      count: count,
      infoSections: infoSections,
      isTaken: isTaken ?? this.isTaken,
    );
  }
}
