part of 'scan_pass_game_screen.dart';

typedef AuthoredTouchSampleLoader = Future<AuthoredTouchSample> Function();

class ScanPassAuthoredTouchSampleScreen extends StatefulWidget {
  final AuthoredTouchSampleLoader? dataLoader;

  const ScanPassAuthoredTouchSampleScreen({
    super.key,
    this.dataLoader,
  });

  @override
  State<ScanPassAuthoredTouchSampleScreen> createState() =>
      _ScanPassAuthoredTouchSampleScreenState();
}

class _ScanPassAuthoredTouchSampleScreenState
    extends State<ScanPassAuthoredTouchSampleScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const String _asset =
      'assets/scan_pass_authored/first-touch-open-side.json';

  late final AnimationController _controller;
  AuthoredTouchSample? _sample;
  Object? _loadError;
  AuthoredTouchContinuation _continuation = AuthoredTouchContinuation.openSide;
  bool _playing = false;
  int _loadGeneration = 0;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;
  double get _time => (_sample?.duration ?? 0) * _controller.value;
  bool get _finished => _controller.value >= 1 - 1e-9;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      animationBehavior: AnimationBehavior.preserve,
    )
      ..addListener(_handleTick)
      ..addStatusListener(_handleStatus);
    _load();
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    try {
      final loader = widget.dataLoader ??
          () async => AuthoredTouchSample.fromJsonString(
                await rootBundle.loadString(_asset),
              );
      final sample = await loader();
      if (!mounted || generation != _loadGeneration) return;
      _controller
        ..duration = Duration(
          microseconds: (sample.duration /
                  sample.playbackRate *
                  Duration.microsecondsPerSecond)
              .round(),
        )
        ..value = 0;
      setState(() {
        _sample = sample;
        _loadError = null;
        _playing = false;
      });
    } catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() => _loadError = error);
    }
  }

  void _handleTick() {
    if (mounted) setState(() {});
  }

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted && _playing) {
      setState(() => _playing = false);
    }
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
    if (!_controller.isAnimating && !_playing) return;
    _controller.stop();
    if (mounted) setState(() => _playing = false);
  }

  void _togglePlayback() {
    if (_controller.isAnimating || _playing) {
      _pause();
      return;
    }
    if (_finished) _controller.value = 0;
    setState(() => _playing = true);
    _controller.forward();
  }

  void _compareContinuation() {
    _controller
      ..stop()
      ..value = 0;
    setState(() {
      _playing = false;
      _continuation = _continuation == AuthoredTouchContinuation.openSide
          ? AuthoredTouchContinuation.pressureSide
          : AuthoredTouchContinuation.openSide;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _loadGeneration++;
    _controller
      ..removeListener(_handleTick)
      ..removeStatusListener(_handleStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _ScanPassColors.of(context);
    final viewport = MediaQuery.sizeOf(context);
    final compactChrome =
        viewport.width > viewport.height && viewport.height < 520;
    return Scaffold(
      key: const ValueKey<String>('authored-touch-screen'),
      backgroundColor: colors.background,
      appBar: compactChrome
          ? null
          : AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: colors.surface,
              foregroundColor: colors.text,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                key: const ValueKey<String>('authored-touch-close'),
                tooltip: _l10n.authoredTouchClose,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close),
              ),
              title: Text(
                _l10n.authoredTouchAppBarTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
      body: SafeArea(child: _buildBody(colors)),
    );
  }

  Widget _buildBody(_ScanPassColors colors) {
    final error = _loadError;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.sports_soccer, color: colors.muted, size: 42),
            const SizedBox(height: 12),
            Text(
              _l10n.realMatchReplayLoadFailed,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _load,
              child: Text(_l10n.realMatchReplayRetry),
            ),
          ]),
        ),
      );
    }
    final sample = _sample;
    if (sample == null) {
      return Center(
        child: Semantics(
          label: _l10n.realMatchReplayLoading,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    final frame = sample.sampleAt(_time, _continuation);
    return LayoutBuilder(builder: (context, constraints) {
      final compactHeight = constraints.maxHeight < 470;
      final sideBySide = constraints.maxWidth >= 700 ||
          (constraints.maxWidth > constraints.maxHeight && compactHeight);
      return Padding(
        padding: EdgeInsets.fromLTRB(
          compactHeight ? 6 : 10,
          compactHeight ? 5 : 8,
          compactHeight ? 6 : 10,
          compactHeight ? 5 : 8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildIntroduction(colors, compact: compactHeight),
            SizedBox(height: compactHeight ? 4 : 7),
            Expanded(
              child: sideBySide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildDiagram(
                            sample,
                            frame,
                            colors,
                            detail: false,
                            compact: compactHeight,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          flex: 2,
                          child: _buildDiagram(
                            sample,
                            frame,
                            colors,
                            detail: true,
                            compact: compactHeight,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 9,
                          child: _buildDiagram(
                            sample,
                            frame,
                            colors,
                            detail: false,
                            compact: compactHeight,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Expanded(
                          flex: 11,
                          child: _buildDiagram(
                            sample,
                            frame,
                            colors,
                            detail: true,
                            compact: compactHeight,
                          ),
                        ),
                      ],
                    ),
            ),
            SizedBox(height: compactHeight ? 4 : 7),
            _buildControls(sample, frame, colors, compact: compactHeight),
          ],
        ),
      );
    });
  }

  Widget _buildIntroduction(_ScanPassColors colors, {required bool compact}) {
    final textTheme = Theme.of(context).textTheme;
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.active,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.accent.withValues(alpha: .5)),
      ),
      child: Text(
        _l10n.authoredTouchDisclosure,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textTheme.labelSmall?.copyWith(
          color: colors.accent,
          fontWeight: FontWeight.w800,
          letterSpacing: .25,
        ),
      ),
    );
    if (compact) {
      return Row(children: [
        IconButton(
          key: const ValueKey<String>('authored-touch-close'),
          tooltip: _l10n.authoredTouchClose,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close, size: 20),
        ),
        const SizedBox(width: 3),
        Flexible(child: badge),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _l10n.authoredTouchSituationTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Tooltip(
          message: _l10n.authoredTouchManualNote,
          child: Icon(Icons.info_outline, size: 18, color: colors.muted),
        ),
      ]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Flexible(child: badge),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _l10n.authoredTouchSituationTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ]),
        if (MediaQuery.sizeOf(context).width >= 420) ...[
          const SizedBox(height: 3),
          Text(
            _l10n.authoredTouchSituationSummary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(color: colors.muted),
          ),
        ],
        const SizedBox(height: 2),
        Text(
          _l10n.authoredTouchManualNote,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.labelSmall?.copyWith(color: colors.muted),
        ),
      ],
    );
  }

  Widget _buildDiagram(
    AuthoredTouchSample sample,
    AuthoredTouchFrame frame,
    _ScanPassColors colors, {
    required bool detail,
    required bool compact,
  }) {
    final continuation = _continuationLabel();
    final phase = _phaseLabel(frame.phase);
    final semantics = detail
        ? _l10n.authoredTouchDetailSemantics(
            continuation,
            phase,
            frame.time.toStringAsFixed(1),
          )
        : _l10n.authoredTouchContextSemantics(
            continuation,
            phase,
            frame.time.toStringAsFixed(1),
          );
    final labels = _AuthoredTouchPainterLabels(
      pressure: _l10n.authoredTouchCuePressure,
      openSpace: _l10n.authoredTouchCueOpenSpace,
      incomingPass: _l10n.authoredTouchCueIncomingPass,
      forwardLink: _l10n.authoredTouchCueForwardLink,
      supportFoot: _l10n.authoredTouchCueSupportFoot,
      leftShoe: _l10n.authoredTouchLeftShoe,
      rightShoe: _l10n.authoredTouchRightShoe,
    );
    final forwardPass = sample.eventFor(
      _continuation,
      AuthoredTouchEventType.forwardPass,
    );
    final showFollowThrough = detail &&
        forwardPass != null &&
        frame.time >= forwardPass.time &&
        _continuation == AuthoredTouchContinuation.openSide;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 7 : 10,
            vertical: compact ? 3 : 5,
          ),
          color: colors.surface,
          child: Row(children: [
            Icon(
              detail ? Icons.accessibility_new : Icons.grid_view_rounded,
              size: compact ? 14 : 16,
              color: colors.accent,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                detail
                    ? _l10n.authoredTouchDetailTitle
                    : _l10n.authoredTouchContextTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                    ),
              ),
            ),
            if (showFollowThrough) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _l10n.authoredTouchCueFollowThrough,
                  key: const ValueKey<String>(
                    'authored-touch-detail-phase-cue',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.muted,
                      ),
                ),
              ),
            ],
          ]),
        ),
        Expanded(
          child: Semantics(
            label: semantics,
            image: true,
            child: RepaintBoundary(
              child: CustomPaint(
                key: ValueKey<String>(
                  detail ? 'authored-touch-detail' : 'authored-touch-context',
                ),
                painter: _AuthoredTouchSamplePainter(
                  sample: sample,
                  frame: frame,
                  detail: detail,
                  labels: labels,
                  dark: Theme.of(context).brightness == Brightness.dark,
                  textScaler: MediaQuery.textScalerOf(context),
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildControls(
    AuthoredTouchSample sample,
    AuthoredTouchFrame frame,
    _ScanPassColors colors, {
    required bool compact,
  }) {
    final phase = _finished
        ? (_continuation == AuthoredTouchContinuation.openSide
            ? _l10n.authoredTouchOpenFeedback
            : _l10n.authoredTouchPressureFeedback)
        : _phaseLabel(frame.phase);
    final playLabel = _playing
        ? _l10n.authoredTouchPause
        : (_finished ? _l10n.authoredTouchReplay : _l10n.authoredTouchPlay);
    final compareLabel = _continuation == AuthoredTouchContinuation.openSide
        ? _l10n.authoredTouchComparePressure
        : _l10n.authoredTouchCompareOpen;
    final play = FilledButton.icon(
      key: const ValueKey<String>('authored-touch-play'),
      onPressed: _togglePlayback,
      icon: Icon(
        _playing ? Icons.pause : (_finished ? Icons.replay : Icons.play_arrow),
      ),
      label: Text(playLabel, textAlign: TextAlign.center),
    );
    final compare = OutlinedButton.icon(
      key: const ValueKey<String>('authored-touch-compare'),
      onPressed: _compareContinuation,
      icon: const Icon(Icons.compare_arrows),
      label: Text(compareLabel, textAlign: TextAlign.center),
    );
    final state = Semantics(
      key: const ValueKey<String>('authored-touch-current-state'),
      liveRegion: true,
      label: _l10n.authoredTouchCurrentStateSemantics(
        _continuationLabel(),
        phase,
      ),
      child: Text(
        phase,
        key: _finished
            ? const ValueKey<String>('authored-touch-end-feedback')
            : const ValueKey<String>('authored-touch-phase'),
        maxLines: compact ? 1 : 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _finished ? colors.accent : colors.text,
              fontWeight: _finished ? FontWeight.w700 : FontWeight.w600,
            ),
      ),
    );
    final buttonRow = Row(children: [
      Expanded(child: play),
      const SizedBox(width: 7),
      Expanded(child: compare),
    ]);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Semantics(
        label: _l10n.authoredTouchProgressSemantics(
          frame.time.toStringAsFixed(1),
          sample.duration.toStringAsFixed(1),
          (_controller.value * 100).round(),
        ),
        child: LinearProgressIndicator(
          key: const ValueKey<String>('authored-touch-progress'),
          value: _controller.value,
          minHeight: 4,
          backgroundColor: colors.line,
        ),
      ),
      SizedBox(height: compact ? 4 : 6),
      if (compact)
        Row(children: [
          Expanded(child: state),
          const SizedBox(width: 8),
          SizedBox(width: 150, child: play),
          const SizedBox(width: 7),
          SizedBox(width: 205, child: compare),
        ])
      else ...[
        state,
        const SizedBox(height: 6),
        if (MediaQuery.sizeOf(context).width < 390)
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            play,
            const SizedBox(height: 6),
            compare,
          ])
        else
          buttonRow,
      ],
    ]);
  }

  String _continuationLabel() =>
      _continuation == AuthoredTouchContinuation.openSide
          ? _l10n.authoredTouchOpenSide
          : _l10n.authoredTouchPressureSide;

  String _phaseLabel(AuthoredTouchPhase phase) => switch (phase) {
        AuthoredTouchPhase.prepare => _l10n.authoredTouchPhasePrepare,
        AuthoredTouchPhase.incomingPass => _l10n.authoredTouchPhaseIncomingPass,
        AuthoredTouchPhase.firstTouch => _l10n.authoredTouchPhaseFirstTouch,
        AuthoredTouchPhase.turnAndCarry => _l10n.authoredTouchPhaseTurnCarry,
        AuthoredTouchPhase.forwardPass => _l10n.authoredTouchPhaseForwardPass,
        AuthoredTouchPhase.forwardReceive =>
          _l10n.authoredTouchPhaseForwardReceive,
        AuthoredTouchPhase.pressureSteal =>
          _l10n.authoredTouchPhasePressureSteal,
        AuthoredTouchPhase.defenderCarry =>
          _l10n.authoredTouchPhaseDefenderCarry,
        AuthoredTouchPhase.complete => _l10n.authoredTouchPhaseComplete,
      };
}

