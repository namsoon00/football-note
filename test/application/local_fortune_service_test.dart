import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/local_fortune_service.dart';
import 'package:football_note/domain/entities/player_profile.dart';
import 'package:football_note/domain/entities/training_entry.dart';

void main() {
  test('generateResult omits removed lucky info lines', () {
    final service = LocalFortuneService();
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
      profile: const PlayerProfile(name: 'Tester'),
      history: const <TrainingEntry>[],
      isKo: true,
    );

    expect(result.fortuneText, isNot(contains('행운 흐름:')));
    expect(result.fortuneText, isNot(contains('행운 컨디션')));
    expect(result.fortuneText, isNot(contains('행운 준비도:')));
    expect(result.fortuneText, isNot(contains('행운 최근 흐름:')));
    expect(result.fortuneText, contains('행운 숫자:'));
    expect(result.fortuneText, contains('행운 색상:'));
  });
}
