part of 'scan_pass_game_screen.dart';

class SpatialActionPictogramAssetSpec {
  final SpatialOnPitchActionKind kind;
  final String assetPath;
  final Offset contactAnchor;

  const SpatialActionPictogramAssetSpec({
    required this.kind,
    required this.assetPath,
    required this.contactAnchor,
  });
}

class SpatialActionPictogramAssets {
  static const int decodedSize = 128;

  static const Map<SpatialOnPitchActionKind, SpatialActionPictogramAssetSpec>
      specs = <SpatialOnPitchActionKind, SpatialActionPictogramAssetSpec>{
    SpatialOnPitchActionKind.carry: SpatialActionPictogramAssetSpec(
      kind: SpatialOnPitchActionKind.carry,
      assetPath: 'assets/scan_pass_actions/carry.png',
      contactAnchor: Offset(.72, .91),
    ),
    SpatialOnPitchActionKind.directionChange: SpatialActionPictogramAssetSpec(
      kind: SpatialOnPitchActionKind.directionChange,
      assetPath: 'assets/scan_pass_actions/direction_change.png',
      contactAnchor: Offset(.58, .825),
    ),
    SpatialOnPitchActionKind.receive: SpatialActionPictogramAssetSpec(
      kind: SpatialOnPitchActionKind.receive,
      assetPath: 'assets/scan_pass_actions/receive.png',
      contactAnchor: Offset(.16, .91),
    ),
    SpatialOnPitchActionKind.header: SpatialActionPictogramAssetSpec(
      kind: SpatialOnPitchActionKind.header,
      assetPath: 'assets/scan_pass_actions/header.png',
      contactAnchor: Offset(.778, .15),
    ),
    SpatialOnPitchActionKind.oneTouchPass: SpatialActionPictogramAssetSpec(
      kind: SpatialOnPitchActionKind.oneTouchPass,
      assetPath: 'assets/scan_pass_actions/one_touch_pass.png',
      contactAnchor: Offset(.75, .91),
    ),
  };

  static SpatialActionPictogramAssetSpec spec(
    SpatialOnPitchActionKind kind,
  ) =>
      specs[kind]!;

  static ImageProvider imageProvider(SpatialOnPitchActionKind kind) =>
      ResizeImage.resizeIfNeeded(
        decodedSize,
        decodedSize,
        AssetImage(spec(kind).assetPath),
      );
}

class SpatialActionGesturePhase {
  final double progress;
  final double elapsedSourceSeconds;
  final bool reducedMotion;

  const SpatialActionGesturePhase({
    required this.progress,
    required this.elapsedSourceSeconds,
    required this.reducedMotion,
  });
}

class SpatialActionMotion {
  static const double durationSeconds = .72;
  static const double receiveContactFraction = .7;
  static const double oneTouchContactFraction = .36;

  static int sourceStartFrame(SpatialOnPitchAction action) =>
      switch (action.kind) {
        SpatialOnPitchActionKind.carry =>
          action.evidence.geometry.carryOnsetFrame!,
        SpatialOnPitchActionKind.directionChange =>
          action.evidence.geometry.directionChangeOnsetFrame!,
        SpatialOnPitchActionKind.receive ||
        SpatialOnPitchActionKind.header =>
          action.evidence.sourceStartFrame,
        SpatialOnPitchActionKind.oneTouchPass => action.evidence.sourceEndFrame,
      };

  static SpatialActionGesturePhase phaseAt({
    required SpatialOnPitchAction action,
    required SpatialLibraryScene scene,
    required RealMatchReplayData data,
    required double time,
    required bool reducedMotion,
  }) {
    final currentSourceFrame =
        scene.startFrame + time.clamp(0.0, data.duration) * data.fps;
    final elapsed = math.max(
      0.0,
      (currentSourceFrame - sourceStartFrame(action)) / data.fps,
    );
    final progress = reducedMotion
        ? switch (action.kind) {
            SpatialOnPitchActionKind.receive => receiveContactFraction,
            SpatialOnPitchActionKind.oneTouchPass => oneTouchContactFraction,
            _ => 1.0,
          }
        : (elapsed / durationSeconds).clamp(0.0, 1.0).toDouble();
    return SpatialActionGesturePhase(
      progress: progress,
      elapsedSourceSeconds: elapsed,
      reducedMotion: reducedMotion,
    );
  }
}

