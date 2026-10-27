import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/scan_pass_spatial_library_service.dart';
import 'package:football_note/domain/repositories/scan_pass_spatial_library_repository.dart';
import 'package:football_note/domain/scan_pass/real_match_replay.dart';
import 'package:football_note/domain/scan_pass/scan_pass_spatial_library.dart';
import 'package:football_note/infrastructure/scan_pass_spatial_asset_repository.dart';

void main() {
  late ScanPassSpatialAssetRepository assets;
  late SpatialLibraryCatalog catalog;

  setUpAll(() async {
    assets = ScanPassSpatialAssetRepository(
      loadAsset: (asset) => File(asset).readAsString(),
    );
    catalog = await assets.loadCatalog();
  });

  test('asset repository hashes, parses, and service-validates a scene',
      () async {
    final service = ScanPassSpatialLibraryService(assets);
    final loadedCatalog = await service.loadCatalog();
    final scene = loadedCatalog.scenes.first;
    final data = await service.loadScene(scene);

    expect(loadedCatalog.scenes, hasLength(108));
    expect(data.scene.id, scene.id);
    expect(data.match.id, scene.matchId);
  });

  test('asset repository rejects corrupt scene bytes before parsing', () async {
    final scene = catalog.scenes.first;
    final corrupt = ScanPassSpatialAssetRepository(
      loadAsset: (asset) async {
        final source = await File(asset).readAsString();
        return asset == scene.asset ? '$source\ncorrupt' : source;
      },
    );

    expect(corrupt.loadScene(scene), throwsFormatException);
  });

  test('application service rejects a valid payload from another scene',
      () async {
    final first = catalog.scenes.first;
    final second = catalog.scenes[1];
    final wrongData = RealMatchReplayData.fromJsonString(
      File(second.asset).readAsStringSync(),
    );
    final service = ScanPassSpatialLibraryService(
      _FakeRepository(catalog, wrongData),
    );

    expect(service.loadScene(first), throwsFormatException);
  });
}

class _FakeRepository implements ScanPassSpatialLibraryRepository {
  final SpatialLibraryCatalog catalog;
  final RealMatchReplayData scene;

  const _FakeRepository(this.catalog, this.scene);

  @override
  Future<SpatialLibraryCatalog> loadCatalog() async => catalog;

  @override
  Future<RealMatchReplayData> loadScene(SpatialLibraryScene scene) async =>
      this.scene;
}
