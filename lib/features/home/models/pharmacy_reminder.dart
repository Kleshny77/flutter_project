import 'vitamin_catalog_item.dart';
import 'weekday.dart';

class ReminderCourse {
  const ReminderCourse({required this.startDate, this.endDate, this.timezone});

  final DateTime startDate;
  final DateTime? endDate;
  final String? timezone;
}

class ReminderSchedule {
  const ReminderSchedule({required this.days, required this.times});

  final List<Weekday> days;
  final List<String> times;
}

class ReminderNotificationPreferences {
  const ReminderNotificationPreferences({
    this.includeDose = true,
    this.includeFrequency = true,
    this.includeInteraction = true,
    this.includeCompatibility = true,
    this.includeCondition = true,
    this.includeContraindications = true,
  });

  final bool includeDose;
  final bool includeFrequency;
  final bool includeInteraction;
  final bool includeCompatibility;
  final bool includeCondition;
  final bool includeContraindications;
}

class ReminderContentOverrides {
  const ReminderContentOverrides({
    this.interactionTextOverride,
    this.compatibilityTextOverride,
    this.contraindicationsTextOverride,
  });

  final String? interactionTextOverride;
  final String? compatibilityTextOverride;
  final String? contraindicationsTextOverride;
}

class PharmacyReminder {
  const PharmacyReminder({
    required this.id,
    required this.title,
    required this.isActive,
    required this.form,
    this.dose,
    this.condition,
    this.note,
    this.catalogId,
    this.catalog,
    required this.course,
    required this.schedule,
    required this.notificationPreferences,
    required this.contentOverrides,
  });

  final String id;
  final String title;
  final bool isActive;
  final String form;
  final String? dose;
  final String? condition;
  final String? note;
  final String? catalogId;
  final VitaminCatalogItem? catalog;
  final ReminderCourse course;
  final ReminderSchedule schedule;
  final ReminderNotificationPreferences notificationPreferences;
  final ReminderContentOverrides contentOverrides;
}
