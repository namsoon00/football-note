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
    if (sourceSize.isEmpty || viewportSize.isEmpty) {
      return CameraViewportTransform._(
        sourceSize: sourceSize,
        viewportSize: viewportSize,
        mirrorHorizontally: mirrorHorizontally,
        sourceRect: Rect.zero,
        destinationRect: Rect.zero,
      );
    }

    final fitted = applyBoxFit(BoxFit.cover, sourceSize, viewportSize);
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

Size detectorImageSizeForRotation(Size rawImageSize, int rotationDegrees) {
  final normalizedRotation = ((rotationDegrees % 360) + 360) % 360;
  if (normalizedRotation == 90 || normalizedRotation == 270) {
    return Size(rawImageSize.height, rawImageSize.width);
  }
  return rawImageSize;
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
