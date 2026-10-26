part of 'scan_pass_game_screen.dart';

typedef ScanPassReplayDataLoader = Future<RealMatchReplayData> Function();
typedef ScanPassReplayCatalogLoader = Future<RealMatchReplayCatalog> Function();
typedef ScanPassReplaySceneLoader = Future<RealMatchReplayData> Function(
  RealMatchReplayCatalogScene scene,
);

class ScanPassRealMatchReplayScreen extends StatefulWidget {
  final MatchMomentSourceLauncher? sourceLauncher;
  final ScanPassReplayDataLoader? dataLoader;
  final ScanPassReplayCatalogLoader? catalogLoader;
  final ScanPassReplaySceneLoader? sceneLoader;

  const ScanPassRealMatchReplayScreen({
    super.key,
    this.sourceLauncher,
    this.dataLoader,
    this.catalogLoader,
    this.sceneLoader,
  });

  @override
  State<ScanPassRealMatchReplayScreen> createState() =>
      _ScanPassRealMatchReplayScreenState();
}

class _ScanPassRealMatchReplayScreenState
    extends State<ScanPassRealMatchReplayScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const String _catalogAsset = 'assets/scan_pass_replay/catalog.json';
  static const String _licenseAsset = 'assets/scan_pass_replay/LICENSE';
  static const String _sourceUrl =
      'https://github.com/SkillCorner/opendata/tree/4340d274572876239c154c90bc507a9b3250a656';
  static bool _licenseRegistered = false;

  late final AnimationController _controller;
  RealMatchReplayCatalog? _catalog;
  RealMatchReplayData? _data;
  Object? _loadError;
  int _sceneIndex = 0;
  int _loadGeneration = 0;
  bool _playing = false;
  bool _explanation = false;
  bool _zoom = false;
  bool _expanded = false;
  double _speed = 1;
  ReplayPitchView _view = ReplayPitchView.context;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;
  double get _time => (_data?.duration ?? 0) * _controller.value;
  bool get _compactExpanded {
    final size = MediaQuery.sizeOf(context);
    return _expanded &&
        _data != null &&
        size.width > size.height &&
        size.height < 520;
  }

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
    _registerLicense();
    _loadInitial();
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

  Future<void> _loadInitial() async {
    final generation = ++_loadGeneration;
    try {
      if (widget.dataLoader != null &&
          widget.catalogLoader == null &&
          widget.sceneLoader == null) {
        final data = await widget.dataLoader!();
        if (!mounted || generation != _loadGeneration) return;
        _applyLoaded(
          RealMatchReplayCatalog.single(data),
          data,
          sceneIndex: 0,
        );
        return;
      }
      final catalogLoader = widget.catalogLoader ??
          () async => RealMatchReplayCatalog.fromJsonString(
                await rootBundle.loadString(_catalogAsset),
              );
      final catalog = await catalogLoader();
      if (!mounted || generation != _loadGeneration) return;
      final data = await _loadSceneData(catalog.scenes.first);
      if (!mounted || generation != _loadGeneration) return;
      _validateLoadedScene(catalog, catalog.scenes.first, data);
      _applyLoaded(catalog, data, sceneIndex: 0);
    } catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() => _loadError = error);
    }
  }

  Future<RealMatchReplayData> _loadSceneData(
    RealMatchReplayCatalogScene scene,
  ) {
    final loader = widget.sceneLoader;
    if (loader != null) return loader(scene);
    return rootBundle
        .loadString(scene.asset)
        .then(RealMatchReplayData.fromJsonString);
  }

  Future<void> _selectScene(int index) async {
    final catalog = _catalog;
    if (catalog == null || index < 0 || index >= catalog.scenes.length) return;
    final generation = ++_loadGeneration;
    _controller
      ..stop()
      ..value = 0;
    setState(() {
      _playing = false;
      _zoom = false;
      _sceneIndex = index;
      _data = null;
      _loadError = null;
    });
    try {
      final entry = catalog.scenes[index];
      final data = await _loadSceneData(entry);
      if (!mounted || generation != _loadGeneration) return;
      _validateLoadedScene(catalog, entry, data);
      _applyLoaded(catalog, data, sceneIndex: index);
    } catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() => _loadError = error);
    }
  }

  void _validateLoadedScene(
    RealMatchReplayCatalog catalog,
    RealMatchReplayCatalogScene entry,
    RealMatchReplayData data,
  ) {
    if (data.scene.id != entry.id ||
        data.match.id != entry.matchId ||
        data.sourceCommit != catalog.sourceCommit ||
        (data.duration - entry.duration).abs() > 1 / data.fps) {
      throw const FormatException('Replay scene does not match its catalog.');
    }
  }

  void _applyLoaded(
    RealMatchReplayCatalog catalog,
    RealMatchReplayData data, {
    required int sceneIndex,
  }) {
    _controller
      ..duration = _playbackDuration(data.duration, _speed)
      ..value = 0;
    setState(() {
      _catalog = catalog;
      _data = data;
      _sceneIndex = sceneIndex;
      _loadError = null;
      _playing = false;
      _zoom = false;
    });
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
    _loadGeneration++;
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
      appBar: _compactExpanded
          ? null
          : AppBar(
              title: Text(
                _expanded && _data != null
                    ? _sceneTitle(_l10n, _data!.scene.titleKey)
                    : _l10n.realMatchReplayAppBarTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: _viewerActions(),
            ),
      body: SafeArea(child: _buildBody(colors)),
    );
  }

  List<Widget> _viewerActions() => [
        if (_expanded && (_catalog?.scenes.length ?? 0) > 1)
          AppBarActionButton(
            compact: true,
            margin: EdgeInsets.zero,
            key: const ValueKey<String>('replay-choose-scene'),
            tooltip: _l10n.realMatchReplayChooseScene,
            onPressed: _openSceneLibrary,
            icon: const Icon(Icons.video_library_outlined),
          ),
        if (_data != null || _expanded)
          AppBarActionButton(
            compact: true,
            margin: EdgeInsets.zero,
            key: const ValueKey<String>('replay-expand'),
            tooltip: _expanded
                ? _l10n.realMatchReplayCollapsePitch
                : _l10n.realMatchReplayExpandPitch,
            onPressed: () => setState(() {
              _expanded = !_expanded;
              if (_expanded) _zoom = false;
            }),
            icon: Icon(
              _expanded ? Icons.fullscreen_exit : Icons.fullscreen,
            ),
          ),
      ];

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
              onPressed: _catalog == null
                  ? _loadInitial
                  : () => _selectScene(_sceneIndex),
              child: Text(_l10n.realMatchReplayRetry),
            ),
          ]),
        ),
      );
    }
    final data = _data;
    final catalog = _catalog;
    if (data == null || catalog == null) {
      return Center(
        child: Semantics(
          label: _l10n.realMatchReplayLoading,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    return LayoutBuilder(builder: (context, constraints) {
      if (_compactExpanded) {
        return Stack(
          children: [
            Positioned.fill(
              child: _buildField(
                data,
                colors,
                constraints.maxHeight,
                compact: true,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: colors.surface.withValues(alpha: .94),
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _viewerActions(),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ColoredBox(
                color: colors.surface.withValues(alpha: .96),
                child: Row(
                  children: [
                    Expanded(child: _buildControls(data, colors)),
                    Expanded(child: _buildProgress(data, colors)),
                  ],
                ),
              ),
            ),
          ],
        );
      }
      if (_expanded) {
        return Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, fieldConstraints) => _buildField(
                  data,
                  colors,
                  fieldConstraints.maxHeight,
                ),
              ),
            ),
            _buildProgress(data, colors),
            _buildControls(data, colors),
          ],
        );
      }
      final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
      final expanded = _view == ReplayPitchView.full;
      final stageHeight = expanded
          ? (constraints.maxHeight - 130).clamp(520.0, 900.0)
          : (constraints.maxWidth * .52 + (textScale - 1) * 80)
              .clamp(textScale > 1.2 ? 500.0 : 400.0, 720.0);
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1600),
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
                    _buildHeader(data, catalog, colors),
                    _buildProgress(data, colors),
                    _buildControls(data, colors),
                    _buildViewControls(data, colors),
                    _buildStage(data, colors, stageHeight),
                    _buildSteps(data, colors),
                    _buildCredit(data, colors),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildHeader(
    RealMatchReplayData data,
    RealMatchReplayCatalog catalog,
    _ScanPassColors colors,
  ) {
    final entry = catalog.scenes[_sceneIndex];
    final title = _sceneTitle(_l10n, data.scene.titleKey);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _l10n.realMatchReplayHeaderMeta(data.match.date),
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: colors.muted),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  key: const ValueKey<String>('replay-scene-title'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            key: const ValueKey<String>('replay-choose-scene'),
            onPressed: catalog.scenes.length > 1 ? _openSceneLibrary : null,
            icon: const Icon(Icons.video_library_outlined, size: 18),
            label: Text(_l10n.realMatchReplayChooseScene),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 40),
              maximumSize: const Size(240, 52),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ]),
        const SizedBox(height: 7),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 7,
          runSpacing: 5,
          children: [
            Text(data.match.home, style: TextStyle(color: colors.text)),
            _ReplayTeamDot(color: _replayColor(data.scene.homeColor)),
            Text(_l10n.realMatchReplayVersus,
                style: TextStyle(color: colors.muted)),
            _ReplayTeamDot(
              color: _replayColor(data.scene.awayColor),
              outlined: true,
            ),
            Text(data.match.away, style: TextStyle(color: colors.text)),
            Text('·', style: TextStyle(color: colors.muted)),
            Text(
              _categoryLabel(_l10n, data.scene.category),
              style: TextStyle(color: colors.muted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(children: [
          AppBarActionButton(
            compact: true,
            margin: EdgeInsets.zero,
            key: const ValueKey<String>('replay-previous-scene'),
            tooltip: _l10n.realMatchReplayPreviousScene,
            onPressed:
                _sceneIndex > 0 ? () => _selectScene(_sceneIndex - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            _l10n.realMatchReplaySceneCount(
              _sceneIndex + 1,
              catalog.scenes.length,
            ),
            key: const ValueKey<String>('replay-scene-count'),
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: colors.muted),
          ),
          AppBarActionButton(
            compact: true,
            margin: EdgeInsets.zero,
            key: const ValueKey<String>('replay-next-scene'),
            tooltip: _l10n.realMatchReplayNextScene,
            onPressed: _sceneIndex + 1 < catalog.scenes.length
                ? () => _selectScene(_sceneIndex + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              _l10n.realMatchReplayMatchClock(
                _matchClock(entry.startClock),
                _matchClock(entry.startClock + entry.duration),
              ),
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: colors.muted),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildViewControls(
    RealMatchReplayData data,
    _ScanPassColors colors,
  ) {
    final hasFocusPose = data.hasRecordedPoseFor(data.scene.focusPlayerId);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            _l10n.realMatchReplayViewLabel,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: colors.muted),
          ),
          for (final view in ReplayPitchView.values)
            ChoiceChip(
              key: ValueKey<String>('replay-view-${view.name}'),
              selected: _view == view,
              onSelected: (_) => setState(() => _view = view),
              label: Text(_viewLabel(_l10n, view)),
              visualDensity: VisualDensity.compact,
            ),
          if (hasFocusPose)
            OutlinedButton.icon(
              key: const ValueKey<String>('replay-zoom'),
              onPressed: () => setState(() => _zoom = !_zoom),
              icon: Icon(
                  _zoom ? Icons.close_fullscreen : Icons.accessibility_new,
                  size: 17),
              label: Text(
                _l10n.realMatchReplayPoseAction(
                  data.player(data.scene.focusPlayerId).number,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 38),
                maximumSize: const Size(240, 48),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
            )
          else
            Chip(
              key: const ValueKey<String>('replay-tracking-only'),
              avatar: const Icon(Icons.route_outlined, size: 16),
              label: Text(_l10n.realMatchReplayTrackingOnly),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _buildStage(
    RealMatchReplayData data,
    _ScanPassColors colors,
    double height,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildField(data, colors, height),
        if (_zoom)
          Padding(
            key: const ValueKey<String>('replay-pose-detail'),
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: 180,
              height: 214,
              child: _ReplayPoseCard(data: data, time: _time, colors: colors),
            ),
          ),
      ],
    );
  }

  Widget _buildField(
    RealMatchReplayData data,
    _ScanPassColors colors,
    double height, {
    bool compact = false,
  }) {
    final step = data.stepAt(_time);
    final stepLabel = _stepLabel(_l10n, step.kind, step.runType);
    final actor = data.player(step.actorId);
    final focus = _sceneFocus(_l10n, data.scene.focusKey);
    final copy = _ReplayPitchCopy(
      annotations: <String>[
        _l10n.realMatchReplayCalloutPlayer(actor.number, stepLabel),
        if (step.targetId != null)
          _l10n.realMatchReplayCalloutTarget(
            data.player(step.targetId!).number,
          ),
      ],
    );
    return LayoutBuilder(builder: (context, constraints) {
      final narrow = constraints.maxWidth < 540;
      return SizedBox(
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Stack(children: [
            Positioned.fill(
              child: Semantics(
                image: true,
                label: _l10n.realMatchReplayPitchSemanticsGeneric(
                  data.match.home,
                  data.match.away,
                  _sceneTitle(_l10n, data.scene.titleKey),
                ),
                child: ExcludeSemantics(
                  child: CustomPaint(
                    key: const ValueKey<String>('replay-pitch'),
                    painter: _RealMatchReplayPainter(
                      data: data,
                      time: _time,
                      explanation: _explanation,
                      showZoom: false,
                      view: _view,
                      copy: copy,
                      brightness: Theme.of(context).brightness,
                      textDirection: Directionality.of(context),
                      textScaler: MediaQuery.textScalerOf(context),
                      compact: compact,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: compact ? 116 : 12,
              top: 10,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: .9),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!compact)
                          Text(
                            _explanation
                                ? _l10n
                                    .realMatchReplayExplanationKicker(stepLabel)
                                : _l10n.realMatchReplayObservationKicker(
                                    stepLabel),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: colors.muted),
                          ),
                        if (compact)
                          Text(
                            _sceneTitle(_l10n, data.scene.titleKey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        Text(
                          _l10n.realMatchReplayStageWithPlayer(
                            stepLabel,
                            actor.number,
                          ),
                          maxLines: compact ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colors.text,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        if (!compact)
                          Text(
                            focus,
                            maxLines: narrow ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: colors.muted),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (!compact)
              Positioned(
                left: 12,
                right: 12,
                bottom: 8,
                child: IgnorePointer(
                  child: Row(children: [
                    Flexible(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.surface.withValues(alpha: .9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            _l10n.realMatchReplayOutcomeLabel(
                              _replayOutcomeLabel(_l10n, data.scene.outcome),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: colors.muted),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      narrow
                          ? _l10n.realMatchReplayAttackDirectionUp
                          : _l10n.realMatchReplayAttackDirectionRight,
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
            divisions: math.max(1, data.frames.length - 1),
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
              _durationClock(current),
              _durationClock(data.duration),
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
    final playLabel = _playing
        ? _l10n.realMatchReplayPause
        : _controller.isCompleted
            ? (_explanation
                ? _l10n.realMatchReplayRestart
                : _l10n.realMatchReplayGuidedReplay)
            : _time > .02
                ? _l10n.realMatchReplayContinue
                : _l10n.realMatchReplayPlay;
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
              maximumSize: const Size(240, 52),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
          ),
          FilterChip(
            key: const ValueKey<String>('replay-explanation'),
            selected: _explanation,
            onSelected: (selected) => setState(() => _explanation = selected),
            avatar: const Icon(Icons.subtitles_outlined, size: 17),
            label: Text(_l10n.realMatchReplayExplanationToggle),
          ),
          Semantics(
            label: _l10n.realMatchReplaySpeedLabel,
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
                        child: Text(_l10n.realMatchReplaySpeedNormal),
                      ),
                      DropdownMenuItem(
                        value: .5,
                        child: Text(_l10n.realMatchReplaySpeedHalf),
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

  Widget _buildSteps(RealMatchReplayData data, _ScanPassColors colors) {
    final active = data.scene.steps.indexOf(data.stepAt(_time));
    return Semantics(
      container: true,
      label: _l10n.realMatchReplayChaptersSemantics,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 9),
        child: Wrap(
          key: const ValueKey<String>('replay-chapters'),
          spacing: 5,
          runSpacing: 5,
          children: List<Widget>.generate(data.scene.steps.length, (index) {
            final step = data.scene.steps[index];
            return OutlinedButton(
              key: ValueKey<String>('replay-chapter-$index'),
              onPressed: () => _pauseAt(step.time, explain: true),
              style: OutlinedButton.styleFrom(
                foregroundColor: active == index ? colors.text : colors.muted,
                backgroundColor:
                    active == index ? colors.active : Colors.transparent,
                minimumSize: const Size(0, 38),
                maximumSize: const Size(220, 48),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                side: BorderSide(
                  color: active == index ? colors.accent : colors.line,
                ),
              ),
              child: Text(
                _stepLabel(_l10n, step.kind, step.runType),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCredit(
    RealMatchReplayData data,
    _ScanPassColors colors,
  ) {
    final disclosure = data.hasRecordedPose
        ? _l10n.realMatchReplayDisclosure
        : _l10n.realMatchReplayTrackingDisclosure;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 10, 13),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Text(
            disclosure,
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
            maximumSize: const Size(180, 48),
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

  Future<void> _openSceneLibrary() async {
    final catalog = _catalog;
    if (catalog == null) return;
    _controller.stop();
    setState(() => _playing = false);
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _ReplaySceneLibrarySheet(
        catalog: catalog,
        selectedIndex: _sceneIndex,
      ),
    );
    if (!mounted || selected == null || selected == _sceneIndex) return;
    await _selectScene(selected);
  }

  String _durationClock(double seconds) {
    final whole = seconds.floor();
    return '${whole ~/ 60}:${(whole % 60).toString().padLeft(2, '0')}';
  }

  String _matchClock(double seconds) {
    final minutes = seconds ~/ 60;
    final remainder = seconds - minutes * 60;
    return '$minutes:${remainder.toStringAsFixed(2).padLeft(5, '0')}';
  }
}

class _ReplaySceneLibrarySheet extends StatefulWidget {
  final RealMatchReplayCatalog catalog;
  final int selectedIndex;

  const _ReplaySceneLibrarySheet({
    required this.catalog,
    required this.selectedIndex,
  });

  @override
  State<_ReplaySceneLibrarySheet> createState() =>
      _ReplaySceneLibrarySheetState();
}

class _ReplaySceneLibrarySheetState extends State<_ReplaySceneLibrarySheet> {
  RealMatchReplayCategory? _category;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = _ScanPassColors.of(context);
    final entries = <({int index, RealMatchReplayCatalogScene scene})>[
      for (var index = 0; index < widget.catalog.scenes.length; index++)
        if (_category == null ||
            widget.catalog.scenes[index].category == _category)
          (index: index, scene: widget.catalog.scenes[index]),
    ];
    return FractionallySizedBox(
      heightFactor: .9,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.realMatchReplaySceneLibraryTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    l10n.realMatchReplaySceneLibrarySubtitle(
                      widget.catalog.scenes.length,
                    ),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: colors.muted),
                  ),
                ],
              ),
            ),
            AppBarActionButton(
              compact: true,
              margin: EdgeInsets.zero,
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ]),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                key: const ValueKey<String>('replay-category-all'),
                selected: _category == null,
                onSelected: (_) => setState(() => _category = null),
                label: Text(l10n.realMatchReplayAllCategories),
              ),
            ),
            for (final category in RealMatchReplayCategory.values)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  key: ValueKey<String>('replay-category-${category.name}'),
                  selected: _category == category,
                  onSelected: (_) => setState(() => _category = category),
                  label: Text(_categoryLabel(l10n, category)),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, row) {
              final item = entries[row];
              final scene = item.scene;
              return Card(
                child: ListTile(
                  key: ValueKey<String>('replay-scene-${scene.id}'),
                  selected: item.index == widget.selectedIndex,
                  onTap: () => Navigator.pop(context, item.index),
                  leading: CircleAvatar(
                    child: Text('${item.index + 1}'),
                  ),
                  title: Text(_sceneTitle(l10n, scene.titleKey)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.realMatchReplaySceneRowMeta(
                          '${scene.home} · ${scene.away}',
                          _formatCatalogClock(scene.startClock),
                          scene.duration.toStringAsFixed(1),
                        ),
                      ),
                      Text(
                        _sceneFocus(l10n, scene.focusKey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  trailing: Text(_categoryLabel(l10n, scene.category)),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  String _formatCatalogClock(double seconds) {
    final minutes = seconds ~/ 60;
    final remainder = seconds - minutes * 60;
    return '$minutes:${remainder.toStringAsFixed(1).padLeft(4, '0')}';
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
    final player = data.player(data.scene.focusPlayerId);
    final pose = data.poseAt(time, data.playerIndex(player.id));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: .97),
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 6, 5, 5),
        child: Column(children: [
          Text(
            l10n.realMatchReplayPoseTitlePlayer(player.name, player.number),
            maxLines: 2,
            textAlign: TextAlign.center,
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
                      player: player,
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
  final List<String> annotations;

  const _ReplayPitchCopy({required this.annotations});
}

class _RealMatchReplayPainter extends CustomPainter {
  final RealMatchReplayData data;
  final double time;
  final bool explanation;
  final bool showZoom;
  final ReplayPitchView view;
  final _ReplayPitchCopy copy;
  final Brightness brightness;
  final TextDirection textDirection;
  final TextScaler textScaler;
  final bool compact;

  const _RealMatchReplayPainter({
    required this.data,
    required this.time,
    required this.explanation,
    required this.showZoom,
    required this.view,
    required this.copy,
    required this.brightness,
    required this.textDirection,
    required this.textScaler,
    this.compact = false,
  });

  bool get _dark => brightness == Brightness.dark;
  Color get _pitch => _dark ? const Color(0xFF183D2B) : const Color(0xFFD7E5D9);
  Color get _stripe =>
      _dark ? const Color(0xFF235034) : const Color(0xFFB9CDBD);
  Color get _line => _dark ? const Color(0xFF6B9878) : const Color(0xFF668A75);
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
    final geometry = ReplayPitchGeometry.forSize(
      size,
      camera: data.scene.camera,
      attackDirection: data.scene.attackDirection,
      view: view,
      pitchLength: data.pitchLength,
      pitchWidth: data.pitchWidth,
      headerInset: compact ? textScaler.scale(42) + 20 : null,
      bottomInset: compact ? (textScaler.scale(14) > 16.8 ? 110 : 76) : 34,
    );
    final sample = data.renderSample(time);
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
    final halfLength = data.pitchLength / 2;
    final halfWidth = data.pitchWidth / 2;
    for (var x = -halfLength; x < halfLength; x += 10) {
      if (((x + halfLength) / 10).round().isOdd) continue;
      final x2 = math.min(x + 10, halfLength);
      final path = Path()
        ..moveTo(geometry.project(x, -halfWidth).dx,
            geometry.project(x, -halfWidth).dy)
        ..lineTo(geometry.project(x2, -halfWidth).dx,
            geometry.project(x2, -halfWidth).dy)
        ..lineTo(geometry.project(x2, halfWidth).dx,
            geometry.project(x2, halfWidth).dy)
        ..lineTo(geometry.project(x, halfWidth).dx,
            geometry.project(x, halfWidth).dy)
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
        index == 0
            ? path.moveTo(point.dx, point.dy)
            : path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }

    worldLine(<RealMatchReplayPoint>[
      RealMatchReplayPoint(-halfLength, -halfWidth),
      RealMatchReplayPoint(halfLength, -halfWidth),
      RealMatchReplayPoint(halfLength, halfWidth),
      RealMatchReplayPoint(-halfLength, halfWidth),
      RealMatchReplayPoint(-halfLength, -halfWidth),
    ]);
    worldLine(<RealMatchReplayPoint>[
      RealMatchReplayPoint(0, -halfWidth),
      RealMatchReplayPoint(0, halfWidth),
    ]);
    for (final side in <double>[-1, 1]) {
      final goalLine = side * halfLength;
      final penaltyX = side * (halfLength - 16.5);
      final goalAreaX = side * (halfLength - 5.5);
      worldLine(<RealMatchReplayPoint>[
        RealMatchReplayPoint(goalLine, -20.16),
        RealMatchReplayPoint(penaltyX, -20.16),
        RealMatchReplayPoint(penaltyX, 20.16),
        RealMatchReplayPoint(goalLine, 20.16),
      ]);
      worldLine(<RealMatchReplayPoint>[
        RealMatchReplayPoint(goalLine, -9.16),
        RealMatchReplayPoint(goalAreaX, -9.16),
        RealMatchReplayPoint(goalAreaX, 9.16),
        RealMatchReplayPoint(goalLine, 9.16),
      ]);
      worldLine(<RealMatchReplayPoint>[
        RealMatchReplayPoint(goalLine, -3.66),
        RealMatchReplayPoint(goalLine + side * 2, -3.66),
        RealMatchReplayPoint(goalLine + side * 2, 3.66),
        RealMatchReplayPoint(goalLine, 3.66),
      ]);
      canvas.drawCircle(
        geometry.project(side * (halfLength - 11), 0),
        1.8,
        Paint()..color = _line,
      );
    }
    final circle = List<RealMatchReplayPoint>.generate(65, (index) {
      final angle = index / 64 * math.pi * 2;
      return RealMatchReplayPoint(
        math.cos(angle) * 9.15,
        math.sin(angle) * 9.15,
      );
    });
    worldLine(circle);
    canvas.drawCircle(geometry.project(0, 0), 1.8, Paint()..color = _line);
  }

  List<_ReplayMark> _drawExplanation(
    Canvas canvas,
    ReplayPitchGeometry geometry,
    RealMatchReplaySample sample,
  ) {
    final step = data.stepAt(time);
    final actorIndex = data.playerIndex(step.actorId);
    final nextIndex = data.scene.steps.indexOf(step) + 1;
    final segmentEnd = nextIndex < data.scene.steps.length
        ? data.scene.steps[nextIndex].time
        : data.duration;
    final trailEnd = math.min(time, segmentEnd);
    _drawPlayerTrail(
      canvas,
      geometry,
      actorIndex,
      step.time,
      trailEnd,
      step.kind == RealMatchReplayStepKind.pressure ? _pressure : _good,
    );
    if (step.kind == RealMatchReplayStepKind.pass ||
        step.kind == RealMatchReplayStepKind.carry ||
        step.kind == RealMatchReplayStepKind.receive ||
        step.kind == RealMatchReplayStepKind.outcome) {
      _drawBallTrail(canvas, geometry, step.time, trailEnd, _good);
    }
    final marks = <_ReplayMark>[
      _ReplayMark(
        copy.annotations.first,
        sample.players[actorIndex],
        step.kind == RealMatchReplayStepKind.pressure ? _pressure : _good,
      ),
    ];
    if (step.targetId != null && copy.annotations.length > 1) {
      marks.add(_ReplayMark(
        copy.annotations[1],
        sample.players[data.playerIndex(step.targetId!)],
        _good,
      ));
    }
    return marks.take(2).toList(growable: false);
  }

  void _drawPlayerTrail(
    Canvas canvas,
    ReplayPitchGeometry geometry,
    int playerIndex,
    double from,
    double to,
    Color color,
  ) {
    if (to <= from) return;
    final points = <RealMatchReplayPoint>[];
    for (var cursor = from; cursor < to; cursor += .12) {
      points.add(data.renderSample(cursor).players[playerIndex]);
    }
    points.add(data.renderSample(to).players[playerIndex]);
    _drawWorldPath(
      canvas,
      geometry,
      points,
      color.withValues(alpha: .82),
      2,
      dashed: true,
      arrow: true,
    );
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
    _drawWorldPath(
      canvas,
      geometry,
      points,
      color.withValues(alpha: .9),
      2.4,
      arrow: true,
    );
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
    if ((b - a).distance < 1) return;
    final angle = math.atan2(b.dy - a.dy, b.dx - a.dx);
    canvas.drawPath(
      Path()
        ..moveTo(
          b.dx - 7 * math.cos(angle - .45),
          b.dy - 7 * math.sin(angle - .45),
        )
        ..lineTo(b.dx, b.dy)
        ..lineTo(
          b.dx - 7 * math.cos(angle + .45),
          b.dy - 7 * math.sin(angle + .45),
        ),
      paint,
    );
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
    final bodyScale =
        math.max(compact ? 14.0 : 17.0, math.min(32.0, geometry.scale * 1.45));
    final step = data.stepAt(time);
    for (final index in entries) {
      final base = sample.players[index];
      final ground = geometry.project(base.x, base.y);
      if (ground.dx < -30 ||
          ground.dx > geometry.size.width + 30 ||
          ground.dy < 54 ||
          ground.dy > geometry.size.height - 16) {
        continue;
      }
      canvas.drawOval(
        Rect.fromCenter(center: ground.translate(0, 1), width: 16, height: 6),
        Paint()..color = _shadow.withValues(alpha: .2),
      );
      final measured = data.poseAt(time, index);
      final pose = measured ?? data.motion.simplifiedPoseAt(time, index);
      final joints = <String, RealMatchReplayPoint>{
        for (var joint = 0; joint < data.joints.length; joint++)
          data.joints[joint]: pose.joints[joint],
      };
      if (!_hasRenderableJoints(joints)) continue;
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

      final player = data.players[index];
      if (player.id == data.scene.focusPlayerId ||
          (explanation && player.id == step.actorId)) {
        canvas.drawOval(
          Rect.fromCenter(center: ground, width: 25, height: 10),
          Paint()
            ..color = _good.withValues(alpha: .58)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
      }
      final head = _drawPlayerBody(
        canvas,
        projectJoint,
        bodyScale,
        player,
      );
      occupied.add(Rect.fromLTRB(
        ground.dx - 16,
        math.min(head.dy, ground.dy) - 8,
        ground.dx + 16,
        ground.dy + 8,
      ));
    }
    return occupied;
  }

  bool _hasRenderableJoints(Map<String, RealMatchReplayPoint> joints) =>
      const <String>{
        'nose',
        'neck',
        'lShoulder',
        'rShoulder',
        'lElbow',
        'rElbow',
        'lWrist',
        'rWrist',
        'lHip',
        'rHip',
        'lKnee',
        'rKnee',
        'lAnkle',
        'rAnkle',
        'lHeel',
        'rHeel',
        'lBigToe',
        'rBigToe',
      }.every(joints.containsKey);

  Offset _drawPlayerBody(
    Canvas canvas,
    Offset Function(String name) joint,
    double scale,
    RealMatchReplayPlayer player,
  ) {
    final kit = _replayColor(
      player.home ? data.scene.homeColor : data.scene.awayColor,
    );
    final number = _replayColor(
      player.home ? data.scene.homeNumberColor : data.scene.awayNumberColor,
    );
    final shorts = Color.lerp(kit, const Color(0xFF142F38), .62)!;
    const skin = Color(0xFFC99B78);
    const boots = Color(0xFF192625);
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
      line('${side}Knee', '${side}Ankle', kit, scale * .10);
      line('${side}Heel', '${side}BigToe', boots, scale * .12);
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
        ..color = shorts
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
          fontSize: math.max(9, math.min(16, scale * .5)),
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
    numberPainter.dispose();
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
      index == 0
          ? patch.moveTo(point.dx, point.dy)
          : patch.lineTo(point.dx, point.dy);
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
    if (compact) return Rect.zero;
    final width = size.width < 540 ? 86.0 : 116.0;
    final height = width * data.pitchWidth / data.pitchLength;
    final candidates = <Rect>[
      Rect.fromLTWH(
        size.width - width - 14,
        size.height - height - 43,
        width,
        height,
      ),
      Rect.fromLTWH(size.width - width - 14, 92, width, height),
      Rect.fromLTWH(14, size.height - height - 43, width, height),
    ];
    final ball = geometry.project(sample.ball.x, sample.ball.y);
    final blocked = <Rect>[
      ...occupied,
      Rect.fromCircle(center: ball, radius: 10),
      if (showZoom) _poseCardRect(size),
    ];
    final rect = candidates.cast<Rect?>().firstWhere(
          (candidate) => blocked.every(
            (other) => !candidate!.inflate(4).overlaps(other),
          ),
          orElse: () => candidates.first,
        )!;
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
    double x(double world) =>
        rect.left +
        (world * data.scene.attackDirection + data.pitchLength / 2) /
            data.pitchLength *
            rect.width;
    double y(double world) =>
        rect.top +
        (data.pitchWidth / 2 - world) / data.pitchWidth * rect.height;
    canvas.drawLine(
      Offset(x(0), rect.top),
      Offset(x(0), rect.bottom),
      Paint()..color = _line,
    );
    final visible = geometry.visibleCamera;
    final viewport = Rect.fromPoints(
      Offset(
        x(visible.minX.clamp(-data.pitchLength / 2, data.pitchLength / 2)),
        y(visible.maxY.clamp(-data.pitchWidth / 2, data.pitchWidth / 2)),
      ),
      Offset(
        x(visible.maxX.clamp(-data.pitchLength / 2, data.pitchLength / 2)),
        y(visible.minY.clamp(-data.pitchWidth / 2, data.pitchWidth / 2)),
      ),
    );
    canvas.drawRect(
      viewport,
      Paint()
        ..color = _good.withValues(alpha: .8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    for (var index = 0; index < sample.players.length; index++) {
      final point = sample.players[index];
      canvas.drawCircle(
        Offset(x(point.x), y(point.y)),
        1.6,
        Paint()
          ..color = _replayColor(data.players[index].home
              ? data.scene.homeColor
              : data.scene.awayColor),
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
      )..layout(maxWidth: 138);
    }).toList(growable: false);
    final anchors = marks
        .map((mark) => geometry.project(mark.at.x, mark.at.y, mark.at.z))
        .toList(growable: false);
    final ball = geometry.project(sample.ball.x, sample.ball.y, sample.ball.z);
    final step = data.stepAt(time);
    final protected = <Rect>[
      Rect.fromCircle(center: ball, radius: 10),
      for (final id in <int>{
        data.scene.focusPlayerId,
        step.actorId,
        if (step.targetId != null) step.targetId!,
        if (step.secondaryId != null) step.secondaryId!,
      })
        Rect.fromCenter(
          center: geometry
              .project(
                sample.players[data.playerIndex(id)].x,
                sample.players[data.playerIndex(id)].y,
              )
              .translate(0, -16),
          width: 38,
          height: 56,
        ),
      if (showZoom) _poseCardRect(size),
    ];
    final rects = ReplayLabelLayout.place(
      stageSize: size,
      topInset: geometry.origin.dy + 4,
      bottomInset: compact
          ? geometry.bottomInset
          : ReplayLabelLayout.bottomControlsInset,
      labelSizes: painters
          .map((painter) => Size(painter.width + 16, painter.height + 12))
          .toList(growable: false),
      anchors: anchors,
      obstacles: <Rect>[
        ...occupied,
        ...protected,
      ],
      protectedObstacles: protected,
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

  Rect _poseCardRect(Size size) {
    final narrow = size.width < 540;
    final width = narrow ? 122.0 : 148.0;
    final height = narrow ? 174.0 : 214.0;
    return Rect.fromLTWH(
      size.width - width - 12,
      narrow ? 108 : 10,
      width,
      height,
    );
  }

  @override
  bool shouldRepaint(covariant _RealMatchReplayPainter oldDelegate) =>
      data != oldDelegate.data ||
      time != oldDelegate.time ||
      explanation != oldDelegate.explanation ||
      showZoom != oldDelegate.showZoom ||
      view != oldDelegate.view ||
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
  final RealMatchReplayPlayer player;
  final Brightness brightness;

  const _ReplayPosePainter({
    required this.data,
    required this.pose,
    required this.player,
    required this.brightness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final joints = <String, RealMatchReplayPoint>{
      for (var index = 0; index < data.joints.length; index++)
        data.joints[index]: pose.joints[index],
    };
    if (!joints.containsKey('lHeel') || !joints.containsKey('rHeel')) return;
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
    final kit = _replayColor(
      player.home ? data.scene.homeColor : data.scene.awayColor,
    );
    final numberColor = _replayColor(
      player.home ? data.scene.homeNumberColor : data.scene.awayNumberColor,
    );
    final shorts = Color.lerp(kit, const Color(0xFF142F38), .62)!;
    const skin = Color(0xFFC99B78);
    const boots = Color(0xFF192625);
    void line(String a, String b, Color color, double width) {
      if (!joints.containsKey(a) || !joints.containsKey(b)) return;
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
      line('${side}Knee', '${side}Ankle', kit, 6.2);
      line('${side}Heel', '${side}BigToe', boots, 7.4);
      line('${side}Shoulder', '${side}Elbow', kit, 8.2);
      line('${side}Elbow', '${side}Wrist', skin, 6.2);
    }
    if (!const <String>{
      'lShoulder',
      'rShoulder',
      'lHip',
      'rHip',
      'neck',
      'nose'
    }.every(joints.containsKey)) {
      return;
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
      text: TextSpan(
        text: '${player.number}',
        style: TextStyle(
          color: numberColor,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    number.paint(canvas, center - number.size.center(Offset.zero));
    number.dispose();
  }

  @override
  bool shouldRepaint(covariant _ReplayPosePainter oldDelegate) =>
      pose != oldDelegate.pose ||
      player != oldDelegate.player ||
      brightness != oldDelegate.brightness;
}

Color _replayColor(String value) {
  final hex = value.substring(1);
  final parsed = int.parse(hex, radix: 16);
  return Color(hex.length == 6 ? 0xFF000000 | parsed : parsed);
}

String _viewLabel(AppLocalizations l10n, ReplayPitchView view) =>
    switch (view) {
      ReplayPitchView.context => l10n.realMatchReplayViewContext,
      ReplayPitchView.close => l10n.realMatchReplayViewClose,
      ReplayPitchView.full => l10n.realMatchReplayViewFull,
    };

String _categoryLabel(
  AppLocalizations l10n,
  RealMatchReplayCategory category,
) =>
    switch (category) {
      RealMatchReplayCategory.transition => l10n.replayCategoryTransition,
      RealMatchReplayCategory.buildUp => l10n.replayCategoryBuildUp,
      RealMatchReplayCategory.pressure => l10n.replayCategoryPressure,
      RealMatchReplayCategory.switchPlay => l10n.replayCategorySwitchPlay,
      RealMatchReplayCategory.penetration => l10n.replayCategoryPenetration,
      RealMatchReplayCategory.combination => l10n.replayCategoryCombination,
      RealMatchReplayCategory.wideAttack => l10n.replayCategoryWideAttack,
      RealMatchReplayCategory.turnover => l10n.replayCategoryTurnover,
    };

String _stepLabel(
  AppLocalizations l10n,
  RealMatchReplayStepKind kind,
  String? runType,
) =>
    switch (kind) {
      RealMatchReplayStepKind.observe => l10n.replayStepObserve,
      RealMatchReplayStepKind.carry => l10n.replayStepCarry,
      RealMatchReplayStepKind.pass => l10n.replayStepPass,
      RealMatchReplayStepKind.receive => l10n.replayStepReceive,
      RealMatchReplayStepKind.run => switch (runType) {
          'behind' => l10n.replayStepRunBehind,
          'overlap' => l10n.replayStepRunOverlap,
          'underlap' => l10n.replayStepRunUnderlap,
          'cross_receiver' => l10n.replayStepRunCrossReceiver,
          _ => l10n.replayStepRun,
        },
      RealMatchReplayStepKind.pressure => l10n.replayStepPressure,
      RealMatchReplayStepKind.outcome => l10n.replayStepOutcome,
    };

String _replayOutcomeLabel(
  AppLocalizations l10n,
  RealMatchReplayOutcome outcome,
) =>
    switch (outcome) {
      RealMatchReplayOutcome.shot => l10n.replayOutcomeShot,
      RealMatchReplayOutcome.kept => l10n.replayOutcomeKept,
      RealMatchReplayOutcome.lost => l10n.replayOutcomeLost,
      RealMatchReplayOutcome.end => l10n.replayOutcomeEnd,
    };

String _sceneTitle(AppLocalizations l10n, String key) => switch (key) {
      'replaySceneTransitionWing' => l10n.replaySceneTransitionWing,
      'replaySceneKeeperBuild' => l10n.replaySceneKeeperBuild,
      'replaySceneCentralBuild' => l10n.replaySceneCentralBuild,
      'replayScenePressureSwitch' => l10n.replayScenePressureSwitch,
      'replayScenePressureSupport' => l10n.replayScenePressureSupport,
      'replaySceneBacklineSwitch' => l10n.replaySceneBacklineSwitch,
      'replaySceneWideSwitch' => l10n.replaySceneWideSwitch,
      'replaySceneLoftedBehind' => l10n.replaySceneLoftedBehind,
      'replaySceneThroughChannel' => l10n.replaySceneThroughChannel,
      'replaySceneThroughMiddle' => l10n.replaySceneThroughMiddle,
      'replaySceneOneTouchLink' => l10n.replaySceneOneTouchLink,
      'replayScenePassAndMove' => l10n.replayScenePassAndMove,
      'replaySceneCarrySupport' => l10n.replaySceneCarrySupport,
      'replaySceneCarryShot' => l10n.replaySceneCarryShot,
      'replaySceneOverlapWing' => l10n.replaySceneOverlapWing,
      'replaySceneOverlapCarry' => l10n.replaySceneOverlapCarry,
      'replaySceneUnderlapChannel' => l10n.replaySceneUnderlapChannel,
      'replaySceneCrossArrival' => l10n.replaySceneCrossArrival,
      'replayScenePressureTurnover' => l10n.replayScenePressureTurnover,
      'replaySceneCarryTurnover' => l10n.replaySceneCarryTurnover,
      _ => key,
    };

String _sceneFocus(AppLocalizations l10n, String key) => switch (key) {
      'replayFocusTransitionWing' => l10n.replayFocusTransitionWing,
      'replayFocusKeeperBuild' => l10n.replayFocusKeeperBuild,
      'replayFocusCentralBuild' => l10n.replayFocusCentralBuild,
      'replayFocusPressureSwitch' => l10n.replayFocusPressureSwitch,
      'replayFocusPressureSupport' => l10n.replayFocusPressureSupport,
      'replayFocusBacklineSwitch' => l10n.replayFocusBacklineSwitch,
      'replayFocusWideSwitch' => l10n.replayFocusWideSwitch,
      'replayFocusLoftedBehind' => l10n.replayFocusLoftedBehind,
      'replayFocusThroughChannel' => l10n.replayFocusThroughChannel,
      'replayFocusThroughMiddle' => l10n.replayFocusThroughMiddle,
      'replayFocusOneTouchLink' => l10n.replayFocusOneTouchLink,
      'replayFocusPassAndMove' => l10n.replayFocusPassAndMove,
      'replayFocusCarrySupport' => l10n.replayFocusCarrySupport,
      'replayFocusCarryShot' => l10n.replayFocusCarryShot,
      'replayFocusOverlapWing' => l10n.replayFocusOverlapWing,
      'replayFocusOverlapCarry' => l10n.replayFocusOverlapCarry,
      'replayFocusUnderlapChannel' => l10n.replayFocusUnderlapChannel,
      'replayFocusCrossArrival' => l10n.replayFocusCrossArrival,
      'replayFocusPressureTurnover' => l10n.replayFocusPressureTurnover,
      'replayFocusCarryTurnover' => l10n.replayFocusCarryTurnover,
      _ => key,
    };
