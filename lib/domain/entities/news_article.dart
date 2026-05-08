class NewsArticle {
  final String title;
  final String link;
  final String source;
  final String summary;
  final String imageUrl;
  final DateTime? publishedAt;
  final String channelId;

  const NewsArticle({
    required this.title,
    required this.link,
    required this.source,
    this.summary = '',
    this.imageUrl = '',
    this.publishedAt,
    this.channelId = '',
  });
}
