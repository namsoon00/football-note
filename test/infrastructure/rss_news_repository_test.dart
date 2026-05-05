import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/infrastructure/rss_news_repository.dart';

void main() {
  test('keeps supported Korean domestic football news channels', () {
    final channels = RssNewsRepository().channels();
    final ids = channels.map((channel) => channel.id).toSet();

    expect(
      ids,
      containsAll(<String>{
        'sports_khan_domestic_soccer_ko',
        'sports_khan_soccer_ko',
        'sportschosun_soccer_ko',
        'newsis_sports_domestic_soccer_ko',
      }),
    );
  });

  test('removes Kyunghyang domestic football news channel', () {
    final channels = RssNewsRepository().channels();
    final ids = channels.map((channel) => channel.id).toSet();

    expect(ids, isNot(contains('khan_sports_domestic_soccer_ko')));
  });

  test('removes Google domestic football news channels', () {
    final channels = RssNewsRepository().channels();
    final ids = channels.map((channel) => channel.id).toSet();

    for (final id in <String>{
      'google_news_domestic_soccer_ko',
      'google_news_kleague_ko',
      'google_news_kleague1_ko',
      'google_news_kleague2_ko',
      'google_news_korea_national_team_ko',
      'google_news_kfa_ko',
      'google_news_korea_cup_ko',
      'google_news_wkleague_ko',
      'google_news_k3_k4_ko',
    }) {
      expect(ids, isNot(contains(id)));
    }
  });

  test('removes Sports Donga football news channel', () {
    final channels = RssNewsRepository().channels();
    final ids = channels.map((channel) => channel.id).toSet();

    expect(ids, isNot(contains('sportsdonga_soccer_ko')));
  });

  test('uses unique news channel ids', () {
    final channels = RssNewsRepository().channels();
    final ids = channels.map((channel) => channel.id).toList();

    expect(ids.toSet(), hasLength(ids.length));
  });

  test('domestic football channels use Korean suffix for picker grouping', () {
    final channels = RssNewsRepository().channels();
    final domesticChannels = channels.where(
      (channel) => channel.name.contains('국내축구') || channel.name.contains('축구'),
    );

    expect(domesticChannels, isNotEmpty);
    expect(
      domesticChannels.every((channel) => channel.id.endsWith('_ko')),
      isTrue,
    );
  });

  test('marks domestic and international channel groups for news filters', () {
    final channels = RssNewsRepository().channels();
    final domesticChannels = channels.where((channel) => channel.isDomestic);
    final internationalChannels = channels.where(
      (channel) => !channel.isDomestic,
    );

    expect(domesticChannels, isNotEmpty);
    expect(internationalChannels, isNotEmpty);
    expect(
      domesticChannels.every((channel) => channel.id.endsWith('_ko')),
      isTrue,
    );
    expect(
      internationalChannels.every((channel) => channel.id.endsWith('_en')),
      isTrue,
    );
  });
}
