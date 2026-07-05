import 'dart:convert';

import '../domain/entities/challenge.dart';
import '../domain/entities/meal_entry.dart';
import '../domain/entities/training_entry.dart';
import '../domain/repositories/option_repository.dart';
import 'player_level_service.dart';
import 'sport_scoped_storage.dart';

const int challengeConsecutiveRoundBonusStepXp = 3;
const int challengeConsecutiveRoundBonusMaxXp = 15;

class ChallengeService {
  static const String storageKey = 'challenge_runs_v1';

  final OptionRepository _options;
  final String? _sportId;

  ChallengeService(this._options, {String? sportId}) : _sportId = sportId;

  String get _storageKey => sportScopedOptionKey(
        _options,
        storageKey,
        sportId: _sportId,
      );

  List<ChallengeTemplate> templates() => defaultChallengeTemplates;

  ChallengeTemplate? templateById(String id) {
    for (final template in defaultChallengeTemplates) {
      if (template.id == id) return template;
    }
    return null;
  }

  List<ChallengeRun> loadRuns() {
    final raw = _options.getValue<String>(_storageKey) ?? '[]';
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <ChallengeRun>[];
      return decoded
          .whereType<Map>()
          .map((item) => ChallengeRun.fromMap(item.cast<String, dynamic>()))
          .where((run) => templateById(run.templateId) != null)
          .toList(growable: false)
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    } catch (_) {
      return const <ChallengeRun>[];
    }
  }

  ChallengeRun? activeRun() {
    final runs = activeRuns();
    return runs.isEmpty ? null : runs.first;
  }

  List<ChallengeRun> activeRuns() {
    return loadRuns().where((run) => !run.isEnded).toList(growable: false);
  }

  ChallengeRun? latestCompletedRun() {
    for (final run in loadRuns()) {
      if (run.isCompleted) return run;
    }
    return null;
  }

  Future<ChallengeRun> startChallenge(
    ChallengeTemplate template, {
    ChallengeTrainingLevel trainingLevel = ChallengeTrainingLevel.rookie,
    List<String> selectedSkillIds = defaultChallengeSkillIds,
    ChallengeMissionTargets? missionTargets,
    int cadenceDays = 1,
    String rewardGift = '',
    DateTime? startedAt,
  }) async {
    final start = startedAt ?? DateTime.now();
    final run = ChallengeRun(
      id: '${template.id}-${start.toUtc().microsecondsSinceEpoch}',
      templateId: template.id,
      trainingLevel: trainingLevel,
      startedAt: start,
      selectedSkillIds: normalizeChallengeSkillIds(
        selectedSkillIds,
        allowEmpty: missionTargets?.hasTrainingMission == false,
      ),
      missionTargets: missionTargets,
      cadenceDays: cadenceDays,
      rewardGift: rewardGift.trim(),
    );
    final runs = loadRuns().toList(growable: true);
    runs.insert(0, run);
    await _saveRuns(runs);
    return run;
  }

  Future<ChallengeRun?> updateRun(
    String runId, {
    required ChallengeTemplate template,
    List<String> selectedSkillIds = defaultChallengeSkillIds,
    ChallengeMissionTargets? missionTargets,
    int cadenceDays = 1,
    String? rewardGift,
  }) async {
    ChallengeRun? updatedRun;
    final completedRoundLimit = template.dayCount;
    final runs = loadRuns().map(
      (run) {
        if (run.id != runId || run.isEnded) return run;
        final completedRoundNumbers = run.completedRoundNumbers
            .where((roundNumber) => roundNumber <= completedRoundLimit)
            .toList(growable: false);
        updatedRun = run.copyWith(
          templateId: template.id,
          selectedSkillIds: normalizeChallengeSkillIds(
            selectedSkillIds,
            allowEmpty: missionTargets?.hasTrainingMission == false,
          ),
          missionTargets: missionTargets,
          cadenceDays: cadenceDays,
          completedRoundNumbers: completedRoundNumbers,
          rewardGift: rewardGift?.trim() ?? run.rewardGift,
        );
        return updatedRun!;
      },
    ).toList(growable: false);
    if (updatedRun == null) return null;
    await _saveRuns(runs);
    return updatedRun;
  }

  Future<void> completeRun(
    String runId, {
    DateTime? completedAt,
    List<int> completedRoundNumbers = const <int>[],
  }) async {
    final completed = completedAt ?? DateTime.now();
    final runs = loadRuns()
        .map(
          (run) => run.id == runId
              ? run.copyWith(
                  completedAt: completed,
                  abandoned: false,
                  result: ChallengeRunResult.completed,
                  completedRoundNumbers: completedRoundNumbers,
                )
              : run,
        )
        .toList(growable: false);
    await _saveRuns(runs);
  }

  Future<void> failRun(
    String runId, {
    required int roundNumber,
    DateTime? failedAt,
    List<int> completedRoundNumbers = const <int>[],
  }) async {
    final endedAt = failedAt ?? DateTime.now();
    final runs = loadRuns()
        .map(
          (run) => run.id == runId
              ? run.copyWith(
                  completedAt: endedAt,
                  abandoned: false,
                  result: ChallengeRunResult.failed,
                  failedRoundNumber: roundNumber,
                  completedRoundNumbers: completedRoundNumbers,
                )
              : run,
        )
        .toList(growable: false);
    await _saveRuns(runs);
  }

  Future<void> abandonActiveRun({
    DateTime? abandonedAt,
    List<int> completedRoundNumbers = const <int>[],
  }) async {
    final active = activeRun();
    if (active == null) return;
    await abandonRun(
      active.id,
      abandonedAt: abandonedAt,
      completedRoundNumbers: completedRoundNumbers,
    );
  }

  Future<void> abandonRun(
    String runId, {
    DateTime? abandonedAt,
    List<int> completedRoundNumbers = const <int>[],
  }) async {
    final endedAt = abandonedAt ?? DateTime.now();
    final runs = loadRuns()
        .map(
          (run) => run.id == runId
              ? run.copyWith(
                  completedAt: endedAt,
                  abandoned: true,
                  result: ChallengeRunResult.abandoned,
                  completedRoundNumbers: completedRoundNumbers,
                )
              : run,
        )
        .toList(growable: false);
    await _saveRuns(runs);
  }

  Future<bool> deleteActiveRun(String runId) async {
    var deleted = false;
    final runs = loadRuns().where(
      (run) {
        if (run.id == runId && !run.isEnded) {
          deleted = true;
          return false;
        }
        return true;
      },
    ).toList(growable: false);
    if (!deleted) return false;
    await _saveRuns(runs);
    return true;
  }

  ChallengeProgress? progressForRun({
    required ChallengeRun run,
    required List<TrainingEntry> trainingEntries,
    required List<MealEntry> mealEntries,
  }) {
    final template = templateById(run.templateId);
    if (template == null) return null;
    final rounds = template.rounds.map((round) {
      final levelRound = roundForLevel(round, run.trainingLevel);
      final targets = missionTargetsForRun(levelRound, run);
      final effectiveRound = roundWithMissionTargets(
        levelRound,
        targets,
        selectedSkillIds: run.selectedSkillIds,
      );
      final date = run.dayForRound(round.number);
      final trainingPrograms = trainingProgramProgressForDay(
        trainingEntries,
        date,
        selectedSkillIds: run.selectedSkillIds,
        targetTrainingMinutes: effectiveRound.targetTrainingMinutes,
        targetMinutesByProgram: targets.trainingProgramTargetsFor(
          run.selectedSkillIds,
        ),
      );
      return ChallengeRoundProgress(
        round: effectiveRound,
        date: date,
        trainingMinutes: trainingPrograms.isEmpty
            ? trainingMinutesForDay(
                trainingEntries,
                date,
                selectedSkillIds: run.selectedSkillIds,
              )
            : trainingPrograms.fold<int>(
                0,
                (sum, program) => sum + program.currentMinutes,
              ),
        jumpRopeMinutes: jumpRopeMinutesForDay(trainingEntries, date),
        liftingMinutes: liftingMinutesForDay(trainingEntries, date),
        riceBowls: riceBowlsForDay(mealEntries, date),
        trainingPrograms: trainingPrograms,
      );
    }).toList(growable: false);
    return ChallengeProgress(run: run, template: template, rounds: rounds);
  }

  ChallengeProgress? activeProgress({
    required List<TrainingEntry> trainingEntries,
    required List<MealEntry> mealEntries,
  }) {
    final run = activeRun();
    if (run == null) return null;
    return progressForRun(
      run: run,
      trainingEntries: trainingEntries,
      mealEntries: mealEntries,
    );
  }

  List<ChallengeProgress> activeProgresses({
    required List<TrainingEntry> trainingEntries,
    required List<MealEntry> mealEntries,
  }) {
    return activeRuns()
        .map(
          (run) => progressForRun(
            run: run,
            trainingEntries: trainingEntries,
            mealEntries: mealEntries,
          ),
        )
        .whereType<ChallengeProgress>()
        .toList(growable: false);
  }

  ChallengeProgress? activeProgressForRun({
    required String runId,
    required List<TrainingEntry> trainingEntries,
    required List<MealEntry> mealEntries,
  }) {
    for (final run in activeRuns()) {
      if (run.id != runId) continue;
      return progressForRun(
        run: run,
        trainingEntries: trainingEntries,
        mealEntries: mealEntries,
      );
    }
    return null;
  }

  Future<List<PlayerLevelAward>> awardCompletedRounds({
    required ChallengeProgress progress,
    required PlayerLevelService playerLevelService,
    DateTime? awardedAt,
  }) async {
    final awards = <PlayerLevelAward>[];
    awards.addAll(
      await revokeIncompleteAwards(
        progress: progress,
        playerLevelService: playerLevelService,
      ),
    );
    var consecutiveRoundNumber = 0;
    for (final round in progress.rounds) {
      if (!round.completed) {
        consecutiveRoundNumber = 0;
        continue;
      }
      consecutiveRoundNumber += 1;
      final streakBonusXp = challengeRoundStreakBonusXpFor(
        consecutiveRoundNumber,
      );
      final award = await playerLevelService.awardForChallengeRound(
        challengeRunId: progress.run.id,
        roundNumber: round.round.number,
        challengeLabel: progress.template.id,
        completedAt: awardedAt ?? DateTime.now(),
        rewardXp: challengeRoundRewardXpFor(
          baseRewardXp: round.round.rewardXp,
          consecutiveRoundNumber: consecutiveRoundNumber,
        ),
        streakBonusXp: streakBonusXp,
      );
      awards.add(award);
    }
    return awards;
  }

  Future<List<PlayerLevelAward>> revokeIncompleteAwards({
    required ChallengeProgress progress,
    required PlayerLevelService playerLevelService,
  }) async {
    final awards = <PlayerLevelAward>[];
    for (final round in progress.rounds) {
      if (round.completed) continue;
      awards.add(
        await playerLevelService.revokeChallengeRound(
          challengeRunId: progress.run.id,
          roundNumber: round.round.number,
        ),
      );
    }
    if (!progress.allRoundsCompleted) {
      awards.add(
        await playerLevelService.revokeChallengeCompletion(
          challengeRunId: progress.run.id,
        ),
      );
    }
    return awards;
  }

  Future<List<PlayerLevelAward>> finalizeRun({
    required ChallengeProgress progress,
    required PlayerLevelService playerLevelService,
    DateTime? finalizedAt,
  }) async {
    final endedAt = finalizedAt ?? DateTime.now();
    if (progress.run.isEnded || !progress.readyToFinalize(now: endedAt)) {
      return const <PlayerLevelAward>[];
    }

    final awards = <PlayerLevelAward>[];
    awards.addAll(
      await revokeIncompleteAwards(
        progress: progress,
        playerLevelService: playerLevelService,
      ),
    );
    var consecutiveRoundNumber = 0;
    for (final round in progress.rounds) {
      if (!round.completed) {
        consecutiveRoundNumber = 0;
        continue;
      }
      consecutiveRoundNumber += 1;
      final streakBonusXp = challengeRoundStreakBonusXpFor(
        consecutiveRoundNumber,
      );
      final award = await playerLevelService.awardForChallengeRound(
        challengeRunId: progress.run.id,
        roundNumber: round.round.number,
        challengeLabel: progress.template.id,
        completedAt: round.date.add(const Duration(hours: 21)),
        rewardXp: challengeRoundRewardXpFor(
          baseRewardXp: round.round.rewardXp,
          consecutiveRoundNumber: consecutiveRoundNumber,
        ),
        streakBonusXp: streakBonusXp,
      );
      awards.add(award);
    }

    if (progress.allRoundsCompleted) {
      final completionAward =
          await playerLevelService.awardForChallengeCompletion(
        challengeRunId: progress.run.id,
        challengeLabel: progress.template.id,
        completedAt: endedAt,
        rewardXp: challengeCompletionBonusXpFor(
          progress.template,
          progress.run.trainingLevel,
        ),
      );
      awards.add(completionAward);
      await completeRun(
        progress.run.id,
        completedAt: endedAt,
        completedRoundNumbers: _completedRoundNumbers(progress),
      );
    } else {
      final failedRoundNumber = progress.firstIncompleteRound?.round.number;
      await failRun(
        progress.run.id,
        roundNumber: failedRoundNumber ?? progress.rounds.length,
        failedAt: endedAt,
        completedRoundNumbers: _completedRoundNumbers(progress),
      );
    }

    return awards;
  }

  ChallengeRound roundForLevel(
    ChallengeRound base,
    ChallengeTrainingLevel level,
  ) {
    final config = trainingLevelConfig(level);
    return ChallengeRound(
      number: base.number,
      targetTrainingMinutes: config.targetTrainingMinutes,
      targetJumpRopeMinutes: config.targetJumpRopeMinutes,
      targetLiftingMinutes: config.targetLiftingMinutes,
      targetRiceBowls: config.targetRiceBowls,
      rewardXp: config.rewardXpPerRound,
    );
  }

  ChallengeRound roundForRun(ChallengeRound base, ChallengeRun run) {
    final levelRound = roundForLevel(base, run.trainingLevel);
    final targets = missionTargetsForRun(levelRound, run);
    return roundWithMissionTargets(
      levelRound,
      targets,
      selectedSkillIds: run.selectedSkillIds,
    );
  }

  ChallengeMissionTargets missionTargetsForRun(
    ChallengeRound levelRound,
    ChallengeRun run,
  ) {
    return run.missionTargets ?? challengeMissionTargetsFromRound(levelRound);
  }

  ChallengeRound roundWithMissionTargets(
    ChallengeRound base,
    ChallengeMissionTargets targets, {
    Iterable<String> selectedSkillIds = const <String>[],
  }) {
    return ChallengeRound(
      number: base.number,
      targetTrainingMinutes: targets.trainingMinutesForPrograms(
        selectedSkillIds,
      ),
      targetJumpRopeMinutes: targets.jumpRopeMinutes,
      targetLiftingMinutes: targets.liftingMinutes,
      targetRiceBowls: targets.riceBowls,
      rewardXp: base.rewardXp,
    );
  }

  int completionBonusXpFor(
    ChallengeTemplate template,
    ChallengeTrainingLevel level,
  ) {
    return challengeCompletionBonusXpFor(template, level);
  }

  int totalPotentialXpFor(
    ChallengeTemplate template,
    ChallengeTrainingLevel level,
  ) {
    return challengeTotalPotentialXpFor(template, level);
  }

  static ChallengeTrainingLevel recommendedLevel({
    required int? ageYears,
    required int? soccerYears,
  }) {
    final age = ageYears ?? 10;
    final years = soccerYears ?? 0;
    if (age >= 13 && years >= 4) return ChallengeTrainingLevel.ace;
    if (age >= 10 && years >= 2) return ChallengeTrainingLevel.growth;
    return ChallengeTrainingLevel.rookie;
  }

  Future<void> _saveRuns(List<ChallengeRun> runs) async {
    final capped = runs.take(20).toList(growable: false);
    await _options.setValue(
      _storageKey,
      jsonEncode(capped.map((run) => run.toMap()).toList(growable: false)),
    );
  }
}