class _AuthoredTouchPainterLabels {
  final String pressure;
  final String openSpace;
  final String incomingPass;
  final String forwardLink;
  final String supportFoot;
  final String leftShoe;
  final String rightShoe;

  const _AuthoredTouchPainterLabels({
    required this.pressure,
    required this.openSpace,
    required this.incomingPass,
    required this.forwardLink,
    required this.supportFoot,
    required this.leftShoe,
    required this.rightShoe,
  });
}

class _AuthoredTouchSamplePainter extends CustomPainter {
  final AuthoredTouchSample sample;
  final AuthoredTouchFrame frame;
  final bool detail;
  final _AuthoredTouchPainterLabels labels;
  final bool dark;
  final TextScaler textScaler;

  static const AuthoredTouchBodyRig _bodyRig = AuthoredTouchBodyRig();

  const _AuthoredTouchSamplePainter({
    required this.sample,
    required this.frame,
    required this.detail,
    required this.labels,
    required this.dark,
    required this.textScaler,
  });

  double get time => frame.time;
  AuthoredTouchContinuation get continuation => frame.continuation;
  AuthoredTouchPoint get ballPoint => frame.ball.point;
  AuthoredTouchPoint get receiverRoot => frame.players['receiver']!.root;
  int get visiblePlayerCount => detail ? 2 : frame.players.length;
  double get scaledCueFontSize => textScaler.scale(11);

