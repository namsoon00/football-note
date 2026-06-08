import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/locale_service.dart';
import 'package:football_note/application/news_badge_service.dart';
import 'package:football_note/application/news_read_state.dart';
import 'package:football_note/application/news_service.dart';
import 'package:football_note/application/settings_service.dart';
import 'package:football_note/application/training_service.dart';
import 'package:football_note/domain/entities/news_article.dart';
import 'package:football_note/domain/entities/news_channel.dart';
import 'package:football_note/domain/entities/training_entry.dart';
import 'package:football_note/domain/repositories/news_repository.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/domain/repositories/training_repository.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/news_screen.dart';

const _scrapToggleActionKey = ValueKey<String>(
  'news_quick_action_scrap_toggle',
);
const _translateToggleActionKey = ValueKey<String>(
  'news_quick_action_translate_toggle',
);
const _searchActionKey = ValueKey<String>('news_quick_action_search');
const _viewedHistoryActionKey = ValueKey<String>(
  'news_quick_action_viewed_history',
);
const _leagueStandingsActionKey = ValueKey<String>(
  'news_quick_action_league_standings',
);
const _fifaHubActionKey = ValueKey<String>('news_quick_action_fifa_hub');
const _worldCupActionKey = ValueKey<String>('news_quick_action_world_cup');

