import 'dart:math' as math;
import 'dart:ui';

import '../../domain/scan_pass/real_match_replay.dart';

enum ReplayPitchView { context, close, full, coaching }

class ReplayPitchGeometry {
  // Compatibility defaults for callers that do not yet provide scene data.
  static const double cameraMinX = -5;
  static const double cameraMaxX = 56;
  static const double cameraMinY = -5;
  static const double cameraMaxY = 35;

  final Size size;
  final bool rotated;
  final double scale;
  final Offset origin;
  final RealMatchReplayCamera camera;
  final int attackDirection;
  final double worldWidth;
  final double worldHeight;
  final double topInset;
  final double bottomInset;

  const ReplayPitchGeometry._({
    required this.size,
    required this.rotated,
    required this.scale,
    required this.origin,
    required this.camera,
    required this.attackDirection,
    required this.worldWidth,
    required this.worldHeight,
    required this.topInset,
    required this.bottomInset,
  });

  factory ReplayPitchGeometry.forSize(
    Size size, {
    RealMatchReplayCamera camera = const RealMatchReplayCamera(
      minX: cameraMinX,
      maxX: cameraMaxX,
      minY: cameraMinY,
      maxY: cameraMaxY,
    ),
    int attackDirection = 1,
    ReplayPitchView view = ReplayPitchView.context,
    double pitchLength = 105,
    double pitchWidth = 68,
    double? headerInset,
    double bottomInset = 34,
  }) {
    if (attackDirection.abs() != 1) {
      throw ArgumentError.value(
        attackDirection,
        'attackDirection',
        'must be -1 or 1',
      );
    }
    final rotated = size.width < 540;
    final topInset =
        headerInset ?? (rotated && size.height >= 520 ? 92.0 : 68.0);
    final area = Rect.fromLTWH(
      rotated ? 10 : 16,
      topInset,
      math.max(1, size.width - (rotated ? 20 : 32)),
      math.max(1, size.height - topInset - bottomInset),
    );
    final selected = switch (view) {
      ReplayPitchView.full => RealMatchReplayCamera(
          minX: -pitchLength / 2 - 3,
          maxX: pitchLength / 2 + 3,
          minY: -pitchWidth / 2 - 2,
          maxY: pitchWidth / 2 + 2,
        ),
      ReplayPitchView.context => _expandedCamera(
          camera,
          minimumWidth: math.min(65, pitchLength + 6),
          minimumHeight: math.min(48, pitchWidth + 4),
          pitchLength: pitchLength,
          pitchWidth: pitchWidth,
        ),
      ReplayPitchView.close => _expandedCamera(
          camera,
          minimumWidth: math.min(44, pitchLength + 6),
          minimumHeight: math.min(34, pitchWidth + 4),
          maximumWidth: 52,
          maximumHeight: 40,
          pitchLength: pitchLength,
          pitchWidth: pitchWidth,
        ),
      // Coaching cameras are already derived from the recorded actors and
      // ball. Preserve their deliberate tight bounds instead of applying the
      // broad context minimums used by the old manual viewer.
      ReplayPitchView.coaching => _expandedCamera(
          camera,
          minimumWidth: math.min(18, pitchLength + 6),
          minimumHeight: math.min(14, pitchWidth + 4),
          pitchLength: pitchLength,
          pitchWidth: pitchWidth,
        ),
    };
    final normalizedMinX = math.min(
      selected.minX * attackDirection,
      selected.maxX * attackDirection,
    );
    final normalizedMaxX = math.max(
      selected.minX * attackDirection,
      selected.maxX * attackDirection,
    );
    final attackSpan = normalizedMaxX - normalizedMinX;
    final lateralSpan = selected.height;
    final worldWidth = rotated ? lateralSpan : attackSpan;
    final worldHeight = rotated ? attackSpan : lateralSpan;
    final scale = math.min(area.width / worldWidth, area.height / worldHeight);
    return ReplayPitchGeometry._(
      size: size,
      rotated: rotated,
      scale: scale,
      camera: selected,
      attackDirection: attackDirection,
      worldWidth: worldWidth,
      worldHeight: worldHeight,
      topInset: topInset,
      bottomInset: bottomInset,
      origin: Offset(
        area.left + (area.width - worldWidth * scale) / 2,
        area.top + (area.height - worldHeight * scale) / 2,
      ),
    );
  }

  Offset project(double x, double y, [double z = 0]) {
    final attackX = x * attackDirection;
    final minAttackX = math.min(
      camera.minX * attackDirection,
      camera.maxX * attackDirection,
    );
    final maxAttackX = math.max(
      camera.minX * attackDirection,
      camera.maxX * attackDirection,
    );
    return rotated
        ? Offset(
            origin.dx + (y - camera.minY) * scale,
            origin.dy + (maxAttackX - attackX) * scale - z * scale * .85,
          )
        : Offset(
            origin.dx + (attackX - minAttackX) * scale,
            origin.dy + (camera.maxY - y) * scale - z * scale * .85,
          );
  }

