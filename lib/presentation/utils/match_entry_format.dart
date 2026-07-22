import 'package:football_note/gen/app_localizations.dart';

import '../../domain/entities/training_entry.dart';

const List<String> matchTournamentStageValues = <String>[
  'preliminary',
  'round16',
  'quarterfinal',
  'semifinal',
  'final',
];

const List<String> matchTournamentOutcomeValues = <String>[
  'ongoing',
  'advanced',
  'eliminated',
  'champion',
];

String normalizeMatchTournamentStage(String raw) {
  final value = raw.trim();
  return matchTournamentStageValues.contains(value) ? value : 'preliminary';
}

String normalizeMatchTournamentOutcome(String raw) {
  final value = raw.trim();
  return matchTournamentOutcomeValues.contains(value) ? value : 'ongoing';
}

String matchKindLabel(TrainingEntry entry, AppLocalizations l10n) {
  if (entry.isTournamentMatch) return l10n.matchKindTournament;
  if (entry.isLeagueMatch) return l10n.matchKindLeague;
  return l10n.matchKindFriendly;
}

String matchTournamentStageLabel(AppLocalizations l10n, String stage) {
  return switch (normalizeMatchTournamentStage(stage)) {
    'round16' => l10n.matchTournamentStageRound16,
    'quarterfinal' => l10n.matchTournamentStageQuarterfinal,
    'semifinal' => l10n.matchTournamentStageSemifinal,
    'final' => l10n.matchTournamentStageFinal,
    _ => l10n.matchTournamentStagePreliminary,
  };
}

String matchTournamentOutcomeLabel(AppLocalizations l10n, String outcome) {
  return switch (normalizeMatchTournamentOutcome(outcome)) {
    'advanced' => l10n.matchTournamentOutcomeAdvanced,
    'eliminated' => l10n.matchTournamentOutcomeEliminated,
    'champion' => l10n.matchTournamentOutcomeChampion,
    _ => l10n.matchTournamentOutcomeOngoing,
  };
}

List<String> matchCompetitionDetailParts(
  TrainingEntry entry,
  AppLocalizations l10n, {
  int teamLimit = 3,
}) {
  final parts = <String>[];
  final competitionName = entry.matchCompetitionName.trim();
  if (competitionName.isNotEmpty) {
    parts.add(competitionName);
  }

  if (entry.isLeagueMatch) {
    final round = entry.matchStage.trim();
    if (round.isNotEmpty) {
      parts.add(round);
    }
    if (entry.leagueTeamNames.isNotEmpty) {
      parts.add(entry.leagueTeamNames.take(teamLimit).join(', '));
    }
    if (entry.leaguePoints != null) {
      parts.add(l10n.matchLeaguePointsValue(entry.leaguePoints!));
    }
  } else if (entry.isTournamentMatch) {
    final stage = entry.matchStage.trim();
    if (stage.isNotEmpty) {
      parts.add(matchTournamentStageLabel(l10n, stage));
    }
    final shootout = matchTournamentShootoutLabel(entry, l10n);
    if (shootout != null) {
      parts.add(shootout);
    }
    final outcome = entry.tournamentOutcome.trim();
    if (outcome.isNotEmpty) {
      parts.add(matchTournamentOutcomeLabel(l10n, outcome));
    }
    if (entry.leagueTeamNames.isNotEmpty) {
      parts.add(entry.leagueTeamNames.take(teamLimit).join(', '));
    }
    if (entry.tournamentWins != null) {
      parts.add(l10n.matchTournamentWinsValue(entry.tournamentWins!));
    }
  }

  return parts;
}

String? matchTournamentShootoutLabel(
  TrainingEntry entry,
  AppLocalizations l10n,
) {
  if (!entry.hasPenaltyShootout) return null;
  return l10n.matchTournamentShootoutSummary(
    entry.penaltyShootoutGoalsFor!,
    entry.penaltyShootoutGoalsAgainst!,
  );
}
