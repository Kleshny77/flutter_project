import '../models/monthly_vitamin_stats.dart';
import '../models/pharmacy_reminder.dart';
import '../models/weekday.dart';

class ReminderStatisticsService {
  const ReminderStatisticsService();

  List<MonthlyVitaminStats> buildMonthlyStats({
    required List<PharmacyReminder> reminders,
    required Set<String> takenIds,
    DateTime? month,
  }) {
    final now = DateTime.now();
    final currentMonth = DateTime((month ?? now).year, (month ?? now).month);
    final previousMonth = DateTime(currentMonth.year, currentMonth.month - 1);
    final result = <MonthlyVitaminStats>[];

    for (final reminder in reminders) {
      if (!reminder.isActive) {
        continue;
      }

      final currentOccurrences = _occurrencesForMonth(reminder, currentMonth);
      if (currentOccurrences.isEmpty) {
        continue;
      }
      final previousOccurrences = _occurrencesForMonth(reminder, previousMonth);

      final takenCount = currentOccurrences
          .where((occurrence) => takenIds.contains(occurrence.id))
          .length;
      final missedCount = currentOccurrences
          .where(
            (occurrence) =>
                !takenIds.contains(occurrence.id) &&
                occurrence.scheduledAt.isBefore(now),
          )
          .length;
      final remainingCount =
          currentOccurrences.length - takenCount - missedCount;
      final progressPercent = _progressPercent(
        taken: takenCount,
        missed: missedCount,
      );
      final previousTaken = previousOccurrences
          .where((occurrence) => takenIds.contains(occurrence.id))
          .length;
      final previousMissed = previousOccurrences.length - previousTaken;
      final previousProgress = _progressPercent(
        taken: previousTaken,
        missed: previousMissed,
      );

      result.add(
        MonthlyVitaminStats(
          reminder: reminder,
          displayName: reminder.catalog?.displayName?.trim().isNotEmpty == true
              ? reminder.catalog!.displayName!.trim()
              : reminder.title,
          monthLabel: _monthLabel(currentMonth),
          totalCount: currentOccurrences.length,
          takenCount: takenCount,
          missedCount: missedCount,
          remainingCount: remainingCount,
          progressPercent: progressPercent,
          isProgress: progressPercent >= previousProgress,
        ),
      );
    }

    result.sort(
      (left, right) => left.displayName.toLowerCase().compareTo(
        right.displayName.toLowerCase(),
      ),
    );
    return result;
  }

  int _progressPercent({required int taken, required int missed}) {
    final elapsed = taken + missed;
    if (elapsed <= 0) {
      return 0;
    }
    return ((taken / elapsed) * 100).round();
  }

  List<_ReminderOccurrence> _occurrencesForMonth(
    PharmacyReminder reminder,
    DateTime month,
  ) {
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 0);
    final firstDate =
        _normalizeDate(reminder.course.startDate).isAfter(monthStart)
        ? _normalizeDate(reminder.course.startDate)
        : monthStart;
    final reminderEnd = reminder.course.endDate == null
        ? monthEnd
        : _normalizeDate(reminder.course.endDate!);
    final lastDate = reminderEnd.isBefore(monthEnd) ? reminderEnd : monthEnd;
    if (lastDate.isBefore(firstDate)) {
      return const <_ReminderOccurrence>[];
    }

    final times = _normalizedTimes(reminder.schedule.times);
    final occurrences = <_ReminderOccurrence>[];
    for (
      DateTime date = firstDate;
      !date.isAfter(lastDate);
      date = date.add(const Duration(days: 1))
    ) {
      if (!reminder.schedule.days.contains(Weekday.fromDate(date))) {
        continue;
      }
      for (var index = 0; index < times.length; index++) {
        final time = times[index];
        final scheduledAt = _combine(date, time);
        occurrences.add(
          _ReminderOccurrence(
            id: _occurrenceId(reminder.id, date, time, index),
            scheduledAt: scheduledAt,
          ),
        );
      }
    }

    return occurrences;
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
    return normalized.isEmpty ? const <String>['09:00'] : normalized.toList()
      ..sort();
  }

  DateTime _combine(DateTime date, String time) {
    final parts = time.split(':');
    final hour = int.tryParse(parts[0]) ?? 9;
    final minute = int.tryParse(parts[1]) ?? 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _occurrenceId(
    String reminderId,
    DateTime date,
    String time,
    int index,
  ) {
    return '$reminderId-${_isoDate(date)}-$time-$index';
  }

  String _isoDate(DateTime value) {
    final normalized = _normalizeDate(value);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

  String _monthLabel(DateTime month) {
    const months = <String>[
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь',
    ];
    return '${months[month.month - 1]} ${month.year}';
  }
}

class _ReminderOccurrence {
  const _ReminderOccurrence({required this.id, required this.scheduledAt});

  final String id;
  final DateTime scheduledAt;
}
