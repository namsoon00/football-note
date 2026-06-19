import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../domain/entities/news_article.dart';
import '../domain/entities/sport_definition.dart';
import '../domain/repositories/option_repository.dart';
import '../infrastructure/rss_news_repository.dart';
import 'news_read_state.dart';
import 'news_service.dart';
import 'sport_service.dart';

class NewsBadgeService {
  static const String seenArticleKeysKey = 'news_badge_seen_article_keys_v1';
  static const String lastOpenedAtKey = 'news_badge_last_opened_at_v1';
  static const String lastRefreshAtKey = 'news_badge_last_refresh_at_v1';
  static const int _maxStoredKeys = 500;
  static const Duration _refreshInterval = Duration(hours: 3);
  static final ValueNotifier<int> _unreadCountNotifier = ValueNotifier<int>(0);

  static ValueListenable<int> listenable(OptionRepository optionRepository) {
    return _unreadCountNotifier;
  }

  static Future<int> unreadCount(OptionRepository optionRepository) async {
    final sportId = SportService(optionRepository).currentSportId();
    final service = NewsService(RssNewsRepository(optionRepository));
    final channels = service.channels(sportId: sportId);
    final articles = <NewsArticle>[];
    final seenKeys = <String>{};

    await Future.wait(
      channels.map((channel) async {
        try {
          final channelArticles = await service.latest(channel.id);
          for (final article in channelArticles) {
            final key = _articleKey(article);
            if (!seenKeys.add(key)) continue;
            articles.add(article);
          }
        } catch (_) {
          // Ignore per-channel failures and count only successfully loaded feeds.
        }
      }),
    );

    return _unreadCount(optionRepository, articles, sportId: sportId);
  }

  static Future<void> refresh(
    OptionRepository optionRepository, {
    bool force = false,
  }) async {
    final sportId = SportService(optionRepository).currentSportId();
    if (!force && !_shouldRefresh(optionRepository, sportId: sportId)) {
      return;
    }
    final count = await unreadCount(optionRepository);
    await optionRepository.setValue(
      _scopedKey(lastRefreshAtKey, sportId),
      DateTime.now().toIso8601String(),
    );
    if (_unreadCountNotifier.value != count) {
      _unreadCountNotifier.value = count;
    }
  }

  static void clearUnreadCount() {
    if (_unreadCountNotifier.value != 0) {
      _unreadCountNotifier.value = 0;
    }
  }

  static Future<void> markFeedOpened(OptionRepository optionRepository) async {
    final sportId = SportService(optionRepository).currentSportId();
    await optionRepository.setValue(
      _scopedKey(lastOpenedAtKey, sportId),
      DateTime.now().toIso8601String(),
    );
    clearUnreadCount();
  }

  static Future<void> markSeen(
    OptionRepository optionRepository,
    Iterable<NewsArticle> articles,
  ) async {
    final sportId = SportService(optionRepository).currentSportId();
    final seenKey = _scopedKey(seenArticleKeysKey, sportId);
    final merged = LinkedHashSet<String>.from(
      optionRepository
          .getOptions(seenKey, const <String>[])
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty),
    );
    for (final article in articles) {
      final key = NewsReadState.articleKey(article);
      if (key.isEmpty) continue;
      merged.remove(key);
      merged.add(key);
    }
    while (merged.length > _maxStoredKeys) {
      merged.remove(merged.first);
    }
    await optionRepository.saveOptions(seenKey, merged.toList());
  }

  static bool openedToday(OptionRepository optionRepository, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final sportId = SportService(optionRepository).currentSportId();
    final lastOpenedAt = DateTime.tryParse(
      optionRepository.getValue<String>(_scopedKey(lastOpenedAtKey, sportId)) ??
          '',
    );
    return lastOpenedAt != null &&
        lastOpenedAt.year == current.year &&
        lastOpenedAt.month == current.month &&
        lastOpenedAt.day == current.day;
  }

  static int _unreadCount(
    OptionRepository optionRepository,
    Iterable<NewsArticle> articles, {
    required String sportId,
  }) {
    final lastOpenedAt = DateTime.tryParse(
      optionRepository.getValue<String>(_scopedKey(lastOpenedAtKey, sportId)) ??
          '',
    );
    final seenKeys = {
      ...optionRepository
          .getOptions(_scopedKey(seenArticleKeysKey, sportId), const <String>[])
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty),
      ...NewsReadState.loadReadKeys(optionRepository),
    };
    final articleKeys = <String>{};
    for (final article in articles) {
      final publishedAt = article.publishedAt;
      if (lastOpenedAt != null &&
          publishedAt != null &&
          !publishedAt.isAfter(lastOpenedAt)) {
        continue;
      }
      final key = NewsReadState.articleKey(article);
      if (key.isEmpty || !articleKeys.add(key)) continue;
    }
    return articleKeys.where((key) => !seenKeys.contains(key)).length;
  }

  static bool _shouldRefresh(
    OptionRepository optionRepository, {
    required String sportId,
  }) {
    final lastRefreshAt = DateTime.tryParse(
      optionRepository
              .getValue<String>(_scopedKey(lastRefreshAtKey, sportId)) ??
          '',
    );
    if (lastRefreshAt == null) return true;
    return DateTime.now().difference(lastRefreshAt) >= _refreshInterval;
  }

  static String _articleKey(NewsArticle article) {
    final link = article.link.trim();
    if (link.isNotEmpty) return link;
    return '${article.source.trim()}::${article.title.trim().toLowerCase()}';
  }

  static String _scopedKey(String baseKey, String sportId) {
    final normalizedSportId = SportCatalog.normalizeSportId(sportId);
    if (normalizedSportId == SportCatalog.footballId) return baseKey;
    return '${baseKey}_$normalizedSportId';
  }
}
