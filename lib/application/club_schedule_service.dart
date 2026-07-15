import 'dart:convert';

import '../domain/repositories/option_repository.dart';
import 'sport_scoped_storage.dart';

class ClubTrainingSchedule {
  static const int defaultStartMinutes = 18 * 60;
  static const int defaultEndMinutes = 20 * 60;
  static const int defaultUniformColorValue = 0xFF2563EB;
  static const int defaultSockColorValue = 0xFFFFFFFF;

  final int weekday;
  final bool enabled;
  final int startMinutes;
  final int endMinutes;
  final int uniformColorValue;
  final int sockColorValue;

  const ClubTrainingSchedule({
    required this.weekday,
    this.enabled = false,
    this.startMinutes = defaultStartMinutes,
    this.endMinutes = defaultEndMinutes,
    this.uniformColorValue = defaultUniformColorValue,
    this.sockColorValue = defaultSockColorValue,
  });

  factory ClubTrainingSchedule.disabled(int weekday) {
    return ClubTrainingSchedule(
      weekday: ClubScheduleService.normalizeWeekday(weekday),
    );
  }

  factory ClubTrainingSchedule.fromMap(
    Map<String, dynamic> map, {
    int fallbackUniformColorValue = defaultUniformColorValue,
    int? fallbackSockColorValue,
  }) {
    final start = ClubScheduleService.normalizeMinutes(
      map['startMinutes'],
      fallback: defaultStartMinutes,
    );
    final uniformColorValue = ClubScheduleService.normalizeColorValue(
      map['uniformColorValue'],
      fallback: fallbackUniformColorValue,
    );
    return ClubTrainingSchedule(
      weekday: ClubScheduleService.normalizeWeekday(map['weekday']),
      enabled: map['enabled'] == true,
      startMinutes: start,
      endMinutes: ClubScheduleService.normalizeEndMinutes(
        map['endMinutes'],
        startMinutes: start,
      ),
      uniformColorValue: uniformColorValue,
      sockColorValue: ClubScheduleService.normalizeColorValue(
        map['sockColorValue'],
        fallback: fallbackSockColorValue ?? uniformColorValue,
      ),
    );
  }

  ClubTrainingSchedule copyWith({
    int? weekday,
    bool? enabled,
    int? startMinutes,
    int? endMinutes,
    int? uniformColorValue,
    int? sockColorValue,
  }) {
    final nextStart = ClubScheduleService.normalizeMinutes(
      startMinutes ?? this.startMinutes,
      fallback: defaultStartMinutes,
    );
    return ClubTrainingSchedule(
      weekday: ClubScheduleService.normalizeWeekday(weekday ?? this.weekday),
      enabled: enabled ?? this.enabled,
      startMinutes: nextStart,
      endMinutes: ClubScheduleService.normalizeEndMinutes(
        endMinutes ?? this.endMinutes,
        startMinutes: nextStart,
      ),
      uniformColorValue: ClubScheduleService.normalizeColorValue(
        uniformColorValue ?? this.uniformColorValue,
        fallback: defaultUniformColorValue,
      ),
      sockColorValue: ClubScheduleService.normalizeColorValue(
        sockColorValue ?? this.sockColorValue,
        fallback: defaultSockColorValue,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'weekday': weekday,
      'enabled': enabled,
      'startMinutes': startMinutes,
      'endMinutes': endMinutes,
      'uniformColorValue': uniformColorValue,
      'sockColorValue': sockColorValue,
    };
  }
}

class ClubTrainingOccurrence {
  final DateTime date;
  final ClubTrainingSchedule schedule;

  const ClubTrainingOccurrence({
    required this.date,
    required this.schedule,
  });
}

class ClubScheduleProfile {
  static const int defaultHomeUniformColorValue = 0xFF2563EB;
  static const int defaultAwayUniformColorValue = 0xFFFFFFFF;
  static const int defaultKeeperUniformColorValue = 0xFFF59E0B;

  final String clubName;
  final List<ClubTrainingSchedule> weekdaySchedules;
  final int homeUniformColorValue;
  final int awayUniformColorValue;
  final int keeperUniformColorValue;
  final DateTime updatedAt;

