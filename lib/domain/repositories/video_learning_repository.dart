import '../scan_pass/scan_pass_video_learning.dart';

abstract interface class VideoLearningRepository {
  Future<VideoLearningCatalog> loadCatalog();
}
