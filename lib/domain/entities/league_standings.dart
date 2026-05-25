enum LeagueStandingsType {
  premierLeague,
  championsLeague,
  laLiga,
  bundesliga,
  majorLeagueSoccer,
  saudiProLeague,
}

enum LeagueFixtureStatus { scheduled, live, finished }

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

class LeagueFixtureSnapshot {
  final LeagueStandingsType type;
  final String leagueName;
  final String seasonName;
  final String sourceUrl;
  final DateTime fetchedAt;
  final List<LeagueFixtureEntry> entries;

  const LeagueFixtureSnapshot({
    required this.type,
    required this.leagueName,
    required this.seasonName,
    required this.sourceUrl,
    required this.fetchedAt,
    required this.entries,
  });
}

class LeagueFixtureEntry {
  final String id;
  final DateTime kickoffAt;
  final String stage;
  final String leg;
  final String note;
  final String venue;
  final String city;
  final String homeTeamName;
  final String homeTeamShortName;
  final String homeLogoUrl;
  final String awayTeamName;
  final String awayTeamShortName;
  final String awayLogoUrl;
  final int? homeScore;
  final int? awayScore;
  final LeagueFixtureStatus status;
  final String sourceUrl;

  const LeagueFixtureEntry({
    required this.id,
    required this.kickoffAt,
    required this.stage,
    required this.leg,
    required this.note,
    required this.venue,
    required this.city,
    required this.homeTeamName,
    required this.homeTeamShortName,
    required this.homeLogoUrl,
    required this.awayTeamName,
    required this.awayTeamShortName,
    required this.awayLogoUrl,
    required this.homeScore,
    required this.awayScore,
    required this.status,
    required this.sourceUrl,
  });

  bool get hasScore => homeScore != null && awayScore != null;
}
