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
    DateTime? startedAt,
  }) async {
    final start = startedAt ?? DateTime.now();
    final run = ChallengeRun(
      id: '${template.id}-${start.toUtc().microsecondsSinceEpoch}',
      templateId: template.id,
      startedAt: start,
    );
    final runs = loadRuns()
        .map(
          (item) => item.isEnded
              ? item
              : item.copyWith(completedAt: start, abandoned: true),
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
              ? run.copyWith(completedAt: completed, abandoned: false)
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
              ? run.copyWith(completedAt: endedAt, abandoned: true)
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
        final date = run.dayForRound(round.number);
        return ChallengeRoundProgress(
          round: round,
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
      await completeRun(progress.run.id,
          completedAt: awardedAt ?? DateTime.now());
    }
    return awards;
  }

  Future<void> _saveRuns(List<ChallengeRun> runs) async {
    final capped = runs.take(20).toList(growable: false);
    await _options.setValue(
      storageKey,
      jsonEncode(capped.map((run) => run.toMap()).toList(growable: false)),
    );
  }
}

const List<ChallengeTemplate> defaultChallengeTemplates = <ChallengeTemplate>[
  ChallengeTemplate(
    id: 'starter_3',
    difficulty: ChallengeDifficulty.sprout,
    dayCount: 3,
    rewardXpPerRound: 8,
    rounds: <ChallengeRound>[
      ChallengeRound(
        number: 1,
        targetTrainingMinutes: 20,
        targetJumpRopeMinutes: 5,
        targetLiftingMinutes: 5,
        targetRiceBowls: 2,
        rewardXp: 8,
      ),
      ChallengeRound(
        number: 2,
        targetTrainingMinutes: 25,
        targetJumpRopeMinutes: 6,
        targetLiftingMinutes: 6,
        targetRiceBowls: 2.5,
        rewardXp: 8,
      ),
      ChallengeRound(
        number: 3,
        targetTrainingMinutes: 30,
        targetJumpRopeMinutes: 8,
        targetLiftingMinutes: 8,
        targetRiceBowls: 3,
        rewardXp: 8,
      ),
    ],
  ),
  ChallengeTemplate(
    id: 'weekly_7',
    difficulty: ChallengeDifficulty.boost,
    dayCount: 7,
    rewardXpPerRound: 12,
    rounds: <ChallengeRound>[
      ChallengeRound(
        number: 1,
        targetTrainingMinutes: 30,
        targetJumpRopeMinutes: 8,
        targetLiftingMinutes: 8,
        targetRiceBowls: 3,
        rewardXp: 12,
      ),
      ChallengeRound(
        number: 2,
        targetTrainingMinutes: 30,
        targetJumpRopeMinutes: 8,
        targetLiftingMinutes: 8,
        targetRiceBowls: 3,
        rewardXp: 12,
      ),
      ChallengeRound(
        number: 3,
        targetTrainingMinutes: 35,
        targetJumpRopeMinutes: 10,
        targetLiftingMinutes: 10,
        targetRiceBowls: 3,
        rewardXp: 12,
      ),
      ChallengeRound(
        number: 4,
        targetTrainingMinutes: 35,
        targetJumpRopeMinutes: 10,
        targetLiftingMinutes: 10,
        targetRiceBowls: 3.5,
        rewardXp: 12,
      ),
      ChallengeRound(
        number: 5,
        targetTrainingMinutes: 40,
        targetJumpRopeMinutes: 12,
        targetLiftingMinutes: 12,
        targetRiceBowls: 3.5,
        rewardXp: 12,
      ),
      ChallengeRound(
        number: 6,
        targetTrainingMinutes: 40,
        targetJumpRopeMinutes: 12,
        targetLiftingMinutes: 12,
        targetRiceBowls: 4,
        rewardXp: 12,
      ),
      ChallengeRound(
        number: 7,
        targetTrainingMinutes: 45,
        targetJumpRopeMinutes: 15,
        targetLiftingMinutes: 15,
        targetRiceBowls: 4,
        rewardXp: 12,
      ),
    ],
  ),
  ChallengeTemplate(
    id: 'focus_14',
    difficulty: ChallengeDifficulty.star,
    dayCount: 14,
    rewardXpPerRound: 18,
    rounds: <ChallengeRound>[
      ChallengeRound(
        number: 1,
        targetTrainingMinutes: 35,
        targetJumpRopeMinutes: 10,
        targetLiftingMinutes: 10,
        targetRiceBowls: 3,
        rewardXp: 18,
      ),
      ChallengeRound(
        number: 2,
        targetTrainingMinutes: 35,
        targetJumpRopeMinutes: 10,
        targetLiftingMinutes: 10,
        targetRiceBowls: 3,
        rewardXp: 18,
      ),
      ChallengeRound(
        number: 3,
        targetTrainingMinutes: 40,
        targetJumpRopeMinutes: 12,
        targetLiftingMinutes: 12,
        targetRiceBowls: 3.5,
        rewardXp: 18,
      ),
      ChallengeRound(
        number: 4,
        targetTrainingMinutes: 40,
        targetJumpRopeMinutes: 12,
        targetLiftingMinutes: 12,
        targetRiceBowls: 3.5,
        rewardXp: 18,
      ),
      ChallengeRound(
        number: 5,
        targetTrainingMinutes: 45,
        targetJumpRopeMinutes: 14,
        targetLiftingMinutes: 14,
        targetRiceBowls: 3.5,
        rewardXp: 18,
      ),
      ChallengeRound(
        number: 6,
        targetTrainingMinutes: 45,
        targetJumpRopeMinutes: 14,
        targetLiftingMinutes: 14,
        targetRiceBowls: 4,
        rewardXp: 18,
      ),
      ChallengeRound(
        number: 7,
        targetTrainingMinutes: 50,
        targetJumpRopeMinutes: 16,
        targetLiftingMinutes: 16,
        targetRiceBowls: 4,
        rewardXp: 18,
      ),
      ChallengeRound(
        number: 8,
        targetTrainingMinutes: 50,
        targetJumpRopeMinutes: 16,
        targetLiftingMinutes: 16,
        targetRiceBowls: 4,
        rewardXp: 18,
      ),
      ChallengeRound(
        number: 9,
        targetTrainingMinutes: 55,
        targetJumpRopeMinutes: 18,
        targetLiftingMinutes: 18,
        targetRiceBowls: 4.5,
        rewardXp: 18,
      ),
      ChallengeRound(
        number: 10,
        targetTrainingMinutes: 55,
        targetJumpRopeMinutes: 18,
        targetLiftingMinutes: 18,
        targetRiceBowls: 4.5,
        rewardXp: 18,
      ),
      ChallengeRound(
        number: 11,
        targetTrainingMinutes: 60,
        targetJumpRopeMinutes: 20,
        targetLiftingMinutes: 20,
        targetRiceBowls: 4.5,
        rewardXp: 18,
      ),
      ChallengeRound(
        number: 12,
        targetTrainingMinutes: 60,
        targetJumpRopeMinutes: 20,
        targetLiftingMinutes: 20,
        targetRiceBowls: 5,
        rewardXp: 18,
      ),
      ChallengeRound(
        number: 13,
        targetTrainingMinutes: 65,
        targetJumpRopeMinutes: 22,
        targetLiftingMinutes: 22,
        targetRiceBowls: 5,
        rewardXp: 18,
      ),
      ChallengeRound(
        number: 14,
        targetTrainingMinutes: 70,
        targetJumpRopeMinutes: 24,
        targetLiftingMinutes: 24,
        targetRiceBowls: 5,
        rewardXp: 18,
      ),
    ],
  ),
];
