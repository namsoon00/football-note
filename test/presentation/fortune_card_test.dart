import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/presentation/widgets/fortune_card.dart';

void main() {
  test('fromComment folds legacy lucky info into one section', () {
    final sections = FortuneSections.fromComment(
      '[행운 정보]\n'
      '행운 색상: 에메랄드\n'
      '행운 시간대: 오전 후반 08:10~08:50',
    );

    expect(sections.luckyInfoLines, isEmpty);
    expect(sections.bodyLines, hasLength(1));
    expect(
      sections.bodyLines.single,
      '재미 포인트: 색상 에메랄드.',
    );
  });
}