class SpatialActionGestureGeometry {
  final Offset ballCenter;
  final Offset contactCenter;
  final double ballRadius;
  final List<Path> routePaths;
  final List<Path> arrowheads;
  final int contactCount;
  final bool holdsAtContact;
  final bool loops;

  const SpatialActionGestureGeometry({
    required this.ballCenter,
    required this.contactCenter,
    required this.ballRadius,
    this.routePaths = const <Path>[],
    this.arrowheads = const <Path>[],
    this.contactCount = 1,
    this.holdsAtContact = false,
    this.loops = false,
  });

  Rect get ballBounds =>
      Rect.fromCircle(center: ballCenter, radius: ballRadius);
}

class SpatialActionGesturePainter extends CustomPainter {
  final SpatialOnPitchActionKind kind;
  final SpatialActionGesturePhase phase;
  final bool foreground;
  final bool highlighted;

  const SpatialActionGesturePainter({
    required this.kind,
    required this.phase,
    required this.foreground,
    this.highlighted = false,
  });

  SpatialActionGestureGeometry gestureGeometry(Size size) {
    Offset point(double x, double y) => Offset(x * size.width, y * size.height);
    final spec = SpatialActionPictogramAssets.spec(kind);
    final contact = point(spec.contactAnchor.dx, spec.contactAnchor.dy);
    final ballRadius = math.min(size.width, size.height) * .077;
    final routes = <Path>[];
    final arrows = <Path>[];
    var ball = contact;
    var holdsAtContact = true;

    Path arrowhead(Offset tip, Offset direction) {
      final unit = direction / math.max(direction.distance, .001);
      final normal = Offset(-unit.dy, unit.dx);
      final length = math.min(size.width, size.height) * .105;
      final halfWidth = length * .46;
      final base = tip - unit * length;
      return Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(
          base.dx + normal.dx * halfWidth,
          base.dy + normal.dy * halfWidth,
        )
        ..lineTo(
          base.dx - normal.dx * halfWidth,
          base.dy - normal.dy * halfWidth,
        )
        ..close();
    }

    switch (kind) {
      case SpatialOnPitchActionKind.carry:
        break;
      case SpatialOnPitchActionKind.directionChange:
        final start = point(.14, .72);
        final end = point(.83, .52);
        routes.add(
          Path()
            ..moveTo(start.dx, start.dy)
            ..quadraticBezierTo(
              contact.dx - size.width * .12,
              contact.dy + size.height * .04,
              contact.dx,
              contact.dy,
            )
            ..quadraticBezierTo(
              contact.dx + size.width * .15,
              contact.dy - size.height * .02,
              end.dx,
              end.dy,
            ),
        );
        arrows.add(arrowhead(end, end - contact));
        break;
      case SpatialOnPitchActionKind.receive:
        final start = point(.09, .51);
        routes.add(
          Path()
            ..moveTo(start.dx, start.dy)
            ..quadraticBezierTo(
              size.width * .12,
              size.height * .7,
              contact.dx,
              contact.dy,
            ),
        );
        if (!phase.reducedMotion &&
            phase.progress < SpatialActionMotion.receiveContactFraction) {
          final arrival = _smoothStep(
            phase.progress / SpatialActionMotion.receiveContactFraction,
          );
          ball = Offset.lerp(start, contact, arrival)!;
          holdsAtContact = false;
        }
        break;
      case SpatialOnPitchActionKind.header:
        final start = point(.93, .08);
        routes.add(
          Path()
            ..moveTo(start.dx, start.dy)
            ..lineTo(contact.dx, contact.dy),
        );
        break;
      case SpatialOnPitchActionKind.oneTouchPass:
        final start = point(.08, .57);
        final end = point(.91, .5);
        routes.add(
          Path()
            ..moveTo(start.dx, start.dy)
            ..quadraticBezierTo(
              size.width * .34,
              size.height * .7,
              contact.dx,
              contact.dy,
            )
            ..quadraticBezierTo(
              size.width * .8,
              size.height * .76,
              end.dx,
              end.dy,
            ),
        );
        arrows.add(arrowhead(end, end - contact));
        if (phase.reducedMotion) {
          ball = contact;
        } else if (phase.progress <=
            SpatialActionMotion.oneTouchContactFraction) {
          final arrival = _smoothStep(
            phase.progress / SpatialActionMotion.oneTouchContactFraction,
          );
          ball = Offset.lerp(start, contact, arrival)!;
        } else {
          final departure = _smoothStep(
            (phase.progress - SpatialActionMotion.oneTouchContactFraction) /
                (1 - SpatialActionMotion.oneTouchContactFraction),
          );
          ball = Offset.lerp(contact, end, departure)!;
        }
        holdsAtContact = phase.reducedMotion ||
            (phase.progress - SpatialActionMotion.oneTouchContactFraction)
                    .abs() <
                .0001;
        break;
    }

    return SpatialActionGestureGeometry(
      ballCenter: ball,
      contactCenter: contact,
      ballRadius: ballRadius,
      routePaths: routes,
      arrowheads: arrows,
      holdsAtContact: holdsAtContact,
    );
  }

