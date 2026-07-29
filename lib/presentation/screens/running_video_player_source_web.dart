import 'package:video_player/video_player.dart';

Future<VideoPlayerController?> openRunningVideoPlayer(String path) async {
  final uri = Uri.tryParse(path);
  if (uri == null || uri.scheme.isEmpty) return null;
  return VideoPlayerController.networkUrl(uri);
}
