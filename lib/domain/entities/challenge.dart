import 'meal_entry.dart';
import 'training_entry.dart';

enum ChallengeTrainingLevel { rookie, growth, ace }

enum ChallengeRunResult { completed, failed, abandoned }

const List<String> defaultChallengeSkillIds = <String>[
  'dribble',
  'speedRun',
  'jumpRope',
  'lifting',
];

const Set<String> legacyChallengeSkillIds = <String>{
  'dribble',
  'speedRun',
  'jumpRope',
  'lifting',
  'passing',
  'shooting',
  'firstTouch',
  'defense',
};

List<String> normalizeChallengeSkillIds(
  Iterable<String> rawIds, {
  bool allowEmpty = false,
}) {
  final seen = <String>{};
  final normalized = <String>[];
  for (final id in rawIds) {
    final trimmed = id.trim();
    if (trimmed.isEmpty || seen.contains(trimmed)) continue;
    seen.add(trimmed);
    normalized.add(trimmed);
  }
  if (normalized.isNotEmpty) return normalized;
  return allowEmpty ? <String>[] : List<String>.from(defaultChallengeSkillIds);
}

class ChallengeMissionTargets {
  final int trainingMinutes;
  final Map<String, int> trainingProgramMinutes;
  final int jumpRopeMinutes;
  final int liftingMinutes;
  final double riceBowls;

  const ChallengeMissionTargets({
    required this.trainingMinutes,
    this.trainingProgramMinutes = const <String, int>{},
    required this.jumpRopeMinutes,
    required this.liftingMinutes,
    required this.riceBowls,
  });

  bool get hasTrainingMission =>
      trainingMinutes > 0 ||
      trainingProgramMinutes.values.any((minutes) => minutes > 0);

  bool get hasJumpRopeMission => jumpRopeMinutes > 0;

  bool get hasLiftingMission => liftingMinutes > 0;

  bool get hasMealMission => riceBowls > 0;

  bool get hasAnyMission =>
      hasTrainingMission ||
      hasJumpRopeMission ||
      hasLiftingMission ||
      hasMealMission;

  ChallengeMissionTargets copyWith({
    int? trainingMinutes,
    Map<String, int>? trainingProgramMinutes,
    int? jumpRopeMinutes,
    int? liftingMinutes,
    double? riceBowls,
  }) {
    return ChallengeMissionTargets(
      trainingMinutes: trainingMinutes ?? this.trainingMinutes,
      trainingProgramMinutes:
          trainingProgramMinutes ?? this.trainingProgramMinutes,
      jumpRopeMinutes: jumpRopeMinutes ?? this.jumpRopeMinutes,
      liftingMinutes: liftingMinutes ?? this.liftingMinutes,
      riceBowls: riceBowls ?? this.riceBowls,
    );
  }

  int trainingMinutesForPrograms(Iterable<String> selectedSkillIds) {
    final programs = _challengeTrainingProgramIds(selectedSkillIds);
    if (programs.isEmpty) {
      return _trainingProgramMinutesTotal(trainingProgramMinutes) > 0
          ? _trainingProgramMinutesTotal(trainingProgramMinutes)
          : trainingMinutes;
    }
    final targets = trainingProgramTargetsFor(programs);
    if (targets.isEmpty) return trainingMinutes;
    return _trainingProgramMinutesTotal(targets);
  }

  Map<String, int> trainingProgramTargetsFor(
    Iterable<String> selectedSkillIds,
  ) {
    final programs = _challengeTrainingProgramIds(selectedSkillIds);
    if (programs.isEmpty) return const <String, int>{};
    final targets = <String, int>{};
    for (final program in programs) {
      final target = trainingProgramMinutes[program];
      if (target != null && target > 0) {
        targets[program] = target;
      }
    }
    return targets;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'trainingMinutes': trainingMinutes,
      'trainingProgramMinutes': trainingProgramMinutes,
      'jumpRopeMinutes': jumpRopeMinutes,
      'liftingMinutes': liftingMinutes,
      'riceBowls': riceBowls,
    };
  }

  factory ChallengeMissionTargets.fromMap(Map<String, dynamic> map) {
    return ChallengeMissionTargets(
      trainingMinutes: _nonNegativeInt(map['trainingMinutes']),
      trainingProgramMinutes: _nonNegativeIntMap(map['trainingProgramMinutes']),
      jumpRopeMinutes: _nonNegativeInt(map['jumpRopeMinutes']),
      liftingMinutes: _nonNegativeInt(map['liftingMinutes']),
      riceBowls: _nonNegativeDouble(map['riceBowls']),
    );
  }
}