List<int> _completedRoundNumbers(ChallengeProgress progress) {
  return progress.rounds
      .where((round) => round.completed)
      .map((round) => round.round.number)
      .toList(growable: false);
}

class ChallengeTrainingLevelConfig {
  final ChallengeTrainingLevel level;
  final int targetTrainingMinutes;
  final int targetJumpRopeMinutes;
  final int targetLiftingMinutes;
  final double targetRiceBowls;
  final int rewardXpPerRound;
  final int completionBonusXpPerDay;

  const ChallengeTrainingLevelConfig({
    required this.level,
    required this.targetTrainingMinutes,
    required this.targetJumpRopeMinutes,
    required this.targetLiftingMinutes,
    required this.targetRiceBowls,
    required this.rewardXpPerRound,
    required this.completionBonusXpPerDay,
  });
}

ChallengeMissionTargets challengeMissionTargetsFromConfig(
  ChallengeTrainingLevelConfig config,
) {
  return ChallengeMissionTargets(
    trainingMinutes: config.targetTrainingMinutes,
    jumpRopeMinutes: config.targetJumpRopeMinutes,
    liftingMinutes: config.targetLiftingMinutes,
    riceBowls: config.targetRiceBowls,
  );
}

ChallengeMissionTargets challengeMissionTargetsFromRound(ChallengeRound round) {
  return ChallengeMissionTargets(
    trainingMinutes: round.targetTrainingMinutes,
    jumpRopeMinutes: round.targetJumpRopeMinutes,
    liftingMinutes: round.targetLiftingMinutes,
    riceBowls: round.targetRiceBowls,
  );
}

