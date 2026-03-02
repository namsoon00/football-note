import '../domain/entities/news_article.dart';
import '../domain/entities/news_channel.dart';
import '../domain/repositories/news_repository.dart';

class NewsService {
  final NewsRepository _repository;

  NewsService(this._repository);

  List<NewsChannel> channels() => _repository.channels();

  Future<List<NewsArticle>> latest(String channelId) =>
      _repository.fetchLatest(channelId);
}