class ChallengeTemplate {
  final String id;
  final int dayCount;
  final int rewardXpPerRound;
  final List<ChallengeRound> rounds;

  const ChallengeTemplate({
    required this.id,
    required this.dayCount,
    required this.rewardXpPerRound,
    required this.rounds,
  });
}

class ChallengeRound {
  final int number;
  final int targetTrainingMinutes;
  final int targetJumpRopeMinutes;
  final int targetLiftingMinutes;
  final double targetRiceBowls;
  final int rewardXp;

  const ChallengeRound({
    required this.number,
    required this.targetTrainingMinutes,
    required this.targetJumpRopeMinutes,
    required this.targetLiftingMinutes,
    required this.targetRiceBowls,
    required this.rewardXp,
  });
}

class ChallengeRun {
  final String id;
  final String templateId;
  final ChallengeTrainingLevel trainingLevel;
  final DateTime startedAt;
  final bool started;
  final DateTime? completedAt;
  final bool abandoned;
  final ChallengeRunResult? result;
  final int? failedRoundNumber;
  final List<int> completedRoundNumbers;
  final List<String> selectedSkillIds;
  final ChallengeMissionTargets? missionTargets;
  final int cadenceDays;
  final String rewardGift;

  const ChallengeRun({
    required this.id,
    required this.templateId,
    this.trainingLevel = ChallengeTrainingLevel.rookie,
    required this.startedAt,
    this.started = true,
    this.completedAt,
    this.abandoned = false,
    this.result,
    this.failedRoundNumber,
    this.completedRoundNumbers = const <int>[],
    this.selectedSkillIds = defaultChallengeSkillIds,
    this.missionTargets,
    this.cadenceDays = 1,
    this.rewardGift = '',
  });

  bool get isStarted => started;

  bool get isEnded => completedAt != null || result != null;

  bool get isCompleted =>
      result == ChallengeRunResult.completed ||
      (result == null && completedAt != null && !abandoned);

  bool get isFailed => result == ChallengeRunResult.failed;

  bool get isAbandoned =>
      result == ChallengeRunResult.abandoned ||
      (result == null && completedAt != null && abandoned);

  DateTime get startDay => normalizeDay(startedAt);

  int get normalizedCadenceDays => cadenceDays < 1 ? 1 : cadenceDays;

  bool get hasRewardGift => rewardGift.trim().isNotEmpty;

  DateTime dayForRound(int roundNumber) {
    return startDay.add(
      Duration(days: (roundNumber - 1) * normalizedCadenceDays),
    );
  }

  ChallengeRun copyWith({
    String? id,
    String? templateId,
    ChallengeTrainingLevel? trainingLevel,
    DateTime? startedAt,
    bool? started,
    DateTime? completedAt,
    bool? abandoned,
    ChallengeRunResult? result,
    int? failedRoundNumber,
    List<int>? completedRoundNumbers,
    List<String>? selectedSkillIds,
    ChallengeMissionTargets? missionTargets,
    int? cadenceDays,
    String? rewardGift,
  }) {
    return ChallengeRun(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      trainingLevel: trainingLevel ?? this.trainingLevel,
      startedAt: startedAt ?? this.startedAt,
      started: started ?? this.started,
      completedAt: completedAt ?? this.completedAt,
      abandoned: abandoned ?? this.abandoned,
      result: result ?? this.result,
      failedRoundNumber: failedRoundNumber ?? this.failedRoundNumber,
      completedRoundNumbers:
          completedRoundNumbers ?? this.completedRoundNumbers,
      selectedSkillIds: selectedSkillIds ?? this.selectedSkillIds,
      missionTargets: missionTargets ?? this.missionTargets,
      cadenceDays: cadenceDays ?? this.cadenceDays,
      rewardGift: rewardGift ?? this.rewardGift,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'templateId': templateId,
      'trainingLevel': trainingLevel.name,
      'startedAt': startedAt.toIso8601String(),
      'started': started,
      'completedAt': completedAt?.toIso8601String(),
      'abandoned': abandoned,
      'result': result?.name,
      'failedRoundNumber': failedRoundNumber,
      'completedRoundNumbers': completedRoundNumbers,
      'selectedSkillIds': selectedSkillIds,
      'missionTargets': missionTargets?.toMap(),
      'cadenceDays': normalizedCadenceDays,
      'rewardGift': rewardGift.trim(),
    };
  }

