import 'weekday.dart';

enum IntakeMoment {
  before(
    'До еды',
    'before_meal',
    'assets/images/pharmacy/plate_unselected.png',
    'assets/images/pharmacy/plate_selected.png',
  ),
  after(
    'После еды',
    'after_meal',
    'assets/images/pharmacy/fork_unselected.png',
    'assets/images/pharmacy/fork_selected.png',
  ),
  during(
    'Во время\nеды',
    'during_meal',
    'assets/images/pharmacy/knee_unselected.png',
    'assets/images/pharmacy/knee_selected.png',
  ),
  any(
    'Неважно',
    'any',
    'assets/images/pharmacy/mark_magnifier_unselected.png',
    'assets/images/pharmacy/mark_magnifier_selected.png',
  );

  const IntakeMoment(
    this.title,
    this.apiCondition,
    this.iconAsset,
    this.selectedIconAsset,
  );

  final String title;
  final String apiCondition;
  final String iconAsset;
  final String selectedIconAsset;

  static IntakeMoment? fromApiCondition(String? value) {
    for (final moment in values) {
      if (moment.apiCondition == value) {
        return moment;
      }
    }
    return null;
  }
}

class VitaminDraft {
  const VitaminDraft({
    this.name = '',
    this.type = '',
    this.dose = '',
    this.intake,
    this.notes = '',
    this.catalogId,
    this.catalogDefaultUnit,
    this.catalogInteractionText,
    this.catalogCompatibilityText,
    this.catalogContraindicationsText,
    this.catalogDefaultCondition,
    this.interactionTextOverride,
    this.compatibilityTextOverride,
    this.contraindicationsTextOverride,
    this.includeDose = true,
    this.includeFrequency = true,
    this.includeInteraction = true,
    this.includeCompatibility = true,
    this.includeCondition = true,
    this.includeContraindications = true,
    this.intakeTimes = const [],
    this.weekdays = Weekday.values,
    required this.courseStartDate,
    this.courseEndDate,
  });

  final String name;
  final String type;
  final String dose;
  final IntakeMoment? intake;
  final String notes;
  final String? catalogId;
  final String? catalogDefaultUnit;
  final String? catalogInteractionText;
  final String? catalogCompatibilityText;
  final String? catalogContraindicationsText;
  final String? catalogDefaultCondition;
  final String? interactionTextOverride;
  final String? compatibilityTextOverride;
  final String? contraindicationsTextOverride;
  final bool includeDose;
  final bool includeFrequency;
  final bool includeInteraction;
  final bool includeCompatibility;
  final bool includeCondition;
  final bool includeContraindications;
  final List<String> intakeTimes;
  final List<Weekday> weekdays;
  final DateTime courseStartDate;
  final DateTime? courseEndDate;

  factory VitaminDraft.empty() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return VitaminDraft(courseStartDate: start);
  }

  VitaminDraft copyWith({
    String? name,
    String? type,
    String? dose,
    IntakeMoment? intake,
    bool clearIntake = false,
    String? notes,
    String? catalogId,
    String? catalogDefaultUnit,
    String? catalogInteractionText,
    String? catalogCompatibilityText,
    String? catalogContraindicationsText,
    String? catalogDefaultCondition,
    String? interactionTextOverride,
    String? compatibilityTextOverride,
    String? contraindicationsTextOverride,
    bool? includeDose,
    bool? includeFrequency,
    bool? includeInteraction,
    bool? includeCompatibility,
    bool? includeCondition,
    bool? includeContraindications,
    List<String>? intakeTimes,
    List<Weekday>? weekdays,
    DateTime? courseStartDate,
    DateTime? courseEndDate,
    bool clearCourseEndDate = false,
  }) {
    return VitaminDraft(
      name: name ?? this.name,
      type: type ?? this.type,
      dose: dose ?? this.dose,
      intake: clearIntake ? null : intake ?? this.intake,
      notes: notes ?? this.notes,
      catalogId: catalogId ?? this.catalogId,
      catalogDefaultUnit: catalogDefaultUnit ?? this.catalogDefaultUnit,
      catalogInteractionText:
          catalogInteractionText ?? this.catalogInteractionText,
      catalogCompatibilityText:
          catalogCompatibilityText ?? this.catalogCompatibilityText,
      catalogContraindicationsText:
          catalogContraindicationsText ?? this.catalogContraindicationsText,
      catalogDefaultCondition:
          catalogDefaultCondition ?? this.catalogDefaultCondition,
      interactionTextOverride:
          interactionTextOverride ?? this.interactionTextOverride,
      compatibilityTextOverride:
          compatibilityTextOverride ?? this.compatibilityTextOverride,
      contraindicationsTextOverride:
          contraindicationsTextOverride ?? this.contraindicationsTextOverride,
      includeDose: includeDose ?? this.includeDose,
      includeFrequency: includeFrequency ?? this.includeFrequency,
      includeInteraction: includeInteraction ?? this.includeInteraction,
      includeCompatibility: includeCompatibility ?? this.includeCompatibility,
      includeCondition: includeCondition ?? this.includeCondition,
      includeContraindications:
          includeContraindications ?? this.includeContraindications,
      intakeTimes: intakeTimes ?? this.intakeTimes,
      weekdays: weekdays ?? this.weekdays,
      courseStartDate: courseStartDate ?? this.courseStartDate,
      courseEndDate: clearCourseEndDate
          ? null
          : courseEndDate ?? this.courseEndDate,
    );
  }
}
