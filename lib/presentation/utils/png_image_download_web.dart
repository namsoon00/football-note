import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<void> downloadPngImage({
  required Uint8List pngImage,
  required String filename,
}) async {
  if (pngImage.isEmpty) {
    throw StateError('No image to download.');
  }

  final body = web.document.body;
  if (body == null) {
    throw StateError('Browser document is not ready.');
  }

  final blob = web.Blob(
    <JSUint8Array>[pngImage.toJS].toJS,
    web.BlobPropertyBag(type: 'image/png'),
  );
  final objectUrl = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = objectUrl
    ..download = filename
    ..style.display = 'none';

  body.children.add(anchor);
  try {
    anchor.click();
  } finally {
    anchor.remove();
    Future<void>.delayed(const Duration(seconds: 1), () {
      web.URL.revokeObjectURL(objectUrl);
    });
  }
}
