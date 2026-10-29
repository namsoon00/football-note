import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../application/video_learning_player.dart';

class VideoLearningSurface extends StatelessWidget {
  final VideoLearningPlayerPort player;
  final String semanticsLabel;
  final String unavailableLabel;

  const VideoLearningSurface({
    super.key,
    required this.player,
    required this.semanticsLabel,
    required this.unavailableLabel,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        label: semanticsLabel,
        child: HtmlElementView.fromTagName(
          tagName: 'div',
          onElementCreated: (element) {
            final host = element as web.HTMLDivElement;
            host
              ..setAttribute('aria-label', semanticsLabel)
              ..style.width = '100%'
              ..style.height = '100%'
              ..style.backgroundColor = '#111827';
            final attachable = player;
            if (attachable is AttachableVideoLearningPlayerPort) {
              (attachable as AttachableVideoLearningPlayerPort)
                  .attachHost(host);
            }
          },
        ),
      );
}
