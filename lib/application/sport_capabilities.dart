import 'package:football_note/gen/app_localizations.dart';

import '../domain/entities/sport_definition.dart';
import '../domain/entities/training_entry.dart';

class SportCapabilities {
  final String sportId;

  const SportCapabilities._(this.sportId);

  factory SportCapabilities.forSport(String? sportId) {
    return SportCapabilities._(SportCatalog.normalizeSportId(sportId));
  }

  bool get supportsFootballContent => sportId == SportCatalog.footballId;

  bool get supportsTeamManagement {
    switch (sportId) {
      case SportCatalog.footballId:
      case SportCatalog.baseballId:
      case SportCatalog.basketballId:
        return true;
      case SportCatalog.tennisId:
        return false;
      default:
        return false;
    }
  }
}

class SportMatchMetricLabel {
  final String label;

  const SportMatchMetricLabel(this.label);
}

class SportMatchLabels {
  final SportMatchMetricLabel primary;
  final SportMatchMetricLabel secondary;
  final SportMatchMetricLabel tertiary;
  final SportMatchMetricLabel quaternary;

  const SportMatchLabels({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.quaternary,
  });

  factory SportMatchLabels.forSport({
    required AppLocalizations l10n,
    required String? sportId,
  }) {
    switch (SportCatalog.normalizeSportId(sportId)) {
      case SportCatalog.baseballId:
        return SportMatchLabels(
          primary: SportMatchMetricLabel(l10n.baseballMatchHitsLabel),
          secondary: SportMatchMetricLabel(l10n.baseballMatchRbisLabel),
          tertiary: SportMatchMetricLabel(l10n.baseballMatchRunsLabel),
          quaternary:
              SportMatchMetricLabel(l10n.baseballMatchDefensivePlaysLabel),
        );
      case SportCatalog.basketballId:
        return SportMatchLabels(
          primary: SportMatchMetricLabel(l10n.basketballMatchPointsLabel),
          secondary: SportMatchMetricLabel(l10n.basketballMatchAssistsLabel),
          tertiary: SportMatchMetricLabel(l10n.basketballMatchReboundsLabel),
          quaternary: SportMatchMetricLabel(l10n.basketballMatchStealsLabel),
        );
      case SportCatalog.tennisId:
        return SportMatchLabels(
          primary: SportMatchMetricLabel(l10n.tennisMatchGamesWonLabel),
          secondary: SportMatchMetricLabel(l10n.tennisMatchAcesLabel),
          tertiary: SportMatchMetricLabel(l10n.tennisMatchFirstServesInLabel),
          quaternary:
              SportMatchMetricLabel(l10n.tennisMatchBreakPointsWonLabel),
        );
      case SportCatalog.footballId:
      default:
        return SportMatchLabels(
          primary: SportMatchMetricLabel(l10n.matchGoalsLabel),
          secondary: SportMatchMetricLabel(l10n.matchAssistsLabel),
          tertiary: SportMatchMetricLabel(l10n.matchShotsOnTargetLabel),
          quaternary: SportMatchMetricLabel(l10n.matchBallsWonLabel),
        );
    }
  }

  List<String> personalRecordParts(TrainingEntry entry) {
    final parts = <String>[];
    if (entry.playerGoals != null) {
      parts.add('${primary.label} ${entry.playerGoals}');
    }
    if (entry.playerAssists != null) {
      parts.add('${secondary.label} ${entry.playerAssists}');
    }
    if (entry.shotsOnTarget != null) {
      parts.add('${tertiary.label} ${entry.shotsOnTarget}');
    }
    if (entry.ballsWon != null) {
      parts.add('${quaternary.label} ${entry.ballsWon}');
    }
    return parts;
  }
}

List<TrainingEntry> filterEntriesForSport(
  Iterable<TrainingEntry> entries,
  String? sportId,
) {
  final normalizedSportId = SportCatalog.normalizeSportId(sportId);
  return entries
      .where((entry) => entry.sportId == normalizedSportId)
      .toList(growable: false);
}
