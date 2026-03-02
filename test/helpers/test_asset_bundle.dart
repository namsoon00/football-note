import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

class TestAssetBundle extends CachingAssetBundle {
  static const _svg =
      '<svg viewBox="0 0 10 10" xmlns="http://www.w3.org/2000/svg"></svg>';
  static const _transparentPngBase64 =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII=';

  @override
  Future<ByteData> load(String key) async {
    if (key.endsWith('AssetManifest.bin')) {
      final encoded = const StandardMessageCodec().encodeMessage(
        <String, List<String>>{},
      ) as ByteData;
      return encoded;
    }
    if (key.endsWith('.svg')) {
      final bytes = utf8.encode(_svg);
      return ByteData.view(Uint8List.fromList(bytes).buffer);
    }
    if (key.endsWith('.png') || key.endsWith('.jpg') || key.endsWith('.jpeg')) {
      final bytes = base64Decode(_transparentPngBase64);
      return ByteData.view(Uint8List.fromList(bytes).buffer);
    }
    return ByteData.view(Uint8List.fromList(<int>[0]).buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key.endsWith('AssetManifest.json')) {
      return '{}';
    }
    if (key.endsWith('.svg')) {
      return _svg;
    }
    return '';
  }

  @override
  Future<ui.ImmutableBuffer> loadBuffer(String key) async {
    final data = await load(key);
    return ui.ImmutableBuffer.fromUint8List(data.buffer.asUint8List());
  }

  @override
  Future<T> loadStructuredData<T>(
    String key,
    FutureOr<T> Function(String value) parser,
  ) async {
    final data = await loadString(key);
    return parser(data);
  }

  @override
  Future<T> loadStructuredBinaryData<T>(
    String key,
    FutureOr<T> Function(ByteData data) parser,
  ) async {
    final data = await load(key);
    return parser(data);
  }
}
