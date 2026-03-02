import 'package:flutter/material.dart';

class WatchDetailImage extends StatelessWidget {
  final String image;
  final String? tag;

  const WatchDetailImage({
    super.key,
    required this.image,
    this.tag,
  });

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Container(
        padding: const EdgeInsets.all(24.0),
        height: MediaQuery.of(context).size.height * 0.32,
        width: MediaQuery.of(context).size.width * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: Colors.grey.shade300,
          ),
        ),
        child: Image.asset(
          image,
          fit: BoxFit.contain,
        ),
      ),
    );

    if (tag == null) {
      return content;
    }

    return Hero(tag: tag!, child: content);
  }
}
