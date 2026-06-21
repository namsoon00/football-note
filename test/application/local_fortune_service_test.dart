import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/local_fortune_service.dart';
import 'package:football_note/domain/entities/player_profile.dart';
import 'package:football_note/domain/entities/training_entry.dart';
import 'package:football_note/gen/app_localizations_ko.dart';

void main() {
  test('generateResult adds saju-style daily reading before lucky info', () {
    final service = LocalFortuneService();
    final l10n = AppLocalizationsKo();
    final result = service.generateResult(
      entry: TrainingEntry(
        date: DateTime(2026, 3, 15, 18),
        createdAt: DateTime(2026, 3, 15, 18),
        durationMinutes: 70,
        intensity: 4,
        type: '드리블',
        mood: 4,
        injury: false,
        notes: '테스트 메모',
        location: '학교 운동장',
        program: '볼터치',
      ),
      profile: PlayerProfile(
        name: '민준',
        birthDate: DateTime(2012, 3, 10, 7, 30),
      ),
      history: const <TrainingEntry>[],
      l10n: l10n,
    );

    expect(result.fortuneText, isNot(contains('행운 흐름:')));
    expect(result.fortuneText, isNot(contains('행운 컨디션')));
    expect(result.fortuneText, isNot(contains('행운 준비도:')));
    expect(result.fortuneText, isNot(contains('행운 최근 흐름:')));
    final lines = result.fortuneText.split('\n');
    expect(lines, hasLength(5));
    expect(lines.first, contains('민준'));
    expect(lines.first, contains('생일 코드'));
    expect(lines.first, contains('임진/'));
    expect(lines[3], '[재미 포인트]');
    expect(lines.last, contains('오늘 숫자 '));
    expect(lines.last, contains('색상 '));
    expect(lines.last, contains('시간대 '));
    expect(lines.last, contains('떠올려 보세요.'));
  });

  test('birth date and name change the generated fortune', () {
    final service = LocalFortuneService();
    final l10n = AppLocalizationsKo();
    final entry = TrainingEntry(
      date: DateTime(2026, 4, 2, 18),
      createdAt: DateTime(2026, 4, 2, 18),
      durationMinutes: 60,
      intensity: 3,
      type: '패스',
      mood: 3,
      injury: false,
      notes: '',
      location: '',
      program: '패스',
    );

    final first = service.generateResult(
      entry: entry,
      profile: PlayerProfile(
        name: '민준',
        birthDate: DateTime(2012, 3, 10, 7, 30),
      ),
      history: const <TrainingEntry>[],
      l10n: l10n,
    );
    final second = service.generateResult(
      entry: entry,
      profile: PlayerProfile(
        name: '서윤',
        birthDate: DateTime(2014, 9, 20, 15, 10),
      ),
      history: const <TrainingEntry>[],
      l10n: l10n,
    );

    expect(first.fortuneText, isNot(second.fortuneText));
    expect(first.fortuneText, contains('민준'));
    expect(second.fortuneText, contains('서윤'));
  });
}
