import '../entities/news_article.dart';
import '../entities/news_channel.dart';

abstract class NewsRepository {
  List<NewsChannel> channels();
  Future<List<NewsArticle>> fetchLatest(String channelId);
}