  static double _smoothStep(double value) {
    final t = value.clamp(0.0, 1.0);
    return (t * t * (3 - 2 * t)).toDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = gestureGeometry(size);
    if (!foreground) {
      final bounds = Offset.zero & size;
      final shape = RRect.fromRectAndRadius(
        bounds.deflate(.8),
        Radius.circular(math.min(size.width, size.height) * .2),
      );
      canvas.drawRRect(shape, Paint()..color = const Color(0xF21A2420));
      canvas.drawRRect(
        shape,
        Paint()
          ..color =
              highlighted ? const Color(0xFFFFFFFF) : const Color(0xFFD8E2DD)
          ..style = PaintingStyle.stroke
          ..strokeWidth = highlighted ? 2 : 1.15,
      );
      final routePaint = Paint()
        ..color = const Color(0xFFC8D3CE).withValues(alpha: .88)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.min(size.width, size.height) * .035
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      for (final route in geometry.routePaths) {
        canvas.drawPath(route, routePaint);
      }
      return;
    }

    final arrowPaint = Paint()..color = const Color(0xFFE3EAE6);
    for (final arrowhead in geometry.arrowheads) {
      canvas.drawPath(arrowhead, arrowPaint);
    }
    _drawFootball(
      canvas,
      geometry.ballCenter,
      geometry.ballRadius,
    );
  }

  static void _drawFootball(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFFF8FAF9));
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF101311)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.65, radius * .22),
    );
    final panel = Path();
    for (var index = 0; index < 5; index++) {
      final angle = -math.pi / 2 + index * math.pi * 2 / 5;
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius * .42);
      if (index == 0) {
        panel.moveTo(point.dx, point.dy);
      } else {
        panel.lineTo(point.dx, point.dy);
      }
    }
    panel.close();
    canvas.drawPath(panel, Paint()..color = const Color(0xFF141715));
    final seam = Paint()
      ..color = const Color(0xFF141715)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.42, radius * .12);
    for (var index = 0; index < 5; index++) {
      final angle = -math.pi / 2 + index * math.pi * 2 / 5;
      final inner =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius * .42);
      final outer =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius * .84);
      canvas.drawLine(inner, outer, seam);
    }
  }

  @override
  bool shouldRepaint(covariant SpatialActionGesturePainter oldDelegate) =>
      oldDelegate.kind != kind ||
      oldDelegate.phase.progress != phase.progress ||
      oldDelegate.phase.reducedMotion != phase.reducedMotion ||
      oldDelegate.foreground != foreground ||
      oldDelegate.highlighted != highlighted;
}

class SpatialActionPictogram extends StatelessWidget {
  final SpatialOnPitchActionKind kind;
  final SpatialActionGesturePhase phase;
  final bool highlighted;

  const SpatialActionPictogram({
    super.key,
    required this.kind,
    required this.phase,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        CustomPaint(
          painter: SpatialActionGesturePainter(
            kind: kind,
            phase: phase,
            foreground: false,
            highlighted: highlighted,
          ),
        ),
        Image(
          key: ValueKey<String>(
            'spatial-action-athlete-${kind.name}',
          ),
          image: SpatialActionPictogramAssets.imageProvider(kind),
          color: const Color(0xFFF4F8F5),
          colorBlendMode: BlendMode.srcIn,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          gaplessPlayback: true,
          excludeFromSemantics: true,
        ),
        CustomPaint(
          painter: SpatialActionGesturePainter(
            kind: kind,
            phase: phase,
            foreground: true,
          ),
        ),
      ],
    );
  }
}

class SpatialActionIconGeometry {
  final int actorPlayerId;
  final SpatialOnPitchActionKind kind;
  final String eventId;
  final Rect visualRect;
  final Rect hitRect;
  final Rect actorBadgeRect;
  final int placementIndex;

  const SpatialActionIconGeometry({
    required this.actorPlayerId,
    required this.kind,
    required this.eventId,
    required this.visualRect,
    required this.hitRect,
    required this.actorBadgeRect,
    required this.placementIndex,
  });

