enum FifaRankingGender { men, women }

extension FifaRankingGenderX on FifaRankingGender {
  int get apiValue => this == FifaRankingGender.men ? 1 : 2;

  String get code => this == FifaRankingGender.men ? 'men' : 'women';

  String get officialRankingUrl =>
      'https://inside.fifa.com/fifa-world-ranking/$code';
}

enum FifaAMatchStatus { scheduled, live, finished }

class FifaWorldOverview {
  final FifaRankingGender gender;
  final List<FifaRankingEntry> rankings;
  final DateTime? lastUpdatedAt;
  final DateTime? nextUpdatedAt;
  final List<FifaAMatchEntry> recentResults;
  final List<FifaAMatchEntry> upcomingFixtures;

  const FifaWorldOverview({
    required this.gender,
    required this.rankings,
    required this.lastUpdatedAt,
    required this.nextUpdatedAt,
    required this.recentResults,
    required this.upcomingFixtures,
  });

  bool get isEmpty =>
      rankings.isEmpty && recentResults.isEmpty && upcomingFixtures.isEmpty;

  FifaRankingEntry? get leader => rankings.isEmpty ? null : rankings.first;

  int get confederationCount =>
      rankings.map((entry) => entry.confederation).toSet().length;

  FifaRankingEntry? get biggestClimber {
    if (rankings.isEmpty) return null;
    final sorted = [...rankings]
      ..sort((a, b) => b.rankMovement.compareTo(a.rankMovement));
    return sorted.first.rankMovement > 0 ? sorted.first : null;
  }

  FifaRankingEntry? get biggestFaller {
    if (rankings.isEmpty) return null;
    final sorted = [...rankings]
      ..sort((a, b) => a.rankMovement.compareTo(b.rankMovement));
    return sorted.first.rankMovement < 0 ? sorted.first : null;
  }
}

class FifaRankingEntry {
  final String teamId;
  final String teamName;
  final String countryCode;
  final String confederation;
  final int rank;
  final int previousRank;
  final double points;
  final double previousPoints;
  final DateTime? publishedAt;

  const FifaRankingEntry({
    required this.teamId,
    required this.teamName,
    required this.countryCode,
    required this.confederation,
    required this.rank,
    required this.previousRank,
    required this.points,
    required this.previousPoints,
    required this.publishedAt,
  });

  String get flagUrl =>
      'https://api.fifa.com/api/v3/picture/flags-sq-2/$countryCode';

  int get rankMovement => previousRank - rank;

  double get pointsMovement => points - previousPoints;
}

class FifaAMatchEntry {
  final String matchId;
  final FifaRankingGender gender;
  final String competition;
  final String stage;
  final String venue;
  final String city;
  final DateTime kickoffAt;
  final String homeTeamName;
  final String homeCountryCode;
  final String awayTeamName;
  final String awayCountryCode;
  final int? homeScore;
  final int? awayScore;
  final FifaAMatchStatus status;

  const FifaAMatchEntry({
    required this.matchId,
    required this.gender,
    required this.competition,
    required this.stage,
    required this.venue,
    required this.city,
    required this.kickoffAt,
    required this.homeTeamName,
    required this.homeCountryCode,
    required this.awayTeamName,
    required this.awayCountryCode,
    required this.homeScore,
    required this.awayScore,
    required this.status,
  });

  bool get hasScore => homeScore != null && awayScore != null;
}
