class LocalizedOptionDefaults {
  static const List<List<String>> _locationVariants = [
    ['학교 운동장', '동네 운동장', '실내 체육관'],
    ['School field', 'Community field', 'Indoor gym'],
  ];

  static const List<List<String>> _programVariants = [
    ['기본기', '피지컬', '전술', '회복'],
    ['Fundamentals', 'Physical', 'Tactical', 'Recovery'],
  ];

  static List<String> normalizeOptions({
    required String key,
    required List<String> stored,
    required List<String> localizedDefaults,
  }) {
    final variants = _variantsForKey(key);
    if (variants == null) return List<String>.from(stored);

    final normalized = <String>[];
    for (final item in stored) {
      final value = item.trim();
      if (value.isEmpty) continue;
      final mapped = _translateKnownValue(
            value: value,
            variants: variants,
            localizedDefaults: localizedDefaults,
          ) ??
          value;
      if (!normalized.contains(mapped)) {
        normalized.add(mapped);
      }
    }
    return normalized.isEmpty
        ? List<String>.from(localizedDefaults)
        : normalized;
  }

  static String normalizeDefaultValue({
    required String key,
    required String? storedValue,
    required List<String> localizedDefaults,
    required List<String> options,
  }) {
    if (options.isEmpty) return '';
    final fallback = options.first;
    final value = storedValue?.trim();
    if (value == null || value.isEmpty) return fallback;

    if (options.contains(value)) return value;

    final variants = _variantsForKey(key);
    if (variants == null) return fallback;
    final mapped = _translateKnownValue(
      value: value,
      variants: variants,
      localizedDefaults: localizedDefaults,
    );
    if (mapped != null && options.contains(mapped)) {
      return mapped;
    }
    return fallback;
  }

  static List<List<String>>? _variantsForKey(String key) {
    switch (key) {
      case 'locations':
      case 'default_location':
        return _locationVariants;
      case 'programs':
      case 'default_program':
        return _programVariants;
      default:
        return null;
    }
  }

  static String? _translateKnownValue({
    required String value,
    required List<List<String>> variants,
    required List<String> localizedDefaults,
  }) {
    for (final variant in variants) {
      for (var i = 0; i < variant.length; i++) {
        if (variant[i] == value && i < localizedDefaults.length) {
          return localizedDefaults[i];
        }
      }
    }
    return null;
  }
}
