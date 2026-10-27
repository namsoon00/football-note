part of 'scan_pass_game_screen.dart';

typedef ScanPassSpatialCatalogLoader = Future<SpatialLibraryCatalog> Function();
typedef ScanPassSpatialSceneLoader = Future<RealMatchReplayData> Function(
  SpatialLibraryScene scene,
);

class _InjectedSpatialLibraryRepository
    implements ScanPassSpatialLibraryRepository {
  final ScanPassSpatialCatalogLoader catalogLoader;
  final ScanPassSpatialSceneLoader sceneLoader;

  const _InjectedSpatialLibraryRepository({
    required this.catalogLoader,
    required this.sceneLoader,
  });

  @override
  Future<SpatialLibraryCatalog> loadCatalog() => catalogLoader();

  @override
  Future<RealMatchReplayData> loadScene(SpatialLibraryScene scene) =>
      sceneLoader(scene);
}

enum _SpatialMenuAction {
  chooseScene,
  focusReplay,
  sourceInfo,
  legacyViewer,
  authoredSample,
}

class ScanPassSpatialLibraryScreen extends StatefulWidget {
  final MatchMomentSourceLauncher? sourceLauncher;
  final ScanPassSpatialCatalogLoader? catalogLoader;
  final ScanPassSpatialSceneLoader? sceneLoader;
  final AuthoredTouchSampleLoader? authoredSampleLoader;

  const ScanPassSpatialLibraryScreen({
    super.key,
    this.sourceLauncher,
    this.catalogLoader,
    this.sceneLoader,
    this.authoredSampleLoader,
  });

  @override
  State<ScanPassSpatialLibraryScreen> createState() =>
      _ScanPassSpatialLibraryScreenState();
}

