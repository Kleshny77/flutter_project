import 'vitamin_catalog_item.dart';
import 'weekday.dart';

class PharmacyReminderInput {
  const PharmacyReminderInput({
    required this.title,
    required this.form,
    required this.dose,
    required this.condition,
    required this.note,
    required this.courseStartDate,
    required this.courseEndDate,
    required this.timezone,
    required this.days,
    required this.times,
    required this.includeDose,
    required this.includeFrequency,
    required this.includeInteraction,
    required this.includeCompatibility,
    required this.includeCondition,
    required this.includeContraindications,
    this.catalogId,
    this.catalog,
    this.interactionTextOverride,
    this.compatibilityTextOverride,
    this.contraindicationsTextOverride,
  });

  final String title;
  final String form;
  final String dose;
  final String condition;
  final String note;
  final DateTime courseStartDate;
  final DateTime? courseEndDate;
  final String timezone;
  final List<Weekday> days;
  final List<String> times;
  final bool includeDose;
  final bool includeFrequency;
  final bool includeInteraction;
  final bool includeCompatibility;
  final bool includeCondition;
  final bool includeContraindications;
  final String? catalogId;
  final VitaminCatalogItem? catalog;
  final String? interactionTextOverride;
  final String? compatibilityTextOverride;
  final String? contraindicationsTextOverride;
}
