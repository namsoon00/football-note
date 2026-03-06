import 'package:hive/hive.dart';

@HiveType(typeId: 1)
class TrainingEntry extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final int durationMinutes;

  @HiveField(2)
  final int intensity;

  @HiveField(3)
  final String type;

  @HiveField(4)
  final int mood;

  @HiveField(5)
  final bool injury;

  @HiveField(6)
  final String notes;

  @HiveField(7)
  final String location;

  @HiveField(8)
  final String program;

  @HiveField(9)
  final String drills;

  @HiveField(12)
  final String club;

  @HiveField(17)
  final String injuryPart;

  @HiveField(18)
  final int? painLevel;

  @HiveField(19)
  final bool rehab;

  @HiveField(20)
  final String goal;

  @HiveField(21)
  final String feedback;

  @HiveField(22)
  final double? heightCm;

  @HiveField(23)
  final double? weightKg;

  @HiveField(24)
  final String imagePath;

  @HiveField(25)
  final List<String> imagePaths;

  @HiveField(26)
  final String status;

  @HiveField(27)
  final Map<String, int> liftingByPart;

  @HiveField(28)
  final String coachComment;

  @HiveField(29)
  final String fortuneComment;

  @HiveField(30)
  final String fortuneRecommendation;

  @HiveField(31)
  final String fortuneRecommendedProgram;

  @HiveField(32)
  final List<String> goalFocuses;

  @HiveField(33)
  final String goodPoints;

  @HiveField(34)
  final String improvements;

  @HiveField(35)
  final String nextGoal;

  @HiveField(36)
  final DateTime createdAt;

  @HiveField(37)
  final int jumpRopeCount;

  @HiveField(38)
  final int jumpRopeMinutes;

  TrainingEntry({
    required this.date,
    required this.durationMinutes,
    required this.intensity,
    required this.type,
    required this.mood,
    required this.injury,
    required this.notes,
    required this.location,
    this.program = '',
    this.drills = '',
    this.club = '',
    this.injuryPart = '',
    this.painLevel,
    this.rehab = false,
    this.goal = '',
    this.feedback = '',
    this.heightCm,
    this.weightKg,
    this.imagePath = '',
    this.imagePaths = const [],
    this.status = 'normal',
    this.liftingByPart = const {},
    this.coachComment = '',
    this.fortuneComment = '',
    this.fortuneRecommendation = '',
    this.fortuneRecommendedProgram = '',
    this.goalFocuses = const [],
    this.goodPoints = '',
    this.improvements = '',
    this.nextGoal = '',
    DateTime? createdAt,
    this.jumpRopeCount = 0,
    this.jumpRopeMinutes = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  static int compareByRecentCreated(TrainingEntry a, TrainingEntry b) {
    final createdCompare = b.createdAt.compareTo(a.createdAt);
    if (createdCompare != 0) return createdCompare;
    return b.date.compareTo(a.date);
  }
}

class TrainingEntryAdapter extends TypeAdapter<TrainingEntry> {
  @override
  final int typeId = 1;

  @override
  TrainingEntry read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    final legacyNotes = (fields[6] as String?) ?? '';
    final legacyGoal = (fields[20] as String?) ?? '';
    final legacyFeedback = (fields[21] as String?) ?? '';
    final goodPoints = (fields[33] as String?) ?? legacyFeedback;
    final improvements = (fields[34] as String?) ?? legacyNotes;
    final nextGoal = (fields[35] as String?) ?? legacyGoal;
    return TrainingEntry(
      date: fields[0] as DateTime,
      durationMinutes: fields[1] as int,
      intensity: fields[2] as int,
      type: fields[3] as String,
      mood: fields[4] as int,
      injury: fields[5] as bool,
      notes: legacyNotes.isNotEmpty ? legacyNotes : improvements,
      location: fields[7] as String,
      program: (fields[8] as String?) ?? '',
      drills: (fields[9] as String?) ?? '',
      club: (fields[12] as String?) ?? '',
      injuryPart: (fields[17] as String?) ?? '',
      painLevel: fields[18] as int?,
      rehab: (fields[19] as bool?) ?? false,
      goal: legacyGoal.isNotEmpty ? legacyGoal : nextGoal,
      feedback: legacyFeedback.isNotEmpty ? legacyFeedback : goodPoints,
      heightCm: fields[22] as double?,
      weightKg: fields[23] as double?,
      imagePath: (fields[24] as String?) ?? '',
      imagePaths:
          (fields[25] as List?)?.cast<String>() ??
          ((fields[24] as String?)?.isNotEmpty ?? false
              ? [fields[24] as String]
              : []),
      status: (fields[26] as String?) ?? 'normal',
      liftingByPart:
          (fields[27] as Map?)?.map(
            (key, value) =>
                MapEntry(key.toString(), (value is num) ? value.toInt() : 0),
          ) ??
          const {},
      coachComment: (fields[28] as String?) ?? '',
      fortuneComment: (fields[29] as String?) ?? '',
      fortuneRecommendation: (fields[30] as String?) ?? '',
      fortuneRecommendedProgram: (fields[31] as String?) ?? '',
      goalFocuses:
          (fields[32] as List?)?.map((e) => e.toString()).toList() ??
          const <String>[],
      goodPoints: goodPoints,
      improvements: improvements,
      nextGoal: nextGoal,
      createdAt: (fields[36] as DateTime?) ?? (fields[0] as DateTime),
      jumpRopeCount: (fields[37] as num?)?.toInt() ?? 0,
      jumpRopeMinutes: (fields[38] as num?)?.toInt() ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, TrainingEntry obj) {
    writer
      ..writeByte(33)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.durationMinutes)
      ..writeByte(2)
      ..write(obj.intensity)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.mood)
      ..writeByte(5)
      ..write(obj.injury)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.location)
      ..writeByte(8)
      ..write(obj.program)
      ..writeByte(9)
      ..write(obj.drills)
      ..writeByte(12)
      ..write(obj.club)
      ..writeByte(17)
      ..write(obj.injuryPart)
      ..writeByte(18)
      ..write(obj.painLevel)
      ..writeByte(19)
      ..write(obj.rehab)
      ..writeByte(20)
      ..write(obj.goal)
      ..writeByte(21)
      ..write(obj.feedback)
      ..writeByte(22)
      ..write(obj.heightCm)
      ..writeByte(23)
      ..write(obj.weightKg)
      ..writeByte(24)
      ..write(obj.imagePath)
      ..writeByte(25)
      ..write(obj.imagePaths)
      ..writeByte(26)
      ..write(obj.status)
      ..writeByte(27)
      ..write(obj.liftingByPart)
      ..writeByte(28)
      ..write(obj.coachComment)
      ..writeByte(29)
      ..write(obj.fortuneComment)
      ..writeByte(30)
      ..write(obj.fortuneRecommendation)
      ..writeByte(31)
      ..write(obj.fortuneRecommendedProgram)
      ..writeByte(32)
      ..write(obj.goalFocuses)
      ..writeByte(33)
      ..write(obj.goodPoints)
      ..writeByte(34)
      ..write(obj.improvements)
      ..writeByte(35)
      ..write(obj.nextGoal)
      ..writeByte(36)
      ..write(obj.createdAt)
      ..writeByte(37)
      ..write(obj.jumpRopeCount)
      ..writeByte(38)
      ..write(obj.jumpRopeMinutes);
  }
}
