import 'pharmacy_reminder.dart';

class MonthlyVitaminStats {
  const MonthlyVitaminStats({
    required this.reminder,
    required this.displayName,
    required this.monthLabel,
    required this.totalCount,
    required this.takenCount,
    required this.missedCount,
    required this.remainingCount,
    required this.progressPercent,
    required this.isProgress,
  });

  final PharmacyReminder reminder;
  final String displayName;
  final String monthLabel;
  final int totalCount;
  final int takenCount;
  final int missedCount;
  final int remainingCount;
  final int progressPercent;
  final bool isProgress;

  String get progressTitle =>
      isProgress ? 'Прогресс за месяц' : 'Регресс за месяц';
}
