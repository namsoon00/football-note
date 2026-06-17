import 'package:football_note/gen/app_localizations.dart';

import '../domain/entities/sport_definition.dart';

class SportDefaults {
  const SportDefaults._();

  static List<String> programOptions({
    required AppLocalizations l10n,
    String sportId = SportCatalog.defaultSportId,
  }) {
    switch (SportCatalog.normalizeSportId(sportId)) {
      case SportCatalog.footballId:
      default:
        return [
          l10n.defaultProgram1,
          l10n.defaultProgram2,
          l10n.defaultProgram3,
          l10n.defaultProgram4,
          l10n.challengeLiftingLabel,
          l10n.challengeJumpRopeLabel,
        ];
    }
  }

  static List<String> dailyGoals({
    required String languageCode,
    String sportId = SportCatalog.defaultSportId,
  }) {
    switch (SportCatalog.normalizeSportId(sportId)) {
      case SportCatalog.footballId:
      default:
        if (languageCode == 'ko') {
          return const [
            '드리블',
            '패스 정확도',
            '슈팅',
            '체력',
            '수비 위치 선정',
            '퍼스트 터치',
          ];
        }
        return const [
          'Dribbling',
          'Passing Accuracy',
          'Shooting',
          'Fitness',
          'Defensive Positioning',
          'First Touch',
        ];
    }
  }
}
