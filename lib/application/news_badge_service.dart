import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../domain/entities/news_article.dart';
import '../domain/repositories/option_repository.dart';
import '../infrastructure/rss_news_repository.dart';
import 'news_read_state.dart';
import 'news_service.dart';

class NewsBadgeService {
  static const String seenArticleKeysKey = 'news_badge_seen_article_keys_v1';
  static const int _maxStoredKeys = 500;
  static final ValueNotifier<int> _unreadCountNotifier = ValueNotifier<int>(0);

  static ValueListenable<int> listenable(OptionRepository optionRepository) {
    refresh(optionRepository);
    return _unreadCountNotifier;
  }

  static Future<int> unreadCount(OptionRepository optionRepository) async {
    final service = NewsService(RssNewsRepository(optionRepository));
    final channels = service.channels();
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

    return _unreadCount(optionRepository, articles);
  }

  static Future<void> refresh(OptionRepository optionRepository) async {
    final count = await unreadCount(optionRepository);
    if (_unreadCountNotifier.value != count) {
      _unreadCountNotifier.value = count;
    }
  }

  static void clearUnreadCount() {
    if (_unreadCountNotifier.value != 0) {
      _unreadCountNotifier.value = 0;
    }
  }

  static Future<void> markSeen(
    OptionRepository optionRepository,
    Iterable<NewsArticle> articles,
  ) async {
    final merged = LinkedHashSet<String>.from(
      optionRepository
          .getOptions(seenArticleKeysKey, const <String>[])
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
    await optionRepository.saveOptions(seenArticleKeysKey, merged.toList());
  }

  static int _unreadCount(
    OptionRepository optionRepository,
    Iterable<NewsArticle> articles,
  ) {
    final seenKeys = {
      ...optionRepository
          .getOptions(seenArticleKeysKey, const <String>[])
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty),
      ...NewsReadState.loadReadKeys(optionRepository),
    };
    final articleKeys = <String>{};
    for (final article in articles) {
      final key = NewsReadState.articleKey(article);
      if (key.isEmpty || !articleKeys.add(key)) continue;
    }
    return articleKeys.where((key) => !seenKeys.contains(key)).length;
  }

  static String _articleKey(NewsArticle article) {
    final link = article.link.trim();
    if (link.isNotEmpty) return link;
    return '${article.source.trim()}::${article.title.trim().toLowerCase()}';
  }
}
