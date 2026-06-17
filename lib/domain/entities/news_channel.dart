class NewsChannel {
  final String id;
  final String name;
  final bool isDomestic;
  final String sportId;

  const NewsChannel({
    required this.id,
    required this.name,
    this.isDomestic = false,
    required this.sportId,
  });
}
