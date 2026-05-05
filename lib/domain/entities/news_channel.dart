class NewsChannel {
  final String id;
  final String name;
  final bool isDomestic;

  const NewsChannel({
    required this.id,
    required this.name,
    this.isDomestic = false,
  });
}