  factory ChallengeRun.fromMap(Map<String, dynamic> map) {
    final completedAt = DateTime.tryParse(map['completedAt']?.toString() ?? '');
    final abandoned = map['abandoned'] == true;
    final parsedResult = _challengeRunResultFromName(map['result']?.toString());
    final parsedStarted =
        map.containsKey('started') ? map['started'] == true : true;
    final rawCompletedRoundNumbers = map['completedRoundNumbers'];
    final rawSelectedSkillIds = map['selectedSkillIds'];
    final rawMissionTargets = map['missionTargets'];
    return ChallengeRun(
      id: map['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      templateId: map['templateId']?.toString() ?? '',
      trainingLevel: _challengeTrainingLevelFromName(
        map['trainingLevel']?.toString(),
        templateId: map['templateId']?.toString() ?? '',
      ),
      startedAt: DateTime.tryParse(map['startedAt']?.toString() ?? '') ??
          DateTime.now(),
      started:
          completedAt != null || parsedResult != null ? true : parsedStarted,
      completedAt: completedAt,
      abandoned: abandoned,
      result: parsedResult ??
          (completedAt == null
              ? null
              : abandoned
                  ? ChallengeRunResult.abandoned
                  : ChallengeRunResult.completed),
      failedRoundNumber: (map['failedRoundNumber'] as num?)?.toInt(),
      completedRoundNumbers: _positiveUniqueIntList(rawCompletedRoundNumbers),
      selectedSkillIds: normalizeChallengeSkillIds(
        (rawSelectedSkillIds as List?)?.map((item) => item.toString()) ??
            defaultChallengeSkillIds,
        allowEmpty: rawSelectedSkillIds is List,
      ),
      missionTargets: rawMissionTargets is Map
          ? ChallengeMissionTargets.fromMap(
              rawMissionTargets.cast<String, dynamic>(),
            )
          : null,
      cadenceDays: _positiveIntOrDefault(map['cadenceDays'], 1),
      rewardGift: _trimmedString(map['rewardGift']),
    );
  }
}

class ChallengeProgress {
  final ChallengeRun run;
  final ChallengeTemplate template;
  final List<ChallengeRoundProgress> rounds;

  const ChallengeProgress({
    required this.run,
    required this.template,
    required this.rounds,
  });

  int get completedRoundCount =>
      rounds.where((round) => round.completed).length;

  int get totalRoundCount => rounds.length;

  bool get allRoundsCompleted =>
      rounds.isNotEmpty && completedRoundCount >= rounds.length;

  ChallengeRoundProgress? get firstIncompleteRound {
    for (final round in rounds) {
      if (!round.completed) return round;
    }
    return null;
  }

  DateTime? get finalRoundDate => rounds.isEmpty ? null : rounds.last.date;

  double get completionRate {
    if (!run.isStarted) return 0;
    if (rounds.isEmpty) return 0;
    return completedRoundCount / rounds.length;
  }

  bool hasEndedByDate({DateTime? now}) {
    if (!run.isStarted) return false;
    final finalDate = finalRoundDate;
    if (finalDate == null) return false;
    final today = normalizeDay(now ?? DateTime.now());
    return finalDate.isBefore(today);
  }

  bool readyToFinalize({DateTime? now}) {
    if (!run.isStarted) return false;
    return allRoundsCompleted || hasEndedByDate(now: now);
  }

  ChallengeRoundProgress? get todayRound {
    if (!run.isStarted) return null;
    final today = normalizeDay(DateTime.now());
    for (final round in rounds) {
      if (round.date == today) return round;
    }
    return null;
  }

  ChallengeRoundProgress? get activeRound {
    if (!run.isStarted) return null;
    final today = normalizeDay(DateTime.now());
    final todayMatch = todayRound;
    if (todayMatch != null) return todayMatch;
    for (final round in rounds) {
      if (!round.completed && !round.date.isBefore(today)) return round;
    }
    for (final round in rounds) {
      if (!round.completed) return round;
    }
    return rounds.isEmpty ? null : rounds.last;
  }

