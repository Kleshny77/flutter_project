import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/home_preferences.dart';
import '../data/pharmacy_repository.dart';
import '../models/pharmacy_reminder.dart';
import '../models/pharmacy_reminder_input.dart';
import '../models/weekday.dart';

class ScheduleTab extends StatefulWidget {
  const ScheduleTab({
    super.key,
    required this.repository,
    required this.onAdd,
    required this.bottomInset,
  });

  final PharmacyRepository repository;
  final VoidCallback onAdd;
  final double bottomInset;

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  final ReminderCompletionStorage _completionStorage = ReminderCompletionStorage();

  DateTime _selectedDate = _normalizeDate(DateTime.now());
  List<PharmacyReminder> _reminders = const <PharmacyReminder>[];
  Set<String> _takenIds = const <String>{};
  _ScheduleEntry? _activeEntry;
  bool _hasLoaded = false;
  bool _actionInProgress = false;
  bool _hasAnyReminders = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entriesForSelectedDate;

    return Stack(
      children: [
        RefreshIndicator(
          color: const Color(0xFF0773F1),
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(24, 32, 24, widget.bottomInset + 84),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Расписание',
                    style: TextStyle(
                      fontFamily: 'Commissioner',
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3B3B3B),
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 113,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemBuilder: (context, index) {
                      final date = _monthDays[index];
                      final isSelected = _isSameDay(date, _selectedDate);
                      return _DateCell(
                        date: date,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedDate = date;
                          });
                        },
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemCount: _monthDays.length,
                  ),
                ),
                if (!_hasLoaded) const _ScheduleLoadingState(),
                if (_hasLoaded && entries.isEmpty)
                  _hasAnyReminders
                      ? const _ScheduleEmptyDayState()
                      : const _ScheduleEmptyState(),
                if (_hasLoaded && entries.isNotEmpty)
                  ..._ScheduleDayPart.values.map((part) {
                    final grouped = entries.where((entry) => entry.dayPart == part).toList();
                    if (grouped.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _DayPartSection(
                        part: part,
                        entries: grouped,
                        onToggle: _toggleTaken,
                        onLongPress: (entry) {
                          setState(() {
                            _activeEntry = entry;
                          });
                        },
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        if (_hasLoaded && !_hasAnyReminders)
          Positioned(
            right: 30,
            bottom: widget.bottomInset + 30,
            child: _FloatingPlusButton(onTap: widget.onAdd),
          ),
        if (_activeEntry != null)
          _ReminderActionOverlay(
            entry: _activeEntry!,
            isSubmitting: _actionInProgress,
            onDismiss: () {
              if (_actionInProgress) {
                return;
              }
              setState(() {
                _activeEntry = null;
              });
            },
            onPrimaryAction: () => _applyAction(
              _activeEntry!.isTaken ? _ScheduleAction.unmarkTaken : _ScheduleAction.markTaken,
              _activeEntry!,
            ),
            onSnooze15: () => _applyAction(_ScheduleAction.snooze15, _activeEntry!),
            onSnooze60: () => _applyAction(_ScheduleAction.snooze60, _activeEntry!),
          ),
      ],
    );
  }

  Future<void> _load() async {
    final takenIds = await _completionStorage.load();

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
    } else {
      updated.add(entry.id);
    }
    await _completionStorage.save(updated);
    if (!mounted) {
      return;
    }
    setState(() {
      _takenIds = updated;
      if (_activeEntry?.id == entry.id) {
        _activeEntry = entry.copyWith(isTaken: updated.contains(entry.id));
      }
    });
  }

  Future<void> _applyAction(_ScheduleAction action, _ScheduleEntry entry) async {
    setState(() {
      _actionInProgress = true;
    });

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
        return;
      }

