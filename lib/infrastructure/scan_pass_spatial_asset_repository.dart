import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import '../domain/repositories/scan_pass_spatial_library_repository.dart';
import '../domain/scan_pass/real_match_replay.dart';
import '../domain/scan_pass/scan_pass_spatial_library.dart';

typedef ScanPassSpatialAssetLoader = Future<String> Function(String asset);

class ScanPassSpatialAssetRepository
    implements ScanPassSpatialLibraryRepository {
  static const catalogAsset = 'assets/scan_pass_spatial/catalog.json';

  final ScanPassSpatialAssetLoader _loadAsset;

  ScanPassSpatialAssetRepository({ScanPassSpatialAssetLoader? loadAsset})
      : _loadAsset = loadAsset ?? rootBundle.loadString;

  @override
  Future<SpatialLibraryCatalog> loadCatalog() async {
    return SpatialLibraryCatalog.fromJsonString(
      await _loadAsset(catalogAsset),
    );
  }

  @override
  Future<RealMatchReplayData> loadScene(SpatialLibraryScene scene) async {
    final source = await _loadAsset(scene.asset);
    final actualHash = sha256.convert(utf8.encode(source)).toString();
    if (actualHash != scene.assetSha256) {
      throw const FormatException('Spatial scene asset hash mismatch.');
    }
    return RealMatchReplayData.fromJsonString(source);
  }
}