  String get sourceIdentity => '$eventId:${kind.name}:$actorPlayerId';

  double get visualSize => visualRect.shortestSide;

  Rect get visualRectInsideHitTarget => visualRect.shift(-hitRect.topLeft);

  bool get hitTargetContainsVisual =>
      hitRect.contains(visualRect.topLeft) &&
      hitRect.contains(visualRect.bottomRight);

  double get attachmentDistance {
    final dx = math.max(
      0.0,
      math.max(
        actorBadgeRect.left - visualRect.right,
        visualRect.left - actorBadgeRect.right,
      ),
    );
    final dy = math.max(
      0.0,
      math.max(
        actorBadgeRect.top - visualRect.bottom,
        visualRect.top - actorBadgeRect.bottom,
      ),
    );
    return math.sqrt(dx * dx + dy * dy);
  }

  static Rect clampTarget(Rect target, Rect bounds) {
    final dx = target.left < bounds.left
        ? bounds.left - target.left
        : target.right > bounds.right
            ? bounds.right - target.right
            : 0.0;
    final dy = target.top < bounds.top
        ? bounds.top - target.top
        : target.bottom > bounds.bottom
            ? bounds.bottom - target.bottom
            : 0.0;
    return target.shift(Offset(dx, dy));
  }
}

class _SpatialActionIconControl extends StatefulWidget {
  final SpatialActionIconGeometry geometry;
  final SpatialActionGesturePhase gesturePhase;
  final String message;
  final VoidCallback onInspect;

  const _SpatialActionIconControl({
    super.key,
    required this.geometry,
    required this.gesturePhase,
    required this.message,
    required this.onInspect,
  });

  @override
  State<_SpatialActionIconControl> createState() =>
      _SpatialActionIconControlState();
}

class _SpatialActionIconControlState extends State<_SpatialActionIconControl> {
  final _tooltipKey = GlobalKey<TooltipState>();
  final _focusNode = FocusNode();
  bool _hovered = false;
  bool _focused = false;
  bool _pinned = false;

  void _show({bool pinned = false}) {
    if (pinned) _pinned = true;
    _tooltipKey.currentState?.ensureTooltipVisible();
    if (mounted) setState(() {});
  }

  void _dismiss() {
    Tooltip.dismissAllToolTips();
    _pinned = false;
    if (mounted) setState(() {});
  }

  void _activate() {
    widget.onInspect();
    _show(pinned: true);
  }

  void _handleFocus(bool focused) {
    _focused = focused;
    if (focused) {
      _show();
    } else if (!_hovered && !_pinned) {
      _dismiss();
    } else if (mounted) {
      setState(() {});
    }
  }

  void _handleEnter(PointerEnterEvent event) {
    _hovered = true;
    _show();
  }

  void _handleExit(PointerExitEvent event) {
    _hovered = false;
    if (!_focused && !_pinned) {
      _dismiss();
    } else if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final geometry = widget.geometry;
    final preferBelow =
        geometry.visualRect.center.dy >= geometry.actorBadgeRect.center.dy;
    return Semantics(
      key: ValueKey<String>(
        'spatial-action-control-${geometry.sourceIdentity}',
      ),
      container: true,
      button: true,
      label: widget.message,
      onTap: _activate,
      child: Tooltip(
        key: _tooltipKey,
        message: widget.message,
        excludeFromSemantics: true,
        triggerMode: TooltipTriggerMode.manual,
        preferBelow: preferBelow,
        verticalOffset: 18,
        child: FocusableActionDetector(
          focusNode: _focusNode,
          mouseCursor: SystemMouseCursors.click,
          onFocusChange: _handleFocus,
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
          },
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (intent) {
                _activate();
                return null;
              },
            ),
            DismissIntent: CallbackAction<DismissIntent>(
              onInvoke: (intent) {
                _dismiss();
                return null;
              },
            ),
          },
          child: MouseRegion(
            onEnter: _handleEnter,
            onExit: _handleExit,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTap: () {
                _focusNode.requestFocus();
                _activate();
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned.fromRect(
                    rect: geometry.visualRectInsideHitTarget,
                    child: ExcludeSemantics(
                      child: SpatialActionPictogram(
                        key: ValueKey<String>(
                          'spatial-action-glyph-${geometry.sourceIdentity}',
                        ),
                        kind: geometry.kind,
                        phase: widget.gesturePhase,
                        highlighted: _hovered || _focused,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
