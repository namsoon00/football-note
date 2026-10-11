import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class MatchMomentOfficialVideo extends StatefulWidget {
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
  State<MatchMomentOfficialVideo> createState() =>
      _MatchMomentOfficialVideoState();
}

class _MatchMomentOfficialVideoState extends State<MatchMomentOfficialVideo> {
  bool _playing = false;

  void _play() {
    setState(() => _playing = true);
  }

  void _configurePlayer(Object element) {
    final iframe = element as web.HTMLIFrameElement;
    final source = Uri.parse(widget.embedUrl);
    final params = <String, String>{
      ...source.queryParameters,
      'controls': '1',
      'autoplay': '0',
      if (Uri.base.scheme == 'https' || Uri.base.scheme == 'http')
        'origin': Uri.base.origin,
    };
    iframe
      ..src = source.replace(queryParameters: params).toString()
      ..title = widget.title
      ..referrerPolicy = 'strict-origin-when-cross-origin'
      ..allow = 'encrypted-media; picture-in-picture; fullscreen'
      ..allowFullscreen = true;
    iframe.style
      ..width = '100%'
      ..height = '100%'
      ..border = '0';
  }

  @override
  Widget build(BuildContext context) {
    if (!_playing) {
      return OutlinedButton(
        key: const ValueKey<String>('match-play-official-embed'),
        onPressed: _play,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_arrow, size: 18),
            const SizedBox(width: 6),
            Flexible(child: Text(widget.playLabel)),
          ],
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        // YouTube requires a viewport of at least 200 x 200. External source
        // links remain visible in the enclosing review if space is too small.
        if (constraints.maxWidth < 200) return const SizedBox.shrink();
        return SizedBox(
          width: constraints.maxWidth,
          height: math.max(200.0, constraints.maxWidth * 9 / 16),
          child: HtmlElementView.fromTagName(
            key: ValueKey(widget.embedUrl),
            tagName: 'iframe',
            onElementCreated: _configurePlayer,
          ),
        );
      },
    );
  }
}
