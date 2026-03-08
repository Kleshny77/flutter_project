class VitaminCatalogItem {
  const VitaminCatalogItem({
    required this.id,
    this.code,
    this.displayName,
    this.defaultUnit,
    this.interactionText,
    this.compatibilityText,
    this.contraindicationsText,
    this.defaultCondition,
  });

  final String id;
  final String? code;
  final String? displayName;
  final String? defaultUnit;
  final String? interactionText;
  final String? compatibilityText;
  final String? contraindicationsText;
  final String? defaultCondition;

  String get resolvedName {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    final fallback = code?.trim();
    return fallback == null || fallback.isEmpty ? 'Витамин' : fallback;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'display_name': displayName,
      'default_unit': defaultUnit,
      'interaction_text': interactionText,
      'compatibility_text': compatibilityText,
      'contraindications_text': contraindicationsText,
      'default_condition': defaultCondition,
    };
  }

  factory VitaminCatalogItem.fromMap(Map<String, dynamic> map) {
    String? readString(Object? value) {
      if (value is String) {
        return value;
      }
      if (value is num) {
        return value.toString();
      }
      return null;
    }

    String? normalizeCondition(String? value) {
      final normalized = value?.trim();
      if (normalized == null || normalized.isEmpty) {
        return null;
      }

      final lowered = normalized.toLowerCase();
      if (lowered.contains('до еды')) {
        return 'before_meal';
      }
      if (lowered.contains('после еды')) {
        return 'after_meal';
      }
      if (lowered.contains('во время еды') || lowered.contains('с едой')) {
        return 'during_meal';
      }
      if (lowered.contains('неважно')) {
        return 'any';
      }

      return normalized;
    }

    return VitaminCatalogItem(
      id: readString(map['id']) ?? '',
      code: readString(map['code']) ?? readString(map['Supplement']),
      displayName: readString(map['displayName']) ??
          readString(map['display_name']) ??
          readString(map['Supplement']) ??
          readString(map['supplement']) ??
          readString(map['name']) ??
          readString(map['title']),
      defaultUnit:
          readString(map['defaultUnit']) ?? readString(map['default_unit']),
      interactionText: readString(map['interactionText']) ??
          readString(map['interaction_text']) ??
          readString(map['Interactions']),
      compatibilityText: readString(map['compatibilityText']) ??
          readString(map['compatibility_text']) ??
          readString(map['Compatibility']),
      contraindicationsText: readString(map['contraindicationsText']) ??
          readString(map['contraindications_text']) ??
          readString(map['Contraindications']),
      defaultCondition: normalizeCondition(
        readString(map['defaultCondition']) ??
            readString(map['default_condition']) ??
            readString(map['Timing']),
      ),
    );
  }
}
