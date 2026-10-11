import 'package:flutter/widgets.dart';

class MatchMomentOfficialVideo extends StatelessWidget {
  final String playLabel;
  final String title;
  final String embedUrl;

  const MatchMomentOfficialVideo({
    super.key,
    required this.playLabel,
    required this.title,
    required this.embedUrl,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
