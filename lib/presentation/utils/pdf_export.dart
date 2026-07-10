import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'png_image_download.dart';

typedef PdfShareOverride = Future<void> Function({
  required Uint8List bytes,
  required String filename,
});

typedef PngImageShareOverride = Future<void> Function({
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
PngImageShareOverride? debugPngImageShareOverride;

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
  final mediaQuery = MediaQuery.maybeOf(context);
  final textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;
  final view = View.maybeOf(context) ??
      WidgetsBinding.instance.platformDispatcher.views.first;
  final repaintBoundary = RenderRepaintBoundary();
  final renderView = RenderView(
    view: view,
    configuration: ViewConfiguration(
      logicalConstraints: BoxConstraints.tight(size),
      physicalConstraints: BoxConstraints.tight(size),
      devicePixelRatio: 1,
    ),
    child: repaintBoundary,
  );
  final pipelineOwner = PipelineOwner();
  final focusManager = FocusManager();
  final buildOwner = BuildOwner(focusManager: focusManager);
  final mediaData = (mediaQuery ?? MediaQueryData(size: size)).copyWith(
    size: size,
    devicePixelRatio: 1,
  );
  Widget exportChild = MediaQuery(
    data: mediaData,
    child: Directionality(
      textDirection: textDirection,
      child: SizedBox.fromSize(size: size, child: child),
    ),
  );
  if (Localizations.maybeLocaleOf(context) != null) {
    exportChild = Localizations.override(
      context: context,
      child: exportChild,
    );
  }
  exportChild = InheritedTheme.captureAll(context, exportChild);

  renderView.attach(pipelineOwner);
  renderView.prepareInitialFrame();
  final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
    container: repaintBoundary,
    debugShortDescription: '[png export]',
    child: exportChild,
  ).attachToRenderTree(buildOwner);

  try {
    _pumpOffscreenFrame(
      buildOwner: buildOwner,
      pipelineOwner: pipelineOwner,
      rootElement: rootElement,
    );
    final image = await repaintBoundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final bytes = byteData?.buffer.asUint8List();
    if (bytes == null || bytes.isEmpty) {
      throw StateError('PDF export image is empty.');
    }
    return bytes;
  } finally {
    RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      debugShortDescription: '[png export teardown]',
    ).attachToRenderTree(buildOwner, rootElement);
    _pumpOffscreenFrame(
      buildOwner: buildOwner,
      pipelineOwner: pipelineOwner,
      rootElement: rootElement,
    );
    renderView.detach();
    focusManager.dispose();
  }
}

void _pumpOffscreenFrame({
  required BuildOwner buildOwner,
  required PipelineOwner pipelineOwner,
  required RenderObjectToWidgetElement<RenderBox> rootElement,
}) {
  buildOwner.buildScope(rootElement);
  pipelineOwner.flushLayout();
  pipelineOwner.flushCompositingBits();
  pipelineOwner.flushPaint();
  buildOwner.finalizeTree();
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

Future<void> sharePngImage({
  required Uint8List pngImage,
  required String filename,
  String? title,
}) async {
  if (pngImage.isEmpty) {
    throw StateError('No image to share.');
  }
  final override = debugPngImageShareOverride;
  if (override != null) {
    await override(bytes: pngImage, filename: filename);
    return;
  }
  if (kIsWeb) {
    await downloadPngImage(pngImage: pngImage, filename: filename);
    return;
  }
  await SharePlus.instance.share(
    ShareParams(
      title: title ?? filename,
      files: [
        XFile.fromData(
          pngImage,
          mimeType: 'image/png',
          name: filename,
        ),
      ],
      fileNameOverrides: [filename],
    ),
  );
}

String timestampedPdfFilename(String prefix) {
  return _timestampedFilename(prefix, 'pdf');
}

String timestampedImageFilename(String prefix) {
  return _timestampedFilename(prefix, 'png');
}

String _timestampedFilename(String prefix, String extension) {
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
  return '${safePrefix.isEmpty ? 'export' : safePrefix}_$timestamp.$extension';
}