void main() {
  testWidgets('news header exposes one league entry point', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _MemoryOptionRepository();
    final newsRepository = _FakeNewsRepository(
      channels: const [
        NewsChannel(
          id: 'issue271_domestic_soccer_ko',
          name: '테스트 · 국내축구',
          isDomestic: true,
        ),
      ],
      articlesByChannelId: <String, List<NewsArticle>>{
        'issue271_domestic_soccer_ko': const [
          NewsArticle(
            title: '국내 기사',
            link: 'https://example.com/domestic-issue271',
            source: '테스트',
            channelId: 'issue271_domestic_soccer_ko',
          ),
        ],
      },
    );

    await tester.pumpWidget(
      _buildNewsApp(
        optionRepository: repository,
        newsService: NewsService(newsRepository),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('오늘의 소식'), findsOneWidget);
    expect(find.byKey(_leagueStandingsActionKey), findsOneWidget);
    expect(find.byKey(_fifaHubActionKey), findsOneWidget);
    expect(find.text('리그보기'), findsOneWidget);
    expect(find.text('국내리그'), findsNothing);
    expect(find.text('피파랭킹'), findsOneWidget);
  });

  testWidgets('world cup action moves to the left during the tournament', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _MemoryOptionRepository();
    final newsRepository = _FakeNewsRepository(
      channels: const [
        NewsChannel(
          id: 'issue_world_cup_header_domestic_soccer_ko',
          name: '테스트 · 국내축구',
          isDomestic: true,
        ),
      ],
      articlesByChannelId: <String, List<NewsArticle>>{
        'issue_world_cup_header_domestic_soccer_ko': const [
          NewsArticle(
            title: '월드컵 기간 뉴스',
            link: 'https://example.com/world-cup-header',
            source: '테스트',
            channelId: 'issue_world_cup_header_domestic_soccer_ko',
          ),
        ],
      },
    );

    await tester.pumpWidget(
      _buildNewsApp(
        optionRepository: repository,
        newsService: NewsService(newsRepository),
        nowForTesting: DateTime(2026, 6, 12),
      ),
    );
    await tester.pumpAndSettle();

    final worldCupX = tester.getTopLeft(find.byKey(_worldCupActionKey)).dx;
    final fifaX = tester.getTopLeft(find.byKey(_fifaHubActionKey)).dx;
    final leagueX = tester.getTopLeft(find.byKey(_leagueStandingsActionKey)).dx;

    expect(isWorldCupTournamentPeriod(DateTime(2026, 6, 12)), isTrue);
    expect(worldCupX, lessThan(fifaX));
    expect(fifaX, lessThan(leagueX));
  });

  testWidgets('news quick actions keep scrap, translate, search order', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _MemoryOptionRepository();
    final newsRepository = _FakeNewsRepository(
      channels: const [
        NewsChannel(
          id: 'issue260_order_domestic_soccer_ko',
          name: '테스트 · 국내축구',
          isDomestic: true,
        ),
        NewsChannel(id: 'issue260_order_world_en', name: 'Test World'),
      ],
      articlesByChannelId: <String, List<NewsArticle>>{
        'issue260_order_domestic_soccer_ko': const [
          NewsArticle(
            title: '국내 뉴스',
            link: 'https://example.com/domestic-order',
            source: '테스트',
            channelId: 'issue260_order_domestic_soccer_ko',
          ),
        ],
        'issue260_order_world_en': const [
          NewsArticle(
            title: 'World news',
            link: 'https://example.com/world-order',
            source: 'Test World',
            channelId: 'issue260_order_world_en',
          ),
        ],
      },
    );

    await tester.pumpWidget(
      _buildNewsApp(
        optionRepository: repository,
        newsService: NewsService(newsRepository),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('스크랩한 소식만 보기'), findsNothing);
    expect(find.text('번역'), findsNothing);

    final scrapX = tester.getTopLeft(find.byKey(_scrapToggleActionKey)).dx;
    final translateX =
        tester.getTopLeft(find.byKey(_translateToggleActionKey)).dx;
    final searchX = tester.getTopLeft(find.byKey(_searchActionKey)).dx;

    expect(scrapX, lessThan(translateX));
    expect(translateX, lessThan(searchX));
  });

  testWidgets(
    'switching to domestic filter keeps fresh articles without refetch',
    (WidgetTester tester) async {
      final repository = _MemoryOptionRepository();
      final newsRepository = _FakeNewsRepository(
        channels: const [
          NewsChannel(
            id: 'issue260_domestic_fast_soccer_ko',
            name: '테스트 · 국내축구',
            isDomestic: true,
          ),
          NewsChannel(id: 'issue260_world_fast_en', name: 'Test World'),
        ],
        articlesByChannelId: <String, List<NewsArticle>>{
          'issue260_domestic_fast_soccer_ko': const [
            NewsArticle(
              title: '국내 기사',
              link: 'https://example.com/domestic-fast',
              source: '테스트',
              channelId: 'issue260_domestic_fast_soccer_ko',
            ),
          ],
          'issue260_world_fast_en': const [
            NewsArticle(
              title: 'World article',
              link: 'https://example.com/world-fast',
              source: 'Test World',
              channelId: 'issue260_world_fast_en',
            ),
          ],
        },
      );

      await tester.pumpWidget(
        _buildNewsApp(
          optionRepository: repository,
          newsService: NewsService(newsRepository),
        ),
      );
      await tester.pumpAndSettle();

      expect(newsRepository.calls, hasLength(2));
      expect(find.text('국내 기사'), findsOneWidget);

      await tester.tap(find.text('국내'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(newsRepository.calls, hasLength(2));
      expect(find.text('국내 기사'), findsOneWidget);
    },
  );

  testWidgets('read news is hidden from the feed', (WidgetTester tester) async {
    final repository = _MemoryOptionRepository();
    const readArticle = NewsArticle(
      title: '이미 읽은 기사',
      link: 'https://example.com/read-news',
      source: '테스트',
      channelId: 'issue272_domestic_soccer_ko',
    );
    const unreadArticle = NewsArticle(
      title: '안 읽은 기사',
      link: 'https://example.com/unread-news',
      source: '테스트',
      channelId: 'issue272_domestic_soccer_ko',
    );
    await repository.saveOptions(NewsReadState.readArticleKeysKey, [
      NewsReadState.articleKey(readArticle),
    ]);
    final newsRepository = _FakeNewsRepository(
      channels: const [
        NewsChannel(
          id: 'issue272_domestic_soccer_ko',
          name: '테스트 · 국내축구',
          isDomestic: true,
        ),
      ],
      articlesByChannelId: const <String, List<NewsArticle>>{
        'issue272_domestic_soccer_ko': [readArticle, unreadArticle],
      },
    );

    await tester.pumpWidget(
      _buildNewsApp(
        optionRepository: repository,
        newsService: NewsService(newsRepository),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('안 읽은 기사'), findsOneWidget);
    expect(find.text('이미 읽은 기사'), findsNothing);
  });

  testWidgets(
    'opening news marks loaded articles seen but keeps them visible',
    (WidgetTester tester) async {
      final repository = _MemoryOptionRepository();
      const article = NewsArticle(
        title: '새 기사',
        link: 'https://example.com/new-news',
        source: '테스트',
        channelId: 'issue284_seen_domestic_soccer_ko',
      );
      final newsRepository = _FakeNewsRepository(
        channels: const [
          NewsChannel(
            id: 'issue284_seen_domestic_soccer_ko',
            name: '테스트 · 국내축구',
            isDomestic: true,
          ),
        ],
        articlesByChannelId: const <String, List<NewsArticle>>{
          'issue284_seen_domestic_soccer_ko': [article],
        },
      );

      await tester.pumpWidget(
        _buildNewsApp(
          optionRepository: repository,
          newsService: NewsService(newsRepository),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('새 기사'), findsOneWidget);
      expect(
        repository.getOptions(NewsBadgeService.seenArticleKeysKey, const []),
        contains(NewsReadState.articleKey(article)),
      );
      expect(
        repository.getOptions(NewsReadState.readArticleKeysKey, const []),
        isNot(contains(NewsReadState.articleKey(article))),
      );
    },
  );

  testWidgets('viewed news history shows opened articles', (
    WidgetTester tester,
  ) async {
    final repository = _MemoryOptionRepository();
    await repository.setValue(
      NewsScreen.openedItemsKey,
      jsonEncode([
        {
          'title': 'Viewed article',
          'titleKo': '본 기사',
          'link': 'https://example.com/viewed-news',
          'source': '테스트',
          'imageUrl': 'https://example.com/viewed-news.jpg',
          'openedAt': DateTime(2026, 5, 19, 10, 30).toIso8601String(),
        },
      ]),
    );
    final newsRepository = _FakeNewsRepository(
      channels: const [
        NewsChannel(
          id: 'issue284_history_domestic_soccer_ko',
          name: '테스트 · 국내축구',
          isDomestic: true,
        ),
      ],
      articlesByChannelId: const <String, List<NewsArticle>>{
        'issue284_history_domestic_soccer_ko': [],
      },
    );

    await tester.pumpWidget(
      _buildNewsApp(
        optionRepository: repository,
        newsService: NewsService(newsRepository),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(_viewedHistoryActionKey));
    await tester.pumpAndSettle();

    expect(find.text('본 소식'), findsOneWidget);
    expect(find.text('본 기사'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>(
          'opened-news-thumb-https://example.com/viewed-news',
        ),
      ),
      findsOneWidget,
    );
  });
}

Widget _buildNewsApp({
  required OptionRepository optionRepository,
  required NewsService newsService,
  DateTime? nowForTesting,
}) {
  return MaterialApp(
    locale: const Locale('ko'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: NewsScreen(
      trainingService: TrainingService(_FakeTrainingRepository()),
      localeService: LocaleService(optionRepository),
      optionRepository: optionRepository,
      settingsService: SettingsService(optionRepository),
      newsService: newsService,
      nowForTesting: nowForTesting,
    ),
  );
}

class _FakeNewsRepository implements NewsRepository {
  final List<NewsChannel> _channels;
  final Map<String, List<NewsArticle>> _articlesByChannelId;
  final List<String> calls = <String>[];

  _FakeNewsRepository({
    required List<NewsChannel> channels,
    required Map<String, List<NewsArticle>> articlesByChannelId,
  })  : _channels = channels,
        _articlesByChannelId = articlesByChannelId;

  @override
  List<NewsChannel> channels() => _channels;

  @override
  Future<List<NewsArticle>> fetchLatest(
    String channelId, {
    bool forceRefresh = false,
  }) async {
    calls.add(channelId);
    return _articlesByChannelId[channelId] ?? const <NewsArticle>[];
  }
}

class _FakeTrainingRepository implements TrainingRepository {
  @override
  Future<void> add(TrainingEntry entry) async {}

  @override
  Future<void> delete(TrainingEntry entry) async {}

  @override
  Future<List<TrainingEntry>> getAll() async => const <TrainingEntry>[];

  @override
  Future<void> update(int key, TrainingEntry entry) async {}

  @override
  Stream<List<TrainingEntry>> watchAll() =>
      const Stream<List<TrainingEntry>>.empty();
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> _values = <String, dynamic>{};

  @override
  T? getValue<T>(String key) => _values[key] as T?;

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final value = _values[key];
    if (value is List<int>) {
      return List<int>.from(value);
    }
    if (value is List) {
      return value.map((item) => item as int).toList(growable: false);
    }
    return List<int>.from(defaults);
  }

  @override
  List<String> getOptions(String key, List<String> defaults) {
    final value = _values[key];
    if (value is List<String>) {
      return List<String>.from(value);
    }
    if (value is List) {
      return value.map((item) => item.toString()).toList(growable: false);
    }
    return List<String>.from(defaults);
  }

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {
    _values[key] = List<dynamic>.from(options);
  }

  @override
  Future<void> setValue(String key, value) async {
    _values[key] = value;
  }
}
