import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/local_fortune_service.dart';
import 'package:football_note/application/myeongli_database.dart';
import 'package:football_note/domain/entities/player_profile.dart';
import 'package:football_note/domain/entities/training_entry.dart';
import 'package:football_note/gen/app_localizations_ko.dart';

void main() {
  test('generateResult returns one clear fortune section', () {
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
    expect(result.fortuneText, isNot(contains('생일 코드')));
    expect(result.fortuneText, isNot(contains('[재미 포인트]')));
    expect(result.fortuneText, isNot(contains('재미 포인트')));
    final lines = result.fortuneText.split('\n');
    expect(lines, hasLength(2));
    expect(lines.first, contains('민준님'));
    expect(lines.first, isNot(contains('그래서')));
    expect(lines.first, isNot(contains('분위기예요')));
    expect(lines.first, isNot(contains('쪽으로 흐름이 잡혀요')));
    expect(lines.first, matches(RegExp(r'(흐름이라|날이라) .+요\.$')));
    final myeongliDailyLines = <String>{
      ...l10n.fortuneMyeongliTenGodDailyLines.split('|'),
      ...l10n.fortuneMyeongliTwelveStageDailyLines.split('|'),
      ...l10n.fortuneMyeongliBranchRelationDailyLines.split('|'),
    };
    expect(myeongliDailyLines.any(lines.first.contains), isTrue);
    expect(lines.first, isNot(contains('훈련')));
    expect(lines.first, isNot(contains('패스')));
    expect(lines.last, contains('오늘의 컬러는 '));
    expect(lines.last, contains('숫자는 '));
    expect(lines.last, isNot(contains('시간대 ')));
  });

  test('korean day flow copy reads as linked natural snippets', () {
    final l10n = AppLocalizationsKo();
    final flows = '${l10n.fortuneSajuElementFlows}|'
            '${l10n.fortuneSajuElementFlowExtras}'
        .split('|');

    expect(flows, hasLength(60));
    expect(flows, contains('빠른 눈치가 필요한 흐름이라'));
    for (final flow in flows) {
      final line = l10n.fortuneGeneratedLinkedDailyLine(
        '민준',
        flow,
        '작은 일이 자연스럽게 풀릴 수 있어요.',
      );
      expect(line, startsWith('민준님, '));
      expect(line, isNot(contains('빠른 눈치 분위기')));
      expect(line, isNot(contains('분위기예요')));
      expect(line, isNot(contains('쪽으로 흐름이 잡혀요')));
      expect(line, isNot(contains('그래서')));
      expect(line, matches(RegExp(r'(흐름이라|날이라) .+요\.$')));
      expect(line, endsWith('.'));
    }
  });

  test('databaseSections exposes expanded fortune database', () {
    final sections = LocalFortuneService.databaseSections(AppLocalizationsKo());

    expect(
      sections.map((section) => section.values.length),
      <int>[
        22,
        12,
        10,
        12,
        35,
        12,
        5,
        60,
        96,
        72,
        60,
        96,
        40,
        48,
        32,
        48,
        40,
        48,
        40,
        64,
      ],
    );
    expect(sections[1].title, '지장간');
    expect(sections[2].values, contains(startsWith('비견:')));
    expect(sections[3].values, contains(startsWith('장생:')));
    expect(sections[4].values, contains(startsWith('자오충:')));
    expect(sections[5].values, contains(startsWith('천을귀인:')));
    expect(sections[6].values, contains(startsWith('목:')));
    expect(sections[7].title, '오늘 흐름의 이유');
    expect(sections[8].title, '이어질 수 있는 일');
  });

  test('myeongli database exposes practitioner-style reference rules', () {
    const database = MyeongliDatabase.instance;

    expect(database.branchRelations, hasLength(35));
    expect(
      database.tenGodFor(
        dayStem: database.stemAt(0),
        targetStem: database.stemAt(2),
      ),
      MyeongliTenGod.eatingGod,
    );
    expect(
      database.twelveStageFor(
        dayStem: database.stemAt(0),
        targetBranch: database.branchAt(11),
      ),
      MyeongliTwelveStage.longevity,
    );

    final clash = database.branchRelationsFor(
      sourceBranches: <MyeongliBranch>[database.branchAt(0)],
      targetBranch: database.branchAt(6),
    );
    expect(clash.first.type, MyeongliBranchRelationType.clash);

    final chart = database.chartForBirth(DateTime(2012, 3, 10, 7, 30));
    final signature = database.dailySignature(
      birthChart: chart,
      date: DateTime(2026, 3, 15, 18),
    );
    expect(signature.tenGod, isA<MyeongliTenGod>());
    expect(signature.twelveStage, isA<MyeongliTwelveStage>());
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
    expect(first.fortuneText, contains('민준님'));
    expect(second.fortuneText, contains('서윤님'));
  });

  test('same-day records use record timing for different fortunes', () {
    final service = LocalFortuneService();
    final l10n = AppLocalizationsKo();
    final profile = PlayerProfile(
      name: '민준',
      birthDate: DateTime(2012, 3, 10, 7, 30),
    );
    final firstEntry = TrainingEntry(
      date: DateTime(2026, 4, 2, 18),
      createdAt: DateTime(2026, 4, 2, 18),
      durationMinutes: 60,
      intensity: 3,
      type: '일상 기록',
      mood: 3,
      injury: false,
      notes: '첫 번째 기록',
      location: '집',
      program: '기록',
    );
    final secondEntry = TrainingEntry(
      date: DateTime(2026, 4, 2, 18),
      createdAt: DateTime(2026, 4, 2, 18, 5),
      durationMinutes: 60,
      intensity: 3,
      type: '일상 기록',
      mood: 3,
      injury: false,
      notes: '두 번째 기록',
      location: '집',
      program: '기록',
    );

    final first = service.generateResult(
      entry: firstEntry,
      profile: profile,
      history: const <TrainingEntry>[],
      l10n: l10n,
    );
    final second = service.generateResult(
      entry: secondEntry,
      profile: profile,
      history: const <TrainingEntry>[],
      l10n: l10n,
    );

    expect(first.fortuneText, isNot(second.fortuneText));
    expect(
      first.fortuneText.split('\n').first,
      isNot(second.fortuneText.split('\n').first),
    );
  });
}
