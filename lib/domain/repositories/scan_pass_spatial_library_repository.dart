import '../scan_pass/real_match_replay.dart';
import '../scan_pass/scan_pass_spatial_library.dart';

abstract interface class ScanPassSpatialLibraryRepository {
  Future<SpatialLibraryCatalog> loadCatalog();

  Future<RealMatchReplayData> loadScene(SpatialLibraryScene scene);
}