  Rect get pitchArea => Rect.fromLTWH(
        origin.dx,
        origin.dy,
        worldWidth * scale,
        worldHeight * scale,
      );

  /// The canvas also shows field beyond the fitted scene in its side gutters.
  /// Describe that actual visible area, rather than only the fitted crop.
  RealMatchReplayCamera get visibleCamera {
    final minAttackX = math.min(
      camera.minX * attackDirection,
      camera.maxX * attackDirection,
    );
    final maxAttackX = math.max(
      camera.minX * attackDirection,
      camera.maxX * attackDirection,
    );
    Offset world(Offset point) => rotated
        ? Offset(
            (maxAttackX - (point.dy - origin.dy) / scale) * attackDirection,
            camera.minY + (point.dx - origin.dx) / scale,
          )
        : Offset(
            (minAttackX + (point.dx - origin.dx) / scale) * attackDirection,
            camera.maxY - (point.dy - origin.dy) / scale,
          );
    final a = world(Offset(0, topInset));
    final b = world(Offset(size.width, size.height - bottomInset));
    return RealMatchReplayCamera(
      minX: math.min(a.dx, b.dx),
      maxX: math.max(a.dx, b.dx),
      minY: math.min(a.dy, b.dy),
      maxY: math.max(a.dy, b.dy),
    );
  }

  Rect zoomRect({required bool visible, required bool finalPhase}) {
    if (!visible) return Rect.zero;
    const width = 132.0;
    const height = 190.0;
    final left = rotated ? 9.0 : 12.0;
    final top = rotated && finalPhase ? size.height - height - 62 : 88.0;
    return Rect.fromLTWH(left, top, width, height);
  }

  static RealMatchReplayCamera _expandedCamera(
    RealMatchReplayCamera source, {
    required double minimumWidth,
    required double minimumHeight,
    required double pitchLength,
    required double pitchWidth,
    double? maximumWidth,
    double? maximumHeight,
  }) {
    final width = math.max(
        minimumWidth,
        maximumWidth == null
            ? source.width
            : math.min(source.width, maximumWidth));
    final height = math.max(
        minimumHeight,
        maximumHeight == null
            ? source.height
            : math.min(source.height, maximumHeight));
    final halfWidth = width / 2;
    final halfHeight = height / 2;
    // A recorded sequence may finish out of play. Respect its source camera
    // extent so the final ball path stays visible beyond a touch/goal line.
    final worldMinX = math.min(-pitchLength / 2 - 3, source.minX);
    final worldMaxX = math.max(pitchLength / 2 + 3, source.maxX);
    final worldMinY = math.min(-pitchWidth / 2 - 2, source.minY);
    final worldMaxY = math.max(pitchWidth / 2 + 2, source.maxY);
    double centered(double preferred, double minimum, double maximum) {
      if (minimum >= maximum) return (minimum + maximum) / 2;
      return preferred.clamp(minimum, maximum);
    }

    final centerX = centered(
      (source.minX + source.maxX) / 2,
      worldMinX + halfWidth,
      worldMaxX - halfWidth,
    );
    final centerY = centered(
      (source.minY + source.maxY) / 2,
      worldMinY + halfHeight,
      worldMaxY - halfHeight,
    );
    return RealMatchReplayCamera(
      minX: centerX - halfWidth,
      maxX: centerX + halfWidth,
      minY: centerY - halfHeight,
      maxY: centerY + halfHeight,
    );
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
    double bottomInset = bottomControlsInset,
  }) {
    if (labelSizes.length != anchors.length) {
      throw ArgumentError('Each replay label needs one anchor.');
    }
    final placed = <Rect>[];
    final blocked = <Rect>[...obstacles];
    for (var index = 0; index < labelSizes.length; index++) {
      final size = labelSizes[index];
      if (size.width + 16 > stageSize.width ||
          topInset + size.height + bottomInset > stageSize.height) {
        placed.add(Rect.zero);
        continue;
      }
      final anchor = anchors[index];
      final candidates = <Offset>[
        Offset(anchor.dx + 17, anchor.dy - size.height - 16),
        Offset(anchor.dx - size.width - 17, anchor.dy - size.height - 16),
        Offset(anchor.dx - size.width / 2, anchor.dy + 23),
      ];
      for (var y = topInset + 6;
          y <= stageSize.height - bottomInset - size.height;
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
          stageSize.height - size.height - bottomInset,
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
            y <= stageSize.height - bottomInset - size.height;
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
