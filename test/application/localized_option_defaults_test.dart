import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/localized_option_defaults.dart';

void main() {
  test('program defaults append newly introduced training items', () {
    final normalized = LocalizedOptionDefaults.normalizeOptions(
      key: 'programs',
      stored: const ['기본기', '피지컬', '전술', '회복', '개인 훈련'],
      localizedDefaults: const ['기본기', '피지컬', '전술', '회복', '리프팅', '줄넘기'],
    );

    expect(normalized, const [
      '기본기',
      '피지컬',
      '전술',
      '회복',
      '개인 훈련',
      '리프팅',
      '줄넘기',
    ]);
  });

  test('non-program defaults keep the stored list unchanged', () {
    final normalized = LocalizedOptionDefaults.normalizeOptions(
      key: 'locations',
      stored: const ['학교 운동장'],
      localizedDefaults: const ['학교 운동장', '동네 운동장', '실내 체육관'],
    );

    expect(normalized, const ['학교 운동장']);
  });
}
