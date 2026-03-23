import 'package:flutter/foundation.dart';

import '../domain/entities/news_article.dart';
import '../domain/repositories/option_repository.dart';
import '../infrastructure/rss_news_repository.dart';
import 'news_read_state.dart';
import 'news_service.dart';

class NewsBadgeService {
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

    return NewsReadState.unreadCount(optionRepository, articles);
  }

  static Future<void> refresh(OptionRepository optionRepository) async {
    final count = await unreadCount(optionRepository);
    if (_unreadCountNotifier.value != count) {
      _unreadCountNotifier.value = count;
    }
  }

  static String _articleKey(NewsArticle article) {
    final link = article.link.trim();
    if (link.isNotEmpty) return link;
    return '${article.source.trim()}::${article.title.trim().toLowerCase()}';
  }
}
