part of 'scan_pass_game_screen.dart';

class _ReplayActionDetailSheet extends StatefulWidget {
  final RealMatchReplayData data;
  final RealMatchReplayActionDetail detail;
  final double openedAtSourceTime;

  const _ReplayActionDetailSheet({
    required this.data,
    required this.detail,
    required this.openedAtSourceTime,
  });

  @override
  State<_ReplayActionDetailSheet> createState() =>
      _ReplayActionDetailSheetState();
}

class _ReplayActionDetailSheetState extends State<_ReplayActionDetailSheet>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;
  double get _time => widget.detail.sourceTimeAt(_controller.value);
  bool get _playing => _controller.isAnimating;
  bool get _finished => _controller.value >= 1 - 1e-9;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        microseconds: (widget.detail.duration /
                RealMatchReplayActionDetail.playbackRate *
                Duration.microsecondsPerSecond)
            .round(),
      ),
      animationBehavior: AnimationBehavior.preserve,
    )
      ..addListener(_handleTick)
      ..forward();
  }

  void _handleTick() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _pause();
    }
  }

  void _pause() {
    if (!_playing) return;
    _controller.stop();
    if (mounted) setState(() {});
  }

  void _togglePlayback() {
    if (_playing) {
      _pause();
      return;
    }
    if (_finished) _controller.value = 0;
    _controller.forward();
    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller
      ..removeListener(_handleTick)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _ScanPassColors.of(context);
    final size = MediaQuery.sizeOf(context);
    final plan = RealMatchReplayCoachingPlan.forData(widget.data);
    final moment = plan.activeMomentAt(widget.data, widget.detail.step.time);
    final shortLandscape = size.width > size.height && size.height < 520;
    return Material(
      color: colors.surface,
      child: SizedBox(
        height: size.height * (shortLandscape ? 1 : .96),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            shortLandscape ? 8 : 12,
            8,
            shortLandscape ? 8 : 12,
            8,
          ),
          child: Column(children: [
            _buildHeader(colors),
            const SizedBox(height: 6),
            Expanded(
              child: (shortLandscape || size.width >= 900)
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                          Expanded(
                            flex: 3,
                            child: _buildCloseUp(plan, moment),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width:
                                math.min(250, math.max(205, size.width * .31)),
                            child: _buildSidePanel(colors, landscape: true),
                          ),
                        ])
                  : Column(children: [
                      _buildFidelity(colors),
                      const SizedBox(height: 7),
                      Expanded(child: _buildCloseUp(plan, moment)),
                      const SizedBox(height: 7),
                      SizedBox(
                          height: size.height < 700 ? 136 : 164,
                          child: _buildOverview(colors)),
                      const SizedBox(height: 7),
                      _buildPlaybackControl(),
                    ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeader(_ScanPassColors colors) => Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _detailTitle(_l10n, widget.detail.step.kind),
                key: const ValueKey<String>('replay-detail-title'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                _l10n.realMatchReplayActionDetailSlowRate,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: colors.muted),
              ),
            ],
          ),
        ),
        AppBarActionButton(
          key: const ValueKey<String>('replay-detail-close'),
          tooltip: _l10n.realMatchReplayActionDetailClose,
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          margin: EdgeInsets.zero,
        ),
      ]);

  Widget _buildSidePanel(
    _ScanPassColors colors, {
    required bool landscape,
  }) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _buildFidelity(colors),
        const SizedBox(height: 5),
        Expanded(child: _buildOverview(colors)),
        const SizedBox(height: 5),
        _buildPlaybackControl(),
      ]);

  Widget _buildFidelity(_ScanPassColors colors) {
    final pose = widget.detail.hasRecordedPose
        ? _l10n.realMatchReplayActionDetailRecordedPose
        : _l10n.realMatchReplayActionDetailSimplifiedPose;
    final height = widget.detail.ballHeightAvailable
        ? _l10n.realMatchReplayActionDetailHeightXyz
        : _l10n.realMatchReplayActionDetailHeightXy;
    return Column(
      key: const ValueKey<String>('replay-detail-fidelity'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ReplayDetailFact(icon: Icons.directions_run, label: pose),
        const SizedBox(height: 2),
        _ReplayDetailFact(icon: Icons.sports_soccer, label: height),
      ],
    );
  }

  Widget _buildCloseUp(
    RealMatchReplayCoachingPlan plan,
    RealMatchReplayCoachingMoment moment,
  ) {
    final cue = _detailCue(
      _l10n,
      widget.detail.step.kind,
      before: _time < widget.detail.step.time - 1e-9,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(children: [
        Positioned.fill(
          child: Semantics(
            image: true,
            label: widget.detail.hasRecordedPose
                ? _l10n.realMatchReplayActionDetailSemanticsRecorded(cue)
                : _l10n.realMatchReplayActionDetailSemanticsSimplified(cue),
            child: ExcludeSemantics(
              child: CustomPaint(
                key: const ValueKey<String>('replay-detail-pitch'),
                size: Size.infinite,
                painter: _RealMatchReplayPainter(
                  data: widget.data,
                  plan: plan,
                  moment: moment,
                  time: _time,
                  camera: widget.detail.camera,
                  cue: cue,
                  brightness: Theme.of(context).brightness,
                  textDirection: Directionality.of(context),
                  textScaler: MediaQuery.textScalerOf(context),
                  actionDetail: widget.detail,
                ),
              ),
            ),
          ),
        ),
        PositionedDirectional(
          start: 8,
          end: 8,
          top: 7,
          child: IgnorePointer(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF183B2E).withValues(alpha: .94),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    cue,
                    key: const ValueKey<String>('replay-detail-phase-cue'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFFF4F8ED),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ),
          ),
        ),
        PositionedDirectional(
          start: 8,
          bottom: 8,
          child: IgnorePointer(child: _buildPathLegend()),
        ),
      ]),
    );
  }

  Widget _buildPathLegend() {
    final style = Theme.of(context)
        .textTheme
        .labelSmall
        ?.copyWith(color: const Color(0xFFF4F8ED));
    return DecoratedBox(
      key: const ValueKey<String>('replay-detail-path-legend'),
      decoration: BoxDecoration(
        color: const Color(0xFF183B2E).withValues(alpha: .94),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.trending_flat, size: 16, color: Color(0xFFF5AC92)),
          const SizedBox(width: 4),
          Text(_l10n.realMatchReplayActionDetailBallPath, style: style),
          const SizedBox(width: 12),
          const Icon(Icons.more_horiz, size: 16, color: Color(0xFFD4EF9D)),
          const SizedBox(width: 4),
          Text(_l10n.realMatchReplayActionDetailPlayerPath, style: style),
        ]),
      ),
    );
  }

  Widget _buildOverview(_ScanPassColors colors) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _l10n.realMatchReplayActionDetailOverviewTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: colors.text, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Semantics(
                image: true,
                label: _l10n.realMatchReplayActionDetailOverviewSemantics,
                child: ExcludeSemantics(
                  child: CustomPaint(
                    key: const ValueKey<String>('replay-detail-overview'),
                    size: Size.infinite,
                    painter: _ReplayActionOverviewPainter(
                      data: widget.data,
                      detail: widget.detail,
                      time: _time,
                      brightness: Theme.of(context).brightness,
                      textDirection: Directionality.of(context),
                      textScaler: MediaQuery.textScalerOf(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.data.displaySample(_time).hasReconstructedPositions)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                _l10n.realMatchReplayActionDetailOverviewReconstructed,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: colors.muted),
              ),
            ),
        ],
      );

  Widget _buildPlaybackControl() {
    final label = _playing
        ? _l10n.realMatchReplayPauseAction
        : _finished
            ? _l10n.realMatchReplayReplayAction
            : _l10n.realMatchReplayActionDetailPlay;
    return FilledButton.icon(
      key: const ValueKey<String>('replay-detail-play'),
      onPressed: _togglePlayback,
      icon: Icon(
        _playing
            ? Icons.pause
            : _finished
                ? Icons.replay
                : Icons.play_arrow,
        size: 18,
      ),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}

class _ReplayDetailFact extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ReplayDetailFact({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 13, color: _ScanPassColors.of(context).muted),
          const SizedBox(width: 3),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _ScanPassColors.of(context).muted,
                  ),
            ),
          ),
        ],
      );
}