class _ScanPassSpatialLibraryScreenState
    extends State<ScanPassSpatialLibraryScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _systemUiStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFF10291F),
    systemNavigationBarIconBrightness: Brightness.light,
  );

  static const _licenseAsset = 'assets/scan_pass_spatial/LICENSE';
  static bool _licenseRegistered = false;

  late final AnimationController _controller;
  late final ScanPassSpatialLibraryService _service;
  SpatialLibraryCatalog? _catalog;
  RealMatchReplayData? _data;
  Object? _loadError;
  int _sceneIndex = 0;
  int _loadGeneration = 0;
  int _playGeneration = 0;
  bool _playing = false;
  bool _focusedReplay = false;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;
  SpatialLibraryScene? get _scene => _catalog?.scenes[_sceneIndex];
  double get _time => (_data?.duration ?? 0) * _controller.value;
  bool get _finished =>
      _data != null && _time >= _data!.duration - 1 / _data!.fps;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      animationBehavior: AnimationBehavior.preserve,
    )..addListener(_tick);
    final assets = ScanPassSpatialAssetRepository();
    _service = ScanPassSpatialLibraryService(
      _InjectedSpatialLibraryRepository(
        catalogLoader: widget.catalogLoader ?? assets.loadCatalog,
        sceneLoader: widget.sceneLoader ?? assets.loadScene,
      ),
    );
    _registerLicense();
    _loadInitial();
  }

  static void _registerLicense() {
    if (_licenseRegistered) return;
    _licenseRegistered = true;
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks(
        const <String>['SkillCorner Open Data'],
        await rootBundle.loadString(_licenseAsset),
      );
    });
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  Future<void> _loadInitial() async {
    final generation = ++_loadGeneration;
    try {
      final catalog = await _service.loadCatalog();
      if (!mounted || generation != _loadGeneration) return;
      final data = await _loadScene(catalog.scenes.first);
      if (!mounted || generation != _loadGeneration) return;
      _applyLoaded(catalog, data, 0);
    } catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() => _loadError = error);
    }
  }

  Future<RealMatchReplayData> _loadScene(SpatialLibraryScene scene) {
    return _service.loadScene(scene);
  }

  Future<void> _selectScene(int index) async {
    final catalog = _catalog;
    if (catalog == null || index < 0 || index >= catalog.scenes.length) return;
    final generation = ++_loadGeneration;
    _stopPlayback(update: false);
    _controller.value = 0;
    setState(() {
      _sceneIndex = index;
      _data = null;
      _loadError = null;
      _focusedReplay = false;
    });
    try {
      final scene = catalog.scenes[index];
      final data = await _loadScene(scene);
      if (!mounted || generation != _loadGeneration) return;
      _applyLoaded(catalog, data, index);
    } catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() => _loadError = error);
    }
  }

  void _applyLoaded(
    SpatialLibraryCatalog catalog,
    RealMatchReplayData data,
    int index,
  ) {
    _controller
      ..duration = Duration(milliseconds: (data.duration * 1000).round())
      ..value = 0;
    setState(() {
      _catalog = catalog;
      _data = data;
      _sceneIndex = index;
      _loadError = null;
      _playing = false;
      _focusedReplay = false;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _stopPlayback();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _loadGeneration++;
    _playGeneration++;
    _controller
      ..removeListener(_tick)
      ..dispose();
    super.dispose();
  }

  void _stopPlayback({bool update = true}) {
    _playGeneration++;
    _controller.stop();
    if (update && mounted && (_playing || _focusedReplay)) {
      setState(() {
        _playing = false;
        _focusedReplay = false;
      });
    } else {
      _playing = false;
      _focusedReplay = false;
    }
  }

  void _togglePlayback() {
    if (_data == null) return;
    if (_playing) {
      _stopPlayback();
      return;
    }
    if (_finished) _controller.value = 0;
    _playAtSourceSpeed();
  }

  void _playAtSourceSpeed() {
    final data = _data;
    if (data == null) return;
    final generation = ++_playGeneration;
    setState(() {
      _playing = true;
      _focusedReplay = false;
    });
    unawaited(() async {
      try {
        await _controller.forward().orCancel;
      } on TickerCanceled {
        return;
      }
      if (!mounted || generation != _playGeneration) return;
      setState(() => _playing = false);
    }());
  }

  void _playFocusReplay() {
    final data = _data;
    final scene = _scene;
    if (data == null || scene == null) return;
    _stopPlayback(update: false);
    _controller.value = scene.evidenceStart / data.duration;
    final generation = ++_playGeneration;
    setState(() {
      _playing = true;
      _focusedReplay = true;
    });
    unawaited(() async {
      try {
        await _controller
            .animateTo(
              scene.evidenceEnd / data.duration,
              duration: Duration(
                milliseconds:
                    ((scene.evidenceEnd - scene.evidenceStart) * 2000).round(),
              ),
              curve: Curves.linear,
            )
            .orCancel;
        if (!mounted || generation != _playGeneration) return;
        setState(() => _focusedReplay = false);
        await _controller
            .animateTo(
              1,
              duration: Duration(
                milliseconds:
                    ((data.duration - scene.evidenceEnd) * 1000).round(),
              ),
              curve: Curves.linear,
            )
            .orCancel;
      } on TickerCanceled {
        return;
      }
      if (!mounted || generation != _playGeneration) return;
      setState(() => _playing = false);
    }());
  }

  void _seek(double value) {
    _stopPlayback(update: false);
    setState(() => _controller.value = value);
  }

  Future<void> _openLibrary() async {
    final catalog = _catalog;
    if (catalog == null) return;
    _stopPlayback();
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _SpatialLibrarySheet(
        catalog: catalog,
        selectedIndex: _sceneIndex,
      ),
    );
    if (!mounted || selected == null || selected == _sceneIndex) return;
    await _selectScene(selected);
  }

  Future<void> _openInfo() async {
    final catalog = _catalog;
    final scene = _scene;
    if (catalog == null || scene == null) return;
    _stopPlayback();
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => _SpatialSourceInfoSheet(
        catalog: catalog,
        scene: scene,
        onOpenSource: () {
          Navigator.pop(sheetContext);
          unawaited(_openSource());
        },
      ),
    );
  }

  Future<void> _openSource() async {
    final scene = _scene;
    if (scene == null) return;
    final launcher = widget.sourceLauncher ??
        (Uri value) => launchUrl(value, mode: LaunchMode.externalApplication);
    var opened = false;
    try {
      opened = await launcher(Uri.parse(scene.sourceUrl));
    } catch (_) {
      opened = false;
    }
    if (!mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_l10n.realMatchReplaySourceUnavailable)),
    );
  }

  Future<void> _handleMenu(_SpatialMenuAction action) async {
    switch (action) {
      case _SpatialMenuAction.chooseScene:
        await _openLibrary();
        break;
      case _SpatialMenuAction.focusReplay:
        _playFocusReplay();
        break;
      case _SpatialMenuAction.sourceInfo:
        await _openInfo();
        break;
      case _SpatialMenuAction.legacyViewer:
        _stopPlayback();
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (context) => ScanPassRealMatchReplayScreen(
              sourceLauncher: widget.sourceLauncher,
              authoredSampleLoader: widget.authoredSampleLoader,
            ),
          ),
        );
        break;
      case _SpatialMenuAction.authoredSample:
        _stopPlayback();
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (context) => ScanPassAuthoredTouchSampleScreen(
              dataLoader: widget.authoredSampleLoader,
            ),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final catalog = _catalog;
    final scene = _scene;
    final colors = _ScanPassColors.of(context);
    if (_loadError != null) {
      return _withReadableSystemUi(Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.sports_soccer, size: 44, color: colors.muted),
                const SizedBox(height: 12),
                Text(
                  _l10n.spatialLibraryLoadFailed,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: catalog == null
                      ? _loadInitial
                      : () => _selectScene(_sceneIndex),
                  child: Text(_l10n.realMatchReplayRetry),
                ),
              ]),
            ),
          ),
        ),
      ));
    }
    if (data == null || catalog == null || scene == null) {
      return _withReadableSystemUi(Scaffold(
        backgroundColor: colors.background,
        body: Center(
          child: Semantics(
            label: _l10n.spatialLibraryLoading,
            child: const CircularProgressIndicator(),
          ),
        ),
      ));
    }
    return _withReadableSystemUi(Scaffold(
      backgroundColor: const Color(0xFF10291F),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final portrait = constraints.maxHeight > constraints.maxWidth;
          final compact =
              constraints.maxWidth <= 380 || constraints.maxHeight <= 340;
          final pitch = _buildPitch(data, scene, portrait);
          final shortLandscape = !portrait && constraints.maxHeight <= 420;
          if (!shortLandscape) {
            return Column(children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 5 : 8,
                  compact ? 4 : 8,
                  compact ? 5 : 8,
                  3,
                ),
                child: _buildContextCard(
                  scene,
                  catalog,
                  portrait,
                  compact,
                  sidePanel: false,
                ),
              ),
              Expanded(child: pitch),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 5 : 8,
                  3,
                  compact ? 5 : 8,
                  compact ? 4 : 8,
                ),
                child: _buildControls(
                  scene,
                  portrait,
                  compact,
                  sidePanel: false,
                ),
              ),
            ]);
          }
          final cameraRatio =
              data.scene.camera.width / data.scene.camera.height;
          final idealPitchWidth = constraints.maxHeight * cameraRatio;
          final sidePanelWidth =
              (constraints.maxWidth * .34).clamp(214.0, 240.0);
          final pitchWidth = math.min(
            idealPitchWidth,
            math.max(0.0, constraints.maxWidth - sidePanelWidth),
          );
          return Row(children: [
            SizedBox(width: pitchWidth, child: pitch),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 5, 4),
                child: DecoratedBox(
                  key: const ValueKey<String>('spatial-side-panel'),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10291F),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(children: [
                    Expanded(
                      child: _buildContextCard(
                        scene,
                        catalog,
                        portrait,
                        compact,
                        sidePanel: true,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildControls(
                      scene,
                      portrait,
                      compact,
                      sidePanel: true,
                    ),
                  ]),
                ),
              ),
            ),
          ]);
        }),
      ),
    ));
  }

  Widget _withReadableSystemUi(Widget child) =>
      AnnotatedRegion<SystemUiOverlayStyle>(
        key: const ValueKey<String>('spatial-system-ui'),
        value: _systemUiStyle,
        child: child,
      );

  Widget _buildPitch(
    RealMatchReplayData data,
    SpatialLibraryScene scene,
    bool portrait,
  ) {
    return Center(
      child: AspectRatio(
        aspectRatio: portrait
            ? data.scene.camera.height / data.scene.camera.width
            : data.scene.camera.width / data.scene.camera.height,
        child: Semantics(
          image: true,
          label: _l10n.spatialPitchSemantics(
            scene.home,
            scene.away,
            scene.focusPlayerName,
            _themeTitle(_l10n, scene.theme),
          ),
          value: _sourceTimeLabel(scene),
          child: ExcludeSemantics(
            child: CustomPaint(
              key: const ValueKey<String>('spatial-pitch'),
              painter: SpatialLibraryPitchPainter(
                data: data,
                scene: scene,
                time: _time,
                brightness: Theme.of(context).brightness,
                portrait: portrait,
                textDirection: Directionality.of(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContextCard(
    SpatialLibraryScene scene,
    SpatialLibraryCatalog catalog,
    bool portrait,
    bool compact, {
    required bool sidePanel,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final matchLine = _l10n.spatialMatchLine(
      scene.home,
      scene.away,
      scene.date,
    );
    final sceneLine = sidePanel
        ? '${scene.focusPlayerName} · ${_themeTitle(_l10n, scene.theme)}'
        : '${_l10n.spatialSceneHeader(_sceneIndex + 1, catalog.scenes.length, scene.focusPlayerName)} · ${_themeTitle(_l10n, scene.theme)}';
    final cue = _phaseCue(_l10n, scene, _data!, _time);
    final content = Padding(
      padding: EdgeInsets.fromLTRB(compact ? 7 : 10, 4, 4, compact ? 5 : 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (!sidePanel && Navigator.of(context).canPop())
              AppBarActionButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                compact: true,
                margin: EdgeInsets.zero,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
              ),
            Expanded(
              child: Text(
                matchLine,
                key: const ValueKey<String>('spatial-match-line'),
                style: (sidePanel || compact
                        ? textTheme.labelMedium
                        : textTheme.titleSmall)
                    ?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (!sidePanel) _buildMoreMenu(compact: compact),
          ]),
          Text(
            sceneLine,
            key: const ValueKey<String>('spatial-scene-line'),
            style: textTheme.labelSmall?.copyWith(
              color: const Color(0xFFD6F39F),
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            cue,
            key: const ValueKey<String>('spatial-cue-line'),
            style: (sidePanel ? textTheme.labelSmall : textTheme.bodySmall)
                ?.copyWith(color: Colors.white),
          ),
          if (!sidePanel &&
              _data!.displaySample(_time).hasReconstructedPositions)
            Text(
              _l10n.spatialInferredLegend,
              style: textTheme.labelSmall?.copyWith(color: Colors.white70),
            ),
        ],
      ),
    );
    return DecoratedBox(
      key: const ValueKey<String>('spatial-context'),
      decoration: BoxDecoration(
        color: const Color(0xE6112E23),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: sidePanel
          ? SingleChildScrollView(
              key: const ValueKey<String>('spatial-context-scroll'),
              child: content,
            )
          : content,
    );
  }

  Widget _buildMoreMenu({required bool compact}) =>
      PopupMenuButton<_SpatialMenuAction>(
        key: const ValueKey<String>('spatial-more'),
        tooltip: _l10n.flowMore,
        padding: EdgeInsets.zero,
        constraints: compact
            ? const BoxConstraints.tightFor(width: 38, height: 38)
            : null,
        color: Theme.of(context).colorScheme.surface,
        onOpened: _stopPlayback,
        onSelected: (action) => unawaited(_handleMenu(action)),
        icon: const Icon(Icons.more_horiz, color: Colors.white),
        itemBuilder: (context) => [
          PopupMenuItem(
            key: const ValueKey<String>('spatial-choose-scene'),
            value: _SpatialMenuAction.chooseScene,
            child: Text(_l10n.spatialChooseScene),
          ),
          PopupMenuItem(
            key: const ValueKey<String>('spatial-focus-replay'),
            value: _SpatialMenuAction.focusReplay,
            child: Text(_l10n.spatialFocusReplay),
          ),
          PopupMenuItem(
            key: const ValueKey<String>('spatial-source-info'),
            value: _SpatialMenuAction.sourceInfo,
            child: Text(_l10n.spatialSourceInfo),
          ),
          PopupMenuItem(
            key: const ValueKey<String>('spatial-legacy-viewer'),
            value: _SpatialMenuAction.legacyViewer,
            child: Text(_l10n.spatialLegacyViewer),
          ),
          PopupMenuItem(
            key: const ValueKey<String>('spatial-authored-sample'),
            value: _SpatialMenuAction.authoredSample,
            child: Text(_l10n.authoredTouchMenuEntry),
          ),
        ],
      );

  Widget _buildControls(
    SpatialLibraryScene scene,
    bool portrait,
    bool compact, {
    required bool sidePanel,
  }) {
    final direction = portrait
        ? (scene.attackDirection > 0
            ? _l10n.spatialDirectionUp
            : _l10n.spatialDirectionDown)
        : (scene.attackDirection > 0
            ? _l10n.spatialDirectionRight
            : _l10n.spatialDirectionLeft);
    final playLabel = _playing
        ? _l10n.realMatchReplayPauseAction
        : _finished
            ? _l10n.realMatchReplayReplayAction
            : _l10n.realMatchReplayPlay;
    final playButton = Semantics(
      key: const ValueKey<String>('spatial-play'),
      container: true,
      excludeSemantics: true,
      button: true,
      label: playLabel,
      child: IconButton.filled(
        tooltip: playLabel,
        visualDensity: VisualDensity.compact,
        onPressed: _togglePlayback,
        icon: Icon(
          _playing
              ? Icons.pause
              : _finished
                  ? Icons.replay
                  : Icons.play_arrow,
        ),
      ),
    );
    final nextButton = Semantics(
      key: const ValueKey<String>('spatial-next'),
      container: true,
      excludeSemantics: true,
      button: true,
      label: _l10n.spatialNextScene,
      child: Tooltip(
        message: _l10n.spatialNextScene,
        child: IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => unawaited(
            _selectScene((_sceneIndex + 1) % _catalog!.scenes.length),
          ),
          icon: const Icon(Icons.skip_next, color: Colors.white),
        ),
      ),
    );
    final directionLabel = _focusedReplay
        ? _l10n.spatialFocusReplayActive
        : _l10n.spatialAttackDirection(scene.attackingTeam, direction);
    return DecoratedBox(
      key: const ValueKey<String>('spatial-controls'),
      decoration: BoxDecoration(
        color: const Color(0xE6112E23),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(compact ? 5 : 8, 2, compact ? 5 : 8, 4),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (!sidePanel)
            SizedBox(
              height: compact ? 20 : 26,
              child: Slider(
                key: const ValueKey<String>('spatial-progress'),
                value: _controller.value,
                onChanged: _seek,
                semanticFormatterCallback: (_) => _sourceTimeLabel(scene),
              ),
            ),
          if (sidePanel) ...[
            Text(
              _sourceTimeLabel(scene),
              key: const ValueKey<String>('spatial-clock'),
              maxLines: 1,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Text(
              directionLabel,
              key: const ValueKey<String>('spatial-direction'),
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: Colors.white70),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (Navigator.of(context).canPop())
                  IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).backButtonTooltip,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                playButton,
                nextButton,
                _buildMoreMenu(compact: true),
              ],
            ),
          ] else
            Row(children: [
              playButton,
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _sourceTimeLabel(scene),
                      key: const ValueKey<String>('spatial-clock'),
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      directionLabel,
                      key: const ValueKey<String>('spatial-direction'),
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              nextButton,
            ]),
        ]),
      ),
    );
  }

  String _matchClock(double seconds) {
    final minute = seconds ~/ 60;
    final second = seconds - minute * 60;
    return '$minute:${second.toStringAsFixed(1).padLeft(4, '0')}';
  }

  String _sourceTimeLabel(SpatialLibraryScene scene) {
    final clock = _matchClock(scene.startClock + _time);
    return scene.period == 1
        ? _l10n.spatialFirstHalfTime(clock)
        : _l10n.spatialSecondHalfTime(clock);
  }
}

class _SpatialLibrarySheet extends StatefulWidget {
  final SpatialLibraryCatalog catalog;
  final int selectedIndex;

  const _SpatialLibrarySheet(
      {required this.catalog, required this.selectedIndex});

  @override
  State<_SpatialLibrarySheet> createState() => _SpatialLibrarySheetState();
}

class _SpatialLibrarySheetState extends State<_SpatialLibrarySheet> {
  final _searchController = TextEditingController();
  SpatialLearningTheme? _theme;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scenes = widget.catalog
        .filtered(theme: _theme)
        .where(
          (scene) => _matchesLocalizedSearch(
            l10n,
            scene,
            _searchController.text,
          ),
        )
        .toList(growable: false);
    return FractionallySizedBox(
      heightFactor: .92,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
          child: Row(children: [
            Expanded(
              child: Text(
                l10n.spatialLibraryTitle(widget.catalog.scenes.length),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            key: const ValueKey<String>('spatial-search'),
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.spatialSearchHint,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: ChoiceChip(
                key: const ValueKey<String>('spatial-theme-all'),
                selected: _theme == null,
                onSelected: (_) => setState(() => _theme = null),
                label: Text(l10n.realMatchReplayAllCategories),
              ),
            ),
            for (final theme in SpatialLearningTheme.values)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ChoiceChip(
                  key: ValueKey<String>('spatial-theme-${theme.name}'),
                  selected: _theme == theme,
                  onSelected: (_) => setState(() => _theme = theme),
                  label: Text(_themeTitle(l10n, theme)),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: scenes.isEmpty
              ? Center(child: Text(l10n.spatialNoScenes))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(10, 2, 10, 20),
                  itemCount: scenes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, row) {
                    final scene = scenes[row];
                    final index = widget.catalog.scenes.indexOf(scene);
                    return ListTile(
                      key: ValueKey<String>('spatial-scene-${scene.id}'),
                      selected: index == widget.selectedIndex,
                      onTap: () => Navigator.pop(context, index),
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text(
                        '${scene.focusPlayerName} · ${_themeTitle(l10n, scene.theme)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        l10n.spatialSceneRow(
                          scene.home,
                          scene.away,
                          _catalogClock(scene.startClock),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }

  String _catalogClock(double seconds) {
    final minute = seconds ~/ 60;
    final second = seconds - minute * 60;
    return '$minute:${second.toStringAsFixed(1).padLeft(4, '0')}';
  }
}

class _SpatialSourceInfoSheet extends StatelessWidget {
  final SpatialLibraryCatalog catalog;
  final SpatialLibraryScene scene;
  final VoidCallback onOpenSource;

  const _SpatialSourceInfoSheet({
    required this.catalog,
    required this.scene,
    required this.onOpenSource,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FractionallySizedBox(
      heightFactor: .88,
      child: SingleChildScrollView(
        key: const ValueKey<String>('spatial-info-scroll'),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(
                l10n.spatialSourceInfo,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ]),
          Text(
            l10n.spatialCoverageSummary(
              catalog.scenes.length,
              catalog.matchIds.length,
              catalog.focalPlayers.length,
              catalog.themes.length,
            ),
          ),
          const SizedBox(height: 12),
          Text(l10n.spatialMitAttribution),
          const SizedBox(height: 8),
          Text(l10n.spatialInterpretationLimitation),
          const SizedBox(height: 8),
          Text(l10n.spatialXyOnlyDisclosure),
          const SizedBox(height: 8),
          Text(l10n.spatialInferredDisclosure),
          const SizedBox(height: 8),
          Text(l10n.spatialSelectionDisclosure),
          const SizedBox(height: 12),
          SelectableText(
              l10n.realMatchReplaySourceCommit(catalog.sourceCommit)),
          const SizedBox(height: 8),
          Text(
            l10n.spatialCurrentSceneSource(
              scene.home,
              scene.away,
              scene.period,
              scene.startFrame,
              scene.endFrame,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              key: const ValueKey<String>('spatial-open-source'),
              onPressed: onOpenSource,
              icon: const Icon(Icons.open_in_new),
              label: Text(l10n.realMatchReplaySource),
            ),
          ),
        ]),
      ),
    );
  }
}

class SpatialLibraryPitchPainter extends CustomPainter {
  final RealMatchReplayData data;
  final SpatialLibraryScene scene;
  final double time;
  final Brightness brightness;
  final bool portrait;
  final TextDirection textDirection;

  const SpatialLibraryPitchPainter({
    required this.data,
    required this.scene,
    required this.time,
    required this.brightness,
    required this.portrait,
    required this.textDirection,
  });

  Color get _pitch => brightness == Brightness.dark
      ? const Color(0xFF173E2B)
      : const Color(0xFF286044);
  Color get _stripe => brightness == Brightness.dark
      ? const Color(0xFF1F4933)
      : const Color(0xFF2F684B);
  Color get _line => const Color(0xFFCBDDCE);
  Color get _focus => const Color(0xFFE0F59A);
  Color get _turnover => const Color(0xFFFFB08E);

  bool get showsRecordedTrace => time >= scene.evidenceStart;
  bool get showsEndpointRegion => time >= scene.evidenceEnd;
  SpatialObservedDefenderGap? get currentDefenderGap =>
      scene.observedNearbyDefender(data, time);

  List<int> get currentHighlightPlayerIds {
    final ids = <int>[];
    for (final anchor in scene.evidenceAnchors) {
      if (anchor.time > time) break;
      if (!ids.contains(anchor.playerId)) ids.add(anchor.playerId);
    }
    if (ids.isEmpty) {
      ids.add(scene.evidenceAnchors.first.playerId);
    }
    final defenderGap = currentDefenderGap;
    if (defenderGap != null) {
      if (!ids.contains(defenderGap.actorId)) ids.add(defenderGap.actorId);
      if (!ids.contains(defenderGap.defenderId)) {
        ids.add(defenderGap.defenderId);
      }
    }
    return ids.take(4).toList(growable: false);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFF10291F));
    final view = _viewRect(size);
    final pitch = _pitchRect(view);
    canvas.drawRRect(
      RRect.fromRectAndRadius(pitch, const Radius.circular(3)),
      Paint()..color = _pitch,
    );
    _drawPitch(canvas, view);
    final sample = data.displaySample(time);
    final source = data.renderSample(time);
    _drawEvidence(canvas, view);
    _drawNearbyDefenderGap(canvas, view);
    _drawTails(canvas, view);
    _drawPlayers(canvas, view, sample);
    _drawBall(canvas, view, source.ball);
  }

  Rect _viewRect(Size size) {
    final available = Rect.fromLTWH(4, 4, size.width - 8, size.height - 8);
    final ratio = portrait
        ? data.scene.camera.height / data.scene.camera.width
        : data.scene.camera.width / data.scene.camera.height;
    var width = available.width;
    var height = width / ratio;
    if (height > available.height) {
      height = available.height;
      width = height * ratio;
    }
    return Rect.fromCenter(
      center: available.center,
      width: width,
      height: height,
    );
  }

  Rect _pitchRect(Rect view) {
    final first = _project(
      view,
      RealMatchReplayPoint(-data.pitchLength / 2, -data.pitchWidth / 2),
    );
    final second = _project(
      view,
      RealMatchReplayPoint(data.pitchLength / 2, data.pitchWidth / 2),
    );
    return Rect.fromPoints(first, second);
  }

  Rect pitchBounds(Size size) => _pitchRect(_viewRect(size));

  Offset _project(Rect view, RealMatchReplayPoint point) {
    final camera = data.scene.camera;
    final nx = (point.x - camera.minX) / camera.width;
    final ny = (point.y - camera.minY) / camera.height;
    return portrait
        ? Offset(
            view.left + ny * view.width,
            view.bottom - nx * view.height,
          )
        : Offset(view.left + nx * view.width, view.top + ny * view.height);
  }

  void _drawPitch(Canvas canvas, Rect pitch) {
    final halfLength = data.pitchLength / 2;
    final halfWidth = data.pitchWidth / 2;
    for (var x = -halfLength; x < halfLength; x += 10) {
      final start = _project(pitch, RealMatchReplayPoint(x, -halfWidth));
      final end = _project(
        pitch,
        RealMatchReplayPoint(math.min(x + 10, halfLength), halfWidth),
      );
      final stripeRect = Rect.fromPoints(start, end);
      if (((x + halfLength) / 10).round().isEven) {
        canvas.drawRect(
            stripeRect, Paint()..color = _stripe.withValues(alpha: .45));
      }
    }
    final line = Paint()
      ..color = _line.withValues(alpha: .88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15;
    void path(List<RealMatchReplayPoint> points) {
      final value = Path();
      for (var index = 0; index < points.length; index++) {
        final point = _project(pitch, points[index]);
        index == 0
            ? value.moveTo(point.dx, point.dy)
            : value.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(value, line);
    }

    path([
      RealMatchReplayPoint(-halfLength, -halfWidth),
      RealMatchReplayPoint(halfLength, -halfWidth),
      RealMatchReplayPoint(halfLength, halfWidth),
      RealMatchReplayPoint(-halfLength, halfWidth),
      RealMatchReplayPoint(-halfLength, -halfWidth),
    ]);
    path([
      RealMatchReplayPoint(0, -halfWidth),
      RealMatchReplayPoint(0, halfWidth),
    ]);
    for (final side in [-1.0, 1.0]) {
      final goal = side * halfLength;
      final box = side * (halfLength - 16.5);
      path([
        RealMatchReplayPoint(goal, -20.16),
        RealMatchReplayPoint(box, -20.16),
        RealMatchReplayPoint(box, 20.16),
        RealMatchReplayPoint(goal, 20.16),
      ]);
    }
    final center = _project(pitch, const RealMatchReplayPoint(0, 0));
    final radiusPoint = _project(pitch, const RealMatchReplayPoint(9.15, 0));
    canvas.drawCircle(center, (radiusPoint - center).distance, line);
    canvas.drawCircle(center, 1.5, Paint()..color = _line);
  }

  void _drawEvidence(Canvas canvas, Rect pitch) {
    if (!showsRecordedTrace) return;
    final tone = scene.theme == SpatialLearningTheme.turnover ||
            scene.theme == SpatialLearningTheme.recovery
        ? _turnover
        : _focus;
    final traceEnd = math.min(time, scene.evidenceEnd);
    final firstFrame = (scene.evidenceStart * data.fps).ceil();
    final lastFrame = (traceEnd * data.fps).floor();
    final trace = Path();
    for (var frame = firstFrame; frame <= lastFrame; frame++) {
      final point = _project(pitch, data.sample(frame / data.fps).ball);
      if (frame == firstFrame) {
        trace.moveTo(point.dx, point.dy);
      } else {
        trace.lineTo(point.dx, point.dy);
      }
    }
    if (lastFrame > firstFrame) {
      canvas.drawPath(
        trace,
        Paint()
          ..color = tone.withValues(alpha: .9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    if (showsEndpointRegion) {
      final endpoint = scene.evidenceAnchors.last;
      final currentPlayer =
          data.renderSample(time).players[data.playerIndex(endpoint.playerId)];
      final endpointPlayer = data
          .sample(endpoint.time)
          .players[data.playerIndex(endpoint.playerId)];
      if (currentPlayer == null || endpointPlayer == null) return;
      final target = _project(pitch, endpointPlayer);
      final radiusPoint = _project(
        pitch,
        RealMatchReplayPoint(endpointPlayer.x + 4.5, endpointPlayer.y),
      );
      final radius = math.max(9.0, (radiusPoint - target).distance);
      canvas.drawCircle(
        target,
        radius,
        Paint()..color = tone.withValues(alpha: .15),
      );
      canvas.drawCircle(
        target,
        radius,
        Paint()
          ..color = tone.withValues(alpha: .72)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3,
      );
    }
  }

  void _drawTails(Canvas canvas, Rect pitch) {
    final defenderId = currentDefenderGap?.defenderId;
    for (final id in currentHighlightPlayerIds) {
      final index = data.playerIndex(id);
      final segments = <List<RealMatchReplayPoint>>[];
      var segment = <RealMatchReplayPoint>[];
      final firstFrame = (math.max(0.0, time - .8) * data.fps).ceil();
      final lastFrame = (time * data.fps).floor();
      for (var frame = firstFrame; frame <= lastFrame; frame++) {
        final point = data.sample(frame / data.fps).players[index];
        if (point == null) {
          if (segment.length > 1) segments.add(segment);
          segment = <RealMatchReplayPoint>[];
        } else {
          segment.add(point);
        }
      }
      if (segment.length > 1) segments.add(segment);
      for (final points in segments) {
        final path = Path();
        for (var pointIndex = 0; pointIndex < points.length; pointIndex++) {
          final projected = _project(pitch, points[pointIndex]);
          pointIndex == 0
              ? path.moveTo(projected.dx, projected.dy)
              : path.lineTo(projected.dx, projected.dy);
        }
        canvas.drawPath(
          path,
          Paint()
            ..color =
                (id == defenderId ? _turnover : _focus).withValues(alpha: .7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  void _drawNearbyDefenderGap(Canvas canvas, Rect pitch) {
    final gap = currentDefenderGap;
    if (gap == null) return;
    final actor = _project(pitch, gap.actor);
    final defender = _project(pitch, gap.defender);
    canvas.drawLine(
      actor,
      defender,
      Paint()
        ..color = _turnover.withValues(alpha: .72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    canvas.drawCircle(
      defender,
      3,
      Paint()..color = _turnover.withValues(alpha: .85),
    );
  }

  void _drawPlayers(
    Canvas canvas,
    Rect pitch,
    RealMatchReplayDisplaySample sample,
  ) {
    final marker =
        (math.min(pitch.width, pitch.height) / 48).clamp(5.2, 9.0).toDouble();
    final participants = currentHighlightPlayerIds.toSet();
    final defenderId = currentDefenderGap?.defenderId;
    for (var index = 0; index < data.players.length; index++) {
      final point = sample.players[index];
      if (point == null) continue;
      final player = data.players[index];
      final center = _project(pitch, point);
      final inferred = sample.reconstructed[index];
      final jersey = _parseReplayColor(
        player.home ? data.scene.homeColor : data.scene.awayColor,
      );
      final numberColor = _parseReplayColor(
        player.home ? data.scene.homeNumberColor : data.scene.awayNumberColor,
      );
      if (participants.contains(player.id) && !inferred) {
        canvas.drawCircle(
          center,
          marker + 3.2,
          Paint()
            ..color = player.id == defenderId ? _turnover : _focus
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
      final shirt = Path()
        ..moveTo(center.dx - marker * .45, center.dy - marker * .72)
        ..lineTo(center.dx - marker * 1.02, center.dy - marker * .25)
        ..lineTo(center.dx - marker * .72, center.dy + marker * .18)
        ..lineTo(center.dx - marker * .5, center.dy + marker * .02)
        ..lineTo(center.dx - marker * .42, center.dy + marker * .82)
        ..lineTo(center.dx + marker * .42, center.dy + marker * .82)
        ..lineTo(center.dx + marker * .5, center.dy + marker * .02)
        ..lineTo(center.dx + marker * .72, center.dy + marker * .18)
        ..lineTo(center.dx + marker * 1.02, center.dy - marker * .25)
        ..lineTo(center.dx + marker * .45, center.dy - marker * .72)
        ..close();
      canvas.drawPath(
        shirt,
        Paint()
          ..color = inferred ? jersey.withValues(alpha: .18) : jersey
          ..style = inferred ? PaintingStyle.stroke : PaintingStyle.fill
          ..strokeWidth = inferred ? 1.4 : 1,
      );
      canvas.drawPath(
        shirt,
        Paint()
          ..color = Colors.black.withValues(alpha: .55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8,
      );
      if (inferred) {
        canvas.drawLine(
          center + Offset(-marker * .55, marker * .55),
          center + Offset(marker * .55, -marker * .55),
          Paint()
            ..color = Colors.white70
            ..strokeWidth = 1,
        );
      }
      final number = '${player.number ?? ''}';
      final painter = TextPainter(
        text: TextSpan(
          text: number,
          style: TextStyle(
            color: inferred ? Colors.white70 : numberColor,
            fontSize: marker * 1.12,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        textDirection: textDirection,
      )..layout();
      painter.paint(
          canvas, center - Offset(painter.width / 2, painter.height / 2));
    }
  }

  void _drawBall(Canvas canvas, Rect pitch, RealMatchReplayPoint ball) {
    final center = _project(pitch, ball);
    canvas.drawCircle(
      center,
      5.2,
      Paint()
        ..color = const Color(0xFFFFD66B).withValues(alpha: .9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawCircle(
      center,
      4.2,
      Paint()
        ..color = Colors.black.withValues(alpha: .35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawCircle(center, 3.1, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      3.1,
      Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8,
    );
  }

  @override
  bool shouldRepaint(covariant SpatialLibraryPitchPainter oldDelegate) =>
      oldDelegate.data != data ||
      oldDelegate.scene != scene ||
      oldDelegate.time != time ||
      oldDelegate.brightness != brightness ||
      oldDelegate.portrait != portrait ||
      oldDelegate.textDirection != textDirection;
}

Color _parseReplayColor(String source) {
  final normalized = source.replaceFirst('#', '');
  final value = int.tryParse(normalized, radix: 16);
  if (value == null) return Colors.white;
  return Color(0xFF000000 | value);
}

String _themeTitle(AppLocalizations l10n, SpatialLearningTheme theme) =>
    switch (theme) {
      SpatialLearningTheme.lateralSwitch => l10n.spatialThemeLateralSwitch,
      SpatialLearningTheme.forwardConnection =>
        l10n.spatialThemeForwardConnection,
      SpatialLearningTheme.pressureSupport => l10n.spatialThemePressureSupport,
      SpatialLearningTheme.carryThenConnect =>
        l10n.spatialThemeCarryThenConnect,
      SpatialLearningTheme.wideToInside => l10n.spatialThemeWideToInside,
      SpatialLearningTheme.combination => l10n.spatialThemeCombination,
      SpatialLearningTheme.turnover => l10n.spatialThemeTurnover,
      SpatialLearningTheme.recovery => l10n.spatialThemeRecovery,
    };

String _objective(AppLocalizations l10n, SpatialLearningTheme theme) =>
    switch (theme) {
      SpatialLearningTheme.lateralSwitch => l10n.spatialObjectiveLateralSwitch,
      SpatialLearningTheme.forwardConnection =>
        l10n.spatialObjectiveForwardConnection,
      SpatialLearningTheme.pressureSupport =>
        l10n.spatialObjectivePressureSupport,
      SpatialLearningTheme.carryThenConnect =>
        l10n.spatialObjectiveCarryThenConnect,
      SpatialLearningTheme.wideToInside => l10n.spatialObjectiveWideToInside,
      SpatialLearningTheme.combination => l10n.spatialObjectiveCombination,
      SpatialLearningTheme.turnover => l10n.spatialObjectiveTurnover,
      SpatialLearningTheme.recovery => l10n.spatialObjectiveRecovery,
    };

String _situation(AppLocalizations l10n, SpatialLibraryScene scene) {
  final names = scene.evidenceAnchors
      .map((anchor) => anchor.playerName)
      .toList(growable: false);
  final first = names.first;
  final second = names.length > 1 ? names[1] : names.first;
  final third = names.length > 2 ? names[2] : second;
  final metrics = scene.metrics;
  return switch (scene.theme) {
    SpatialLearningTheme.lateralSwitch => l10n.spatialSituationLateralSwitch(
        first,
        second,
        metrics.lateralMeters.toStringAsFixed(1),
      ),
    SpatialLearningTheme.forwardConnection =>
      l10n.spatialSituationForwardConnection(
        first,
        second,
        metrics.forwardMeters.toStringAsFixed(1),
      ),
    SpatialLearningTheme.pressureSupport =>
      l10n.spatialSituationPressureSupport(
        first,
        second,
        (metrics.pressureMeters ?? 0).toStringAsFixed(1),
      ),
    SpatialLearningTheme.carryThenConnect =>
      l10n.spatialSituationCarryThenConnect(
        first,
        second,
        metrics.carryMeters.toStringAsFixed(1),
      ),
    SpatialLearningTheme.wideToInside => l10n.spatialSituationWideToInside(
        first,
        second,
        metrics.insideGainMeters.toStringAsFixed(1),
      ),
    SpatialLearningTheme.combination => l10n.spatialSituationCombination(
        first,
        second,
        third,
        metrics.sequenceSeconds.toStringAsFixed(1),
      ),
    SpatialLearningTheme.turnover =>
      l10n.spatialSituationTurnover(first, second),
    SpatialLearningTheme.recovery => l10n.spatialSituationRecovery(
        third,
        metrics.sequenceSeconds.toStringAsFixed(1),
      ),
  };
}

String _phaseCue(
  AppLocalizations l10n,
  SpatialLibraryScene scene,
  RealMatchReplayData data,
  double time,
) {
  if (time < scene.evidenceStart) {
    return l10n.spatialBeforeCue(_objective(l10n, scene.theme));
  }
  if (time < scene.evidenceEnd) {
    final gap = scene.observedNearbyDefender(data, time);
    if (gap != null) {
      return l10n.spatialNearbyDefenderCue(
        gap.defenderName,
        gap.actorName,
        gap.meters.toStringAsFixed(1),
      );
    }
    var current = scene.evidenceAnchors.first;
    for (final anchor in scene.evidenceAnchors) {
      if (anchor.time > time) break;
      current = anchor;
    }
    return l10n.spatialDuringCue(current.playerName);
  }
  return l10n.spatialAfterCue(_situation(l10n, scene));
}

bool _matchesLocalizedSearch(
  AppLocalizations l10n,
  SpatialLibraryScene scene,
  String query,
) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty || scene.matchesSearch(normalized)) return true;
  if (_themeTitle(l10n, scene.theme).toLowerCase().contains(normalized)) {
    return true;
  }
  final aliases = <String, String>{
    'Lionel Messi': l10n.spatialAliasLionelMessi,
    'Cristiano Ronaldo': l10n.spatialAliasCristianoRonaldo,
    'Kylian Mbappe': l10n.spatialAliasKylianMbappe,
    'Kevin de Bruyne': l10n.spatialAliasKevinDeBruyne,
    'Erling Haland': l10n.spatialAliasErlingHaland,
  };
  final names = <String>{
    scene.focusPlayerName,
    ...scene.evidenceAnchors.map((anchor) => anchor.playerName),
  };
  return names.any(
    (name) => aliases[name]?.toLowerCase().contains(normalized) ?? false,
  );
}
