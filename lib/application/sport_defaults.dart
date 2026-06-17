import 'package:football_note/gen/app_localizations.dart';

import '../domain/entities/sport_definition.dart';

class SportDefaults {
  const SportDefaults._();

  static String label({
    required AppLocalizations l10n,
    String sportId = SportCatalog.defaultSportId,
  }) {
    switch (SportCatalog.normalizeSportId(sportId)) {
      case SportCatalog.baseballId:
        return l10n.sportBaseball;
      case SportCatalog.basketballId:
        return l10n.sportBasketball;
      case SportCatalog.tennisId:
        return l10n.sportTennis;
      case SportCatalog.footballId:
      default:
        return l10n.sportFootball;
    }
  }

  static List<String> programOptions({
    required AppLocalizations l10n,
    String sportId = SportCatalog.defaultSportId,
  }) {
    switch (SportCatalog.normalizeSportId(sportId)) {
      case SportCatalog.baseballId:
        return [
          l10n.baseballProgramThrowing,
          l10n.baseballProgramBatting,
          l10n.baseballProgramFielding,
          l10n.baseballProgramBaseRunning,
          l10n.baseballProgramConditioning,
          l10n.baseballProgramRecovery,
        ];
      case SportCatalog.basketballId:
        return [
          l10n.basketballProgramBallHandling,
          l10n.basketballProgramShooting,
          l10n.basketballProgramPassing,
          l10n.basketballProgramDefense,
          l10n.basketballProgramConditioning,
          l10n.basketballProgramRecovery,
        ];
      case SportCatalog.tennisId:
        return [
          l10n.tennisProgramStroke,
          l10n.tennisProgramServe,
          l10n.tennisProgramFootwork,
          l10n.tennisProgramMatchPlay,
          l10n.tennisProgramConditioning,
          l10n.tennisProgramRecovery,
        ];
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
    required AppLocalizations l10n,
    String sportId = SportCatalog.defaultSportId,
  }) {
    switch (SportCatalog.normalizeSportId(sportId)) {
      case SportCatalog.baseballId:
        return [
          l10n.baseballGoalThrowingAccuracy,
          l10n.baseballGoalBattingContact,
          l10n.baseballGoalFieldingGlove,
          l10n.baseballGoalBaseRunning,
          l10n.baseballGoalReactionSpeed,
          l10n.baseballGoalGameAwareness,
        ];
      case SportCatalog.basketballId:
        return [
          l10n.basketballGoalBallHandling,
          l10n.basketballGoalShootingForm,
          l10n.basketballGoalPassingChoices,
          l10n.basketballGoalDefensiveFootwork,
          l10n.basketballGoalRebounding,
          l10n.basketballGoalFitness,
        ];
      case SportCatalog.tennisId:
        return [
          l10n.tennisGoalServeConsistency,
          l10n.tennisGoalForehand,
          l10n.tennisGoalBackhand,
          l10n.tennisGoalFootwork,
          l10n.tennisGoalRallyConsistency,
          l10n.tennisGoalMatchStrategy,
        ];
      case SportCatalog.footballId:
      default:
        return [
          l10n.footballGoalDribbling,
          l10n.footballGoalPassingAccuracy,
          l10n.footballGoalShooting,
          l10n.footballGoalFitness,
          l10n.footballGoalDefensivePositioning,
          l10n.footballGoalFirstTouch,
        ];
    }
  }

  static String primaryConditioningLabel({
    required AppLocalizations l10n,
    String sportId = SportCatalog.defaultSportId,
  }) {
    switch (SportCatalog.normalizeSportId(sportId)) {
      case SportCatalog.baseballId:
        return l10n.baseballConditioningPrimary;
      case SportCatalog.basketballId:
        return l10n.basketballConditioningPrimary;
      case SportCatalog.tennisId:
        return l10n.tennisConditioningPrimary;
      case SportCatalog.footballId:
      default:
        return l10n.challengeJumpRopeLabel;
    }
  }

  static String secondaryConditioningLabel({
    required AppLocalizations l10n,
    String sportId = SportCatalog.defaultSportId,
  }) {
    switch (SportCatalog.normalizeSportId(sportId)) {
      case SportCatalog.baseballId:
        return l10n.baseballConditioningSecondary;
      case SportCatalog.basketballId:
        return l10n.basketballConditioningSecondary;
      case SportCatalog.tennisId:
        return l10n.tennisConditioningSecondary;
      case SportCatalog.footballId:
      default:
        return l10n.challengeLiftingLabel;
    }
  }

  static String secondaryConditioningDetailTitle({
    required AppLocalizations l10n,
    String sportId = SportCatalog.defaultSportId,
  }) {
    switch (SportCatalog.normalizeSportId(sportId)) {
      case SportCatalog.baseballId:
        return l10n.baseballConditioningDetailTitle;
      case SportCatalog.basketballId:
        return l10n.basketballConditioningDetailTitle;
      case SportCatalog.tennisId:
        return l10n.tennisConditioningDetailTitle;
      case SportCatalog.footballId:
      default:
        return l10n.liftingByPart;
    }
  }

  static List<String> secondaryConditioningDetailLabels({
    required AppLocalizations l10n,
    String sportId = SportCatalog.defaultSportId,
  }) {
    switch (SportCatalog.normalizeSportId(sportId)) {
      case SportCatalog.baseballId:
        return [
          l10n.baseballConditioningDetailShortThrow,
          l10n.baseballConditioningDetailLongThrow,
          l10n.baseballConditioningDetailGrounder,
          l10n.baseballConditioningDetailFlyBall,
          l10n.baseballConditioningDetailTransfer,
          l10n.baseballConditioningDetailCore,
        ];
      case SportCatalog.basketballId:
        return [
          l10n.basketballConditioningDetailRightHand,
          l10n.basketballConditioningDetailLeftHand,
          l10n.basketballConditioningDetailCrossover,
          l10n.basketballConditioningDetailChangePace,
          l10n.basketballConditioningDetailShootingPocket,
          l10n.basketballConditioningDetailPressure,
        ];
      case SportCatalog.tennisId:
        return [
          l10n.tennisConditioningDetailForehand,
          l10n.tennisConditioningDetailBackhand,
          l10n.tennisConditioningDetailServeToss,
          l10n.tennisConditioningDetailVolley,
          l10n.tennisConditioningDetailApproach,
          l10n.tennisConditioningDetailRecovery,
        ];
      case SportCatalog.footballId:
      default:
        return [
          l10n.liftingPartInfront,
          l10n.liftingPartInside,
          l10n.liftingPartOutside,
          l10n.liftingPartMuple,
          l10n.liftingPartHead,
          l10n.liftingPartChest,
        ];
    }
  }
}
