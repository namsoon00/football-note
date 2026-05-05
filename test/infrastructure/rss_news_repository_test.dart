import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/infrastructure/rss_news_repository.dart';

void main() {
  test('includes Korean domestic football news channels', () {
    final channels = RssNewsRepository().channels();
    final ids = channels.map((channel) => channel.id).toSet();

    expect(
      ids,
      containsAll(<String>{
        'sports_khan_domestic_soccer_ko',
        'sports_khan_soccer_ko',
        'sportschosun_soccer_ko',
        'sportsdonga_soccer_ko',
        'newsis_sports_domestic_soccer_ko',
        'khan_sports_domestic_soccer_ko',
        'google_news_domestic_soccer_ko',
        'google_news_kleague_ko',
        'google_news_kleague1_ko',
        'google_news_kleague2_ko',
        'google_news_korea_national_team_ko',
        'google_news_kfa_ko',
        'google_news_korea_cup_ko',
        'google_news_wkleague_ko',
        'google_news_k3_k4_ko',
      }),
    );
  });

  test('uses unique news channel ids', () {
    final channels = RssNewsRepository().channels();
    final ids = channels.map((channel) => channel.id).toList();

    expect(ids.toSet(), hasLength(ids.length));
  });

  test('domestic football channels use Korean suffix for picker grouping', () {
    final channels = RssNewsRepository().channels();
    final domesticChannels = channels.where(
      (channel) =>
          channel.name.contains('국내축구') ||
          channel.name.contains('K리그') ||
          channel.name.contains('축구대표팀') ||
          channel.name.contains('대한축구협회') ||
          channel.name.contains('코리아컵') ||
          channel.name.contains('WK리그') ||
          channel.name.contains('K3/K4'),
    );

    expect(domesticChannels, isNotEmpty);
    expect(
      domesticChannels.every((channel) => channel.id.endsWith('_ko')),
      isTrue,
    );
  });
}