  ChallengeRoundProgress? missedExpiredRound({DateTime? now}) {
    if (!run.isStarted) return null;
    final today = normalizeDay(now ?? DateTime.now());
    for (final round in rounds) {
      if (round.date.isBefore(today) && !round.completed) return round;
    }
    return null;
  }
}

class ChallengeRoundProgress {
  final ChallengeRound round;
  final DateTime date;
  final int trainingMinutes;
  final int jumpRopeMinutes;
  final int liftingMinutes;
  final double riceBowls;
  final List<ChallengeTrainingProgramProgress> trainingPrograms;

  const ChallengeRoundProgress({
    required this.round,
    required this.date,
    required this.trainingMinutes,
    required this.jumpRopeMinutes,
    required this.liftingMinutes,
    required this.riceBowls,
    this.trainingPrograms = const <ChallengeTrainingProgramProgress>[],
  });

  bool get trainingCompleted => trainingPrograms.isEmpty
      ? trainingMinutes >= round.targetTrainingMinutes
      : trainingPrograms.every((mission) => mission.completed);

  bool get jumpRopeCompleted => jumpRopeMinutes >= round.targetJumpRopeMinutes;

  bool get liftingCompleted => liftingMinutes >= round.targetLiftingMinutes;

  bool get mealCompleted => riceBowls >= round.targetRiceBowls;

  bool get completed =>
      trainingCompleted &&
      jumpRopeCompleted &&
      liftingCompleted &&
      mealCompleted;

  int get missionCount {
    final trainingCount = round.targetTrainingMinutes > 0
        ? (trainingPrograms.isEmpty ? 1 : trainingPrograms.length)
        : 0;
    return trainingCount +
        (round.targetJumpRopeMinutes > 0 ? 1 : 0) +
        (round.targetLiftingMinutes > 0 ? 1 : 0) +
        (round.targetRiceBowls > 0 ? 1 : 0);
  }

  int get completedMissionCount {
    final trainingCount = round.targetTrainingMinutes <= 0
        ? 0
        : trainingPrograms.isEmpty
            ? (trainingCompleted ? 1 : 0)
            : trainingPrograms.where((mission) => mission.completed).length;
    return trainingCount +
        (round.targetJumpRopeMinutes > 0 && jumpRopeCompleted ? 1 : 0) +
        (round.targetLiftingMinutes > 0 && liftingCompleted ? 1 : 0) +
        (round.targetRiceBowls > 0 && mealCompleted ? 1 : 0);
  }

  double get missionCompletionRate {
    if (missionCount <= 0) return 0;
    return completedMissionCount / missionCount;
  }

  bool get isToday => date == normalizeDay(DateTime.now());

  bool get isMissed =>
      !completed && date.isBefore(normalizeDay(DateTime.now()));
}

class ChallengeTrainingProgramProgress {
  final String programId;
  final String label;
  final int currentMinutes;
  final int targetMinutes;

  const ChallengeTrainingProgramProgress({
    required this.programId,
    required this.label,
    required this.currentMinutes,
    required this.targetMinutes,
  });

  bool get completed => currentMinutes >= targetMinutes;

