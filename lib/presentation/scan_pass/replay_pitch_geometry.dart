import 'dart:math' as math;
import 'dart:ui';

class ReplayPitchGeometry {
  static const double cameraMinX = -5;
  static const double cameraMaxX = 56;
  static const double cameraMinY = -5;
  static const double cameraMaxY = 35;

  final Size size;
  final bool rotated;
  final double scale;
  final Offset origin;

  const ReplayPitchGeometry._({
    required this.size,
    required this.rotated,
    required this.scale,
    required this.origin,
  });

  factory ReplayPitchGeometry.forSize(Size size) {
    final rotated = size.width < 490;
    final headerInset = rotated && size.height >= 520 ? 100.0 : 72.0;
    final area = Rect.fromLTWH(
      18,
      headerInset,
      math.max(1, size.width - 36),
      math.max(1, size.height - headerInset - 40),
    );
    final worldWidth = rotated ? 40.0 : 61.0;
    final worldHeight = rotated ? 61.0 : 40.0;
    final scale = math.min(area.width / worldWidth, area.height / worldHeight);
    return ReplayPitchGeometry._(
      size: size,
      rotated: rotated,
      scale: scale,
      origin: Offset(
        area.left + (area.width - worldWidth * scale) / 2,
        area.top + (area.height - worldHeight * scale) / 2,
      ),
    );
  }

  Offset project(double x, double y, [double z = 0]) => rotated
      ? Offset(
          origin.dx + (y - cameraMinY) * scale,
          origin.dy + (cameraMaxX - x) * scale - z * scale * .85,
        )
      : Offset(
          origin.dx + (x - cameraMinX) * scale,
          origin.dy + (cameraMaxY - y) * scale - z * scale * .85,
        );

  Rect zoomRect({required bool visible, required bool finalPhase}) {
    if (!visible) return Rect.zero;
    const width = 132.0;
    const height = 190.0;
    final left = rotated ? 9.0 : 12.0;
    final top = rotated && finalPhase ? size.height - height - 62 : 88.0;
    return Rect.fromLTWH(left, top, width, height);
  }
}

class ReplayLabelLayout {
  // Keep the pitch footer and the close-up toggle free of painted callouts.
  static const double bottomControlsInset = 96;

  static List<Rect> place({
    required Size stageSize,
    required List<Size> labelSizes,
    required List<Offset> anchors,
    required List<Rect> obstacles,
    List<Rect> protectedObstacles = const <Rect>[],
    double topInset = 76,
  }) {
    if (labelSizes.length != anchors.length) {
      throw ArgumentError('Each replay label needs one anchor.');
    }
    final placed = <Rect>[];
    final blocked = <Rect>[...obstacles];
    for (var index = 0; index < labelSizes.length; index++) {
      final size = labelSizes[index];
      final anchor = anchors[index];
      final candidates = <Offset>[
        Offset(anchor.dx + 17, anchor.dy - size.height - 16),
        Offset(anchor.dx - size.width - 17, anchor.dy - size.height - 16),
        Offset(anchor.dx - size.width / 2, anchor.dy + 23),
      ];
      for (var y = topInset + 6;
          y <= stageSize.height - bottomControlsInset - size.height;
          y += 18) {
        candidates.addAll(<Offset>[
          Offset(10, y),
          Offset((stageSize.width - size.width) / 2, y),
          Offset(stageSize.width - size.width - 10, y),
        ]);
      }
      final rects = candidates.map((candidate) {
        final left = candidate.dx.clamp(8.0, stageSize.width - size.width - 8);
        final top = candidate.dy.clamp(
          topInset,
          stageSize.height - size.height - bottomControlsInset,
        );
        return Rect.fromLTWH(left, top, size.width, size.height);
      }).toList(growable: false);
      double score(Rect rect) {
        var overlap = 0.0;
        for (final other in blocked) {
          final intersection = rect.inflate(4).intersect(other.inflate(3));
          if (!intersection.isEmpty) {
            overlap += intersection.width * intersection.height * 100;
          }
        }
        return overlap + (rect.center - anchor).distance;
      }

      // A label may move farther from its player to keep the ball, close-up
      // and previously placed labels visible. Body overlap remains a cost.
      final protected = <Rect>[...protectedObstacles, ...placed];
      bool isLegal(Rect rect) => protected.every(
            (other) =>
                other.isEmpty || !rect.inflate(4).overlaps(other.inflate(3)),
          );
      final legal = rects.where(isLegal).toList();
      if (legal.isEmpty) {
        // Large text can leave a usable gap between the ball and another
        // label that the coarse grid misses. Search that gap before hiding.
        for (var y = topInset;
            y <= stageSize.height - bottomControlsInset - size.height;
            y += 4) {
          for (final x in <double>[
            8,
            (stageSize.width - size.width) / 2,
            stageSize.width - size.width - 8,
          ]) {
            final rect = Rect.fromLTWH(x, y, size.width, size.height);
            if (isLegal(rect)) legal.add(rect);
          }
        }
      }
      if (legal.isEmpty) {
        placed.add(Rect.zero);
        continue;
      }
      legal.sort((a, b) => score(a).compareTo(score(b)));
      final selected = legal.first;
      placed.add(selected);
      blocked.add(selected);
    }
    return placed;
  }
}
