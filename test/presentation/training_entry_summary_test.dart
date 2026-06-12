import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/entities/training_entry.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/utils/training_entry_summary.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('training entry summary avoids duplicated program and adds conditioning',
      () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ko', 'KR'));
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
    expect(
      trainingEntryConditioningParts(entry, l10n),
      const ['리프팅 40회', '줄넘기 120회'],
    );
  });
}