  const ClubScheduleProfile({
    this.clubName = '',
    this.weekdaySchedules = const <ClubTrainingSchedule>[],
    this.homeUniformColorValue = defaultHomeUniformColorValue,
    this.awayUniformColorValue = defaultAwayUniformColorValue,
    this.keeperUniformColorValue = defaultKeeperUniformColorValue,
    required this.updatedAt,
  });

  factory ClubScheduleProfile.empty({DateTime? now}) {
    return ClubScheduleProfile(
      weekdaySchedules: ClubScheduleService.normalizeSchedules(
        const <ClubTrainingSchedule>[],
      ),
      updatedAt: now ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory ClubScheduleProfile.fromMap(Map<String, dynamic> map) {
    final updatedAt = DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final homeUniformColorValue = ClubScheduleService.normalizeColorValue(
      map['homeUniformColorValue'],
      fallback: defaultHomeUniformColorValue,
    );
    final schedules = map['weekdaySchedules'] is List
        ? (map['weekdaySchedules'] as List)
            .whereType<Map>()
            .map((item) => ClubTrainingSchedule.fromMap(
                  item.cast<String, dynamic>(),
                  fallbackUniformColorValue: homeUniformColorValue,
                ))
        : const Iterable<ClubTrainingSchedule>.empty();

    return ClubScheduleProfile(
      clubName: map['clubName']?.toString().trim() ?? '',
      weekdaySchedules: ClubScheduleService.normalizeSchedules(schedules),
      homeUniformColorValue: homeUniformColorValue,
      awayUniformColorValue: ClubScheduleService.normalizeColorValue(
        map['awayUniformColorValue'],
        fallback: defaultAwayUniformColorValue,
      ),
      keeperUniformColorValue: ClubScheduleService.normalizeColorValue(
        map['keeperUniformColorValue'],
        fallback: defaultKeeperUniformColorValue,
      ),
      updatedAt: updatedAt,
    );
  }

  bool get hasAnyTraining =>
      weekdaySchedules.any((schedule) => schedule.enabled);

  ClubTrainingSchedule? scheduleForDate(DateTime date) {
    for (final schedule in weekdaySchedules) {
      if (schedule.weekday == date.weekday) return schedule;
    }
    return null;
  }

  ClubTrainingOccurrence? nextTraining(DateTime from) {
    final today = DateTime(from.year, from.month, from.day);
    for (var dayOffset = 0; dayOffset < 14; dayOffset += 1) {
      final date = today.add(Duration(days: dayOffset));
      final schedule = scheduleForDate(date);
      if (schedule == null || !schedule.enabled) continue;
      return ClubTrainingOccurrence(date: date, schedule: schedule);
    }
    return null;
  }

  ClubTrainingOccurrence? upcomingTraining(DateTime from) {
    final today = DateTime(from.year, from.month, from.day);
    final currentMinutes = from.hour * 60 + from.minute;
    for (var dayOffset = 0; dayOffset < 14; dayOffset += 1) {
      final date = today.add(Duration(days: dayOffset));
      final schedule = scheduleForDate(date);
      if (schedule == null || !schedule.enabled) continue;
      if (dayOffset == 0 && currentMinutes >= schedule.endMinutes) {
        continue;
      }
      return ClubTrainingOccurrence(date: date, schedule: schedule);
    }
    return null;
  }

  ClubScheduleProfile copyWith({
    String? clubName,
    List<ClubTrainingSchedule>? weekdaySchedules,
    int? homeUniformColorValue,
    int? awayUniformColorValue,
    int? keeperUniformColorValue,
    DateTime? updatedAt,
  }) {
    return ClubScheduleProfile(
      clubName: clubName ?? this.clubName,
      weekdaySchedules: ClubScheduleService.normalizeSchedules(
        weekdaySchedules ?? this.weekdaySchedules,
      ),
      homeUniformColorValue: ClubScheduleService.normalizeColorValue(
        homeUniformColorValue ?? this.homeUniformColorValue,
        fallback: defaultHomeUniformColorValue,
      ),
      awayUniformColorValue: ClubScheduleService.normalizeColorValue(
        awayUniformColorValue ?? this.awayUniformColorValue,
        fallback: defaultAwayUniformColorValue,
      ),
      keeperUniformColorValue: ClubScheduleService.normalizeColorValue(
        keeperUniformColorValue ?? this.keeperUniformColorValue,
        fallback: defaultKeeperUniformColorValue,
      ),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'clubName': clubName.trim(),
      'weekdaySchedules': weekdaySchedules
          .map((schedule) => schedule.toMap())
          .toList(growable: false),
      'homeUniformColorValue': homeUniformColorValue,
      'awayUniformColorValue': awayUniformColorValue,
      'keeperUniformColorValue': keeperUniformColorValue,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class ClubScheduleService {
  static const String storageKey = 'club_training_schedule_v1';
  static const List<int> weekdays = <int>[
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
    DateTime.sunday,
  ];

  final OptionRepository _optionRepository;
  final String? _sportId;

  const ClubScheduleService(this._optionRepository, {String? sportId})
      : _sportId = sportId;

  String get _storageKey => sportScopedOptionKey(
        _optionRepository,
        storageKey,
        sportId: _sportId,
      );

  ClubScheduleProfile loadProfile() {
    final raw = _optionRepository.getValue<String>(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return ClubScheduleProfile.empty();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return ClubScheduleProfile.empty();
      return ClubScheduleProfile.fromMap(decoded.cast<String, dynamic>());
    } catch (_) {
      return ClubScheduleProfile.empty();
    }
  }

  Future<void> saveProfile(ClubScheduleProfile profile) {
    final normalized = profile.copyWith(
      clubName: profile.clubName.trim(),
      updatedAt: DateTime.now(),
    );
    return _optionRepository.setValue(
      _storageKey,
      jsonEncode(normalized.toMap()),
    );
  }

  static List<ClubTrainingSchedule> normalizeSchedules(
    Iterable<ClubTrainingSchedule> schedules,
  ) {
    final byWeekday = <int, ClubTrainingSchedule>{};
    for (final schedule in schedules) {
      final weekday = normalizeWeekday(schedule.weekday);
      byWeekday[weekday] = schedule.copyWith(weekday: weekday);
    }
    return <ClubTrainingSchedule>[
      for (final weekday in weekdays)
        byWeekday[weekday] ?? ClubTrainingSchedule.disabled(weekday),
    ];
  }

  static int normalizeWeekday(Object? value) {
    final weekday = switch (value) {
      int() => value,
      num() => value.toInt(),
      String() => int.tryParse(value) ?? DateTime.monday,
      _ => DateTime.monday,
    };
    if (weekday < DateTime.monday || weekday > DateTime.sunday) {
      return DateTime.monday;
    }
    return weekday;
  }

  static int normalizeMinutes(Object? value, {required int fallback}) {
    final minutes = switch (value) {
      int() => value,
      num() => value.toInt(),
      String() => int.tryParse(value) ?? fallback,
      _ => fallback,
    };
    return minutes.clamp(0, 23 * 60 + 59).toInt();
  }

  static int normalizeEndMinutes(Object? value, {required int startMinutes}) {
    final end = normalizeMinutes(
      value,
      fallback: ClubTrainingSchedule.defaultEndMinutes,
    );
    if (end > startMinutes) return end;
    if (startMinutes >= 23 * 60 + 59) return 23 * 60 + 59;
    return (startMinutes + 120).clamp(startMinutes + 1, 23 * 60 + 59).toInt();
  }

  static int normalizeColorValue(Object? value, {required int fallback}) {
    final parsed = switch (value) {
      int() => value,
      num() => value.toInt(),
      String() => int.tryParse(value) ?? fallback,
      _ => fallback,
    };
    final hasAlpha = (parsed & 0xFF000000) != 0;
    return hasAlpha ? parsed : (0xFF000000 | (parsed & 0x00FFFFFF));
  }
}
