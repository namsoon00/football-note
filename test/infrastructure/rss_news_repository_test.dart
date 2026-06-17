import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/entities/news_article.dart';
import 'package:football_note/domain/entities/sport_definition.dart';
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

  test('defaults to football news channels only', () {
    final channels = RssNewsRepository().channels();

    expect(channels, isNotEmpty);
    expect(
      channels.every((channel) => channel.sportId == SportCatalog.footballId),
      isTrue,
    );
  });

  test('provides baseball, basketball, and tennis news channels by sport', () {
    final repository = RssNewsRepository();
    final baseball = repository.channels(sportId: SportCatalog.baseballId);
    final basketball = repository.channels(sportId: SportCatalog.basketballId);
    final tennis = repository.channels(sportId: SportCatalog.tennisId);

    expect(baseball.map((channel) => channel.id), contains('espn_mlb_en'));
    expect(basketball.map((channel) => channel.id), contains('espn_nba_en'));
    expect(tennis.map((channel) => channel.id), contains('espn_tennis_en'));
    expect(
      baseball.every((channel) => channel.sportId == SportCatalog.baseballId),
      isTrue,
    );
    expect(
      basketball.every(
        (channel) => channel.sportId == SportCatalog.basketballId,
      ),
      isTrue,
    );
    expect(
      tennis.every((channel) => channel.sportId == SportCatalog.tennisId),
      isTrue,
    );
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

  test(
    'Newsis football filter uses article content instead of feed source',
    () {
      const nonFootballArticle = NewsArticle(
        title: '남자탁구 세계선수권 8강 마감',
        link: 'https://www.newsis.com/view/NISX20260509_0003622582',
        source: '뉴시스 · 국내축구',
        summary: '한국 남자 탁구 대표팀이 중국과 맞붙었다.',
        channelId: 'newsis_sports_domestic_soccer_ko',
      );
      const footballArticle = NewsArticle(
        title: '전북, K리그 3연승 도전',
        link: 'https://www.newsis.com/view/NISX20260509_0003999999',
        source: '뉴시스 · 국내축구',
        summary: 'K리그와 대표팀 이슈를 다룬 축구 기사다.',
        channelId: 'newsis_sports_domestic_soccer_ko',
      );

      expect(
        RssNewsRepository.matchesDomesticFootballKeywords(nonFootballArticle),
        isFalse,
      );
      expect(
        RssNewsRepository.matchesDomesticFootballKeywords(footballArticle),
        isTrue,
      );
    },
  );
}
