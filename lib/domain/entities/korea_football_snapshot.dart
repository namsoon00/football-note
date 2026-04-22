enum KoreaMatchOutcome { win, draw, loss }

class KoreaFootballSnapshot {
  final KoreaFifaRankingSnapshot? fifaRanking;
  final List<KoreaAMatchSnapshot> recentMatches;
  final DateTime fetchedAt;

  const KoreaFootballSnapshot({
    required this.fifaRanking,
    required this.recentMatches,
    required this.fetchedAt,
  });

  bool get isEmpty => fifaRanking == null && recentMatches.isEmpty;
}

class KoreaFifaRankingSnapshot {
  final String teamName;
  final int currentRank;
  final DateTime? updatedAt;
  final String officialUrl;

  const KoreaFifaRankingSnapshot({
    required this.teamName,
    required this.currentRank,
    required this.updatedAt,
    required this.officialUrl,
  });
}

class KoreaAMatchSnapshot {
  final String competition;
  final String venue;
  final String opponent;
  final int koreaScore;
  final int opponentScore;
  final DateTime? playedAt;
  final String officialUrl;

  const KoreaAMatchSnapshot({
    required this.competition,
    required this.venue,
    required this.opponent,
    required this.koreaScore,
    required this.opponentScore,
    required this.playedAt,
    required this.officialUrl,
  });

  KoreaMatchOutcome get outcome {
    if (koreaScore > opponentScore) return KoreaMatchOutcome.win;
    if (koreaScore < opponentScore) return KoreaMatchOutcome.loss;
    return KoreaMatchOutcome.draw;
  }
}
