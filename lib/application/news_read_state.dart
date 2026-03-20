import 'dart:collection';

import '../domain/entities/news_article.dart';
import '../domain/repositories/option_repository.dart';

class NewsReadState {
  static const String readArticleKeysKey = 'news_read_article_keys_v1';
  static const int _maxStoredKeys = 500;

  static String articleKey(NewsArticle article) {
    final link = article.link.trim();
    if (link.isNotEmpty) return 'link:$link';
    final title = article.title.trim().toLowerCase();
    final source = article.source.trim().toLowerCase();
    final publishedAt = article.publishedAt?.toIso8601String() ?? '';
    if (title.isEmpty && source.isEmpty && publishedAt.isEmpty) return '';
    return 'meta:$title|$source|$publishedAt';
  }

  static Set<String> loadReadKeys(OptionRepository optionRepository) {
    return optionRepository
        .getOptions(readArticleKeysKey, const <String>[])
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
  }

  static int unreadCount(
    OptionRepository optionRepository,
    Iterable<NewsArticle> articles,
  ) {
    final readKeys = loadReadKeys(optionRepository);
    final articleKeys = <String>{};
    for (final article in articles) {
      final key = articleKey(article);
      if (key.isEmpty || !articleKeys.add(key)) continue;
    }
    return articleKeys.where((key) => !readKeys.contains(key)).length;
  }

  static Future<void> markRead(
    OptionRepository optionRepository,
    Iterable<NewsArticle> articles,
  ) async {
    final merged = LinkedHashSet<String>.from(
      optionRepository
          .getOptions(readArticleKeysKey, const <String>[])
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty),
    );
    for (final article in articles) {
      final key = articleKey(article);
      if (key.isEmpty) continue;
      merged.remove(key);
      merged.add(key);
    }
    while (merged.length > _maxStoredKeys) {
      merged.remove(merged.first);
    }
    await optionRepository.saveOptions(readArticleKeysKey, merged.toList());
  }
}
