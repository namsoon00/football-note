import 'dart:io';

import 'package:video_player/video_player.dart';

Future<VideoPlayerController?> openRunningVideoPlayer(String path) async {
  final file = File(path);
  if (!await file.exists()) return null;
  return VideoPlayerController.file(file);
}
