import 'package:flutter/material.dart';

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
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xFF111827)),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.open_in_new, color: Colors.white70, size: 28),
                const SizedBox(height: 6),
                Text(
                  unavailableLabel,
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ]),
            ),
          ),
        ),
      );
}