  AuthoredTouchBounds cameraBounds(Size size) =>
      detail ? _detailBoundsFor(size) : sample.contextBounds;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final bounds = detail ? _detailBoundsFor(size) : sample.contextBounds;
    final geometry = _AuthoredTouchPitchGeometry(
      size,
      bounds,
      margin: detail ? 0 : 7,
      labelInset: !detail && size.width < 420 ? scaledCueFontSize + 12 : 0,
    );
    _drawPitch(canvas, geometry);
    canvas.save();
    canvas.clipRect(geometry.pitchRect);
    if (detail) {
      _drawDetailCues(canvas, geometry);
      _drawPlayerIfFullyVisible(
        canvas,
        geometry,
        sample.player('presser'),
        focus: frame.possessionPlayerId == 'presser',
      );
      _drawPlayerIfFullyVisible(
        canvas,
        geometry,
        sample.player('receiver'),
        focus: frame.possessionPlayerId == 'receiver' ||
            frame.time <= sample.sharedUntil,
      );
      if (bounds.contains(frame.ball.point)) _drawBall(canvas, geometry);
      _drawSupportMark(canvas, geometry);
    } else {
      _drawContextCues(canvas, geometry);
      for (final player in sample.players.where(
        (player) => player.team == AuthoredTouchTeam.defense,
      )) {
        _drawPlayer(canvas, geometry, player);
      }
      for (final player in sample.players.where(
        (player) => player.team == AuthoredTouchTeam.attack,
      )) {
        _drawPlayer(
          canvas,
          geometry,
          player,
          focus: player.id == 'receiver',
        );
      }
      _drawBall(canvas, geometry);
    }
    canvas.restore();
    if (!detail) _drawContextLabels(canvas, geometry);
  }

  AuthoredTouchBounds _detailBoundsFor(Size size) {
    final receiver = frame.players['receiver']!.root;
    final presser = frame.players['presser']!.root;
    final steal = sample.eventFor(
      frame.continuation,
      AuthoredTouchEventType.steal,
    );
    final carry = sample.eventFor(
      frame.continuation,
      AuthoredTouchEventType.defenderCarry,
    );
    var focus = receiver;
    if (frame.continuation == AuthoredTouchContinuation.pressureSide &&
        steal != null &&
        carry != null) {
      final raw = ((frame.time - steal.time) /
              math.max(.001, carry.time - steal.time + .55))
          .clamp(0.0, 1.0);
      final eased = raw * raw * (3 - 2 * raw);
      focus = AuthoredTouchPoint.lerp(receiver, presser, eased);
    }
    const viewHeight = 6.4;
    final aspect = (size.width / math.max(1, size.height)).clamp(.65, 2.5);
    final viewWidth = viewHeight * aspect;
    final centerY = focus.y + .85;
    final centerX =
        focus.x + (frame.ball.point.x - focus.x).clamp(-1.5, 1.5) * .2;
    return AuthoredTouchBounds(
      minX: centerX - viewWidth / 2,
      maxX: centerX + viewWidth / 2,
      minY: centerY - viewHeight / 2,
      maxY: centerY + viewHeight / 2,
    );
  }

  void _drawPitch(Canvas canvas, _AuthoredTouchPitchGeometry geometry) {
    final pitch = geometry.pitchRect;
    final base = dark ? const Color(0xFF193E34) : const Color(0xFF28664C);
    canvas.drawRect(Offset.zero & geometry.size, Paint()..color = base);
    canvas.drawRect(pitch, Paint()..color = base);
    final stripe = Paint()
      ..color = (dark ? Colors.white : Colors.black).withValues(alpha: .035);
    for (var i = 0; i < 8; i += 2) {
      canvas.drawRect(
        Rect.fromLTWH(
          pitch.left + pitch.width * i / 8,
          pitch.top,
          pitch.width / 8,
          pitch.height,
        ),
        stripe,
      );
    }
    final line = Paint()
      ..color = Colors.white.withValues(alpha: .42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, geometry.scale * .035);
    canvas.drawRect(pitch.deflate(.5), line);
    final centerX = geometry.project(const AuthoredTouchPoint(0, 0)).dx;
    canvas.drawLine(
      Offset(centerX, pitch.top),
      Offset(centerX, pitch.bottom),
      line,
    );
    canvas.drawCircle(
      geometry.project(const AuthoredTouchPoint(0, 0)),
      math.min(pitch.width, pitch.height) * .12,
      line,
    );
    final directionY = pitch.top + 10;
    final arrowStart = Offset(pitch.right - 62, directionY);
    final arrowEnd = Offset(pitch.right - 18, directionY);
    _drawArrow(
        canvas,
        arrowStart,
        arrowEnd,
        Colors.white.withValues(alpha: .65),
        math.max(1.2, geometry.scale * .06));
  }

  void _drawContextCues(
    Canvas canvas,
    _AuthoredTouchPitchGeometry geometry,
  ) {
    final initialPass = sample.eventFor(
      frame.continuation,
      AuthoredTouchEventType.initialPass,
    )!;
    final firstTouch = sample.eventFor(
      frame.continuation,
      AuthoredTouchEventType.firstTouch,
    )!;
    final incomingPath = sample.ballPathBetween(
      frame.continuation,
      start: initialPass.time,
      end: firstTouch.time,
    );
    final branchPath = sample.ballPathBetween(
      frame.continuation,
      start: firstTouch.time,
      end: sample.duration,
    );
    final contactFrame = sample.sampleAt(firstTouch.time, frame.continuation);
    final contactReceiver = contactFrame.players['receiver']!.root;
    final contactPresser = contactFrame.players['presser']!.root;
    final awayFromPressure = (contactReceiver - contactPresser).normalized();
    final open = contactReceiver + awayFromPressure.scaled(3.4);
    canvas.drawOval(
      Rect.fromCenter(
        center: geometry.project(open),
        width: geometry.scale * 8.5,
        height: geometry.scale * 5.2,
      ),
      Paint()..color = const Color(0xFF50C98D).withValues(alpha: .14),
    );
    _drawWorldPath(
      canvas,
      geometry,
      incomingPath,
      Colors.white.withValues(alpha: .52),
      dashed: true,
    );
    final receiver = frame.players['receiver']!.root;
    final presser = frame.players['presser']!.root;
    _drawWorldArrow(
      canvas,
      geometry,
      presser,
      receiver,
      const Color(0xFFE96F62).withValues(alpha: .8),
    );
    final branchColor = frame.continuation == AuthoredTouchContinuation.openSide
        ? const Color(0xFFE9CE7A)
        : const Color(0xFFE96F62);
    _drawWorldPath(
      canvas,
      geometry,
      branchPath,
      branchColor.withValues(
        alpha: frame.continuation == AuthoredTouchContinuation.openSide
            ? .65
            : .72,
      ),
    );
  }

  void _drawContextLabels(
    Canvas canvas,
    _AuthoredTouchPitchGeometry geometry,
  ) {
    final initialPass = sample.eventFor(
      frame.continuation,
      AuthoredTouchEventType.initialPass,
    )!;
    final firstTouch = sample.eventFor(
      frame.continuation,
      AuthoredTouchEventType.firstTouch,
    )!;
    final incomingPath = sample.ballPathBetween(
      frame.continuation,
      start: initialPass.time,
      end: firstTouch.time,
    );
    final touchFrame = sample.sampleAt(firstTouch.time, frame.continuation);
    final receiver = touchFrame.players['receiver']!.root;
    final presser = touchFrame.players['presser']!.root;
    final away = (receiver - presser).normalized();
    final open = receiver + away.scaled(4.6);
    if (geometry.size.width < 420) {
      final band = scaledCueFontSize + 12;
      _drawCueWithLeader(
        canvas,
        Offset(geometry.size.width / 2, band / 2 + 2),
        geometry.project(presser),
        labels.pressure,
        const Color(0xFFFFC3BC),
      );
      _drawCueWithLeader(
        canvas,
        Offset(geometry.size.width / 2, geometry.size.height - band / 2 - 2),
        geometry.project(open),
        labels.openSpace,
        const Color(0xFFBDEFD0),
      );
      return;
    }
    final horizontalGutter = geometry.pitchRect.left > 30;
    final verticalGutter = geometry.pitchRect.top > 30;
    late final Offset pressureLabel;
    late final Offset incomingLabel;
    late final Offset openLabel;
    late final Offset forwardLabel;
    if (horizontalGutter) {
      final left = geometry.pitchRect.left / 2;
      final right = (geometry.pitchRect.right + geometry.size.width) / 2;
      pressureLabel = Offset(left, geometry.size.height * .22);
      incomingLabel = Offset(left, geometry.size.height * .68);
      openLabel = Offset(right, geometry.size.height * .28);
      forwardLabel = Offset(right, geometry.size.height * .74);
    } else if (verticalGutter) {
      final top = geometry.pitchRect.top / 2;
      final bottom = (geometry.pitchRect.bottom + geometry.size.height) / 2;
      pressureLabel = Offset(geometry.size.width * .42, top);
      incomingLabel = Offset(geometry.size.width * .16, top);
      openLabel = Offset(geometry.size.width * .42, bottom);
      forwardLabel = Offset(geometry.size.width * .78, bottom);
    } else {
      pressureLabel = Offset(
        geometry.size.width * .38,
        geometry.size.height * .16,
      );
      incomingLabel = Offset(
        geometry.size.width * .19,
        geometry.size.height * .64,
      );
      openLabel = Offset(
        geometry.size.width * .49,
        geometry.size.height * .82,
      );
      forwardLabel = Offset(
        geometry.size.width * .8,
        geometry.size.height * .8,
      );
    }
    _drawCueWithLeader(
      canvas,
      pressureLabel,
      geometry.project(presser),
      labels.pressure,
      const Color(0xFFFFC3BC),
    );
    _drawCueWithLeader(
      canvas,
      incomingLabel,
      geometry.project(_pointAlongPath(incomingPath, .48)),
      labels.incomingPass,
      Colors.white.withValues(alpha: .88),
    );
    _drawCueWithLeader(
      canvas,
      openLabel,
      geometry.project(open),
      labels.openSpace,
      const Color(0xFFBDEFD0),
    );
    if (frame.continuation == AuthoredTouchContinuation.openSide) {
      final pass = sample.eventFor(
        frame.continuation,
        AuthoredTouchEventType.forwardPass,
      )!;
      final receive = sample.eventFor(
        frame.continuation,
        AuthoredTouchEventType.receive,
      )!;
      final path = sample.ballPathBetween(
        frame.continuation,
        start: pass.time,
        end: receive.time,
      );
      _drawCueWithLeader(
        canvas,
        forwardLabel,
        geometry.project(_pointAlongPath(path, .67)),
        labels.forwardLink,
        const Color(0xFFFFE8A4),
      );
    }
  }

  void _drawDetailCues(
    Canvas canvas,
    _AuthoredTouchPitchGeometry geometry,
  ) {
    final presser = frame.players['presser']!.root;
    final receiver = frame.players['receiver']!.root;
    _drawWorldArrow(
      canvas,
      geometry,
      presser,
      receiver,
      const Color(0xFFE96F62).withValues(alpha: .72),
    );
    final firstTouch = sample.eventFor(
      frame.continuation,
      AuthoredTouchEventType.firstTouch,
    )!;
    double pathStart;
    double pathEnd;
    if (frame.time < firstTouch.time) {
      final initialPass = sample.eventFor(
        frame.continuation,
        AuthoredTouchEventType.initialPass,
      )!;
      pathStart = initialPass.time;
      pathEnd = firstTouch.time;
    } else if (frame.continuation == AuthoredTouchContinuation.openSide) {
      final pass = sample.eventFor(
        frame.continuation,
        AuthoredTouchEventType.forwardPass,
      )!;
      pathStart = frame.time < pass.time ? firstTouch.time : pass.time;
      pathEnd =
          frame.time < pass.time ? pass.time : _nextBallKeyframeTime(pass.time);
    } else {
      final steal = sample.eventFor(
        frame.continuation,
        AuthoredTouchEventType.steal,
      )!;
      final carry = sample.eventFor(
        frame.continuation,
        AuthoredTouchEventType.defenderCarry,
      )!;
      if (frame.time < steal.time) {
        pathStart = firstTouch.time;
        pathEnd = steal.time;
      } else if (frame.time < carry.time) {
        pathStart = steal.time;
        pathEnd = carry.time;
      } else {
        pathStart = carry.time;
        pathEnd = _nextBallKeyframeTime(carry.time);
      }
    }
    final path = sample.ballPathBetween(
      frame.continuation,
      start: pathStart,
      end: pathEnd,
    );
    _drawWorldPath(
      canvas,
      geometry,
      path,
      (frame.continuation == AuthoredTouchContinuation.openSide
              ? const Color(0xFFE9CE7A)
              : const Color(0xFFE96F62))
          .withValues(alpha: .7),
    );
  }

  double _nextBallKeyframeTime(double after) {
    for (final keyframe in sample.ballKeyframesFor(frame.continuation)) {
      if (keyframe.time > after + 1e-9) return keyframe.time;
    }
    return sample.duration;
  }

  void _drawSupportMark(
    Canvas canvas,
    _AuthoredTouchPitchGeometry geometry,
  ) {
    AuthoredTouchPlantWindow? active;
    final plants = <AuthoredTouchPlantWindow>[
      ...sample.sharedPlantWindows,
      ...sample.branches[frame.continuation]!.plantWindows,
    ];
    for (final plant in plants) {
      if ((plant.playerId == 'receiver' || plant.playerId == 'presser') &&
          frame.time >= plant.start - .05 &&
          frame.time <= plant.end + .12) {
        active = plant;
        break;
      }
    }
    if (active == null) return;
    final point = geometry.project(active.point);
    final radius = math.max(5.0, geometry.scale * .32);
    canvas.drawCircle(
      point,
      radius,
      Paint()
        ..color = const Color(0xFFFFD86B).withValues(alpha: .9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final cueAt = Offset(
      geometry.pitchRect.left + 8,
      geometry.pitchRect.bottom - 13,
    );
    _drawCue(canvas, cueAt, labels.supportFoot, const Color(0xFFFFE8A4),
        anchorLeft: true);
    canvas.drawLine(
      Offset(cueAt.dx + 12, cueAt.dy - 7),
      point,
      Paint()
        ..color = const Color(0xFFFFD86B).withValues(alpha: .65)
        ..strokeWidth = 1,
    );
  }

  void _drawPlayer(
    Canvas canvas,
    _AuthoredTouchPitchGeometry geometry,
    AuthoredTouchPlayer player, {
    bool focus = false,
  }) {
    final pose = frame.players[player.id]!;
    final body = _bodyRig.solve(pose);
    final scale = geometry.scale;
    final root = geometry.project(pose.root);
    final direction = geometry.direction(pose.root, pose.bodyFacing);
    final side = Offset(-direction.dy, direction.dx);
    final leftFoot = geometry.project(body.leftAnkle);
    final rightFoot = geometry.project(body.rightAnkle);
    final chest = geometry.project(body.chestCenter);
    final head = geometry.project(body.headCenter);
    final kit = player.team == AuthoredTouchTeam.attack
        ? (dark ? const Color(0xFF71B7DA) : const Color(0xFF75C5EA))
        : (dark ? const Color(0xFFD66D62) : const Color(0xFFE77A6F));
    final shorts = Color.lerp(kit, Colors.black, .48)!;
    final skin = dark ? const Color(0xFFD7A577) : const Color(0xFFE3B184);
    if (focus) {
      canvas.drawOval(
        Rect.fromCenter(
          center: root,
          width: math.max(18, scale * 1.45),
          height: math.max(10, scale * .72),
        ),
        Paint()..color = const Color(0xFFFFD86B).withValues(alpha: .2),
      );
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: root.translate(2, 3),
        width: math.max(8, scale * .85),
        height: math.max(3, scale * .28),
      ),
      Paint()..color = Colors.black.withValues(alpha: .18),
    );

    _drawLimb(
      canvas,
      geometry.project(body.leftHip),
      geometry.project(body.leftKnee),
      shorts,
      scale * .22,
    );
    _drawLimb(
      canvas,
      geometry.project(body.rightHip),
      geometry.project(body.rightKnee),
      shorts,
      scale * .22,
    );
    _drawLimb(
      canvas,
      geometry.project(body.leftKnee),
      leftFoot,
      skin,
      scale * .15,
    );
    _drawLimb(
      canvas,
      geometry.project(body.rightKnee),
      rightFoot,
      skin,
      scale * .15,
    );
    canvas.drawCircle(
      geometry.project(body.leftKnee),
      math.max(1.8, scale * .085),
      Paint()..color = skin,
    );
    canvas.drawCircle(
      geometry.project(body.rightKnee),
      math.max(1.8, scale * .085),
      Paint()..color = skin,
    );

    _drawLimb(
      canvas,
      geometry.project(body.leftShoulder),
      geometry.project(body.leftElbow),
      skin,
      scale * .13,
    );
    _drawLimb(
      canvas,
      geometry.project(body.leftElbow),
      geometry.project(body.leftHand),
      skin,
      scale * .11,
    );
    _drawLimb(
      canvas,
      geometry.project(body.rightShoulder),
      geometry.project(body.rightElbow),
      skin,
      scale * .13,
    );
    _drawLimb(
      canvas,
      geometry.project(body.rightElbow),
      geometry.project(body.rightHand),
      skin,
      scale * .11,
    );

    final torsoHull = _convexHull(
      body.torsoVertices.map(geometry.project).toList(growable: false),
    );
    if (torsoHull.length >= 3) {
      final jersey = Path()..moveTo(torsoHull.first.dx, torsoHull.first.dy);
      for (final point in torsoHull.skip(1)) {
        jersey.lineTo(point.dx, point.dy);
      }
      jersey.close();
      canvas.drawPath(jersey, Paint()..color = kit);
      canvas.drawPath(
        jersey,
        Paint()
          ..color = Colors.black.withValues(alpha: .46)
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = math.max(.8, scale * .045),
      );
      final pelvis = geometry.project(body.pelvisCenter);
      canvas.drawLine(
        pelvis - side * (.2 * scale),
        pelvis + side * (.2 * scale),
        Paint()
          ..color = shorts
          ..strokeCap = StrokeCap.round
          ..strokeWidth = math.max(2.2, scale * .18),
      );
    }
    canvas.drawCircle(
      head,
      math.max(2.8, scale * .17),
      Paint()..color = skin,
    );
    canvas.drawCircle(
      head.translate(0, -math.max(1.2, scale * .07)),
      math.max(2.4, scale * .15),
      Paint()..color = const Color(0xFF302821),
    );
    _drawShoe(
      canvas,
      leftFoot,
      direction,
      side,
      scale,
      labels.leftShoe,
      detail && player.id == 'receiver',
      left: true,
    );
    _drawShoe(
      canvas,
      rightFoot,
      direction,
      side,
      scale,
      labels.rightShoe,
      detail && player.id == 'receiver',
      left: false,
    );
    _drawNumber(canvas, chest, player.number, scale);
    if (focus) {
      final facingStart = root - side * (.55 * scale);
      _drawArrow(
        canvas,
        facingStart,
        facingStart + direction * (.35 * scale),
        Colors.white.withValues(alpha: .65),
        math.max(1, scale * .035),
      );
    }
  }

  void _drawPlayerIfFullyVisible(
    Canvas canvas,
    _AuthoredTouchPitchGeometry geometry,
    AuthoredTouchPlayer player, {
    bool focus = false,
  }) {
    final body = _bodyRig.solve(frame.players[player.id]!);
    final points = body.joints.map(geometry.project);
    final bodyBounds =
        _boundsOf(points).inflate(math.max(3, geometry.scale * .2));
    final viewport = geometry.pitchRect.deflate(1);
    if (!viewport.contains(bodyBounds.topLeft) ||
        !viewport.contains(bodyBounds.bottomRight)) {
      return;
    }
    _drawPlayer(canvas, geometry, player, focus: focus);
  }

  void _drawLimb(
    Canvas canvas,
    Offset from,
    Offset to,
    Color color,
    double width,
  ) {
    final strokeWidth = math.max(1.8, width);
    canvas.drawLine(
      from,
      to,
      Paint()
        ..color = Colors.black.withValues(alpha: .45)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth + math.max(1.2, strokeWidth * .24),
    );
    canvas.drawLine(
      from,
      to,
      Paint()
        ..color = color
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth,
    );
  }

  void _drawShoe(
    Canvas canvas,
    Offset point,
    Offset direction,
    Offset side,
    double scale,
    String label,
    bool showLabel, {
    required bool left,
  }) {
    final shoeLength = math.max(5.0, scale * .29);
    final shoeWidth = math.max(3.0, scale * .15);
    canvas.save();
    canvas.translate(point.dx, point.dy);
    canvas.rotate(math.atan2(direction.dy, direction.dx));
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: shoeLength,
        height: shoeWidth,
      ),
      Radius.circular(shoeWidth / 2),
    );
    canvas.drawRRect(rect, Paint()..color = const Color(0xFFF4F3EA));
    canvas.drawRRect(
      rect,
      Paint()
        ..color = const Color(0xFF1B2528)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.7, scale * .04),
    );
    canvas.restore();
    if (showLabel) {
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
      )..layout();
      final distance = math.max(14.0, scale * .31);
      final center = point + side * (left ? distance : -distance);
      final background = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: painter.width + 7,
          height: painter.height + 4,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(
        background,
        Paint()..color = const Color(0xFF132C28).withValues(alpha: .88),
      );
      painter.paint(
        canvas,
        center.translate(-painter.width / 2, -painter.height / 2),
      );
    }
  }

  void _drawNumber(Canvas canvas, Offset at, int number, double scale) {
    if (scale < 6) return;
    final painter = TextPainter(
      text: TextSpan(
        text: '$number',
        style: TextStyle(
          color: Colors.white,
          fontSize: math.max(8, math.min(12, scale * .38)),
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();
    painter.paint(
      canvas,
      at.translate(-painter.width / 2, -painter.height / 2),
    );
  }

  void _drawBall(Canvas canvas, _AuthoredTouchPitchGeometry geometry) {
    final center = geometry.project(frame.ball.point);
    final radius = math.max(detail ? 3.8 : 2.7, geometry.scale * .115);
    canvas.drawCircle(
      center.translate(1.4, 2),
      radius * 1.05,
      Paint()..color = Colors.black.withValues(alpha: .24),
    );
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFFF7F4E9));
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF273036)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.8, radius * .13),
    );
    final patch = Path();
    for (var i = 0; i < 5; i++) {
      final angle = frame.ball.rotation + i * math.pi * 2 / 5 - math.pi / 2;
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * radius * .42;
      if (i == 0) {
        patch.moveTo(point.dx, point.dy);
      } else {
        patch.lineTo(point.dx, point.dy);
      }
    }
    patch.close();
    canvas.drawPath(patch, Paint()..color = const Color(0xFF343B3E));
    for (var i = 0; i < 3; i++) {
      final angle = frame.ball.rotation * .7 + i * math.pi * 2 / 3;
      canvas.drawCircle(
        center + Offset(math.cos(angle), math.sin(angle)) * radius * .7,
        radius * .14,
        Paint()..color = const Color(0xFF343B3E),
      );
    }
  }

  void _drawWorldPath(
    Canvas canvas,
    _AuthoredTouchPitchGeometry geometry,
    List<AuthoredTouchPoint> points,
    Color color, {
    bool dashed = false,
  }) {
    if (points.length < 2) return;
    final width = math.max(1.2, geometry.scale * .09);
    if (dashed) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round;
      for (var index = 1; index < points.length; index++) {
        _drawDashedSegment(
          canvas,
          geometry.project(points[index - 1]),
          geometry.project(points[index]),
          paint,
        );
      }
      _drawArrow(
        canvas,
        geometry.project(points[points.length - 2]),
        geometry.project(points.last),
        color,
        width,
      );
      return;
    }
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final p = geometry.project(points[i]);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = width,
    );
    if (points.length > 1) {
      _drawArrow(
        canvas,
        geometry.project(points[points.length - 2]),
        geometry.project(points.last),
        color,
        width,
      );
    }
  }

  void _drawDashedSegment(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
  ) {
    final vector = end - start;
    final length = vector.distance;
    if (length <= 1) return;
    final unit = vector / length;
    for (double offset = 0; offset < length; offset += 9) {
      canvas.drawLine(
        start + unit * offset,
        start + unit * math.min(length, offset + 5),
        paint,
      );
    }
  }

  void _drawWorldArrow(
    Canvas canvas,
    _AuthoredTouchPitchGeometry geometry,
    AuthoredTouchPoint from,
    AuthoredTouchPoint to,
    Color color, {
    bool dashed = false,
  }) {
    final start = geometry.project(from);
    final end = geometry.project(to);
    if (!dashed) {
      _drawArrow(
        canvas,
        start,
        end,
        color,
        math.max(1.2, geometry.scale * .075),
      );
      return;
    }
    final vector = end - start;
    final length = vector.distance;
    if (length <= 1) return;
    final unit = vector / length;
    final paint = Paint()
      ..color = color
      ..strokeWidth = math.max(1, geometry.scale * .06)
      ..strokeCap = StrokeCap.round;
    for (double offset = 0; offset < length - 8; offset += 9) {
      canvas.drawLine(
        start + unit * offset,
        start + unit * math.min(length - 8, offset + 5),
        paint,
      );
    }
    _drawArrow(canvas, end - unit * 13, end, color, paint.strokeWidth);
  }

  void _drawArrow(
    Canvas canvas,
    Offset from,
    Offset to,
    Color color,
    double width,
  ) {
    final vector = to - from;
    final length = vector.distance;
    if (length < 2) return;
    final unit = vector / length;
    final side = Offset(-unit.dy, unit.dx);
    final head = math.max(4.0, width * 3.2);
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(from, to - unit * head * .4, paint);
    final path = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(
        to.dx - unit.dx * head + side.dx * head * .45,
        to.dy - unit.dy * head + side.dy * head * .45,
      )
      ..lineTo(
        to.dx - unit.dx * head - side.dx * head * .45,
        to.dy - unit.dy * head - side.dy * head * .45,
      )
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawCue(
    Canvas canvas,
    Offset at,
    String text,
    Color color, {
    bool anchorLeft = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: .15,
          height: 1,
        ),
      ),
      maxLines: 1,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout(maxWidth: detail ? 180 : 150);
    final origin = Offset(
      anchorLeft ? at.dx : at.dx - painter.width / 2,
      at.dy - painter.height / 2,
    );
    final background = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        origin.dx - 4,
        origin.dy - 3,
        painter.width + 8,
        painter.height + 6,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      background,
      Paint()..color = const Color(0xFF132C28).withValues(alpha: .82),
    );
    painter.paint(canvas, origin);
  }

  void _drawCueWithLeader(
    Canvas canvas,
    Offset labelAt,
    Offset target,
    String text,
    Color color,
  ) {
    canvas.drawLine(
      labelAt,
      target,
      Paint()
        ..color = color.withValues(alpha: .32)
        ..strokeWidth = 1,
    );
    _drawCue(canvas, labelAt, text, color);
  }

  AuthoredTouchPoint _pointAlongPath(
    List<AuthoredTouchPoint> points,
    double fraction,
  ) {
    if (points.length == 1) return points.first;
    var total = 0.0;
    for (var index = 1; index < points.length; index++) {
      total += points[index - 1].distanceTo(points[index]);
    }
    var remaining = total * fraction.clamp(0.0, 1.0);
    for (var index = 1; index < points.length; index++) {
      final length = points[index - 1].distanceTo(points[index]);
      if (remaining <= length || index == points.length - 1) {
        return AuthoredTouchPoint.lerp(
          points[index - 1],
          points[index],
          length <= 1e-9 ? 0 : remaining / length,
        );
      }
      remaining -= length;
    }
    return points.last;
  }

  Rect _boundsOf(Iterable<Offset> points) {
    final iterator = points.iterator;
    if (!iterator.moveNext()) return Rect.zero;
    var minX = iterator.current.dx;
    var maxX = minX;
    var minY = iterator.current.dy;
    var maxY = minY;
    while (iterator.moveNext()) {
      minX = math.min(minX, iterator.current.dx);
      maxX = math.max(maxX, iterator.current.dx);
      minY = math.min(minY, iterator.current.dy);
      maxY = math.max(maxY, iterator.current.dy);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  List<Offset> _convexHull(List<Offset> points) {
    if (points.length <= 2) return points;
    final sorted = <Offset>[...points]..sort((a, b) {
        final x = a.dx.compareTo(b.dx);
        return x != 0 ? x : a.dy.compareTo(b.dy);
      });
    double cross(Offset origin, Offset a, Offset b) =>
        (a.dx - origin.dx) * (b.dy - origin.dy) -
        (a.dy - origin.dy) * (b.dx - origin.dx);
    final lower = <Offset>[];
    for (final point in sorted) {
      while (lower.length >= 2 &&
          cross(lower[lower.length - 2], lower.last, point) <= 0) {
        lower.removeLast();
      }
      lower.add(point);
    }
    final upper = <Offset>[];
    for (final point in sorted.reversed) {
      while (upper.length >= 2 &&
          cross(upper[upper.length - 2], upper.last, point) <= 0) {
        upper.removeLast();
      }
      upper.add(point);
    }
    return <Offset>[
      ...lower.take(lower.length - 1),
      ...upper.take(upper.length - 1),
    ];
  }

  @override
  bool shouldRepaint(covariant _AuthoredTouchSamplePainter oldDelegate) =>
      oldDelegate.frame.time != frame.time ||
      oldDelegate.frame.continuation != frame.continuation ||
      oldDelegate.detail != detail ||
      oldDelegate.dark != dark ||
      oldDelegate.textScaler != textScaler;
}

class _AuthoredTouchPitchGeometry {
  final Size size;
  final AuthoredTouchBounds bounds;
  final double margin;
  final double labelInset;
  late final double scale;
  late final Rect pitchRect;

  _AuthoredTouchPitchGeometry(
    this.size,
    this.bounds, {
    this.margin = 7,
    this.labelInset = 0,
  }) {
    final available = Rect.fromLTWH(
      margin,
      margin + labelInset,
      math.max(1, size.width - margin * 2),
      math.max(1, size.height - margin * 2 - labelInset * 2),
    );
    scale = math.min(
      available.width / bounds.width,
      available.height / bounds.height,
    );
    pitchRect = Rect.fromLTWH(
      available.left + (available.width - bounds.width * scale) / 2,
      available.top + (available.height - bounds.height * scale) / 2,
      bounds.width * scale,
      bounds.height * scale,
    );
  }

  Offset project(AuthoredTouchPoint point) => Offset(
        pitchRect.left + (point.x - bounds.minX) * scale,
        pitchRect.bottom - (point.y - bounds.minY) * scale - point.z * scale,
      );

  Offset direction(AuthoredTouchPoint root, double facing) {
    final start = project(root);
    final end = project(
      AuthoredTouchPoint(
        root.x + math.cos(facing),
        root.y + math.sin(facing),
        root.z,
      ),
    );
    final vector = end - start;
    return vector.distance <= 1e-9
        ? const Offset(1, 0)
        : vector / vector.distance;
  }
}
