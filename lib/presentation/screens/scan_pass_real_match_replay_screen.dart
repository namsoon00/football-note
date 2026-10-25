part of 'scan_pass_game_screen.dart';

typedef ScanPassReplayDataLoader = Future<RealMatchReplayData> Function();

class ScanPassRealMatchReplayScreen extends StatefulWidget {
  final MatchMomentSourceLauncher? sourceLauncher;
  final ScanPassReplayDataLoader? dataLoader;

  const ScanPassRealMatchReplayScreen({
    super.key,
    this.sourceLauncher,
    this.dataLoader,
  });

  @override
  State<ScanPassRealMatchReplayScreen> createState() =>
      _ScanPassRealMatchReplayScreenState();
}

class _ScanPassRealMatchReplayScreenState
    extends State<ScanPassRealMatchReplayScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const String _dataAsset = 'assets/scan_pass_replay/replay-data.json';
  static const String _licenseAsset = 'assets/scan_pass_replay/LICENSE';
  static const String _sourceUrl =
      'https://github.com/SkillCorner/opendata/tree/4340d274572876239c154c90bc507a9b3250a656';
  static bool _licenseRegistered = false;

  late final AnimationController _controller;
  RealMatchReplayData? _data;
  Object? _loadError;
  bool _playing = false;
  bool _explanation = false;
  bool _zoom = false;
  double _speed = 1;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;
  double get _time => (_data?.duration ?? 0) * _controller.value;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      // User-initiated match playback must keep the source timing, including
      // when accessibility settings shorten decorative UI animations.
      animationBehavior: AnimationBehavior.preserve,
    )
      ..addListener(_handleTick)
      ..addStatusListener(_handleStatus);
    _registerLicense();
    _load();
  }

  static void _registerLicense() {
    if (_licenseRegistered) return;
    _licenseRegistered = true;
    LicenseRegistry.addLicense(() async* {
      final license = await rootBundle.loadString(_licenseAsset);
      yield LicenseEntryWithLineBreaks(
        const <String>['SkillCorner Open Data'],
        license,
      );
    });
  }

  Future<void> _load() async {
    try {
      final loader = widget.dataLoader ??
          () async => RealMatchReplayData.fromJsonString(
                await rootBundle.loadString(_dataAsset),
              );
      final data = await loader();
      if (!mounted) return;
      _controller.duration = _playbackDuration(data.duration, _speed);
      setState(() {
        _data = data;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error);
    }
  }

  Duration _playbackDuration(double seconds, double speed) =>
      Duration(milliseconds: (seconds * 1000 / speed).round());

  void _handleTick() {
    if (mounted) setState(() {});
  }

  void _handleStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !_playing || !mounted) return;
    setState(() => _playing = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.inactive &&
        state != AppLifecycleState.paused &&
        state != AppLifecycleState.detached &&
        state != AppLifecycleState.hidden) {
      return;
    }
    _controller.stop();
    if (_playing && mounted) setState(() => _playing = false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller
      ..removeListener(_handleTick)
      ..removeStatusListener(_handleStatus)
      ..dispose();
    super.dispose();
  }

  void _togglePlayback() {
    final data = _data;
    if (data == null) return;
    if (_playing) {
      _controller.stop();
      setState(() => _playing = false);
      return;
    }
    if (_controller.isCompleted) {
      _controller.value = 0;
      if (!_explanation) {
        _explanation = true;
        _speed = .5;
        _controller.duration = _playbackDuration(data.duration, _speed);
      }
    }
    setState(() => _playing = true);
    _controller.forward();
  }

  void _pauseAt(double seconds, {bool explain = false}) {
    final data = _data;
    if (data == null) return;
    _controller.stop();
    _controller.value = (seconds / data.duration).clamp(0.0, 1.0);
    setState(() {
      _playing = false;
      if (explain) _explanation = true;
    });
  }

  void _setSpeed(double? speed) {
    final data = _data;
    if (data == null || speed == null || speed == _speed) return;
    final wasPlaying = _playing;
    _controller.stop();
    setState(() {
      _speed = speed;
      _controller.duration = _playbackDuration(data.duration, speed);
    });
    if (wasPlaying) _controller.forward();
  }

  Future<void> _openSource() async {
    final uri = Uri.parse(_sourceUrl);
    final launcher = widget.sourceLauncher ??
        (Uri value) => launchUrl(value, mode: LaunchMode.externalApplication);
    var opened = false;
    try {
      opened = await launcher(uri);
    } catch (_) {
      opened = false;
    }
    if (!mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_l10n.realMatchReplaySourceUnavailable)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = _ScanPassColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(_l10n.realMatchReplayAppBarTitle)),
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
            Icon(Icons.sports_soccer, size: 42, color: colors.muted),
            const SizedBox(height: 12),
            Text(
              _l10n.realMatchReplayLoadFailed,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                setState(() => _loadError = null);
                _load();
              },
              child: Text(_l10n.realMatchReplayRetry),
            ),
          ]),
        ),
      );
    }
    final data = _data;
    if (data == null) {
      return Center(
        child: Semantics(
          label: _l10n.realMatchReplayLoading,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    return LayoutBuilder(builder: (context, constraints) {
      final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
      final stageHeight = (constraints.maxHeight - 340 - (textScale - 1) * 140)
          .clamp(textScale > 1.2 ? 520.0 : 380.0, 620.0);
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border.all(color: colors.line),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(data, colors),
                    _buildStage(data, colors, stageHeight),
                    _buildProgress(data, colors),
                    _buildControls(data, colors),
                    _buildChapters(data, colors),
                    _buildCredit(colors),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildHeader(RealMatchReplayData data, _ScanPassColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          _l10n.realMatchReplayHeaderMeta(data.match.date),
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: colors.muted),
        ),
        const SizedBox(height: 3),
        Text(
          _l10n.realMatchReplayTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.text,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 7),
        Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 7,
            children: [
              Text(data.match.home, style: TextStyle(color: colors.text)),
              const _ReplayTeamDot(color: Color(0xFFFF8000)),
              Text(_l10n.realMatchReplayVersus,
                  style: TextStyle(color: colors.muted)),
              const _ReplayTeamDot(color: Colors.white, outlined: true),
              Text(data.match.away, style: TextStyle(color: colors.text)),
            ]),
      ]),
    );
  }

  Widget _buildStage(
    RealMatchReplayData data,
    _ScanPassColors colors,
    double height,
  ) {
    final l10n = _l10n;
    return LayoutBuilder(builder: (context, constraints) {
      final narrow = constraints.maxWidth < 490;
      final phase = data.phaseAt(_time);
      final copy = _copyFor(l10n, phase);
      final finalPhase = phase == RealMatchReplayPhase.outcome;
      return SizedBox(
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Stack(children: [
            Positioned.fill(
              child: Semantics(
                image: true,
                label: l10n.realMatchReplayPitchSemantics,
                child: ExcludeSemantics(
                  child: CustomPaint(
                    key: const ValueKey<String>('replay-pitch'),
                    painter: _RealMatchReplayPainter(
                      data: data,
                      time: _time,
                      explanation: _explanation,
                      showZoom: _zoom,
                      copy: copy,
                      brightness: Theme.of(context).brightness,
                      textDirection: Directionality.of(context),
                      textScaler: MediaQuery.textScalerOf(context),
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
            Positioned(
              left: narrow ? 10 : 14,
              right: narrow ? 10 : 150,
              top: 10,
              child: IgnorePointer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _explanation
                          ? l10n.realMatchReplayExplanationKicker(copy.phase)
                          : l10n.realMatchReplayObservationKicker(copy.phase),
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: colors.muted),
                    ),
                    Text(
                      copy.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.text,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: narrow ? null : 22,
              right: narrow ? 9 : 12,
              bottom: narrow ? 32 : null,
              child: OutlinedButton.icon(
                key: const ValueKey<String>('replay-zoom'),
                onPressed: () => setState(() => _zoom = !_zoom),
                icon: Icon(_zoom ? Icons.close_fullscreen : Icons.zoom_in,
                    size: 16),
                label: Text(l10n.realMatchReplayZoomAction),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(44, 38),
                  foregroundColor: colors.text,
                  backgroundColor: _zoom ? colors.active : colors.surface,
                  side: BorderSide(color: colors.line),
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  textStyle: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
            if (_zoom)
              Positioned(
                left: narrow ? 9 : 12,
                top: narrow && finalPhase ? null : 88,
                bottom: narrow && finalPhase ? 62 : null,
                width: 132,
                height: 190,
                child: _ReplayPoseCard(
                  data: data,
                  time: _time,
                  colors: colors,
                ),
              ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 8,
              child: IgnorePointer(
                child: Row(children: [
                  Expanded(
                    child: Row(children: [
                      Flexible(
                        child: Text(
                          l10n.realMatchReplayPitchFocus,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: colors.muted),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(narrow ? '↑' : '→',
                          style: TextStyle(color: colors.muted)),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.realMatchReplayMatchClock('77:34.48', '77:46.80'),
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: colors.muted),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      );
    });
  }

  Widget _buildProgress(RealMatchReplayData data, _ScanPassColors colors) {
    final current = _time.clamp(0.0, data.duration);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(children: [
        Expanded(
          child: Slider(
            key: const ValueKey<String>('replay-scrub'),
            min: 0,
            max: data.duration,
            divisions: data.frames.length - 1,
            value: current,
            semanticFormatterCallback: (value) =>
                _l10n.realMatchReplaySeconds(value.toStringAsFixed(1)),
            onChangeStart: (_) {
              _controller.stop();
              setState(() => _playing = false);
            },
            onChanged: (value) => _pauseAt(value),
          ),
        ),
        const SizedBox(width: 6),
        ExcludeSemantics(
          child: Text(
            _l10n.realMatchReplayTime(
              _clock(current),
              _clock(data.duration),
            ),
            key: const ValueKey<String>('replay-time'),
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: colors.muted, fontFeatures: const [
              FontFeature.tabularFigures(),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildControls(RealMatchReplayData data, _ScanPassColors colors) {
    final l10n = _l10n;
    final playLabel = _playing
        ? l10n.realMatchReplayPause
        : _controller.isCompleted
            ? (_explanation
                ? l10n.realMatchReplayRestart
                : l10n.realMatchReplayGuidedReplay)
            : _time > .02
                ? l10n.realMatchReplayContinue
                : l10n.realMatchReplayPlay;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
      child: Wrap(
        spacing: 10,
        runSpacing: 7,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          FilledButton.icon(
            key: const ValueKey<String>('replay-play'),
            onPressed: _togglePlayback,
            icon: Icon(_playing ? Icons.pause : Icons.play_arrow, size: 19),
            label: Text(playLabel),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
          ),
          FilterChip(
            key: const ValueKey<String>('replay-explanation'),
            selected: _explanation,
            onSelected: (selected) => setState(() => _explanation = selected),
            avatar: const Icon(Icons.subtitles_outlined, size: 17),
            label: Text(l10n.realMatchReplayExplanationToggle),
          ),
          Semantics(
            label: l10n.realMatchReplaySpeedLabel,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: colors.line),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<double>(
                    key: const ValueKey<String>('replay-speed'),
                    value: _speed,
                    isDense: true,
                    onChanged: _setSpeed,
                    items: <DropdownMenuItem<double>>[
                      DropdownMenuItem(
                        value: 1,
                        child: Text(l10n.realMatchReplaySpeedNormal),
                      ),
                      DropdownMenuItem(
                        value: .5,
                        child: Text(l10n.realMatchReplaySpeedHalf),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapters(RealMatchReplayData data, _ScanPassColors colors) {
    const times = <double>[0, 2.44, 4.8, 9.4];
    final labels = <String>[
      _l10n.realMatchReplayChapterPrepare,
      _l10n.realMatchReplayChapterPass,
      _l10n.realMatchReplayChapterAdvance,
      _l10n.realMatchReplayChapterRecovery,
    ];
    final active = _time < times[1]
        ? 0
        : _time < times[2]
            ? 1
            : _time < times[3]
                ? 2
                : 3;
    return Semantics(
      container: true,
      label: _l10n.realMatchReplayChaptersSemantics,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 9),
        child: Row(
          key: const ValueKey<String>('replay-chapters'),
          children: List<Widget>.generate(labels.length, (index) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: OutlinedButton(
                  key: ValueKey<String>('replay-chapter-$index'),
                  onPressed: () => _pauseAt(times[index], explain: true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        active == index ? colors.text : colors.muted,
                    backgroundColor:
                        active == index ? colors.active : Colors.transparent,
                    minimumSize: const Size(42, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    side: BorderSide(
                      color: active == index ? colors.accent : colors.line,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(labels[index], maxLines: 1),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCredit(_ScanPassColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 10, 13),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Text(
            _l10n.realMatchReplayDisclosure,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: colors.muted),
          ),
        ),
        const SizedBox(width: 6),
        TextButton(
          key: const ValueKey<String>('replay-source'),
          onPressed: _openSource,
          style: TextButton.styleFrom(
            foregroundColor: colors.text,
            padding: const EdgeInsets.symmetric(horizontal: 7),
            minimumSize: const Size(44, 36),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.open_in_new, size: 15),
            const SizedBox(width: 5),
            Text(_l10n.realMatchReplaySource),
          ]),
        ),
      ]),
    );
  }

  _ReplayPitchCopy _copyFor(
    AppLocalizations l10n,
    RealMatchReplayPhase phase,
  ) {
    return switch (phase) {
      RealMatchReplayPhase.prepare => _ReplayPitchCopy(
          phase: l10n.realMatchReplayPhasePrepare,
          title: l10n.realMatchReplayPhasePrepareTitle,
          annotations: <String>[
            l10n.realMatchReplayAnnotationCarry8,
            l10n.realMatchReplayAnnotationMove18,
          ],
        ),
      RealMatchReplayPhase.spacePass => _ReplayPitchCopy(
          phase: l10n.realMatchReplayPhasePass,
          title: l10n.realMatchReplayPhasePassTitle,
          annotations: <String>[
            l10n.realMatchReplayAnnotationReceivingSpace,
            l10n.realMatchReplayAnnotationConnect18,
          ],
        ),
      RealMatchReplayPhase.advance => _ReplayPitchCopy(
          phase: l10n.realMatchReplayPhaseAdvance,
          title: l10n.realMatchReplayPhaseAdvanceTitle,
          annotations: <String>[
            l10n.realMatchReplayAnnotationAdvance18,
            l10n.realMatchReplayAnnotationRecover19,
          ],
        ),
      RealMatchReplayPhase.recovery => _ReplayPitchCopy(
          phase: l10n.realMatchReplayPhaseRecovery,
          title: l10n.realMatchReplayPhaseRecoveryTitle,
          annotations: <String>[
            l10n.realMatchReplayAnnotationTurn18,
            l10n.realMatchReplayAnnotationClose1917,
          ],
        ),
      RealMatchReplayPhase.outcome => _ReplayPitchCopy(
          phase: l10n.realMatchReplayPhaseOutcome,
          title: l10n.realMatchReplayPhaseOutcomeTitle,
          annotations: <String>[
            l10n.realMatchReplayAnnotationShotPath,
            _time >= 12.28
                ? l10n.realMatchReplayAnnotationKeeperPossession
                : l10n.realMatchReplayAnnotationKeeper13,
          ],
        ),
    };
  }

  String _clock(double seconds) {
    final whole = seconds.floor();
    return '${whole ~/ 60}:${(whole % 60).toString().padLeft(2, '0')}';
  }
}

class _ReplayTeamDot extends StatelessWidget {
  final Color color;
  final bool outlined;

  const _ReplayTeamDot({required this.color, this.outlined = false});

  @override
  Widget build(BuildContext context) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: outlined
              ? Border.all(color: _ScanPassColors.of(context).line)
              : null,
        ),
      );
}

class _ReplayPoseCard extends StatelessWidget {
  static const int _player18 = 965698;

  final RealMatchReplayData data;
  final double time;
  final _ScanPassColors colors;

  const _ReplayPoseCard({
    required this.data,
    required this.time,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pose = data.poseAt(time, data.playerIndex(_player18));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: .96),
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 6, 5, 5),
        child: Column(children: [
          Text(
            l10n.realMatchReplayPoseTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: colors.text),
          ),
          Expanded(
            child: pose == null
                ? Center(
                    child: Icon(Icons.accessibility_new,
                        size: 34, color: colors.muted),
                  )
                : CustomPaint(
                    painter: _ReplayPosePainter(
                      data: data,
                      pose: pose,
                      brightness: Theme.of(context).brightness,
                    ),
                    size: Size.infinite,
                  ),
          ),
          Text(
            pose == null
                ? l10n.realMatchReplayPoseUnavailable
                : l10n.realMatchReplayPoseAvailable,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: colors.muted, fontSize: 10),
          ),
        ]),
      ),
    );
  }
}

class _ReplayPitchCopy {
  final String phase;
  final String title;
  final List<String> annotations;

  const _ReplayPitchCopy({
    required this.phase,
    required this.title,
    required this.annotations,
  });
}

class _RealMatchReplayPainter extends CustomPainter {
  static const int _home8 = 287934;
  static const int _home18 = 965698;
  static const int _away19 = 11897;
  static const int _away17 = 795533;
  static const int _keeper13 = 560985;

  final RealMatchReplayData data;
  final double time;
  final bool explanation;
  final bool showZoom;
  final _ReplayPitchCopy copy;
  final Brightness brightness;
  final TextDirection textDirection;
  final TextScaler textScaler;

  const _RealMatchReplayPainter({
    required this.data,
    required this.time,
    required this.explanation,
    required this.showZoom,
    required this.copy,
    required this.brightness,
    required this.textDirection,
    required this.textScaler,
  });

  bool get _dark => brightness == Brightness.dark;
  Color get _pitch => _dark ? const Color(0xFF183D2B) : const Color(0xFFD7E5D9);
  Color get _stripe =>
      _dark ? const Color(0xFF235034) : const Color(0xFFB9CDBD);
  Color get _line => _dark ? const Color(0xFF628A70) : const Color(0xFF789985);
  Color get _surface =>
      _dark ? const Color(0xFF11211D) : const Color(0xFFFBFCFC);
  Color get _text => _dark ? const Color(0xFFE6F2EB) : const Color(0xFF172E29);
  Color get _good => _dark ? const Color(0xFF9AE6BF) : const Color(0xFF09664F);
  Color get _pressure =>
      _dark ? const Color(0xFFF4B49E) : const Color(0xFFA03E36);
  Color get _shadow =>
      _dark ? const Color(0xFF07130D) : const Color(0xFF334E3B);

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = ReplayPitchGeometry.forSize(size);
    final sample = data.sample(time);
    _drawPitch(canvas, size, geometry);
    final marks = explanation
        ? _drawExplanation(canvas, geometry, sample)
        : const <_ReplayMark>[];
    final occupied = _drawPeople(canvas, geometry, sample);
    _drawBall(canvas, geometry, sample.ball);
    final miniMap = _drawMiniMap(canvas, size, geometry, sample, occupied);
    if (!miniMap.isEmpty) occupied.add(miniMap);
    if (explanation) {
      _drawLabels(canvas, size, geometry, sample, marks, occupied);
    }
  }

  void _drawPitch(Canvas canvas, Size size, ReplayPitchGeometry geometry) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _pitch);
    for (var x = -52.5; x < 52.5; x += 10) {
      if (((x + 52.5) / 10).round().isOdd) continue;
      final path = Path()
        ..moveTo(geometry.project(x, -34).dx, geometry.project(x, -34).dy)
        ..lineTo(geometry.project(math.min(x + 10, 52.5), -34).dx,
            geometry.project(math.min(x + 10, 52.5), -34).dy)
        ..lineTo(geometry.project(math.min(x + 10, 52.5), 34).dx,
            geometry.project(math.min(x + 10, 52.5), 34).dy)
        ..lineTo(geometry.project(x, 34).dx, geometry.project(x, 34).dy)
        ..close();
      canvas.drawPath(path, Paint()..color = _stripe.withValues(alpha: .22));
    }
    final paint = Paint()
      ..color = _line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    void worldLine(List<RealMatchReplayPoint> points) {
      final path = Path();
      for (var index = 0; index < points.length; index++) {
        final point = geometry.project(points[index].x, points[index].y);
        if (index == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path, paint);
    }

    worldLine(const <RealMatchReplayPoint>[
      RealMatchReplayPoint(-52.5, -34),
      RealMatchReplayPoint(52.5, -34),
      RealMatchReplayPoint(52.5, 34),
      RealMatchReplayPoint(-52.5, 34),
      RealMatchReplayPoint(-52.5, -34),
    ]);
    worldLine(const <RealMatchReplayPoint>[
      RealMatchReplayPoint(0, -34),
      RealMatchReplayPoint(0, 34),
    ]);
    worldLine(const <RealMatchReplayPoint>[
      RealMatchReplayPoint(52.5, -20.16),
      RealMatchReplayPoint(36, -20.16),
      RealMatchReplayPoint(36, 20.16),
      RealMatchReplayPoint(52.5, 20.16),
    ]);
    worldLine(const <RealMatchReplayPoint>[
      RealMatchReplayPoint(52.5, -9.16),
      RealMatchReplayPoint(47, -9.16),
      RealMatchReplayPoint(47, 9.16),
      RealMatchReplayPoint(52.5, 9.16),
    ]);
    worldLine(const <RealMatchReplayPoint>[
      RealMatchReplayPoint(52.5, -3.66),
      RealMatchReplayPoint(54.5, -3.66),
      RealMatchReplayPoint(54.5, 3.66),
      RealMatchReplayPoint(52.5, 3.66),
    ]);
    final circle = List<RealMatchReplayPoint>.generate(65, (index) {
      final angle = index / 64 * math.pi * 2;
      return RealMatchReplayPoint(
        math.cos(angle) * 9.15,
        math.sin(angle) * 9.15,
      );
    });
    worldLine(circle);
    canvas.drawCircle(geometry.project(41.5, 0), 2, Paint()..color = _line);
  }

  List<_ReplayMark> _drawExplanation(
    Canvas canvas,
    ReplayPitchGeometry geometry,
    RealMatchReplaySample sample,
  ) {
    final phase = data.phaseAt(time);
    final index8 = data.playerIndex(_home8);
    final index18 = data.playerIndex(_home18);
    final index19 = data.playerIndex(_away19);
    final index17 = data.playerIndex(_away17);
    final index13 = data.playerIndex(_keeper13);
    switch (phase) {
      case RealMatchReplayPhase.prepare:
        if (time > .04) {
          _drawPlayerTrail(canvas, geometry, index18, 0, time, _good,
              dashed: true);
        }
        return <_ReplayMark>[
          _ReplayMark(copy.annotations[0], sample.players[index8], _good),
          _ReplayMark(copy.annotations[1], sample.players[index18], _good),
        ];
      case RealMatchReplayPhase.spacePass:
        final start = data.sample(2.42);
        final reception = data.sample(4.22);
        _drawWorldPath(
          canvas,
          geometry,
          <RealMatchReplayPoint>[start.ball, reception.ball],
          _good.withValues(alpha: .4),
          1.2,
        );
        _drawBallTrail(canvas, geometry, 2.42, math.min(4.22, time), _good);
        _drawPlayerTrail(
          canvas,
          geometry,
          index18,
          2.42,
          math.min(4.22, time),
          _good,
          dashed: true,
        );
        final receptionPoint =
            geometry.project(reception.ball.x, reception.ball.y);
        canvas.drawCircle(
          receptionPoint,
          geometry.scale * 1.5,
          Paint()
            ..color = _good.withValues(alpha: .65)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
        return <_ReplayMark>[
          _ReplayMark(copy.annotations[0], reception.ball, _good),
          _ReplayMark(copy.annotations[1], sample.players[index18], _good),
        ];
      case RealMatchReplayPhase.advance:
        _drawBallTrail(
          canvas,
          geometry,
          math.max(4.22, time - 1.5),
          time,
          _good,
        );
        _drawPlayerTrail(
          canvas,
          geometry,
          index19,
          math.max(4.22, time - 1.5),
          time,
          _pressure,
          dashed: true,
        );
        return <_ReplayMark>[
          _ReplayMark(copy.annotations[0], sample.players[index18], _good),
          _ReplayMark(copy.annotations[1], sample.players[index19], _pressure),
        ];
      case RealMatchReplayPhase.recovery:
        for (final index in <int>[index18, index19, index17]) {
          _drawPlayerTrail(
            canvas,
            geometry,
            index,
            math.max(8, time - 1.5),
            time,
            index == index18 ? _good : _pressure,
            dashed: true,
          );
        }
        return <_ReplayMark>[
          _ReplayMark(copy.annotations[0], sample.players[index18], _good),
          _ReplayMark(copy.annotations[1], sample.players[index17], _pressure),
        ];
      case RealMatchReplayPhase.outcome:
        _drawBallTrail(canvas, geometry, 11.22, time, _good);
        return <_ReplayMark>[
          _ReplayMark(copy.annotations[0], sample.ball, _good),
          _ReplayMark(copy.annotations[1], sample.players[index13], _pressure),
        ];
    }
  }

  void _drawPlayerTrail(
    Canvas canvas,
    ReplayPitchGeometry geometry,
    int playerIndex,
    double from,
    double to,
    Color color, {
    bool dashed = false,
  }) {
    if (to <= from) return;
    final points = <RealMatchReplayPoint>[];
    for (var cursor = from; cursor < to; cursor += .12) {
      points.add(data.sample(cursor).players[playerIndex]);
    }
    points.add(data.sample(to).players[playerIndex]);
    _drawWorldPath(canvas, geometry, points, color.withValues(alpha: .82), 2,
        dashed: dashed, arrow: true);
  }

  void _drawBallTrail(
    Canvas canvas,
    ReplayPitchGeometry geometry,
    double from,
    double to,
    Color color,
  ) {
    if (to <= from) return;
    final points = <RealMatchReplayPoint>[];
    for (var cursor = from; cursor < to; cursor += .08) {
      points.add(data.sample(cursor).ball);
    }
    points.add(data.sample(to).ball);
    _drawWorldPath(canvas, geometry, points, color.withValues(alpha: .9), 2.4,
        arrow: true);
  }

  void _drawWorldPath(
    Canvas canvas,
    ReplayPitchGeometry geometry,
    List<RealMatchReplayPoint> points,
    Color color,
    double width, {
    bool dashed = false,
    bool arrow = false,
  }) {
    if (points.length < 2) return;
    final screen = points
        .map((point) => geometry.project(point.x, point.y, point.z))
        .toList(growable: false);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = width;
    if (dashed) {
      for (var index = 1; index < screen.length; index++) {
        if (index.isOdd) {
          canvas.drawLine(screen[index - 1], screen[index], paint);
        }
      }
    } else {
      final path = Path()..moveTo(screen.first.dx, screen.first.dy);
      for (final point in screen.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
    if (!arrow) return;
    final a = screen[screen.length - 2];
    final b = screen.last;
    final angle = math.atan2(b.dy - a.dy, b.dx - a.dx);
    final arrowPath = Path()
      ..moveTo(
        b.dx - 7 * math.cos(angle - .45),
        b.dy - 7 * math.sin(angle - .45),
      )
      ..lineTo(b.dx, b.dy)
      ..lineTo(
        b.dx - 7 * math.cos(angle + .45),
        b.dy - 7 * math.sin(angle + .45),
      );
    canvas.drawPath(arrowPath, paint);
  }

  List<Rect> _drawPeople(
    Canvas canvas,
    ReplayPitchGeometry geometry,
    RealMatchReplaySample sample,
  ) {
    final entries = List<int>.generate(data.players.length, (index) => index)
      ..sort((a, b) => geometry
          .project(sample.players[a].x, sample.players[a].y)
          .dy
          .compareTo(
              geometry.project(sample.players[b].x, sample.players[b].y).dy));
    final occupied = <Rect>[];
    final bodyScale = math.max(20.0, geometry.scale * 1.5);
    for (final index in entries) {
      final base = sample.players[index];
      final ground = geometry.project(base.x, base.y);
      if (ground.dx < -25 ||
          ground.dx > geometry.size.width + 25 ||
          ground.dy < 68 ||
          ground.dy > geometry.size.height - 22) {
        continue;
      }
      canvas.drawOval(
        Rect.fromCenter(center: ground.translate(0, 1), width: 16, height: 6),
        Paint()..color = _shadow.withValues(alpha: .2),
      );
      final measured = data.poseAt(time, index);
      final pose = measured ?? _fallbackPose(index);
      final joints = <String, RealMatchReplayPoint>{
        for (var joint = 0; joint < data.joints.length; joint++)
          data.joints[joint]: pose.joints[joint],
      };
      final baseZ = math.max(
        -.05,
        math.min(joints['lHeel']!.z, joints['rHeel']!.z),
      );
      final local = bodyScale / geometry.scale;
      Offset projectJoint(String name) {
        final joint = joints[name]!;
        final point = geometry.project(
          base.x + joint.x * local,
          base.y + joint.y * local,
        );
        return point.translate(0, -(joint.z - baseZ) * bodyScale * .85);
      }

      if (explanation &&
          (data.players[index].id == _home8 ||
              data.players[index].id == _home18)) {
        canvas.drawOval(
          Rect.fromCenter(center: ground, width: 24, height: 10),
          Paint()
            ..color = _good.withValues(alpha: .52)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.3,
        );
      }
      final head = _drawPlayerBody(
        canvas,
        projectJoint,
        bodyScale,
        data.players[index],
      );
      occupied.add(Rect.fromLTRB(
        ground.dx - 15,
        math.min(head.dy, ground.dy) - 8,
        ground.dx + 15,
        ground.dy + 8,
      ));
    }
    return occupied;
  }

  RealMatchReplayPose _fallbackPose(int playerIndex) {
    final before = data.sample(math.max(0, time - .08)).players[playerIndex];
    final after =
        data.sample(math.min(data.duration, time + .08)).players[playerIndex];
    final dx = after.x - before.x;
    final dy = after.y - before.y;
    final speed = math.sqrt(dx * dx + dy * dy) / .16;
    final theta = math.sqrt(dx * dx + dy * dy) > .05 ? math.atan2(dy, dx) : 0.0;
    final forward = RealMatchReplayPoint(math.cos(theta), math.sin(theta));
    final side = RealMatchReplayPoint(-forward.y, forward.x);
    final stride = math.sin(time * (6 + math.min(speed, 7)) + playerIndex) *
        math.min(.35, speed * .06);
    RealMatchReplayPoint make(double lateral, double along, double z) =>
        RealMatchReplayPoint(
          side.x * lateral + forward.x * along,
          side.y * lateral + forward.y * along,
          z,
        );
    final fallback = <String, RealMatchReplayPoint>{
      'nose': make(0, .1, 1.65),
      'neck': make(0, 0, 1.43),
      'lShoulder': make(.21, 0, 1.42),
      'rShoulder': make(-.21, 0, 1.42),
      'lElbow': make(.28, stride, 1.15),
      'rElbow': make(-.28, -stride, 1.15),
      'lWrist': make(.26, stride * 1.4, .9),
      'rWrist': make(-.26, -stride * 1.4, .9),
      'lHip': make(.13, 0, .86),
      'rHip': make(-.13, 0, .86),
      'lKnee': make(.14, -stride, .45),
      'rKnee': make(-.14, stride, .45),
      'lAnkle': make(.15, -stride * 1.6, .07),
      'rAnkle': make(-.15, stride * 1.6, .07),
      'lHeel': make(.15, -stride * 1.6 - .1, .03),
      'rHeel': make(-.15, stride * 1.6 - .1, .03),
      'lBigToe': make(.15, -stride * 1.6 + .15, .03),
      'rBigToe': make(-.15, stride * 1.6 + .15, .03),
    };
    return RealMatchReplayPose(
      data.joints.map((joint) => fallback[joint]!).toList(growable: false),
    );
  }

  Offset _drawPlayerBody(
    Canvas canvas,
    Offset Function(String name) joint,
    double scale,
    RealMatchReplayPlayer player,
  ) {
    final kit = player.home ? const Color(0xFFFF8000) : Colors.white;
    const shorts = Color(0xFF183345);
    const skin = Color(0xFFC99B78);
    const boots = Color(0xFF192625);
    final number = player.home ? Colors.white : const Color(0xFF17202D);
    void line(String a, String b, Color color, double width) {
      canvas.drawLine(
        joint(a),
        joint(b),
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }

    for (final side in <String>['l', 'r']) {
      line('${side}Hip', '${side}Knee', shorts, scale * .15);
      line('${side}Knee', '${side}Ankle', Colors.white, scale * .10);
      line('${side}Heel', '${side}BigToe', boots, scale * .12);
    }
    for (final side in <String>['l', 'r']) {
      line('${side}Shoulder', '${side}Elbow', kit, scale * .13);
      line('${side}Elbow', '${side}Wrist', skin, scale * .10);
    }
    final leftShoulder = joint('lShoulder');
    final rightShoulder = joint('rShoulder');
    final leftHip = joint('lHip');
    final rightHip = joint('rHip');
    final torso = Path()
      ..moveTo(leftShoulder.dx, leftShoulder.dy)
      ..lineTo(rightShoulder.dx, rightShoulder.dy)
      ..lineTo(rightHip.dx, rightHip.dy)
      ..lineTo(leftHip.dx, leftHip.dy)
      ..close();
    canvas.drawPath(torso, Paint()..color = kit);
    canvas.drawPath(
      torso,
      Paint()
        ..color = player.home ? shorts : const Color(0xFF53695F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .7,
    );
    line('neck', 'nose', skin, scale * .13);
    final head = joint('nose');
    canvas.drawCircle(
      head.translate(0, -scale * .03),
      math.max(2, scale * .095),
      Paint()..color = skin,
    );
    final center = Offset(
      (leftShoulder.dx + rightShoulder.dx + leftHip.dx + rightHip.dx) / 4,
      (leftShoulder.dy + rightShoulder.dy + leftHip.dy + rightHip.dy) / 4,
    );
    final numberPainter = TextPainter(
      text: TextSpan(
        text: '${player.number}',
        style: TextStyle(
          color: number,
          fontSize: math.max(10, math.min(16, scale * .52)),
          fontWeight: FontWeight.w700,
          shadows: <Shadow>[
            Shadow(color: kit, blurRadius: 2),
            Shadow(color: kit, blurRadius: 2),
          ],
        ),
      ),
      textDirection: textDirection,
      textScaler: textScaler,
    )..layout();
    numberPainter.paint(
        canvas, center - numberPainter.size.center(Offset.zero));
    return head;
  }

  void _drawBall(
    Canvas canvas,
    ReplayPitchGeometry geometry,
    RealMatchReplayPoint ball,
  ) {
    final ground = geometry.project(ball.x, ball.y);
    final airborne = geometry.project(ball.x, ball.y, ball.z);
    canvas.drawOval(
      Rect.fromCenter(center: ground.translate(0, 2), width: 10, height: 4.5),
      Paint()..color = _shadow.withValues(alpha: .27),
    );
    canvas.drawCircle(airborne, 4.2, Paint()..color = Colors.white);
    canvas.drawCircle(
      airborne,
      4.2,
      Paint()
        ..color = const Color(0xFF192625)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .9,
    );
    final patch = Path();
    for (var index = 0; index < 5; index++) {
      final angle = index / 5 * math.pi * 2 - .7;
      final point = airborne.translate(
        1.8 * math.cos(angle),
        1.8 * math.sin(angle),
      );
      if (index == 0) {
        patch.moveTo(point.dx, point.dy);
      } else {
        patch.lineTo(point.dx, point.dy);
      }
    }
    patch.close();
    canvas.drawPath(patch, Paint()..color = const Color(0xFF192625));
  }

  Rect _drawMiniMap(
    Canvas canvas,
    Size size,
    ReplayPitchGeometry geometry,
    RealMatchReplaySample sample,
    List<Rect> occupied,
  ) {
    if (size.width < 620) return Rect.zero;
    const width = 104.0;
    const height = width * 68 / 105;
    final candidates = <Rect>[
      Rect.fromLTWH(
          size.width - width - 18, size.height - height - 47, width, height),
      const Rect.fromLTWH(16, 88, width, height),
      Rect.fromLTWH(size.width - width - 18, 88, width, height),
    ];
    final ball = geometry.project(sample.ball.x, sample.ball.y);
    final blocked = <Rect>[
      ...occupied,
      Rect.fromCircle(center: ball, radius: 12),
      geometry.zoomRect(
        visible: showZoom,
        finalPhase: data.phaseAt(time) == RealMatchReplayPhase.outcome,
      ),
    ];
    final rect = candidates.cast<Rect?>().firstWhere(
          (candidate) =>
              blocked.every((other) => !candidate!.inflate(5).overlaps(other)),
          orElse: () => null,
        );
    if (rect == null) return Rect.zero;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.inflate(5), const Radius.circular(4)),
      Paint()..color = _surface.withValues(alpha: .94),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = _line
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8,
    );
    canvas.drawLine(
      Offset(rect.center.dx, rect.top),
      Offset(rect.center.dx, rect.bottom),
      Paint()..color = _line,
    );
    double x(double world) => rect.left + (world + 52.5) / 105 * rect.width;
    double y(double world) => rect.top + (34 - world) / 68 * rect.height;
    for (var index = 0; index < sample.players.length; index++) {
      final point = sample.players[index];
      canvas.drawCircle(
        Offset(x(point.x), y(point.y)),
        1.6,
        Paint()
          ..color = data.players[index].home
              ? const Color(0xFFFF8000)
              : const Color(0xFF17202D),
      );
    }
    canvas.drawCircle(
      Offset(x(sample.ball.x), y(sample.ball.y)),
      2.2,
      Paint()..color = _good,
    );
    return rect.inflate(5);
  }

  void _drawLabels(
    Canvas canvas,
    Size size,
    ReplayPitchGeometry geometry,
    RealMatchReplaySample sample,
    List<_ReplayMark> marks,
    List<Rect> occupied,
  ) {
    final painters = marks.map((mark) {
      return TextPainter(
        text: TextSpan(
          text: mark.text,
          style: TextStyle(
            color: _text,
            fontSize: 11,
            height: 1.25,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: textDirection,
        textScaler: textScaler,
        maxLines: 3,
      )..layout(maxWidth: 128);
    }).toList(growable: false);
    final anchors = marks
        .map((mark) => geometry.project(mark.at.x, mark.at.y, mark.at.z))
        .toList(growable: false);
    final ball = geometry.project(sample.ball.x, sample.ball.y, sample.ball.z);
    final obstacles = <Rect>[
      ...occupied,
      Rect.fromCircle(center: ball, radius: 10),
    ];
    final zoom = geometry.zoomRect(
      visible: showZoom,
      finalPhase: data.phaseAt(time) == RealMatchReplayPhase.outcome,
    );
    if (!zoom.isEmpty) obstacles.add(zoom);
    final rects = ReplayLabelLayout.place(
      stageSize: size,
      topInset: geometry.origin.dy + 4,
      labelSizes: painters
          .map((painter) => Size(painter.width + 16, painter.height + 12))
          .toList(growable: false),
      anchors: anchors,
      obstacles: obstacles,
      protectedObstacles: <Rect>[
        Rect.fromCircle(center: ball, radius: 10),
        if (!zoom.isEmpty) zoom,
      ],
    );
    for (var index = 0; index < rects.length; index++) {
      final rect = rects[index];
      if (rect.isEmpty) continue;
      final anchor = anchors[index];
      final tone = marks[index].tone;
      final edge = Offset(
        anchor.dx.clamp(rect.left, rect.right),
        anchor.dy.clamp(rect.top, rect.bottom),
      );
      canvas.drawLine(
        edge,
        anchor,
        Paint()
          ..color = tone
          ..strokeWidth = 1,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(5)),
        Paint()..color = _surface.withValues(alpha: .96),
      );
      canvas.drawRect(
        Rect.fromLTWH(rect.left, rect.top + 5, 2, rect.height - 10),
        Paint()..color = tone,
      );
      painters[index].paint(canvas, rect.topLeft + const Offset(8, 6));
    }
    for (final painter in painters) {
      painter.dispose();
    }
  }

  @override
  bool shouldRepaint(covariant _RealMatchReplayPainter oldDelegate) =>
      data != oldDelegate.data ||
      time != oldDelegate.time ||
      explanation != oldDelegate.explanation ||
      showZoom != oldDelegate.showZoom ||
      copy != oldDelegate.copy ||
      brightness != oldDelegate.brightness ||
      textDirection != oldDelegate.textDirection ||
      textScaler != oldDelegate.textScaler;
}

class _ReplayMark {
  final String text;
  final RealMatchReplayPoint at;
  final Color tone;

  const _ReplayMark(this.text, this.at, this.tone);
}

class _ReplayPosePainter extends CustomPainter {
  final RealMatchReplayData data;
  final RealMatchReplayPose pose;
  final Brightness brightness;

  const _ReplayPosePainter({
    required this.data,
    required this.pose,
    required this.brightness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final joints = <String, RealMatchReplayPoint>{
      for (var index = 0; index < data.joints.length; index++)
        data.joints[index]: pose.joints[index],
    };
    final baseZ = math.min(joints['lHeel']!.z, joints['rHeel']!.z);
    Offset project(String name) {
      final point = joints[name]!;
      return Offset(
        size.width / 2 + (point.x * .8 - point.y * .6) * 64,
        size.height -
            8 -
            (point.z - baseZ) * 65 -
            (point.x * .6 + point.y * .8) * 18,
      );
    }

    final shadow = brightness == Brightness.dark
        ? const Color(0xFF07130D)
        : const Color(0xFF334E3B);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height - 6),
        width: 42,
        height: 10,
      ),
      Paint()..color = shadow.withValues(alpha: .18),
    );
    const kit = Color(0xFFFF8000);
    const shorts = Color(0xFF183345);
    const skin = Color(0xFFC99B78);
    const boots = Color(0xFF192625);
    void line(String a, String b, Color color, double width) {
      canvas.drawLine(
        project(a),
        project(b),
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }

    for (final side in <String>['l', 'r']) {
      line('${side}Hip', '${side}Knee', shorts, 9.2);
      line('${side}Knee', '${side}Ankle', Colors.white, 6.2);
      line('${side}Heel', '${side}BigToe', boots, 7.4);
      line('${side}Shoulder', '${side}Elbow', kit, 8.2);
      line('${side}Elbow', '${side}Wrist', skin, 6.2);
    }
    final leftShoulder = project('lShoulder');
    final rightShoulder = project('rShoulder');
    final leftHip = project('lHip');
    final rightHip = project('rHip');
    final torso = Path()
      ..moveTo(leftShoulder.dx, leftShoulder.dy)
      ..lineTo(rightShoulder.dx, rightShoulder.dy)
      ..lineTo(rightHip.dx, rightHip.dy)
      ..lineTo(leftHip.dx, leftHip.dy)
      ..close();
    canvas.drawPath(torso, Paint()..color = kit);
    line('neck', 'nose', skin, 8.2);
    canvas.drawCircle(
        project('nose').translate(0, -2), 6, Paint()..color = skin);
    final center = Offset(
      (leftShoulder.dx + rightShoulder.dx + leftHip.dx + rightHip.dx) / 4,
      (leftShoulder.dy + rightShoulder.dy + leftHip.dy + rightHip.dy) / 4,
    );
    final number = TextPainter(
      text: const TextSpan(
        text: '18',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    number.paint(canvas, center - number.size.center(Offset.zero));
  }

  @override
  bool shouldRepaint(covariant _ReplayPosePainter oldDelegate) =>
      pose != oldDelegate.pose || brightness != oldDelegate.brightness;
}
