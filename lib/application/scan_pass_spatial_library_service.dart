import '../domain/repositories/scan_pass_spatial_library_repository.dart';
import '../domain/scan_pass/real_match_replay.dart';
import '../domain/scan_pass/scan_pass_spatial_library.dart';

class ScanPassSpatialLibraryService {
  final ScanPassSpatialLibraryRepository repository;

  const ScanPassSpatialLibraryService(this.repository);

  Future<SpatialLibraryCatalog> loadCatalog() => repository.loadCatalog();

  Future<RealMatchReplayData> loadScene(SpatialLibraryScene scene) async {
    final data = await repository.loadScene(scene);
    scene.validateReplay(data);
    return data;
  }
}
