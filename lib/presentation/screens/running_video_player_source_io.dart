import 'dart:io';

import 'package:video_player/video_player.dart';

Future<VideoPlayerController?> openRunningVideoPlayer(String path) async {
  final file = File(path);
  if (!file.existsSync()) return null;
  return VideoPlayerController.file(file);
}
