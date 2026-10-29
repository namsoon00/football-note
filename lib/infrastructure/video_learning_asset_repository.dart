import 'package:flutter/services.dart';

import '../domain/repositories/video_learning_repository.dart';
import '../domain/scan_pass/scan_pass_video_learning.dart';

typedef VideoLearningAssetLoader = Future<String> Function(String asset);

class VideoLearningAssetRepository implements VideoLearningRepository {
  static const catalogAsset = 'assets/video_learning/catalog.json';

  final VideoLearningAssetLoader _loadAsset;

  VideoLearningAssetRepository({VideoLearningAssetLoader? loadAsset})
      : _loadAsset = loadAsset ?? rootBundle.loadString;

  @override
  Future<VideoLearningCatalog> loadCatalog() async =>
      VideoLearningCatalog.fromJsonString(await _loadAsset(catalogAsset));
}
