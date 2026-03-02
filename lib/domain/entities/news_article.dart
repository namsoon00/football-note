class NewsArticle {
  final String title;
  final String link;
  final String source;
  final String imageUrl;
  final DateTime? publishedAt;

  const NewsArticle({
    required this.title,
    required this.link,
    required this.source,
    this.imageUrl = '',
    this.publishedAt,
  });
}
