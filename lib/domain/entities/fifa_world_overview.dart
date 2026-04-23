enum FifaRankingGender { men, women }

extension FifaRankingGenderX on FifaRankingGender {
  int get apiValue => this == FifaRankingGender.men ? 1 : 2;

  String get code => this == FifaRankingGender.men ? 'men' : 'women';

  String get officialRankingUrl =>
      'https://inside.fifa.com/fifa-world-ranking/$code';
}

enum FifaAMatchStatus { scheduled, live, finished }

enum KfaMatchStatus { scheduled, finished }

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

  FifaWorldOverview copyWith({
    FifaRankingGender? gender,
    List<FifaRankingEntry>? rankings,
    DateTime? lastUpdatedAt,
    DateTime? nextUpdatedAt,
    List<FifaAMatchEntry>? recentResults,
    List<FifaAMatchEntry>? upcomingFixtures,
  }) {
    return FifaWorldOverview(
      gender: gender ?? this.gender,
      rankings: rankings ?? this.rankings,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      nextUpdatedAt: nextUpdatedAt ?? this.nextUpdatedAt,
      recentResults: recentResults ?? this.recentResults,
      upcomingFixtures: upcomingFixtures ?? this.upcomingFixtures,
    );
  }

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

class FifaTeamDetail {
  final String teamId;
  final String teamName;
  final String countryCode;
  final String abbreviation;
  final String confederationCode;
  final String city;
  final String street;
  final String officialSite;
  final String stadiumName;
  final int? foundationYear;

  const FifaTeamDetail({
    required this.teamId,
    required this.teamName,
    required this.countryCode,
    required this.abbreviation,
    required this.confederationCode,
    required this.city,
    required this.street,
    required this.officialSite,
    required this.stadiumName,
    required this.foundationYear,
  });

  bool get hasTeamProfile =>
      abbreviation.isNotEmpty ||
      confederationCode.isNotEmpty ||
      city.isNotEmpty ||
      street.isNotEmpty ||
      officialSite.isNotEmpty ||
      stadiumName.isNotEmpty ||
      foundationYear != null;
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

class FifaAMatchDetail {
  final FifaAMatchEntry match;
  final List<FifaMatchScorer> homeScorers;
  final List<FifaMatchScorer> awayScorers;
  final double? homePossession;
  final double? awayPossession;

  const FifaAMatchDetail({
    required this.match,
    required this.homeScorers,
    required this.awayScorers,
    required this.homePossession,
    required this.awayPossession,
  });

  bool get hasScorers => homeScorers.isNotEmpty || awayScorers.isNotEmpty;

  bool get hasPossession => homePossession != null && awayPossession != null;
}

class FifaMatchScorer {
  final String playerName;
  final String minute;

  const FifaMatchScorer({required this.playerName, required this.minute});
}

class KfaMatchOverview {
  final List<KfaMatchEntry> recentResults;
  final List<KfaMatchEntry> upcomingFixtures;

  const KfaMatchOverview({
    required this.recentResults,
    required this.upcomingFixtures,
  });

  bool get isEmpty => recentResults.isEmpty && upcomingFixtures.isEmpty;
}

class KfaMatchEntry {
  final String matchId;
  final String competition;
  final String venue;
  final String dateLabel;
  final String timeLabel;
  final String homeTeamName;
  final String awayTeamName;
  final int? homeScore;
  final int? awayScore;
  final KfaMatchStatus status;
  final Uri sourceUrl;

  const KfaMatchEntry({
    required this.matchId,
    required this.competition,
    required this.venue,
    required this.dateLabel,
    required this.timeLabel,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homeScore,
    required this.awayScore,
    required this.status,
    required this.sourceUrl,
  });

  bool get hasScore => homeScore != null && awayScore != null;
}