  double get progressRate {
    if (targetMinutes <= 0) return 1;
    return (currentMinutes / targetMinutes).clamp(0, 1).toDouble();
  }
}

DateTime normalizeDay(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

int trainingMinutesForDay(
  Iterable<TrainingEntry> entries,
  DateTime day, {
  Iterable<String> selectedSkillIds = const <String>[],
}) {
  final normalizedDay = normalizeDay(day);
  final skillIds = normalizeChallengeSkillIds(selectedSkillIds);
  final usesTrainingPrograms = skillIds.any(
    (id) => !legacyChallengeSkillIds.contains(id),
  );
  return entries
      .where(
        (entry) => !entry.isMatch && normalizeDay(entry.date) == normalizedDay,
      )
      .where(
        (entry) =>
            !usesTrainingPrograms ||
            trainingEntryMatchesChallengeSkill(entry, skillIds),
      )
      .fold<int>(
        0,
        (sum, entry) =>
            sum +
            (usesTrainingPrograms
                ? trainingProgramMinutesForEntry(entry, skillIds)
                : entry.durationMinutes +
                    entry.jumpRopeMinutes +
                    entry.liftingMinutes),
      );
}

bool trainingEntryMatchesChallengeSkill(
  TrainingEntry entry,
  Iterable<String> selectedSkillIds,
) {
  final normalizedTargets = selectedSkillIds
      .where((id) => !legacyChallengeSkillIds.contains(id))
      .map(_normalizeChallengeSkillText)
      .where((id) => id.isNotEmpty)
      .toSet();
  if (normalizedTargets.isEmpty) return true;
  final entryValues = <String>{
    _normalizeChallengeSkillText(entry.program),
    _normalizeChallengeSkillText(entry.type),
    ...entry.effectiveTrainingProgramMinutes.keys.map(
      _normalizeChallengeSkillText,
    ),
  }..removeWhere((value) => value.isEmpty);
  return entryValues.any(normalizedTargets.contains);
}

List<ChallengeTrainingProgramProgress> trainingProgramProgressForDay(
  Iterable<TrainingEntry> entries,
  DateTime day, {
  required Iterable<String> selectedSkillIds,
  required int targetTrainingMinutes,
  Map<String, int> targetMinutesByProgram = const <String, int>{},
}) {
  if (targetTrainingMinutes <= 0) {
    return const <ChallengeTrainingProgramProgress>[];
  }
  final programs = normalizeChallengeSkillIds(selectedSkillIds)
      .where((id) => !legacyChallengeSkillIds.contains(id))
      .toList(growable: false);
  if (programs.isEmpty) return const <ChallengeTrainingProgramProgress>[];

  final normalizedDay = normalizeDay(day);
  final hasProgramTargets = targetMinutesByProgram.values.any(
    (minutes) => minutes > 0,
  );
  final splitTargets = hasProgramTargets
      ? const <int>[]
      : _splitTargetMinutes(targetTrainingMinutes, programs.length);
  return <ChallengeTrainingProgramProgress>[
    for (var index = 0; index < programs.length; index++)
      ChallengeTrainingProgramProgress(
        programId: programs[index],
        label: programs[index],
        currentMinutes: entries
            .where(
              (entry) =>
                  !entry.isMatch &&
                  normalizeDay(entry.date) == normalizedDay &&
                  trainingEntryMatchesChallengeSkill(entry, <String>[
                    programs[index],
                  ]),
            )
            .fold<int>(
              0,
              (sum, entry) =>
                  sum +
                  trainingProgramMinutesForEntry(entry, <String>[
                    programs[index],
                  ]),
            ),
        targetMinutes: hasProgramTargets
            ? targetMinutesByProgram[programs[index]] ?? targetTrainingMinutes
            : splitTargets[index],
      ),
  ];
}

int trainingProgramMinutesForEntry(
  TrainingEntry entry,
  Iterable<String> selectedSkillIds,
) {
  final normalizedTargets = selectedSkillIds
      .where((id) => !legacyChallengeSkillIds.contains(id))
      .map(_normalizeChallengeSkillText)
      .where((id) => id.isNotEmpty)
      .toSet();
  if (normalizedTargets.isEmpty) return entry.durationMinutes;

  final explicitProgramMinutes = _nonNegativeIntMap(
    entry.trainingProgramMinutes,
  );
  if (explicitProgramMinutes.isNotEmpty) {
    return _selectedTrainingProgramMinutes(
      explicitProgramMinutes,
      normalizedTargets,
    );
  }

  if (entry.effectiveTrainingProgramMinutes.isEmpty) {
    return trainingEntryMatchesChallengeSkill(entry, selectedSkillIds)
        ? entry.durationMinutes
        : 0;
  }

  return _selectedTrainingProgramMinutes(
    entry.effectiveTrainingProgramMinutes,
    normalizedTargets,
  );
}

int _selectedTrainingProgramMinutes(
  Map<String, int> programMinutes,
  Set<String> normalizedTargets,
) {
  var minutes = 0;
  for (final item in programMinutes.entries) {
    final normalizedProgram = _normalizeChallengeSkillText(item.key);
    if (normalizedTargets.contains(normalizedProgram)) {
      minutes += item.value;
    }
  }
  return minutes;
}

List<int> _splitTargetMinutes(int total, int count) {
  if (count <= 0) return const <int>[];
  final base = total ~/ count;
  final remainder = total % count;
  return List<int>.generate(
    count,
    (index) => base + (index < remainder ? 1 : 0),
    growable: false,
  );
}

int jumpRopeMinutesForDay(Iterable<TrainingEntry> entries, DateTime day) {
  final normalizedDay = normalizeDay(day);
  return entries
      .where(
        (entry) => !entry.isMatch && normalizeDay(entry.date) == normalizedDay,
      )
      .fold<int>(0, (sum, entry) => sum + entry.jumpRopeMinutes);
}

int liftingMinutesForDay(Iterable<TrainingEntry> entries, DateTime day) {
  final normalizedDay = normalizeDay(day);
  return entries
      .where(
        (entry) => !entry.isMatch && normalizeDay(entry.date) == normalizedDay,
      )
      .fold<int>(0, (sum, entry) => sum + entry.liftingMinutes);
}

double riceBowlsForDay(Iterable<MealEntry> entries, DateTime day) {
  final normalizedDay = normalizeDay(day);
  MealEntry? latest;
  for (final entry in entries) {
    if (normalizeDay(entry.date) != normalizedDay) continue;
    if (latest == null || entry.createdAt.isAfter(latest.createdAt)) {
      latest = entry;
    }
  }
  return latest?.totalRiceBowls ?? 0;
}

ChallengeTrainingLevel _challengeTrainingLevelFromName(
  String? raw, {
  required String templateId,
}) {
  for (final level in ChallengeTrainingLevel.values) {
    if (level.name == raw) return level;
  }
  return switch (templateId) {
    'weekly_7' => ChallengeTrainingLevel.growth,
    'focus_14' => ChallengeTrainingLevel.ace,
    _ => ChallengeTrainingLevel.rookie,
  };
}

ChallengeRunResult? _challengeRunResultFromName(String? raw) {
  for (final result in ChallengeRunResult.values) {
    if (result.name == raw) return result;
  }
  return null;
}

List<int> _positiveUniqueIntList(Object? raw) {
  if (raw is! List) return const <int>[];
  final seen = <int>{};
  final result = <int>[];
  for (final item in raw) {
    final value =
        item is num ? item.toInt() : int.tryParse(item?.toString() ?? '');
    if (value == null || value <= 0 || seen.contains(value)) continue;
    seen.add(value);
    result.add(value);
  }
  result.sort();
  return List<int>.unmodifiable(result);
}

int _positiveIntOrDefault(Object? raw, int fallback) {
  final value = raw is num ? raw.toInt() : int.tryParse(raw?.toString() ?? '');
  if (value == null || value <= 0) return fallback;
  return value;
}

String _normalizeChallengeSkillText(String value) {
  return value.trim().toLowerCase();
}

List<String> _challengeTrainingProgramIds(Iterable<String> selectedSkillIds) {
  return normalizeChallengeSkillIds(selectedSkillIds, allowEmpty: true)
      .where((id) => !legacyChallengeSkillIds.contains(id))
      .toList(growable: false);
}

int _trainingProgramMinutesTotal(Map<String, int> targets) {
  return targets.values
      .where((minutes) => minutes > 0)
      .fold<int>(0, (sum, minutes) => sum + minutes);
}

int _nonNegativeInt(Object? raw) {
  final value = raw is num ? raw.toInt() : int.tryParse(raw?.toString() ?? '');
  if (value == null || value < 0) return 0;
  return value;
}

Map<String, int> _nonNegativeIntMap(Object? raw) {
  if (raw is! Map) return const <String, int>{};
  final result = <String, int>{};
  raw.forEach((key, value) {
    final normalizedKey = key.toString().trim();
    final normalizedValue = _nonNegativeInt(value);
    if (normalizedKey.isNotEmpty && normalizedValue > 0) {
      result[normalizedKey] = normalizedValue;
    }
  });
  return Map<String, int>.unmodifiable(result);
}

double _nonNegativeDouble(Object? raw) {
  final value =
      raw is num ? raw.toDouble() : double.tryParse(raw?.toString() ?? '');
  if (value == null || value < 0) return 0;
  return value;
}

String _trimmedString(Object? raw) {
  return raw?.toString().trim() ?? '';
}
