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

  ChallengeRound roundForLevel(
    ChallengeRound base,
    ChallengeTrainingLevel level,
  ) {
    final config = trainingLevelConfig(level);
    int scaleMinutes(int value) {
      return (value * config.targetMultiplier)
          .round()
          .clamp(1, 1000000)
          .toInt();
    }

    double scaleBowls(double value) {
      final scaled = value * config.mealMultiplier;
      return (scaled * 2).round() / 2;
    }

    return ChallengeRound(
      number: base.number,
      targetTrainingMinutes: scaleMinutes(base.targetTrainingMinutes),
      targetJumpRopeMinutes: scaleMinutes(base.targetJumpRopeMinutes),
      targetLiftingMinutes: scaleMinutes(base.targetLiftingMinutes),
      targetRiceBowls: scaleBowls(base.targetRiceBowls),
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
  final double targetMultiplier;
  final double mealMultiplier;
  final int rewardXpPerRound;
  final int completionBonusXpPerDay;

  const ChallengeTrainingLevelConfig({
    required this.level,
    required this.targetMultiplier,
    required this.mealMultiplier,
    required this.rewardXpPerRound,
    required this.completionBonusXpPerDay,
  });
}

const List<ChallengeTrainingLevelConfig> challengeTrainingLevelConfigs =
    <ChallengeTrainingLevelConfig>[
  ChallengeTrainingLevelConfig(
    level: ChallengeTrainingLevel.rookie,
    targetMultiplier: 1,
    mealMultiplier: 1,
    rewardXpPerRound: 10,
    completionBonusXpPerDay: 40,
  ),
  ChallengeTrainingLevelConfig(
    level: ChallengeTrainingLevel.growth,
    targetMultiplier: 1.25,
    mealMultiplier: 1.1,
    rewardXpPerRound: 16,
    completionBonusXpPerDay: 70,
  ),
  ChallengeTrainingLevelConfig(
    level: ChallengeTrainingLevel.ace,
    targetMultiplier: 1.5,
    mealMultiplier: 1.2,
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

const List<ChallengeTemplate> defaultChallengeTemplates = <ChallengeTemplate>[
  ChallengeTemplate(
    id: 'starter_3',
    dayCount: 3,
    rewardXpPerRound: 10,
    rounds: <ChallengeRound>[
      ChallengeRound(
        number: 1,
        targetTrainingMinutes: 20,
        targetJumpRopeMinutes: 5,
        targetLiftingMinutes: 5,
        targetRiceBowls: 2,
        rewardXp: 10,
      ),
      ChallengeRound(
        number: 2,
        targetTrainingMinutes: 25,
        targetJumpRopeMinutes: 6,
        targetLiftingMinutes: 6,
        targetRiceBowls: 2.5,
        rewardXp: 10,
      ),
      ChallengeRound(
        number: 3,
        targetTrainingMinutes: 30,
        targetJumpRopeMinutes: 8,
        targetLiftingMinutes: 8,
        targetRiceBowls: 3,
        rewardXp: 10,
      ),
    ],
  ),
  ChallengeTemplate(
    id: 'weekly_7',
    dayCount: 7,
    rewardXpPerRound: 10,
    rounds: <ChallengeRound>[
      ChallengeRound(
        number: 1,
        targetTrainingMinutes: 20,
        targetJumpRopeMinutes: 5,
        targetLiftingMinutes: 5,
        targetRiceBowls: 2,
        rewardXp: 10,
      ),
      ChallengeRound(
        number: 2,
        targetTrainingMinutes: 20,
        targetJumpRopeMinutes: 5,
        targetLiftingMinutes: 5,
        targetRiceBowls: 2,
        rewardXp: 10,
      ),
      ChallengeRound(
        number: 3,
        targetTrainingMinutes: 25,
        targetJumpRopeMinutes: 6,
        targetLiftingMinutes: 6,
        targetRiceBowls: 2.5,
        rewardXp: 10,
      ),
      ChallengeRound(
        number: 4,
        targetTrainingMinutes: 25,
        targetJumpRopeMinutes: 6,
        targetLiftingMinutes: 6,
        targetRiceBowls: 2.5,
        rewardXp: 10,
      ),
      ChallengeRound(
        number: 5,
        targetTrainingMinutes: 30,
        targetJumpRopeMinutes: 8,
        targetLiftingMinutes: 8,
        targetRiceBowls: 3,
        rewardXp: 10,
      ),
      ChallengeRound(
        number: 6,
        targetTrainingMinutes: 30,
        targetJumpRopeMinutes: 8,
        targetLiftingMinutes: 8,
        targetRiceBowls: 3,
        rewardXp: 10,
      ),
      ChallengeRound(
        number: 7,
        targetTrainingMinutes: 35,
        targetJumpRopeMinutes: 10,
        targetLiftingMinutes: 10,
        targetRiceBowls: 3,
        rewardXp: 10,
      ),
    ],
  ),
  ChallengeTemplate(
    id: 'focus_14',
    dayCount: 14,
    rewardXpPerRound: 10,
    rounds: <ChallengeRound>[
      ChallengeRound(
        number: 1,
        targetTrainingMinutes: 15,
        targetJumpRopeMinutes: 4,
        targetLiftingMinutes: 4,
        targetRiceBowls: 2,
        rewardXp: 10,
      ),
      ChallengeRound(
        number: 2,
        targetTrainingMinutes: 20,
        targetJumpRopeMinutes: 5,
        targetLiftingMinutes: 5,
        targetRiceBowls: 2,
        rewardXp: 10,
      ),
      ChallengeRound(
        number: 3,
        targetTrainingMinutes: 20,
        targetJumpRopeMinutes: 5,
        targetLiftingMinutes: 5,
        targetRiceBowls: 2,
        rewardXp: 10,
      ),
      ChallengeRound(
        number: 4,
        targetTrainingMinutes: 20,
        targetJumpRopeMinutes: 5,
        targetLiftingMinutes: 5,
        targetRiceBowls: 2.5,
        rewardXp: 10,
      ),
      ChallengeRound(
        number: 5,
        targetTrainingMinutes: 25,
        targetJumpRopeMinutes: 6,
        targetLiftingMinutes: 6,
        targetRiceBowls: 2.5,
        rewardXp: 10,
      ),
      ChallengeRound(
        number: 6,
        targetTrainingMinutes: 25,
        targetJumpRopeMinutes: 6,
        targetLiftingMinutes: 6,
        targetRiceBowls: 2.5,
        rewardXp: 10,
      ),
      ChallengeRound(
        number: 7,
        targetTrainingMinutes: 25,
        targetJumpRopeMinutes: 6,
        targetLiftingMinutes: 6,
        targetRiceBowls: 3,
        rewardXp: 10,
      ),
      ChallengeRound(
        number: 8,
        targetTrainingMinutes: 30,
        targetJumpRopeMinutes: 8,
        targetLiftingMinutes: 8,
        targetRiceBowls: 3,
        rewardXp: 10,
      ),
      ChallengeRound(
        number: 9,
        targetTrainingMinutes: 30,
        targetJumpRopeMinutes: 8,
        targetLiftingMinutes: 8,
        targetRiceBowls: 3,
        rewardXp: 10,
      ),
      ChallengeRound(
        number: 10,
        targetTrainingMinutes: 30,
        targetJumpRopeMinutes: 8,
        targetLiftingMinutes: 8,
        targetRiceBowls: 3,
        rewardXp: 10,
      ),
      ChallengeRound(
        number: 11,
        targetTrainingMinutes: 35,
        targetJumpRopeMinutes: 10,
        targetLiftingMinutes: 10,
        targetRiceBowls: 3.5,
        rewardXp: 10,
      ),
      ChallengeRound(
        number: 12,
        targetTrainingMinutes: 35,
        targetJumpRopeMinutes: 10,
        targetLiftingMinutes: 10,
        targetRiceBowls: 3.5,
        rewardXp: 10,
      ),
      ChallengeRound(
        number: 13,
        targetTrainingMinutes: 35,
        targetJumpRopeMinutes: 10,
        targetLiftingMinutes: 10,
        targetRiceBowls: 3.5,
        rewardXp: 10,
      ),
      ChallengeRound(
        number: 14,
        targetTrainingMinutes: 40,
        targetJumpRopeMinutes: 12,
        targetLiftingMinutes: 12,
        targetRiceBowls: 3.5,
        rewardXp: 10,
      ),
    ],
  ),
];
