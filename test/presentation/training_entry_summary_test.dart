import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/entities/sport_definition.dart';
import 'package:football_note/domain/entities/training_entry.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/utils/training_entry_summary.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'training entry summary avoids duplicated program and adds conditioning',
    () async {
      final l10n = await AppLocalizations.delegate.load(
        const Locale('ko', 'KR'),
      );
      final entry = TrainingEntry(
        date: DateTime(2024, 1, 3),
        durationMinutes: 50,
        intensity: 3,
        type: '볼터치',
        mood: 3,
        injury: false,
        notes: '',
        location: '학교 운동장',
        program: '볼터치',
        trainingProgramMinutes: const {'볼터치': 50},
        liftingByPart: const {'inside': 40},
        jumpRopeCount: 120,
        jumpRopeEnabled: true,
      );

      expect(trainingEntryPrimaryLabel(entry, l10n), '볼터치');
      expect(trainingEntryDurationLabel(entry, l10n), '50분');
      expect(trainingEntryConditioningParts(entry, l10n), const [
        '리프팅 40회',
        '줄넘기 120회',
      ]);
    },
  );

  test('training entry summary localizes conditioning by sport', () async {
    final l10n = await AppLocalizations.delegate.load(
      const Locale('ko', 'KR'),
    );
    final entry = TrainingEntry(
      date: DateTime(2024, 1, 5),
      durationMinutes: 40,
      intensity: 3,
      type: '수비',
      mood: 3,
      injury: false,
      notes: '',
      location: '야구장',
      liftingByPart: const {'shortThrow': 40},
      jumpRopeCount: 120,
      jumpRopeEnabled: true,
      sportId: SportCatalog.baseballId,
    );

    expect(trainingEntryConditioningParts(entry, l10n), const [
      '캐치볼 40회',
      '스프린트 120회',
    ]);
  });

  test(
    'training entry summary can show empty conditioning and injury',
    () async {
      final l10n = await AppLocalizations.delegate.load(
        const Locale('ko', 'KR'),
      );
      final entry = TrainingEntry(
        date: DateTime(2024, 1, 4),
        durationMinutes: 30,
        intensity: 2,
        type: '회복',
        mood: 3,
        injury: true,
        notes: '',
        location: '학교 운동장',
        injuryPart: '발목',
        painLevel: 3,
      );

      expect(
        trainingEntryConditioningParts(entry, l10n, includeEmptyMessage: true),
        const ['줄넘기/리프팅 기록 없음'],
      );
      expect(trainingEntryInjuryLabel(entry, l10n), '부상: 발목 · 통증 3/10');
      expect(trainingEntryLocationWeatherLabel(entry), isEmpty);
    },
  );

  test('training entry summary includes lesson detail', () async {
    final l10n = await AppLocalizations.delegate.load(
      const Locale('ko', 'KR'),
    );
    final entry = TrainingEntry(
      date: DateTime(2024, 1, 6),
      durationMinutes: 60,
      intensity: 3,
      type: '슈팅',
      mood: 3,
      injury: false,
      notes: '',
      location: '학교 운동장',
      isLesson: true,
      lessonDetail: '슈팅 그룹레슨',
    );

    expect(trainingEntryLessonLabel(entry, l10n), '레슨: 슈팅 그룹레슨');
  });
}
