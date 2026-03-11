import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/pharmacy_reminder.dart';
import '../models/weekday.dart';
import 'reminder_content_builder.dart';

class ReminderNotificationService {
  ReminderNotificationService._();

  static final ReminderNotificationService instance =
      ReminderNotificationService._();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'vitamin_reminders',
    'Напоминания о витаминах',
    description: 'Напоминания о приеме витаминов',
    importance: Importance.max,
  );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final StreamController<String> _reminderOpenController =
      StreamController<String>.broadcast();

  bool _initialized = false;
  String? _pendingReminderId;

  Stream<String> get reminderOpenRequests => _reminderOpenController.stream;

  String? consumePendingReminderId() {
    final value = _pendingReminderId;
    _pendingReminderId = null;
    return value;
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tzdata.initializeTimeZones();

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        defaultPresentAlert: true,
        defaultPresentBadge: true,
        defaultPresentSound: true,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        defaultPresentAlert: true,
        defaultPresentBadge: true,
        defaultPresentSound: true,
      ),
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();

    await _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_channel);

    if (launchDetails?.didNotificationLaunchApp == true) {
      final reminderId = _extractReminderId(
        launchDetails?.notificationResponse?.payload,
      );
      if (reminderId != null) {
        _pendingReminderId = reminderId;
      }
    }

    _initialized = true;
  }

  Future<void> requestPermissions() async {
    await initialize();

    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);

    final macPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    await macPlugin?.requestPermissions(alert: true, badge: true, sound: true);

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
    try {
      await androidPlugin?.requestExactAlarmsPermission();
    } catch (_) {
      // Старые версии Android и некоторые окружения не требуют отдельного разрешения.
    }
  }

  Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAll();
  }

  Future<void> rescheduleReminders(List<PharmacyReminder> reminders) async {
    await initialize();
    await _plugin.cancelAll();

    final now = DateTime.now();
    for (final reminder in reminders) {
      if (!reminder.isActive) {
        continue;
      }

      final content = ReminderContentBuilder.build(reminder);
      final occurrences = _occurrencesForReminder(reminder, now);
      for (final occurrence in occurrences) {
        await _plugin.zonedSchedule(
          _notificationId(reminder.id, occurrence),
          content.notificationTitle,
          content.shortBody,
          tz.TZDateTime.from(occurrence.toUtc(), tz.UTC),
          _notificationDetails(content),
          payload: jsonEncode(<String, String>{'reminderId': reminder.id}),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final reminderId = _extractReminderId(response.payload);
    if (reminderId == null) {
      return;
    }
    _reminderOpenController.add(reminderId);
  }

  NotificationDetails _notificationDetails(
    ReminderNotificationContent content,
  ) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        styleInformation: BigTextStyleInformation(
          content.expandedBody,
          contentTitle: content.notificationTitle,
          summaryText: 'Напоминание о приеме витамина',
        ),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        threadIdentifier: 'vitamin-reminders',
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        threadIdentifier: 'vitamin-reminders',
      ),
    );
  }

  List<DateTime> _occurrencesForReminder(
    PharmacyReminder reminder,
    DateTime now,
  ) {
    final result = <DateTime>[];
    final today = DateTime(now.year, now.month, now.day);
    final startDate = _normalizeDate(reminder.course.startDate);
    final endDate = reminder.course.endDate == null
        ? today.add(const Duration(days: 60))
        : _normalizeDate(reminder.course.endDate!);
    if (endDate.isBefore(today) || endDate.isBefore(startDate)) {
      return result;
    }

    final firstDate = startDate.isAfter(today) ? startDate : today;
    final times = _normalizedTimes(reminder.schedule.times);

    for (
      DateTime date = firstDate;
      !date.isAfter(endDate);
      date = date.add(const Duration(days: 1))
    ) {
      if (!reminder.schedule.days.contains(_weekdayFromDate(date))) {
        continue;
      }
      for (final time in times) {
        final scheduledAt = _combine(date, time);
        if (scheduledAt.isAfter(now.add(const Duration(seconds: 5)))) {
          result.add(scheduledAt);
        }
      }
    }

    return result;
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
    return normalized.isEmpty ? const <String>['09:00'] : normalized.toList();
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

  int _notificationId(String reminderId, DateTime scheduledAt) {
    return Object.hash(
          reminderId,
          scheduledAt.year,
          scheduledAt.month,
          scheduledAt.day,
          scheduledAt.hour,
          scheduledAt.minute,
        ) &
        0x7fffffff;
  }

  String? _extractReminderId(String? payload) {
    if (payload == null || payload.trim().isEmpty) {
      return null;
    }
    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      final reminderId = map['reminderId'] as String?;
      if (reminderId == null || reminderId.trim().isEmpty) {
        return null;
      }
      return reminderId.trim();
    } catch (error, stackTrace) {
      debugPrint('Не удалось разобрать payload напоминания: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  Weekday _weekdayFromDate(DateTime date) {
    return Weekday.fromDate(date);
  }
}
