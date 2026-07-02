import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

typedef PdfShareOverride = Future<void> Function({
  required Uint8List bytes,
  required String filename,
});

typedef PdfWidgetCaptureOverride = Future<Uint8List> Function({
  required BuildContext context,
  required Widget child,
  required Size size,
  required double pixelRatio,
});

@visibleForTesting
PdfShareOverride? debugPdfShareOverride;

@visibleForTesting
PdfWidgetCaptureOverride? debugCaptureWidgetPngOverride;

Future<Uint8List> captureRepaintBoundaryPng(
  GlobalKey key, {
  double pixelRatio = 3,
}) async {
  final renderObject = key.currentContext?.findRenderObject();
  if (renderObject is! RenderRepaintBoundary) {
    throw StateError('PDF export target is not ready.');
  }
  if (renderObject.debugNeedsPaint) {
    await WidgetsBinding.instance.endOfFrame;
  }
  final image = await renderObject.toImage(pixelRatio: pixelRatio);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  final bytes = byteData?.buffer.asUint8List();
  if (bytes == null || bytes.isEmpty) {
    throw StateError('PDF export image is empty.');
  }
  return bytes;
}

Future<Uint8List> captureWidgetPng(
  BuildContext context, {
  required Widget child,
  required Size size,
  double pixelRatio = 2,
}) async {
  final override = debugCaptureWidgetPngOverride;
  if (override != null) {
    return override(
      context: context,
      child: child,
      size: size,
      pixelRatio: pixelRatio,
    );
  }
  final key = GlobalKey();
  final overlay = Overlay.of(context, rootOverlay: true);
  final mediaQuery = MediaQuery.maybeOf(context);
  final textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;
  final entry = OverlayEntry(
    builder: (overlayContext) {
      final exportChild = MediaQuery(
        data: (mediaQuery ?? MediaQuery.of(overlayContext)).copyWith(
          size: size,
          devicePixelRatio: 1,
        ),
        child: Directionality(
          textDirection: textDirection,
          child: RepaintBoundary(
            key: key,
            child: SizedBox.fromSize(size: size, child: child),
          ),
        ),
      );
      return Positioned(
        left: 0,
        top: 0,
        width: size.width,
        height: size.height,
        child: IgnorePointer(
          child: Opacity(
            opacity: 0.01,
            child: InheritedTheme.captureAll(context, exportChild),
          ),
        ),
      );
    },
  );
  overlay.insert(entry);
  try {
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await WidgetsBinding.instance.endOfFrame;
    return captureRepaintBoundaryPng(key, pixelRatio: pixelRatio);
  } finally {
    entry.remove();
  }
}

Future<void> sharePngImagesAsPdf({
  required List<Uint8List> pngImages,
  required String filename,
  PdfPageFormat pageFormat = PdfPageFormat.a4,
  bool landscape = true,
}) async {
  if (pngImages.isEmpty) {
    throw StateError('No PDF pages to export.');
  }
  final document = pw.Document();
  final resolvedFormat = landscape ? pageFormat.landscape : pageFormat;
  for (final pngImage in pngImages) {
    final image = pw.MemoryImage(pngImage);
    document.addPage(
      pw.Page(
        pageFormat: resolvedFormat,
        margin: const pw.EdgeInsets.all(18),
        build: (_) => pw.Center(
          child: pw.Image(image, fit: pw.BoxFit.contain),
        ),
      ),
    );
  }
  final bytes = await document.save();
  final override = debugPdfShareOverride;
  if (override != null) {
    await override(bytes: bytes, filename: filename);
    return;
  }
  await Printing.sharePdf(bytes: bytes, filename: filename);
}

Future<void> sharePngAsPdf({
  required Uint8List pngImage,
  required String filename,
  PdfPageFormat pageFormat = PdfPageFormat.a4,
  bool landscape = true,
}) {
  return sharePngImagesAsPdf(
    pngImages: [pngImage],
    filename: filename,
    pageFormat: pageFormat,
    landscape: landscape,
  );
}

String timestampedPdfFilename(String prefix) {
  final now = DateTime.now();
  final timestamp = '${now.year.toString().padLeft(4, '0')}'
      '${now.month.toString().padLeft(2, '0')}'
      '${now.day.toString().padLeft(2, '0')}_'
      '${now.hour.toString().padLeft(2, '0')}'
      '${now.minute.toString().padLeft(2, '0')}';
  final safePrefix = prefix
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return '${safePrefix.isEmpty ? 'export' : safePrefix}_$timestamp.pdf';
}