const List<ChallengeTrainingLevelConfig> challengeTrainingLevelConfigs =
    <ChallengeTrainingLevelConfig>[
  ChallengeTrainingLevelConfig(
    level: ChallengeTrainingLevel.rookie,
    targetTrainingMinutes: 30,
    targetJumpRopeMinutes: 10,
    targetLiftingMinutes: 10,
    targetRiceBowls: 3,
    rewardXpPerRound: 10,
    completionBonusXpPerDay: 40,
  ),
  ChallengeTrainingLevelConfig(
    level: ChallengeTrainingLevel.growth,
    targetTrainingMinutes: 90,
    targetJumpRopeMinutes: 20,
    targetLiftingMinutes: 20,
    targetRiceBowls: 3.5,
    rewardXpPerRound: 16,
    completionBonusXpPerDay: 70,
  ),
  ChallengeTrainingLevelConfig(
    level: ChallengeTrainingLevel.ace,
    targetTrainingMinutes: 120,
    targetJumpRopeMinutes: 30,
    targetLiftingMinutes: 30,
    targetRiceBowls: 4,
    rewardXpPerRound: 24,
    completionBonusXpPerDay: 110,
  ),
];

ChallengeTrainingLevelConfig trainingLevelConfig(ChallengeTrainingLevel level) {
  for (final config in challengeTrainingLevelConfigs) {
    if (config.level == level) return config;
  }
  return challengeTrainingLevelConfigs.first;
}

