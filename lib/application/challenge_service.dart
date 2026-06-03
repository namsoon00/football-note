import 'dart:convert';

import '../domain/entities/challenge.dart';
import '../domain/entities/meal_entry.dart';
import '../domain/entities/training_entry.dart';
import '../domain/repositories/option_repository.dart';
import 'player_level_service.dart';

class ChallengeService {
  static const String storageKey = 'challenge_runs_v1';

  final OptionRepository _options;

  ChallengeService(this._options);

  List<ChallengeTemplate> templates() => defaultChallengeTemplates;

  ChallengeTemplate? templateById(String id) {
    for (final template in defaultChallengeTemplates) {
      if (template.id == id) return template;
    }
    return null;
  }

  List<ChallengeRun> loadRuns() {
    final raw = _options.getValue<String>(storageKey) ?? '[]';
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
    for (final run in loadRuns()) {
      if (!run.isEnded) return run;
    }
    return null;
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
    DateTime? startedAt,
  }) async {
    final start = startedAt ?? DateTime.now();
    final run = ChallengeRun(
      id: '${template.id}-${start.toUtc().microsecondsSinceEpoch}',
      templateId: template.id,
      trainingLevel: trainingLevel,
      startedAt: start,
    );
    final runs = loadRuns()
        .map(
          (item) => item.isEnded
              ? item
              : item.copyWith(
                  completedAt: start,
                  abandoned: true,
                  result: ChallengeRunResult.abandoned,
                ),
        )
        .toList(growable: true);
    runs.insert(0, run);
    await _saveRuns(runs);
    return run;
  }

  Future<void> completeRun(String runId, {DateTime? completedAt}) async {
    final completed = completedAt ?? DateTime.now();
    final runs = loadRuns()
        .map(
          (run) => run.id == runId
              ? run.copyWith(
                  completedAt: completed,
                  abandoned: false,
                  result: ChallengeRunResult.completed,
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
                )
              : run,
        )
        .toList(growable: false);
    await _saveRuns(runs);
  }

  Future<void> abandonActiveRun({DateTime? abandonedAt}) async {
    final active = activeRun();
    if (active == null) return;
    final endedAt = abandonedAt ?? DateTime.now();
    final runs = loadRuns()
        .map(
          (run) => run.id == active.id
              ? run.copyWith(
                  completedAt: endedAt,
                  abandoned: true,
                  result: ChallengeRunResult.abandoned,
                )
              : run,
        )
        .toList(growable: false);
    await _saveRuns(runs);
  }

  ChallengeProgress? progressForRun({
    required ChallengeRun run,
    required List<TrainingEntry> trainingEntries,
    required List<MealEntry> mealEntries,
  }) {
    final template = templateById(run.templateId);
    if (template == null) return null;
    final rounds = template.rounds.map(
      (round) {
        final effectiveRound = roundForLevel(round, run.trainingLevel);
        final date = run.dayForRound(round.number);
        return ChallengeRoundProgress(
          round: effectiveRound,
          date: date,
          trainingMinutes: trainingMinutesForDay(trainingEntries, date),
          jumpRopeMinutes: jumpRopeMinutesForDay(trainingEntries, date),
          liftingMinutes: liftingMinutesForDay(trainingEntries, date),
          riceBowls: riceBowlsForDay(mealEntries, date),
        );
      },
    ).toList(growable: false);
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

  Future<List<PlayerLevelAward>> awardCompletedRounds({
    required ChallengeProgress progress,
    required PlayerLevelService playerLevelService,
    DateTime? awardedAt,
  }) async {
    final awards = <PlayerLevelAward>[];
    for (final round in progress.rounds.where((item) => item.completed)) {
      final award = await playerLevelService.awardForChallengeRound(
        challengeRunId: progress.run.id,
        roundNumber: round.round.number,
        challengeLabel: progress.template.id,
        completedAt: awardedAt ?? DateTime.now(),
        rewardXp: round.round.rewardXp,
      );
      awards.add(award);
    }
    if (progress.allRoundsCompleted) {
      final completionAward =
          await playerLevelService.awardForChallengeCompletion(
        challengeRunId: progress.run.id,
        challengeLabel: progress.template.id,
        completedAt: awardedAt ?? DateTime.now(),
        rewardXp: completionBonusXpFor(
          progress.template,
          progress.run.trainingLevel,
        ),
      );
      awards.add(completionAward);
      await completeRun(progress.run.id,
          completedAt: awardedAt ?? DateTime.now());
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
    for (final round in progress.rounds.where((item) => item.completed)) {
      final award = await playerLevelService.awardForChallengeRound(
        challengeRunId: progress.run.id,
        roundNumber: round.round.number,
        challengeLabel: progress.template.id,
        completedAt: round.date.add(const Duration(hours: 21)),
        rewardXp: round.round.rewardXp,
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
      await completeRun(progress.run.id, completedAt: endedAt);
    } else {
      final failedRoundNumber = progress.firstIncompleteRound?.round.number;
      await failRun(
        progress.run.id,
        roundNumber: failedRoundNumber ?? progress.rounds.length,
        failedAt: endedAt,
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
      storageKey,
      jsonEncode(capped.map((run) => run.toMap()).toList(growable: false)),
    );
  }
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

const List<ChallengeTrainingLevelConfig> challengeTrainingLevelConfigs =
    <ChallengeTrainingLevelConfig>[
  ChallengeTrainingLevelConfig(
    level: ChallengeTrainingLevel.rookie,
    targetTrainingMinutes: 60,
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

ChallengeTrainingLevelConfig trainingLevelConfig(
  ChallengeTrainingLevel level,
) {
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

int challengeTotalPotentialXpFor(
  ChallengeTemplate template,
  ChallengeTrainingLevel level,
) {
  final config = trainingLevelConfig(level);
  return template.dayCount * config.rewardXpPerRound +
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
        targetTrainingMinutes: 60,
        targetJumpRopeMinutes: 10,
        targetLiftingMinutes: 10,
        targetRiceBowls: 3,
        rewardXp: 10,
      ),
      growable: false,
    ),
  );
}
