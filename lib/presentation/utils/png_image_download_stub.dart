import 'dart:typed_data';

Future<void> downloadPngImage({
  required Uint8List pngImage,
  required String filename,
}) async {
  throw UnsupportedError('PNG image download is only available on web.');
}
