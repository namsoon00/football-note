enum LeagueStandingsType { premierLeague, championsLeague }

class LeagueStandingsSnapshot {
  final LeagueStandingsType type;
  final String leagueName;
  final String seasonName;
  final String sourceUrl;
  final DateTime fetchedAt;
  final List<LeagueStandingEntry> entries;

  const LeagueStandingsSnapshot({
    required this.type,
    required this.leagueName,
    required this.seasonName,
    required this.sourceUrl,
    required this.fetchedAt,
    required this.entries,
  });
}

class LeagueStandingEntry {
  final int rank;
  final String teamName;
  final String teamShortName;
  final String logoUrl;
  final String played;
  final String wins;
  final String draws;
  final String losses;
  final String goalsFor;
  final String goalsAgainst;
  final String goalDifference;
  final String points;
  final String note;

  const LeagueStandingEntry({
    required this.rank,
    required this.teamName,
    required this.teamShortName,
    required this.logoUrl,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.points,
    required this.note,
  });
}
