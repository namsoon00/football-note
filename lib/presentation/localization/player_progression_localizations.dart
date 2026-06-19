import '../../application/player_level_service.dart';
import '../../domain/entities/sport_definition.dart';
import '../../gen/app_localizations.dart';

extension PlayerProgressionLocalizations on AppLocalizations {
  String playerLevelName(int level, {String? sportId}) {
    final normalizedSportId = SportCatalog.normalizeSportId(sportId);
    final fallback = _footballLevelName(level);
    return switch (normalizedSportId) {
      SportCatalog.baseballId =>
        _levelLabelFromList(playerLevelBaseballNames, level, fallback),
      SportCatalog.basketballId =>
        _levelLabelFromList(playerLevelBasketballNames, level, fallback),
      SportCatalog.tennisId =>
        _levelLabelFromList(playerLevelTennisNames, level, fallback),
      _ => fallback,
    };
  }

  String _footballLevelName(int level) {
    switch (level.clamp(1, 20)) {
      case 1:
        return playerLevelName1;
      case 2:
        return playerLevelName2;
      case 3:
        return playerLevelName3;
      case 4:
        return playerLevelName4;
      case 5:
        return playerLevelName5;
      case 6:
        return playerLevelName6;
      case 7:
        return playerLevelName7;
      case 8:
        return playerLevelName8;
      case 9:
        return playerLevelName9;
      case 10:
        return playerLevelName10;
      case 11:
        return playerLevelName11;
      case 12:
        return playerLevelName12;
      case 13:
        return playerLevelName13;
      case 14:
        return playerLevelName14;
      case 15:
        return playerLevelName15;
      case 16:
        return playerLevelName16;
      case 17:
        return playerLevelName17;
      case 18:
        return playerLevelName18;
      case 19:
        return playerLevelName19;
      default:
        return playerLevelName20;
    }
  }

  String playerLevelStageName(int level, {String? sportId}) {
    final normalizedSportId = SportCatalog.normalizeSportId(sportId);
    final fallback = _footballStageName(level);
    return switch (normalizedSportId) {
      SportCatalog.baseballId =>
        _stageLabelFromList(playerLevelBaseballStages, level, fallback),
      SportCatalog.basketballId =>
        _stageLabelFromList(playerLevelBasketballStages, level, fallback),
      SportCatalog.tennisId =>
        _stageLabelFromList(playerLevelTennisStages, level, fallback),
      _ => fallback,
    };
  }

  String _footballStageName(int level) {
    if (level <= 2) return playerLevelStage1;
    if (level <= 4) return playerLevelStage2;
    if (level <= 6) return playerLevelStage3;
    if (level <= 8) return playerLevelStage4;
    if (level <= 12) return playerLevelStage5;
    if (level <= 16) return playerLevelStage6;
    return playerLevelStage7;
  }

  String playerLevelIllustrationLabel(int level, {String? sportId}) {
    final normalizedSportId = SportCatalog.normalizeSportId(sportId);
    final fallback = _footballIllustrationLabel(level);
    return switch (normalizedSportId) {
      SportCatalog.baseballId =>
        _levelLabelFromList(playerLevelBaseballIllustrations, level, fallback),
      SportCatalog.basketballId => _levelLabelFromList(
          playerLevelBasketballIllustrations,
          level,
          fallback,
        ),
      SportCatalog.tennisId =>
        _levelLabelFromList(playerLevelTennisIllustrations, level, fallback),
      _ => fallback,
    };
  }

  String _footballIllustrationLabel(int level) {
    switch (level.clamp(1, 20)) {
      case 1:
        return playerLevelIllustration1;
      case 2:
        return playerLevelIllustration2;
      case 3:
        return playerLevelIllustration3;
      case 4:
        return playerLevelIllustration4;
      case 5:
        return playerLevelIllustration5;
      case 6:
        return playerLevelIllustration6;
      case 7:
        return playerLevelIllustration7;
      case 8:
        return playerLevelIllustration8;
      case 9:
        return playerLevelIllustration9;
      case 10:
        return playerLevelIllustration10;
      case 11:
        return playerLevelIllustration11;
      case 12:
        return playerLevelIllustration12;
      case 13:
        return playerLevelIllustration13;
      case 14:
        return playerLevelIllustration14;
      case 15:
        return playerLevelIllustration15;
      case 16:
        return playerLevelIllustration16;
      case 17:
        return playerLevelIllustration17;
      case 18:
        return playerLevelIllustration18;
      case 19:
        return playerLevelIllustration19;
      default:
        return playerLevelIllustration20;
    }
  }

  String _levelLabelFromList(String raw, int level, String fallback) {
    final labels = raw
        .split('|')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    final index = level.clamp(1, 20) - 1;
    if (index < 0 || index >= labels.length) return fallback;
    return labels[index];
  }

  String _stageLabelFromList(String raw, int level, String fallback) {
    final labels = raw
        .split('|')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    final index = _stageIndex(level);
    if (index < 0 || index >= labels.length) return fallback;
    return labels[index];
  }

  int _stageIndex(int level) {
    if (level <= 2) return 0;
    if (level <= 4) return 1;
    if (level <= 6) return 2;
    if (level <= 8) return 3;
    if (level <= 12) return 4;
    if (level <= 16) return 5;
    return 6;
  }

