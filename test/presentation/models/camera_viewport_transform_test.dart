import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/presentation/models/camera_viewport_transform.dart';

void main() {
  group('CameraViewportTransform', () {
    test('maps uncropped portrait detector points for a back camera', () {
      final transform = CameraViewportTransform.cover(
        sourceSize: const Size(720, 1280),
        viewportSize: const Size(360, 640),
      );

      expect(transform.project(const Offset(360, 640)), const Offset(180, 320));
      expect(transform.project(Offset.zero), Offset.zero);
      expect(
          transform.project(const Offset(720, 1280)), const Offset(360, 640));
    });

    test('maps portrait cover crop from a landscape detector frame', () {
      final transform = CameraViewportTransform.cover(
        sourceSize: const Size(1280, 720),
        viewportSize: const Size(360, 640),
      );

      expect(transform.sourceRect.left, closeTo(437.5, 0.001));
      expect(transform.sourceRect.width, closeTo(405, 0.001));
      expect(
        transform.project(const Offset(437.5, 0)),
        closeToOffset(const Offset(0, 0)),
      );
      expect(
        transform.project(const Offset(842.5, 720)),
        closeToOffset(const Offset(360, 640)),
      );
    });

    test('mirrors front-camera overlay projection exactly once', () {
      final back = CameraViewportTransform.cover(
        sourceSize: const Size(1280, 720),
        viewportSize: const Size(360, 640),
      );
      final front = CameraViewportTransform.cover(
        sourceSize: const Size(1280, 720),
        viewportSize: const Size(360, 640),
        mirrorHorizontally: true,
      );

      const sourcePoint = Offset(538.75, 360);
      final backPoint = back.project(sourcePoint);
      final frontPoint = front.project(sourcePoint);

      expect(backPoint.dx, closeTo(90, 0.001));
      expect(frontPoint.dx, closeTo(270, 0.001));
      expect(frontPoint.dy, closeTo(backPoint.dy, 0.001));
    });

    test('maps landscape cover crop from a portrait detector frame', () {
      final transform = CameraViewportTransform.cover(
        sourceSize: const Size(720, 1280),
        viewportSize: const Size(640, 360),
      );

      expect(transform.sourceRect.top, closeTo(437.5, 0.001));
      expect(transform.sourceRect.height, closeTo(405, 0.001));
      expect(
        transform.project(const Offset(0, 437.5)),
        closeToOffset(const Offset(0, 0)),
      );
      expect(
        transform.project(const Offset(720, 842.5)),
        closeToOffset(const Offset(640, 360)),
      );
    });

    test('uses detector dimensions after native rotation', () {
      expect(
        detectorImageSizeForRotation(const Size(1920, 1080), 90),
        const Size(1080, 1920),
      );
      expect(
        detectorImageSizeForRotation(const Size(1920, 1080), 270),
        const Size(1080, 1920),
      );
      expect(
        detectorImageSizeForRotation(const Size(1920, 1080), 180),
        const Size(1920, 1080),
      );
    });

    test('normalizes portrait display geometry from a landscape sensor frame',
        () {
      final geometry = CameraDisplayGeometry.fromCameraFrame(
        rawImageSize: const Size(1920, 1080),
        controllerPreviewSize: const Size(1280, 720),
        rotationDegrees: 90,
        mirrorHorizontally: false,
      );

      expect(geometry.detectorImageSize, const Size(1080, 1920));
      expect(geometry.previewSourceSize, const Size(720, 1280));

      final transform = geometry.transformFor(
        viewportSize: const Size(360, 640),
      );
      expect(
          transform.project(const Offset(540, 120)),
          closeToOffset(
            const Offset(180, 40),
          ));
      expect(
          transform.project(const Offset(540, 1800)),
          closeToOffset(
            const Offset(180, 600),
          ));
    });

    test('applies front camera mirror after portrait normalization', () {
      final back = CameraDisplayGeometry.fromCameraFrame(
        rawImageSize: const Size(1920, 1080),
        controllerPreviewSize: const Size(1280, 720),
        rotationDegrees: 90,
        mirrorHorizontally: false,
      ).transformFor(viewportSize: const Size(360, 640));
      final front = CameraDisplayGeometry.fromCameraFrame(
        rawImageSize: const Size(1920, 1080),
        controllerPreviewSize: const Size(1280, 720),
        rotationDegrees: 90,
        mirrorHorizontally: true,
      ).transformFor(viewportSize: const Size(360, 640));

      final backPoint = back.project(const Offset(270, 960));
      final frontPoint = front.project(const Offset(270, 960));

      expect(backPoint.dx, closeTo(90, 0.001));
      expect(frontPoint.dx, closeTo(270, 0.001));
      expect(frontPoint.dy, closeTo(backPoint.dy, 0.001));
    });

    test('orients camera preview source size to the viewport', () {
      expect(
        cameraPreviewSourceSizeForViewport(
          controllerPreviewSize: const Size(1280, 720),
          viewportSize: const Size(360, 640),
        ),
        const Size(720, 1280),
      );
      expect(
        cameraPreviewSourceSizeForViewport(
          controllerPreviewSize: const Size(1280, 720),
          viewportSize: const Size(640, 360),
        ),
        const Size(1280, 720),
      );
    });

    test('orients camera preview source size to detector geometry', () {
      expect(
        cameraPreviewSourceSizeForDetector(
          controllerPreviewSize: const Size(1280, 720),
          detectorImageSize: const Size(405, 720),
        ),
        const Size(720, 1280),
      );
      expect(
        cameraPreviewSourceSizeForDetector(
          controllerPreviewSize: const Size(1280, 720),
          detectorImageSize: const Size(720, 405),
        ),
        const Size(1280, 720),
      );
    });
  });
}

Matcher closeToOffset(Offset expected) {
  return predicate<Offset>(
    (actual) =>
        (actual.dx - expected.dx).abs() < 0.001 &&
        (actual.dy - expected.dy).abs() < 0.001,
    'is within 0.001 of $expected',
  );
}
