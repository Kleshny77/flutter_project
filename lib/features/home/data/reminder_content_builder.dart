import '../models/pharmacy_reminder.dart';

class ReminderInfoSection {
  const ReminderInfoSection({
    required this.id,
    required this.title,
    required this.text,
  });

  final String id;
  final String title;
  final String text;
}

class ReminderNotificationContent {
  const ReminderNotificationContent({
    required this.displayName,
    required this.notificationTitle,
    required this.shortBody,
    required this.expandedBody,
    required this.sections,
  });

  final String displayName;
  final String notificationTitle;
  final String shortBody;
  final String expandedBody;
  final List<ReminderInfoSection> sections;
}

class ReminderContentBuilder {
  const ReminderContentBuilder._();

  static ReminderNotificationContent build(PharmacyReminder reminder) {
    final displayName = reminder.catalog?.displayName?.trim().isNotEmpty == true
        ? reminder.catalog!.displayName!.trim()
        : reminder.title.trim().isEmpty
        ? 'Витамин'
        : reminder.title.trim();
    final timesCount = _normalizedTimes(reminder.schedule.times).length;
    final preferences = reminder.notificationPreferences;
    final sections = <ReminderInfoSection>[];

    if (preferences.includeDose || preferences.includeFrequency) {
      final doseText = _doseSectionText(reminder, timesCount);
      if (doseText.isNotEmpty) {
        sections.add(
          ReminderInfoSection(
            id: 'dose',
            title: preferences.includeDose ? 'Дозировка' : 'Частота приема',
            text: doseText,
          ),
        );
      }
    }

    if (preferences.includeCondition) {
      sections.add(
        ReminderInfoSection(
          id: 'condition',
          title: 'Условия приема',
          text: resolvedConditionText(reminder),
        ),
      );
    }

    if (preferences.includeInteraction) {
      sections.add(
        ReminderInfoSection(
          id: 'interaction',
          title: 'Взаимодействие',
          text: resolvedInteractionText(reminder),
        ),
      );
    }

    if (preferences.includeCompatibility) {
      sections.add(
        ReminderInfoSection(
          id: 'compatibility',
          title: 'Совместимость',
          text: resolvedCompatibilityText(reminder),
        ),
      );
    }

    if (preferences.includeContraindications) {
      sections.add(
        ReminderInfoSection(
          id: 'contraindications',
          title: 'Противопоказания',
          text: resolvedContraindicationsText(reminder),
        ),
      );
    }

    final shortBody = sections.isEmpty
        ? 'Нажмите, чтобы открыть напоминание.'
        : sections
              .take(2)
              .map((section) => '${section.title}: ${section.text}')
              .join('\n');
    final expandedBody = sections.isEmpty
        ? 'Нажмите, чтобы открыть карточку витамина.'
        : sections
              .map((section) => '${section.title}: ${section.text}')
              .join('\n\n');

    return ReminderNotificationContent(
      displayName: displayName,
      notificationTitle: 'Примите $displayName!',
      shortBody: shortBody,
      expandedBody: expandedBody,
      sections: sections,
    );
  }

  static String resolvedInteractionText(PharmacyReminder reminder) {
    final override = reminder.contentOverrides.interactionTextOverride?.trim();
    if (override != null && override.isNotEmpty) {
      return override;
    }
    final value = reminder.catalog?.interactionText?.trim();
    return value == null || value.isEmpty ? 'Нет данных' : value;
  }

  static String resolvedCompatibilityText(PharmacyReminder reminder) {
    final override = reminder.contentOverrides.compatibilityTextOverride
        ?.trim();
    if (override != null && override.isNotEmpty) {
      return override;
    }
    final value = reminder.catalog?.compatibilityText?.trim();
    return value == null || value.isEmpty ? 'Нет данных' : value;
  }

  static String resolvedContraindicationsText(PharmacyReminder reminder) {
    final override = reminder.contentOverrides.contraindicationsTextOverride
        ?.trim();
    if (override != null && override.isNotEmpty) {
      return override;
    }
    final value = reminder.catalog?.contraindicationsText?.trim();
    return value == null || value.isEmpty ? 'Нет данных' : value;
  }

  static String resolvedConditionText(PharmacyReminder reminder) {
    final label = switch (reminder.condition?.toLowerCase()) {
      'before_meal' => 'Принимать до еды.',
      'during_meal' => 'Принимать во время еды.',
      'any' => 'Время приема неважно.',
      _ => 'Принимать после еды.',
    };
    final note = reminder.note?.trim() ?? '';
    final merged = [label, note].where((value) => value.isNotEmpty).join(' ');
    return merged.trim().isEmpty ? 'Нет данных' : merged.trim();
  }

  static List<String> _normalizedTimes(List<String> rawTimes) {
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

  static String _doseSectionText(PharmacyReminder reminder, int timesCount) {
    final dose = (reminder.dose ?? '').trim();
    final frequency = _frequencyDescription(timesCount);
    final preferences = reminder.notificationPreferences;

    if (preferences.includeDose && preferences.includeFrequency) {
      return [dose, frequency].where((value) => value.isNotEmpty).join(' ');
    }
    if (preferences.includeDose) {
      return dose.isEmpty ? '1' : dose;
    }
    if (preferences.includeFrequency) {
      return frequency;
    }
    return '';
  }

  static String _frequencyDescription(int count) {
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
}