int challengeCompletionBonusXpFor(
  ChallengeTemplate template,
  ChallengeTrainingLevel level,
) {
  return template.dayCount * trainingLevelConfig(level).completionBonusXpPerDay;
}

int challengeRoundStreakBonusXpFor(int consecutiveRoundNumber) {
  if (consecutiveRoundNumber <= 1) return 0;
  final bonus =
      (consecutiveRoundNumber - 1) * challengeConsecutiveRoundBonusStepXp;
  return bonus.clamp(0, challengeConsecutiveRoundBonusMaxXp).toInt();
}

int challengeRoundRewardXpFor({
  required int baseRewardXp,
  required int consecutiveRoundNumber,
}) {
  return baseRewardXp + challengeRoundStreakBonusXpFor(consecutiveRoundNumber);
}

int challengeTotalRoundRewardXpFor(
  ChallengeTemplate template,
  ChallengeTrainingLevel level,
) {
  final config = trainingLevelConfig(level);
  var total = 0;
  for (var roundNumber = 1; roundNumber <= template.dayCount; roundNumber++) {
    total += challengeRoundRewardXpFor(
      baseRewardXp: config.rewardXpPerRound,
      consecutiveRoundNumber: roundNumber,
    );
  }
  return total;
}

int challengeTotalPotentialXpFor(
  ChallengeTemplate template,
  ChallengeTrainingLevel level,
) {
  return challengeTotalRoundRewardXpFor(template, level) +
      challengeCompletionBonusXpFor(template, level);
}

final List<ChallengeTemplate> defaultChallengeTemplates =
    List<ChallengeTemplate>.unmodifiable(<ChallengeTemplate>[
  _defaultChallengeTemplate(id: 'starter_3', dayCount: 3),
  _defaultChallengeTemplate(id: 'weekly_7', dayCount: 7),
  _defaultChallengeTemplate(id: 'focus_14', dayCount: 14),
]);

ChallengeTemplate _defaultChallengeTemplate({
  required String id,
  required int dayCount,
}) {
  return ChallengeTemplate(
    id: id,
    dayCount: dayCount,
    rewardXpPerRound: 10,
    rounds: List<ChallengeRound>.generate(
      dayCount,
      (index) => ChallengeRound(
        number: index + 1,
        targetTrainingMinutes: 30,
        targetJumpRopeMinutes: 10,
        targetLiftingMinutes: 10,
        targetRiceBowls: 3,
        rewardXp: 10,
      ),
      growable: false,
    ),
  );
}