class _ReplayActionOverviewPainter extends CustomPainter {
  final RealMatchReplayData data;
  final RealMatchReplayActionDetail detail;
  final double time;
  final Brightness brightness;
  final TextDirection textDirection;
  final TextScaler textScaler;

  const _ReplayActionOverviewPainter({
    required this.data,
    required this.detail,
    required this.time,
    required this.brightness,
    required this.textDirection,
    required this.textScaler,
  });

  int get visiblePlayerCount =>
      data.displaySample(time).players.whereType<RealMatchReplayPoint>().length;

  @override
  void paint(Canvas canvas, Size size) {
    final dark = brightness == Brightness.dark;
    final pitch = dark ? const Color(0xFF183D2B) : const Color(0xFF214936);
    final line = dark ? const Color(0xFFA9C6AE) : const Color(0xFFC2D4C4);
    const selected = Color(0xFFD4EF9D);
    canvas.drawRect(Offset.zero & size, Paint()..color = pitch);
    final geometry = ReplayPitchGeometry.forSize(
      size,
      view: ReplayPitchView.coaching,
      camera: data.displayOverviewCamera,
      pitchLength: data.pitchLength,
      pitchWidth: data.pitchWidth,
      attackDirection: data.scene.attackDirection,
      rotatePitch: false,
      headerInset: 10,
      bottomInset: 10,
    );
    final halfLength = data.pitchLength / 2;
    final halfWidth = data.pitchWidth / 2;
    final field = Path()
      ..moveTo(geometry.project(-halfLength, -halfWidth).dx,
          geometry.project(-halfLength, -halfWidth).dy)
      ..lineTo(geometry.project(halfLength, -halfWidth).dx,
          geometry.project(halfLength, -halfWidth).dy)
      ..lineTo(geometry.project(halfLength, halfWidth).dx,
          geometry.project(halfLength, halfWidth).dy)
      ..lineTo(geometry.project(-halfLength, halfWidth).dx,
          geometry.project(-halfLength, halfWidth).dy)
      ..close();
    canvas.drawPath(
      field,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawLine(
      geometry.project(0, -halfWidth),
      geometry.project(0, halfWidth),
      Paint()
        ..color = line
        ..strokeWidth = 1,
    );

    final detailRect = <Offset>[
      geometry.project(detail.camera.minX, detail.camera.minY),
      geometry.project(detail.camera.maxX, detail.camera.minY),
      geometry.project(detail.camera.maxX, detail.camera.maxY),
      geometry.project(detail.camera.minX, detail.camera.maxY),
    ];
    canvas.drawPath(
      Path()..addPolygon(detailRect, true),
      Paint()
        ..color = selected
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final sample = data.displaySample(time);
    for (var index = 0; index < data.players.length; index++) {
      final point = sample.players[index];
      if (point == null) continue;
      final player = data.players[index];
      final center = geometry.project(point.x, point.y);
      final color = _replayColor(
        player.home ? data.scene.homeColor : data.scene.awayColor,
      );
      final numberColor = _replayColor(
        player.home ? data.scene.homeNumberColor : data.scene.awayNumberColor,
      );
      final reconstructed = sample.reconstructed[index];
      canvas.drawCircle(
        center,
        index == detail.actorIndex ? 5.2 : 4.2,
        Paint()
          ..color = reconstructed ? Colors.transparent : color
          ..style = reconstructed ? PaintingStyle.stroke : PaintingStyle.fill
          ..strokeWidth = reconstructed ? 1.4 : 1,
      );
      if (reconstructed) {
        canvas.drawCircle(
          center,
          4.2,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
      }
      if (index == detail.actorIndex) {
        canvas.drawCircle(
          center,
          7,
          Paint()
            ..color = selected
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
      final number = player.number;
      if (number == null || size.width < 180) continue;
      final numberPainter = TextPainter(
        text: TextSpan(
          text: '$number',
          style: TextStyle(
            color: numberColor,
            fontSize: 6,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: textDirection,
        textScaler: textScaler,
      )..layout();
      numberPainter.paint(
        canvas,
        center - numberPainter.size.center(Offset.zero),
      );
      numberPainter.dispose();
    }
    final ball = geometry.project(sample.ball.x, sample.ball.y);
    canvas.drawCircle(ball, 3, Paint()..color = Colors.white);
    canvas.drawCircle(ball, 1.2, Paint()..color = const Color(0xFF142F38));
  }

  @override
  bool shouldRepaint(covariant _ReplayActionOverviewPainter oldDelegate) =>
      data != oldDelegate.data ||
      detail != oldDelegate.detail ||
      time != oldDelegate.time ||
      brightness != oldDelegate.brightness ||
      textDirection != oldDelegate.textDirection ||
      textScaler != oldDelegate.textScaler;
}

String _detailTitle(
  AppLocalizations l10n,
  RealMatchReplayStepKind kind,
) =>
    switch (kind) {
      RealMatchReplayStepKind.receive =>
        l10n.realMatchReplayActionDetailReceiveTitle,
      RealMatchReplayStepKind.pass => l10n.realMatchReplayActionDetailPassTitle,
      RealMatchReplayStepKind.carry =>
        l10n.realMatchReplayActionDetailCarryTitle,
      _ => l10n.realMatchReplayActionDetailAffordance,
    };

String _detailCue(
  AppLocalizations l10n,
  RealMatchReplayStepKind kind, {
  required bool before,
}) =>
    switch ((kind, before)) {
      (RealMatchReplayStepKind.receive, true) =>
        l10n.realMatchReplayActionDetailReceiveBefore,
      (RealMatchReplayStepKind.receive, false) =>
        l10n.realMatchReplayActionDetailReceiveAfter,
      (RealMatchReplayStepKind.pass, true) =>
        l10n.realMatchReplayActionDetailPassBefore,
      (RealMatchReplayStepKind.pass, false) =>
        l10n.realMatchReplayActionDetailPassAfter,
      (RealMatchReplayStepKind.carry, true) =>
        l10n.realMatchReplayActionDetailCarryBefore,
      (RealMatchReplayStepKind.carry, false) =>
        l10n.realMatchReplayActionDetailCarryAfter,
      _ => l10n.realMatchReplayActionDetailAffordance,
    };
