import '../domain/entities/news_article.dart';
import '../domain/entities/news_channel.dart';
import '../domain/repositories/news_repository.dart';
import '../domain/entities/sport_definition.dart';

class NewsService {
  final NewsRepository _repository;

  NewsService(this._repository);

  List<NewsChannel> channels({String? sportId}) => _repository.channels(
        sportId:
            sportId == null ? null : SportCatalog.normalizeSportId(sportId),
      );

  Future<List<NewsArticle>> latest(
    String channelId, {
    bool forceRefresh = false,
  }) =>
      _repository.fetchLatest(channelId, forceRefresh: forceRefresh);
}
