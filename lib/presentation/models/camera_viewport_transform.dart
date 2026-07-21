import 'package:flutter/painting.dart';

class CameraViewportTransform {
  final Size sourceSize;
  final Size viewportSize;
  final bool mirrorHorizontally;
  final Rect sourceRect;
  final Rect destinationRect;

  const CameraViewportTransform._({
    required this.sourceSize,
    required this.viewportSize,
    required this.mirrorHorizontally,
    required this.sourceRect,
    required this.destinationRect,
  });

  factory CameraViewportTransform.cover({
    required Size sourceSize,
    required Size viewportSize,
    bool mirrorHorizontally = false,
  }) {
    return CameraViewportTransform.fit(
      sourceSize: sourceSize,
      viewportSize: viewportSize,
      fit: BoxFit.cover,
      mirrorHorizontally: mirrorHorizontally,
    );
  }

  factory CameraViewportTransform.fit({
    required Size sourceSize,
    required Size viewportSize,
    required BoxFit fit,
    bool mirrorHorizontally = false,
  }) {
    if (sourceSize.isEmpty || viewportSize.isEmpty) {
      return CameraViewportTransform._(
        sourceSize: sourceSize,
        viewportSize: viewportSize,
        mirrorHorizontally: mirrorHorizontally,
        sourceRect: Rect.zero,
        destinationRect: Rect.zero,
      );
    }

    final fitted = applyBoxFit(fit, sourceSize, viewportSize);
    return CameraViewportTransform._(
      sourceSize: sourceSize,
      viewportSize: viewportSize,
      mirrorHorizontally: mirrorHorizontally,
      sourceRect: Alignment.center.inscribe(
        fitted.source,
        Offset.zero & sourceSize,
      ),
      destinationRect: Alignment.center.inscribe(
        fitted.destination,
        Offset.zero & viewportSize,
      ),
    );
  }

  bool get isValid => !sourceRect.isEmpty && !destinationRect.isEmpty;

  Offset project(Offset sourcePoint) {
    if (!isValid) {
      return Offset.zero;
    }

    final projected = Offset(
      destinationRect.left +
          ((sourcePoint.dx - sourceRect.left) *
              destinationRect.width /
              sourceRect.width),
      destinationRect.top +
          ((sourcePoint.dy - sourceRect.top) *
              destinationRect.height /
              sourceRect.height),
    );

    if (!mirrorHorizontally) {
      return projected;
    }
    return Offset(viewportSize.width - projected.dx, projected.dy);
  }
}

class CameraDisplayGeometry {
  final Size detectorImageSize;
  final Size previewSourceSize;
  final bool mirrorHorizontally;

  const CameraDisplayGeometry({
    required this.detectorImageSize,
    required this.previewSourceSize,
    required this.mirrorHorizontally,
  });

  factory CameraDisplayGeometry.fromCameraFrame({
    required Size rawImageSize,
    required Size controllerPreviewSize,
    required int rotationDegrees,
    required bool mirrorHorizontally,
  }) {
    final detectorImageSize = detectorImageSizeForRotation(
      rawImageSize,
      rotationDegrees,
    );
    return CameraDisplayGeometry.fromDetectorImageSize(
      detectorImageSize: detectorImageSize,
      controllerPreviewSize: controllerPreviewSize,
      mirrorHorizontally: mirrorHorizontally,
    );
  }

  factory CameraDisplayGeometry.fromDetectorImageSize({
    required Size detectorImageSize,
    required Size controllerPreviewSize,
    bool mirrorHorizontally = false,
  }) {
    return CameraDisplayGeometry(
      detectorImageSize: detectorImageSize,
      previewSourceSize: cameraPreviewSourceSizeForDetector(
        controllerPreviewSize: controllerPreviewSize,
        detectorImageSize: detectorImageSize,
      ),
      mirrorHorizontally: mirrorHorizontally,
    );
  }

  CameraViewportTransform transformFor({
    required Size viewportSize,
    BoxFit fit = BoxFit.cover,
  }) {
    return CameraViewportTransform.fit(
      sourceSize: detectorImageSize,
      viewportSize: viewportSize,
      fit: fit,
      mirrorHorizontally: mirrorHorizontally,
    );
  }
}

Size detectorImageSizeForRotation(Size rawImageSize, int rotationDegrees) {
  final normalizedRotation = ((rotationDegrees % 360) + 360) % 360;
  if (normalizedRotation == 90 || normalizedRotation == 270) {
    return Size(rawImageSize.height, rawImageSize.width);
  }
  return rawImageSize;
}

Size cameraPreviewSourceSizeForDetector({
  required Size controllerPreviewSize,
  required Size detectorImageSize,
}) {
  if (controllerPreviewSize.isEmpty || detectorImageSize.isEmpty) {
    return controllerPreviewSize;
  }

  final previewIsPortrait =
      controllerPreviewSize.height >= controllerPreviewSize.width;
  final detectorIsPortrait =
      detectorImageSize.height >= detectorImageSize.width;
  if (previewIsPortrait == detectorIsPortrait) {
    return controllerPreviewSize;
  }
  return Size(controllerPreviewSize.height, controllerPreviewSize.width);
}

Size cameraPreviewSourceSizeForViewport({
  required Size controllerPreviewSize,
  required Size viewportSize,
}) {
  if (controllerPreviewSize.isEmpty || viewportSize.isEmpty) {
    return controllerPreviewSize;
  }

  final previewIsPortrait =
      controllerPreviewSize.height >= controllerPreviewSize.width;
  final viewportIsPortrait = viewportSize.height >= viewportSize.width;
  if (previewIsPortrait == viewportIsPortrait) {
    return controllerPreviewSize;
  }
  return Size(controllerPreviewSize.height, controllerPreviewSize.width);
}
