import '../entities/news_article.dart';
import '../entities/news_channel.dart';

abstract class NewsRepository {
  List<NewsChannel> channels({String? sportId});
  Future<List<NewsArticle>> fetchLatest(
    String channelId, {
    bool forceRefresh = false,
  });
}
