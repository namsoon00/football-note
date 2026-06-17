class SportDefinition {
  final String id;

  const SportDefinition({required this.id});

  bool get isFootball => id == SportCatalog.footballId;
}

class SportCatalog {
  static const String footballId = 'football';
  static const String currentSportOptionKey = 'current_sport_id';
  static const String defaultSportId = footballId;

  static const SportDefinition football = SportDefinition(id: footballId);
  static const List<SportDefinition> all = <SportDefinition>[football];

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
}