  String xpHistoryTitleFor(PlayerXpHistoryEntry item) {
    switch (item.category) {
      case PlayerXpHistoryCategory.training:
        final label = xpHistoryTrainingTitleLabel(item);
        return label.isEmpty
            ? xpHistoryTrainingLog
            : xpHistoryTrainingLogWithLabel(label);
      case PlayerXpHistoryCategory.match:
        final label = item.label.trim();
        return label.isEmpty
            ? xpHistoryMatchLog
            : xpHistoryMatchLogWithLabel(label);
      case PlayerXpHistoryCategory.meal:
        return xpHistoryMealLog;
      case PlayerXpHistoryCategory.quiz:
        return xpHistoryQuizCompletion;
      case PlayerXpHistoryCategory.plan:
        return xpHistoryPlanCreated;
      case PlayerXpHistoryCategory.board:
        final label = item.label.trim();
        return label.isEmpty
            ? xpHistoryBoardSaved
            : xpHistoryBoardSavedWithLabel(label);
      case PlayerXpHistoryCategory.diary:
        return xpHistoryDiaryCreated;
      case PlayerXpHistoryCategory.dailyTasks:
        return xpHistoryDailyTasksComplete;
      case PlayerXpHistoryCategory.challenge:
        return xpHistoryChallengeRound(challengeHistoryTitleLabel(item));
    }
  }

  String xpHistoryTrainingTitleLabel(PlayerXpHistoryEntry item) {
    final addedParts = <String>[];
    if (item.reasons.contains('lifting_added')) {
      addedParts.add(xpHistoryTrainingLabelLifting);
    }
    if (item.reasons.contains('jump_rope_added')) {
      addedParts.add(xpHistoryTrainingLabelJumpRope);
    }
    if (addedParts.isNotEmpty) {
      return addedParts.join(', ');
    }
    return item.label.trim();
  }

  String xpHistoryReasonLabel(String reason) {
    switch (reason) {
      case 'log':
        return xpHistoryReasonLog;
      case 'first_daily_log':
        return xpHistoryReasonFirstDailyLog;
      case 'plan_completed':
        return xpHistoryReasonPlanCompleted;
      case 'lifting_recorded':
        return xpHistoryReasonLiftingRecorded;
      case 'jump_rope_recorded':
        return xpHistoryReasonJumpRopeRecorded;
      case 'lifting_missed':
        return xpHistoryReasonLiftingMissed;
      case 'jump_rope_missed':
        return xpHistoryReasonJumpRopeMissed;
      case 'lifting_added':
        return xpHistoryReasonLiftingAdded;
      case 'jump_rope_added':
        return xpHistoryReasonJumpRopeAdded;
      case 'meal_two_plus':
        return xpHistoryReasonMealTwoPlus;
      case 'meal_full_day':
        return xpHistoryReasonMealFullDay;
      case 'meal_full_day_bonus':
        return xpHistoryReasonMealFullDayBonus;
      case 'streak_3':
        return xpHistoryReasonStreak3;
      case 'streak_7':
        return xpHistoryReasonStreak7;
      case 'streak_daily_2_3':
        return xpHistoryReasonStreakDaily2;
      case 'streak_daily_4_6':
        return xpHistoryReasonStreakDaily4;
      case 'streak_daily_7_plus':
        return xpHistoryReasonStreakDaily7;
      case 'routine_complete_day':
        return xpHistoryReasonRoutineComplete;
      case 'weekly_3':
        return xpHistoryReasonWeekly3;
      case 'weekly_5':
        return xpHistoryReasonWeekly5;
      case 'quiz_complete':
        return xpHistoryReasonQuizComplete;
      case 'plan_created':
        return xpHistoryReasonPlanCreated;
      case 'match_logged':
        return xpHistoryReasonMatchLogged;
      case 'match_result_recorded':
        return xpHistoryReasonMatchResultRecorded;
      case 'match_contribution_recorded':
        return xpHistoryReasonMatchContributionRecorded;
      case 'board_created':
        return xpHistoryReasonBoardCreated;
      case 'board_saved':
        return xpHistoryReasonBoardSaved;
      case 'diary_created':
        return xpHistoryReasonDiaryCreated;
      case 'daily_tasks_completed':
        return xpHistoryReasonDailyTasksCompleted;
      case 'challenge_round_completed':
        return xpHistoryReasonChallengeRoundCompleted;
      case 'challenge_round_streak_bonus':
        return xpHistoryReasonChallengeRoundStreakBonus;
      case 'challenge_completed_bonus':
        return xpHistoryReasonChallengeCompletionBonus;
      case 'daily_xp_cap':
        return xpHistoryReasonDailyCap;
      default:
        if (reason.startsWith('plan_group_created:')) {
          final count = int.tryParse(reason.split(':').last) ?? 0;
          return xpHistoryReasonPlanGroupCreated(count);
        }
        return reason;
    }
  }

  String challengeHistoryTitleLabel(PlayerXpHistoryEntry item) {
    final parts = item.label.split(':');
    if (parts.isEmpty) return challengeTitle;
    final templateTitle = switch (parts.first) {
      'starter_3' => challengeTemplateStarterTitle,
      'weekly_7' => challengeTemplateWeeklyTitle,
      'focus_14' => challengeTemplateFocusTitle,
      _ => challengeTitle,
    };
    final roundNumber = parts.length > 1 ? int.tryParse(parts[1]) : null;
    if (parts.length > 1 && parts[1] == 'complete') {
      return '$templateTitle · $xpHistoryReasonChallengeCompletionBonus';
    }
    if (roundNumber == null) return templateTitle;
    return '$templateTitle · $roundNumber';
  }
}
