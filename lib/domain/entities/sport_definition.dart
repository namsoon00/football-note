class SportDefinition {
  final String id;

  const SportDefinition({required this.id});

  bool get isFootball => id == SportCatalog.footballId;
}

class SportCatalog {
  static const String footballId = 'football';
  static const String baseballId = 'baseball';
  static const String basketballId = 'basketball';
  static const String tennisId = 'tennis';
  static const String currentSportOptionKey = 'current_sport_id';
  static const String defaultSportId = footballId;

  static const SportDefinition football = SportDefinition(id: footballId);
  static const SportDefinition baseball = SportDefinition(id: baseballId);
  static const SportDefinition basketball = SportDefinition(id: basketballId);
  static const SportDefinition tennis = SportDefinition(id: tennisId);
  static const List<SportDefinition> all = <SportDefinition>[
    football,
    baseball,
    basketball,
    tennis,
  ];

  const SportCatalog._();

  static SportDefinition byId(String? rawId) {
    final normalized = rawId?.trim().toLowerCase();
    for (final sport in all) {
      if (sport.id == normalized) {
        return sport;
      }
    }
    return football;
  }

  static String normalizeSportId(String? rawId) => byId(rawId).id;

  static String optionKey(String baseKey, {String? sportId}) {
    final normalizedSportId = normalizeSportId(sportId);
    if (normalizedSportId == footballId) {
      return baseKey;
    }
    return '${baseKey}_$normalizedSportId';
  }
}