      setState(() {
        _actionInProgress = false;
        _activeEntry = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _actionInProgress = false;
        _activeEntry = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Не удалось обновить напоминание: $error',
            style: const TextStyle(fontFamily: 'Commissioner'),
          ),
        ),
      );
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
      includeCompatibility: reminder.notificationPreferences.includeCompatibility,
      includeCondition: reminder.notificationPreferences.includeCondition,
      includeContraindications:
          reminder.notificationPreferences.includeContraindications,
      interactionTextOverride: reminder.contentOverrides.interactionTextOverride,
      compatibilityTextOverride:
          reminder.contentOverrides.compatibilityTextOverride,
      contraindicationsTextOverride:
          reminder.contentOverrides.contraindicationsTextOverride,
    );

    await widget.repository.updateReminder(reminder.id, input);
    await _load();
  }

  List<DateTime> get _monthDays {
    final monthStart = DateTime(_selectedDate.year, _selectedDate.month);
    final monthEnd = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    return List<DateTime>.generate(
      monthEnd.day,
      (index) => DateTime(monthStart.year, monthStart.month, index + 1),
    );
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
      final displayName = reminder.catalog?.displayName?.trim().isNotEmpty == true
          ? reminder.catalog!.displayName!.trim()
          : reminder.title;
      final conditionText = _resolvedConditionText(reminder);
      final interactionText = _resolvedInteractionText(reminder);
      final doseText = _resolvedDoseText(reminder, times.length);

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
            doseText: doseText,
            conditionText: conditionText,
            interactionText: interactionText,
            isTaken: _takenIds.contains(id),
          ),
        );
      }
    }

    entries.sort((left, right) => _minutes(left.time).compareTo(_minutes(right.time)));
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

  String _resolvedDoseText(PharmacyReminder reminder, int timesCount) {
    final dose = (reminder.dose ?? '1 капсула').trim();
    return '$dose ${_frequencyDescription(timesCount)}';
  }

  String _resolvedConditionText(PharmacyReminder reminder) {
    final parts = <String>[
      switch (reminder.condition?.toLowerCase()) {
        'before_meal' => 'Принимать до еды.',
        'during_meal' => 'Принимать во время еды.',
        'any' => 'Время приема неважно.',
        _ => 'Принимать после еды.',
      },
      if ((reminder.note ?? '').trim().isNotEmpty) reminder.note!.trim(),
    ];
    return parts.join(' ').trim();
  }

  String _resolvedInteractionText(PharmacyReminder reminder) {
    final values = <String?>[
      reminder.contentOverrides.interactionTextOverride,
      reminder.catalog?.interactionText,
      reminder.contentOverrides.compatibilityTextOverride,
      reminder.catalog?.compatibilityText,
      reminder.contentOverrides.contraindicationsTextOverride,
      reminder.catalog?.contraindicationsText,
    ];
    for (final value in values) {
      final normalized = value?.trim();
      if (normalized != null && normalized.isNotEmpty) {
        return normalized;
      }
    }
    return 'Нет данных о взаимодействии.';
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
        : normalized.toList()..sort((a, b) => _minutes(a).compareTo(_minutes(b)));
  }

  String _frequencyDescription(int count) {
    switch (count) {
      case 1:
        return '1 раз в день';
      case 2:
      case 3:
      case 4:
        return '$count раза в день';
      default:
        return '$count раз в день';
    }
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
    return left.year == right.year && left.month == right.month && left.day == right.day;
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
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 69,
        height: 101,
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
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _weekdayLabel(date.weekday),
                style: const TextStyle(
                  fontFamily: 'Commissioner',
                  fontSize: 20,
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
                    fontSize: 22,
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
        child: Image.asset('assets/images/home/plus.png', width: 22, height: 22),
      ),
    );
  }
}

class _ReminderActionOverlay extends StatelessWidget {
  const _ReminderActionOverlay({
    required this.entry,
    required this.isSubmitting,
    required this.onDismiss,
    required this.onPrimaryAction,
    required this.onSnooze15,
    required this.onSnooze60,
  });

  final _ScheduleEntry entry;
  final bool isSubmitting;
  final VoidCallback onDismiss;
  final VoidCallback onPrimaryAction;
  final VoidCallback onSnooze15;
  final VoidCallback onSnooze60;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.35),
        child: InkWell(
          onTap: onDismiss,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {},
                    child: Container(
                      width: 340,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
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
                          _InfoBlock(title: 'Дозировка', text: entry.doseText),
                          const SizedBox(height: 10),
                          _InfoBlock(title: 'Условия приема', text: entry.conditionText),
                          const SizedBox(height: 10),
                          _InfoBlock(title: 'Взаимодействие', text: entry.interactionText),
                          const SizedBox(height: 22),
                          Center(
                            child: SizedBox(
                              width: 193,
                              height: 52,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFA6C4DD), Color(0xFF1F7CF4)],
                                    begin: Alignment.centerRight,
                                    end: Alignment.centerLeft,
                                  ),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: ElevatedButton(
                                  onPressed: isSubmitting ? null : onPrimaryAction,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    disabledBackgroundColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                  ),
                                  child: isSubmitting
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          entry.isTaken ? 'Снять прием' : 'Отметить прием',
                                          style: const TextStyle(
                                            fontFamily: 'Commissioner',
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!entry.isTaken) ...[
                    const SizedBox(height: 16),
                    _SecondaryOverlayButton(
                      title: 'Отложить на 15 мин',
                      enabled: !isSubmitting,
                      onTap: onSnooze15,
                    ),
                    const SizedBox(height: 10),
                    _SecondaryOverlayButton(
                      title: 'Отложить на 1 ч',
                      enabled: !isSubmitting,
                      onTap: onSnooze60,
                    ),
                  ],
                ],
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
      width: 174,
      height: 40,
      child: OutlinedButton(
        onPressed: enabled ? onTap : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFF88A4FF), width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          shadowColor: Colors.black.withValues(alpha: 0.25),
          elevation: 4,
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Commissioner',
            fontSize: 16,
            fontWeight: FontWeight.w500,
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
        return const Icon(Icons.nights_stay_rounded, size: 22, color: Color(0xFF3B3B3B));
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
    required this.doseText,
    required this.conditionText,
    required this.interactionText,
    required this.isTaken,
  });

  final String id;
  final PharmacyReminder reminder;
  final int scheduleTimeIndex;
  final String vitaminName;
  final _ScheduleIntakeType intakeType;
  final String time;
  final int count;
  final String doseText;
  final String conditionText;
  final String interactionText;
  final bool isTaken;

  _ScheduleDayPart get dayPart {
    final totalMinutes = _ScheduleTabState._minutes(time);
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
      doseText: doseText,
      conditionText: conditionText,
      interactionText: interactionText,
      isTaken: isTaken ?? this.isTaken,
    );
  }
}
