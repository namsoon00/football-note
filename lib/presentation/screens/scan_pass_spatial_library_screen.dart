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
  SpatialFocusPlan? _focusPlan;
  final Map<String, SpatialFocusPlan> _focusPlans = {};
  Object? _loadError;
  int _sceneIndex = 0;
  int? _requestedSceneIndex;
  int? _failedSceneIndex;
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
      setState(() {
        _requestedSceneIndex = null;
        _failedSceneIndex = null;
        _loadError = error;
      });
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
    setState(() {
      _requestedSceneIndex = index;
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
      setState(() {
        _requestedSceneIndex = null;
        _failedSceneIndex = index;
        _loadError = error;
      });
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
    final plan = _focusPlans.putIfAbsent(
      data.scene.id,
      () => SpatialFocusPlan.build(data, catalog.scenes[index]),
    );
    setState(() {
      _catalog = catalog;
      _data = data;
      _focusPlan = plan;
      _sceneIndex = index;
      _requestedSceneIndex = null;
      _failedSceneIndex = null;
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

  void _selectRelative(int delta) {
    final catalog = _catalog;
    if (catalog == null) return;
    final base = _requestedSceneIndex ?? _sceneIndex;
    final target = (base + delta) % catalog.scenes.length;
    unawaited(_selectScene(target));
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final catalog = _catalog;
    final scene = _scene;
    final focusPlan = _focusPlan;
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
                      : () => _selectScene(_failedSceneIndex ?? _sceneIndex),
                  child: Text(_l10n.realMatchReplayRetry),
                ),
              ]),
            ),
          ),
        ),
      ));
    }
    if (data == null || catalog == null || scene == null || focusPlan == null) {
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
              constraints.maxWidth <= 380 || constraints.maxHeight <= 360;
          return Column(children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 5 : 8,
                compact ? 4 : 7,
                compact ? 5 : 8,
                3,
              ),
              child: _buildTopBar(scene),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 8),
                child: _buildPitch(
                  data,
                  scene,
                  focusPlan,
                  portrait,
                  compact,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 5 : 8,
                3,
                compact ? 5 : 8,
                compact ? 4 : 7,
              ),
              child: _buildControls(scene, catalog, compact),
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
    SpatialFocusPlan focusPlan,
    bool portrait,
    bool compact,
  ) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      final shortLandscape = !portrait && size.height < 250;
      final textScaler = MediaQuery.textScalerOf(context);
      final cue = _phaseCue(_l10n, scene, data, _time);
      final cardWidth = shortLandscape
          ? (size.width * .38).clamp(218.0, 260.0)
          : math.min(size.width - 16, compact ? 360.0 : 520.0);
      final cardHeight = _teachingCardHeight(
        scene,
        cue,
        cardWidth,
        compact: compact,
        textScaler: textScaler,
      );
      final minimapWidth = shortLandscape
          ? math.min(84.0, cardWidth * .38)
          : (size.width * (compact ? .25 : .18)).clamp(84.0, 142.0);
      final minimapHeight = minimapWidth * data.pitchWidth / data.pitchLength;
      final Rect cardRect;
      final Rect minimapRect;
      final Rect directionRect;
      final Rect actionRect;
      if (shortLandscape) {
        cardRect = Rect.fromLTWH(
          8,
          8,
          cardWidth - 16,
          math.min(cardHeight, size.height - minimapHeight - 18),
        );
        minimapRect = Rect.fromLTWH(
          8,
          size.height - minimapHeight - 8,
          minimapWidth,
          minimapHeight,
        );
        directionRect = Rect.fromLTRB(
          minimapRect.right + 6,
          minimapRect.top,
          cardWidth - 8,
          size.height - 8,
        );
        actionRect = Rect.fromLTRB(
          cardWidth + 2,
          2,
          size.width - 2,
          size.height - 2,
        );
      } else {
        cardRect = Rect.fromLTWH(8, 8, cardWidth, cardHeight);
        minimapRect = Rect.fromLTWH(
          size.width - minimapWidth - 8,
          size.height - minimapHeight - 8,
          minimapWidth,
          minimapHeight,
        );
        directionRect = Rect.fromLTRB(
          8,
          minimapRect.top,
          minimapRect.left - 8,
          size.height - 8,
        );
        actionRect = Rect.fromLTRB(
          2,
          cardRect.bottom + 7,
          size.width - 2,
          math.min(minimapRect.top - 7, size.height - 2),
        );
      }
      final rotated = SpatialPitchViewport.bestRotation(
        focusPlan.teachingCamera,
        actionRect.size,
      );
      final viewport = SpatialPitchViewport.fit(
        focusPlan.cameraAt(_time),
        size,
        portrait: rotated,
        viewRect: actionRect,
        fieldLength: data.pitchLength,
        fieldWidth: data.pitchWidth,
      );
      final roles = scene.observedRoles(data, _time);
      final roleLabels = <SpatialObservedRoleKind, String>{
        SpatialObservedRoleKind.ballSidePlayer: _l10n.spatialRoleBallSide,
        SpatialObservedRoleKind.connectedTeammate:
            _l10n.spatialRoleRecordedLink,
        SpatialObservedRoleKind.nearbyDefender: _l10n.spatialRoleNearbyDefender,
      };
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(children: [
          Positioned.fill(
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
                    focusPlan: focusPlan,
                    viewport: viewport,
                    time: _time,
                    brightness: Theme.of(context).brightness,
                    portrait: rotated,
                    textDirection: Directionality.of(context),
                    textScaler: textScaler,
                    roles: roles,
                    roleLabels: roleLabels,
                    reservedOverlayRects: [
                      cardRect,
                      minimapRect,
                      directionRect,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fromRect(
            rect: cardRect,
            child: _buildTeachingCard(scene, cue, compact),
          ),
          Positioned.fromRect(
            rect: minimapRect,
            child: Semantics(
              image: true,
              label: _l10n.spatialMinimapSemantics,
              child: ExcludeSemantics(
                child: CustomPaint(
                  key: const ValueKey<String>('spatial-minimap'),
                  painter: SpatialLibraryMinimapPainter(
                    data: data,
                    time: _time,
                    viewportCamera: viewport.camera,
                    portrait: rotated,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fromRect(
            rect: directionRect,
            child: Align(
              alignment: AlignmentDirectional.bottomStart,
              child: _buildDirectionChip(
                scene,
                rotated,
                compactLabel: shortLandscape,
              ),
            ),
          ),
          if (_requestedSceneIndex != null)
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ]),
      );
    });
  }

  Widget _buildTopBar(SpatialLibraryScene scene) {
    final narrow = MediaQuery.sizeOf(context).width <= 380;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 54),
      child: Row(children: [
        if (Navigator.of(context).canPop())
          AppBarActionButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            compact: true,
            margin: const EdgeInsetsDirectional.only(end: 6),
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _l10n.spatialTeamsLine(scene.home, scene.away),
                key: const ValueKey<String>('spatial-match-line'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(
                narrow
                    ? _sourceTimeLabel(scene)
                    : _l10n.spatialDateTimeLine(
                        scene.date,
                        _sourceTimeLabel(scene),
                      ),
                key: const ValueKey<String>('spatial-clock'),
                maxLines: 2,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
        _buildMoreMenu(),
      ]),
    );
  }

  double _teachingCardHeight(
    SpatialLibraryScene scene,
    String cue,
    double width, {
    required bool compact,
    required TextScaler textScaler,
  }) {
    final horizontal = compact ? 8.0 : 10.0;
    final vertical = compact ? 5.0 : 7.0;
    double heightFor(String text, TextStyle? style, int maxLines) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        maxLines: maxLines,
        ellipsis: '…',
        textDirection: Directionality.of(context),
        textScaler: textScaler,
      )..layout(maxWidth: math.max(1, width - horizontal * 2));
      return painter.height;
    }

    final themeStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w900,
        );
    final cueStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          height: 1.15,
          fontWeight: FontWeight.w600,
        );
    // Keep the pitch geometry steady when the brief teaching cue changes phase.
    return vertical * 2 +
        heightFor(_themeTitle(_l10n, scene.theme), themeStyle, 1) +
        heightFor(List.filled(3, cue).join('\n'), cueStyle, 3);
  }

  Widget _buildTeachingCard(
    SpatialLibraryScene scene,
    String cue,
    bool compact,
  ) {
    return IgnorePointer(
      child: DecoratedBox(
        key: const ValueKey<String>('spatial-context'),
        decoration: BoxDecoration(
          color: const Color(0xE810291F),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: Colors.white30),
          boxShadow: const [
            BoxShadow(color: Color(0x55000000), blurRadius: 6),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 5 : 7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _themeTitle(_l10n, scene.theme),
                key: const ValueKey<String>('spatial-theme-line'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFFE0F59A),
                      fontWeight: FontWeight.w900,
                    ),
              ),
              Text(
                cue,
                key: const ValueKey<String>('spatial-cue-line'),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      height: 1.15,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDirectionChip(
    SpatialLibraryScene scene,
    bool portrait, {
    required bool compactLabel,
  }) {
    final label = Text(
      _focusedReplay
          ? _l10n.spatialFocusReplayActive
          : compactLabel
              ? _l10n.spatialDirectionCompact(scene.attackingTeam)
              : _l10n.spatialDirectionTeam(scene.attackingTeam),
      key: const ValueKey<String>('spatial-direction'),
      maxLines: compactLabel ? 1 : 2,
      overflow: compactLabel ? TextOverflow.visible : TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontSize: compactLabel
                ? 9
                : MediaQuery.sizeOf(context).width <= 380
                    ? 10
                    : null,
            fontWeight: FontWeight.w700,
          ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xD910291F),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white30),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            portrait
                ? (scene.attackDirection > 0
                    ? Icons.arrow_upward
                    : Icons.arrow_downward)
                : (scene.attackDirection > 0
                    ? Icons.arrow_forward
                    : Icons.arrow_back),
            size: 15,
            color: const Color(0xFFE0F59A),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: compactLabel
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: label,
                  )
                : label,
          ),
        ]),
      ),
    );
  }

  Widget _buildMoreMenu() => AppBarActionMenuButton<_SpatialMenuAction>(
        key: const ValueKey<String>('spatial-more'),
        tooltip: _l10n.flowMore,
        margin: EdgeInsets.zero,
        onOpened: _stopPlayback,
        onSelected: (action) => unawaited(_handleMenu(action)),
        icon: Icons.more_horiz,
        itemBuilder: (context) => [
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
    SpatialLibraryCatalog catalog,
    bool compact,
  ) {
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
    final previousButton = Semantics(
      key: const ValueKey<String>('spatial-previous'),
      container: true,
      excludeSemantics: true,
      button: true,
      label: _l10n.spatialPreviousScene,
      child: IconButton.filledTonal(
        tooltip: _l10n.spatialPreviousScene,
        visualDensity: VisualDensity.compact,
        onPressed: () => _selectRelative(-1),
        icon: const Icon(Icons.skip_previous),
      ),
    );
    final nextButton = Semantics(
      key: const ValueKey<String>('spatial-next'),
      container: true,
      excludeSemantics: true,
      button: true,
      label: _l10n.spatialNextScene,
      child: IconButton.filledTonal(
        tooltip: _l10n.spatialNextScene,
        visualDensity: VisualDensity.compact,
        onPressed: () => _selectRelative(1),
        icon: const Icon(Icons.skip_next),
      ),
    );
    return DecoratedBox(
      key: const ValueKey<String>('spatial-controls'),
      decoration: BoxDecoration(
        color: const Color(0xE6112E23),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(compact ? 5 : 8, 1, compact ? 5 : 8, 5),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            height: compact ? 20 : 24,
            child: Slider(
              key: const ValueKey<String>('spatial-progress'),
              value: _controller.value,
              onChanged: _seek,
              semanticFormatterCallback: (_) => _sourceTimeLabel(scene),
            ),
          ),
          Row(children: [
            previousButton,
            const SizedBox(width: 5),
            playButton,
            const SizedBox(width: 7),
            Expanded(
              child: OutlinedButton(
                key: const ValueKey<String>('spatial-scene-selector'),
                onPressed: _openLibrary,
                style: ButtonStyle(
                  foregroundColor:
                      const WidgetStatePropertyAll<Color>(Colors.white),
                  backgroundColor: WidgetStateProperty.resolveWith<Color>(
                    (states) => states.contains(WidgetState.disabled)
                        ? const Color(0x99102A20)
                        : const Color(0xFF173E2B),
                  ),
                  overlayColor: const WidgetStatePropertyAll<Color>(
                    Color(0x29E0F59A),
                  ),
                  side: const WidgetStatePropertyAll<BorderSide>(
                    BorderSide(color: Colors.white38),
                  ),
                  padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(
                    EdgeInsets.symmetric(
                      horizontal: compact ? 7 : 10,
                      vertical: 5,
                    ),
                  ),
                  minimumSize: const WidgetStatePropertyAll<Size>(Size(0, 44)),
                  shape: WidgetStatePropertyAll<OutlinedBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                child: Row(children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _l10n.spatialSceneHeader(
                          _sceneIndex + 1,
                          catalog.scenes.length,
                          scene.focusPlayerName,
                        ),
                        key: const ValueKey<String>('spatial-scene-line'),
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontSize: compact ? 9 : 10,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(Icons.expand_less, size: 17),
                ]),
              ),
            ),
            const SizedBox(width: 5),
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

class SpatialPitchViewport {
  final Rect view;
  final RealMatchReplayCamera camera;
  final bool portrait;

  const SpatialPitchViewport._({
    required this.view,
    required this.camera,
    required this.portrait,
  });

  static bool bestRotation(
    RealMatchReplayCamera teachingCamera,
    Size available,
  ) {
    final safeWidth = math.max(1.0, available.width - 32);
    final safeHeight = math.max(1.0, available.height - 32);
    final normalScale = math.min(
      safeWidth / teachingCamera.width,
      safeHeight / teachingCamera.height,
    );
    final rotatedScale = math.min(
      safeWidth / teachingCamera.height,
      safeHeight / teachingCamera.width,
    );
    return rotatedScale > normalScale;
  }

  factory SpatialPitchViewport.fit(
    RealMatchReplayCamera source,
    Size size, {
    required bool portrait,
    Rect? viewRect,
    double? fieldLength,
    double? fieldWidth,
  }) {
    final view = viewRect ??
        Rect.fromLTWH(
          2,
          2,
          math.max(0, size.width - 4),
          math.max(0, size.height - 4),
        );
    final worldRatio = portrait
        ? view.height / math.max(1, view.width)
        : view.width / math.max(1, view.height);
    var width = source.width;
    var height = source.height;
    if (width / height > worldRatio) {
      height = width / worldRatio;
    } else {
      width = height * worldRatio;
    }
    const bodySafety = 32.0;
    final safeWidth = math.max(1.0, view.width - bodySafety * 2);
    final safeHeight = math.max(1.0, view.height - bodySafety * 2);
    final safetyFactor = math.max(
      view.width / safeWidth,
      view.height / safeHeight,
    );
    width *= safetyFactor;
    height *= safetyFactor;
    final sourceCenterX = (source.minX + source.maxX) / 2;
    final sourceCenterY = (source.minY + source.maxY) / 2;
    var centerX = sourceCenterX;
    var centerY = sourceCenterY;
    if (fieldLength != null && width < fieldLength + 1) {
      centerX = centerX.clamp(
        -fieldLength / 2 - .5 + width / 2,
        fieldLength / 2 + .5 - width / 2,
      );
    } else if (fieldLength != null) {
      centerX = 0;
    }
    if (fieldWidth != null && height < fieldWidth + 1) {
      centerY = centerY.clamp(
        -fieldWidth / 2 - .5 + height / 2,
        fieldWidth / 2 + .5 - height / 2,
      );
    } else if (fieldWidth != null) {
      centerY = 0;
    }
    final scaleX = portrait ? view.height / width : view.width / width;
    final scaleY = portrait ? view.width / height : view.height / height;
    final xCenterMin = source.maxX + bodySafety / scaleX - width / 2;
    final xCenterMax = source.minX - bodySafety / scaleX + width / 2;
    final yCenterMin = source.maxY + bodySafety / scaleY - height / 2;
    final yCenterMax = source.minY - bodySafety / scaleY + height / 2;
    centerX = xCenterMin <= xCenterMax
        ? centerX.clamp(xCenterMin, xCenterMax)
        : sourceCenterX;
    centerY = yCenterMin <= yCenterMax
        ? centerY.clamp(yCenterMin, yCenterMax)
        : sourceCenterY;
    return SpatialPitchViewport._(
      view: view,
      camera: RealMatchReplayCamera(
        minX: centerX - width / 2,
        maxX: centerX + width / 2,
        minY: centerY - height / 2,
        maxY: centerY + height / 2,
      ),
      portrait: portrait,
    );
  }

  double get metricScaleX =>
      portrait ? view.height / camera.width : view.width / camera.width;
  double get metricScaleY =>
      portrait ? view.width / camera.height : view.height / camera.height;

  Offset project(RealMatchReplayPoint point) {
    final nx = (point.x - camera.minX) / camera.width;
    final ny = (point.y - camera.minY) / camera.height;
    return portrait
        ? Offset(view.left + ny * view.width, view.bottom - nx * view.height)
        : Offset(view.left + nx * view.width, view.top + ny * view.height);
  }

  bool contains(RealMatchReplayPoint point, {double safetyPixels = 0}) =>
      view.deflate(safetyPixels).contains(project(point));
}

class SpatialLibraryPitchPainter extends CustomPainter {
  final RealMatchReplayData data;
  final SpatialLibraryScene scene;
  final SpatialFocusPlan focusPlan;
  final SpatialPitchViewport viewport;
  final double time;
  final Brightness brightness;
  final bool portrait;
  final TextDirection textDirection;
  final TextScaler textScaler;
  final SpatialObservedRoles roles;
  final Map<SpatialObservedRoleKind, String> roleLabels;
  final List<Rect> reservedOverlayRects;

  const SpatialLibraryPitchPainter({
    required this.data,
    required this.scene,
    required this.focusPlan,
    required this.viewport,
    required this.time,
    required this.brightness,
    required this.portrait,
    required this.textDirection,
    required this.textScaler,
    required this.roles,
    required this.roleLabels,
    this.reservedOverlayRects = const [],
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
  Color get _connection => const Color(0xFF84D8F2);

  bool get showsRecordedTrace =>
      time >= scene.evidenceStart && time <= scene.evidenceEnd + 1.6;
  bool get showsEndpointRegion => time >= scene.evidenceEnd;
  SpatialObservedDefenderGap? get currentDefenderGap =>
      scene.observedNearbyDefender(data, time);

  List<int> get currentHighlightPlayerIds => roles.playerIds;

  List<int> get observedPlayerIds {
    final sample = data.renderSample(time);
    return <int>[
      for (var index = 0; index < data.players.length; index++)
        if (sample.players[index] != null) data.players[index].id,
    ];
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFF10291F));
    final view = viewport.view;
    final pitch = _pitchRect(view);
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(view, const Radius.circular(10)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(pitch, const Radius.circular(3)),
      Paint()..color = _pitch,
    );
    _drawPitch(canvas, view);
    final sample = data.renderSample(time);
    _drawEvidence(canvas, view);
    _drawRoleGap(canvas, view);
    _drawTails(canvas, view);
    _drawPlayers(canvas, view, sample);
    _drawBall(canvas, view, sample.ball);
    _drawRoleCallouts(canvas, view, sample);
    canvas.restore();
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

  Rect pitchBounds(Size size) => _pitchRect(viewport.view);

  Offset _project(Rect view, RealMatchReplayPoint point) {
    return viewport.project(point);
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
    final points = recordedBallTrace;
    final trace = Path();
    for (var index = 0; index < points.length; index++) {
      final point = _project(pitch, points[index]);
      if (index == 0) {
        trace.moveTo(point.dx, point.dy);
      } else {
        trace.lineTo(point.dx, point.dy);
      }
    }
    if (points.length > 1) {
      canvas.drawPath(
        trace,
        Paint()
          ..color = tone.withValues(alpha: .9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      final end = _project(pitch, points.last);
      final previous = _project(pitch, points[points.length - 2]);
      final vector = end - previous;
      if (vector.distance > .5) {
        final direction = vector / vector.distance;
        final side = Offset(-direction.dy, direction.dx);
        final arrow = Path()
          ..moveTo(end.dx, end.dy)
          ..lineTo(
            end.dx - direction.dx * 9 + side.dx * 4,
            end.dy - direction.dy * 9 + side.dy * 4,
          )
          ..lineTo(
            end.dx - direction.dx * 9 - side.dx * 4,
            end.dy - direction.dy * 9 - side.dy * 4,
          )
          ..close();
        canvas.drawPath(arrow, Paint()..color = tone);
      }
    }
    for (final anchor in scene.evidenceAnchors) {
      if (anchor.time > time) break;
      final point = data.sample(anchor.time).ball;
      canvas.drawCircle(
        _project(pitch, point),
        3.2,
        Paint()..color = tone,
      );
    }
  }

  List<RealMatchReplayPoint> get recordedBallTrace {
    if (!showsRecordedTrace) return const [];
    final traceEnd = math.min(time, scene.evidenceEnd);
    final firstFrame = (scene.evidenceStart * data.fps).ceil();
    final lastFrame = (traceEnd * data.fps).floor();
    return <RealMatchReplayPoint>[
      for (var frame = firstFrame; frame <= lastFrame; frame++)
        data.sample(frame / data.fps).ball,
    ];
  }

  List<List<RealMatchReplayPoint>> observedTailSegments(int id) {
    final index = data.playerIndex(id);
    final segments = <List<RealMatchReplayPoint>>[];
    var segment = <RealMatchReplayPoint>[];
    final firstFrame = (math.max(0.0, time - .9) * data.fps).ceil();
    final lastFrame = (time * data.fps).floor();
    for (var frame = firstFrame; frame <= lastFrame; frame++) {
      final point = data.renderSample(frame / data.fps).players[index];
      if (point == null) {
        if (segment.length > 1) segments.add(List.unmodifiable(segment));
        segment = <RealMatchReplayPoint>[];
      } else {
        segment.add(point);
      }
    }
    if (segment.length > 1) segments.add(List.unmodifiable(segment));
    return List.unmodifiable(segments);
  }

  void _drawTails(Canvas canvas, Rect pitch) {
    for (final id in currentHighlightPlayerIds) {
      final role = roles.values.firstWhere((value) => value.playerId == id);
      for (final points in observedTailSegments(id)) {
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
            ..color = _roleColor(role.kind).withValues(alpha: .78)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  void _drawRoleGap(Canvas canvas, Rect pitch) {
    final actor = roles.role(SpatialObservedRoleKind.ballSidePlayer);
    final defender = roles.role(SpatialObservedRoleKind.nearbyDefender);
    if (actor == null || defender == null) return;
    final actorOffset = _project(pitch, actor.point);
    final defenderOffset = _project(pitch, defender.point);
    canvas.drawLine(
      actorOffset,
      defenderOffset,
      Paint()
        ..color = _turnover.withValues(alpha: .72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    canvas.drawCircle(
      defenderOffset,
      3,
      Paint()..color = _turnover.withValues(alpha: .85),
    );
  }

  void _drawPlayers(
    Canvas canvas,
    Rect pitch,
    RealMatchReplaySample sample,
  ) {
    final roleById = <int, SpatialObservedRole>{
      for (final role in roles.values) role.playerId: role,
    };
    final indices = List<int>.generate(data.players.length, (index) => index)
      ..sort((a, b) {
        int priority(int index) {
          final role = roleById[data.players[index].id];
          return switch (role?.kind) {
            null => 0,
            SpatialObservedRoleKind.nearbyDefender => 1,
            SpatialObservedRoleKind.connectedTeammate => 2,
            SpatialObservedRoleKind.ballSidePlayer => 3,
          };
        }

        return priority(a).compareTo(priority(b));
      });
    for (final index in indices) {
      final point = sample.players[index];
      if (point == null) continue;
      final player = data.players[index];
      final center = _project(pitch, point);
      final role = roleById[player.id];
      final involved = role != null;
      final marker = involved ? 16.2 : 13.2;
      final jersey = _parseReplayColor(
        player.home ? data.scene.homeColor : data.scene.awayColor,
      );
      final numberColor = _parseReplayColor(
        player.home ? data.scene.homeNumberColor : data.scene.awayNumberColor,
      );
      if (involved) {
        canvas.drawCircle(
          center,
          marker + 3.2,
          Paint()
            ..color = _roleColor(role.kind)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4,
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
          ..color = involved ? jersey : jersey.withValues(alpha: .82)
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(
        shirt,
        Paint()
          ..color = Colors.black.withValues(alpha: .55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8,
      );
      final number = '${player.number ?? ''}';
      final painter = TextPainter(
        text: TextSpan(
          text: number,
          style: TextStyle(
            color: numberColor,
            fontSize: marker * 1.02,
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
      6.4,
      Paint()
        ..color = const Color(0xFFFFD66B).withValues(alpha: .9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawCircle(
      center,
      5.1,
      Paint()
        ..color = Colors.black.withValues(alpha: .35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawCircle(center, 3.8, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      3.8,
      Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8,
    );
  }

  void _drawRoleCallouts(
    Canvas canvas,
    Rect view,
    RealMatchReplaySample sample,
  ) {
    for (final layout in _layoutRoleCallouts(view, sample)) {
      final center = _project(view, layout.role.point);
      final chosen = layout.rect;
      final painter = layout.painter;
      final tone = _roleColor(layout.role.kind);
      canvas.drawLine(
        center,
        chosen.center,
        Paint()
          ..color = tone.withValues(alpha: .7)
          ..strokeWidth = 1.2,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(chosen, const Radius.circular(7)),
        Paint()..color = const Color(0xE810291F),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(chosen, const Radius.circular(7)),
        Paint()
          ..color = tone
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      painter.paint(
        canvas,
        Offset(
          chosen.left + 7,
          chosen.top + (chosen.height - painter.height) / 2,
        ),
      );
    }
  }

  List<Rect> get calloutRects => _layoutRoleCallouts(
        viewport.view,
        data.renderSample(time),
      ).map((layout) => layout.rect).toList(growable: false);

  Rect get ballSafetyRect => Rect.fromCircle(
        center: _project(viewport.view, data.renderSample(time).ball),
        radius: 12,
      );

  List<Rect> get keyPlayerSafetyRects => [
        for (final role in roles.values)
          Rect.fromCircle(
            center: _project(viewport.view, role.point),
            radius: 25,
          ),
      ];

  List<
      ({
        SpatialObservedRole role,
        TextPainter painter,
        Rect rect,
      })> _layoutRoleCallouts(
    Rect view,
    RealMatchReplaySample sample,
  ) {
    final occupied = <Rect>[
      ...reservedOverlayRects,
      Rect.fromCircle(center: _project(view, sample.ball), radius: 12),
    ];
    for (var index = 0; index < data.players.length; index++) {
      final point = sample.players[index];
      if (point == null) continue;
      occupied.add(Rect.fromCircle(center: _project(view, point), radius: 25));
    }
    final layouts = <({
      SpatialObservedRole role,
      TextPainter painter,
      Rect rect,
    })>[];

    for (final role in roles.values.take(3)) {
      final label = '${roleLabels[role.kind] ?? ''}\n${role.playerName}';
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.white,
            fontSize: textScaler.scale(10.5),
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        maxLines: 2,
        ellipsis: '…',
        textDirection: textDirection,
      )..layout(maxWidth: math.min(180, view.width * .5) - 14);
      final labelSize = Size(painter.width + 14, painter.height + 9);
      final center = _project(view, role.point);
      final candidates = <Offset>[
        center + Offset(22, -labelSize.height - 14),
        center + Offset(-labelSize.width - 22, -labelSize.height - 14),
        center + const Offset(22, 20),
        center + Offset(-labelSize.width - 22, 20),
        center + Offset(-labelSize.width / 2, -labelSize.height - 28),
        center + Offset(-labelSize.width / 2, 32),
        center + Offset(36, -labelSize.height / 2),
        center + Offset(-labelSize.width - 36, -labelSize.height / 2),
        center + Offset(52, -labelSize.height - 28),
        center + Offset(-labelSize.width - 52, -labelSize.height - 28),
        center + const Offset(52, 34),
        center + Offset(-labelSize.width - 52, 34),
        for (final radius in <double>[84, 120, 156])
          for (final direction in const <Offset>[
            Offset(-.7071, .7071),
            Offset(.7071, .7071),
            Offset(0, 1),
            Offset(-1, 0),
            Offset(1, 0),
            Offset(-.7071, -.7071),
            Offset(.7071, -.7071),
            Offset(0, -1),
          ])
            center +
                direction * radius -
                Offset(labelSize.width / 2, labelSize.height / 2),
      ];
      Rect? chosen;
      for (final origin in candidates) {
        final candidate = origin & labelSize;
        if (!view.deflate(5).contains(candidate.topLeft) ||
            !view.deflate(5).contains(candidate.bottomRight) ||
            occupied.any(candidate.overlaps)) {
          continue;
        }
        chosen = candidate;
        break;
      }
      if (chosen == null) {
        final radius = math.min(260.0, view.shortestSide * .75);
        final steps = (radius / 24).ceil();
        var nearestSquared = double.infinity;
        for (var row = -steps; row <= steps; row++) {
          for (var column = -steps; column <= steps; column++) {
            final offset = Offset(column * 24.0, row * 24.0);
            final squared = offset.distanceSquared;
            if (squared > radius * radius || squared >= nearestSquared) {
              continue;
            }
            final candidate = (center +
                    offset -
                    Offset(labelSize.width / 2, labelSize.height / 2)) &
                labelSize;
            if (!view.deflate(5).contains(candidate.topLeft) ||
                !view.deflate(5).contains(candidate.bottomRight) ||
                occupied.any(candidate.overlaps)) {
              continue;
            }
            chosen = candidate;
            nearestSquared = squared;
          }
        }
      }
      if (chosen == null) continue;
      occupied.add(chosen);
      layouts.add((role: role, painter: painter, rect: chosen));
    }
    return layouts;
  }

  Color _roleColor(SpatialObservedRoleKind kind) => switch (kind) {
        SpatialObservedRoleKind.ballSidePlayer => _focus,
        SpatialObservedRoleKind.connectedTeammate => _connection,
        SpatialObservedRoleKind.nearbyDefender => _turnover,
      };

  @override
  bool shouldRepaint(covariant SpatialLibraryPitchPainter oldDelegate) =>
      oldDelegate.data != data ||
      oldDelegate.scene != scene ||
      oldDelegate.time != time ||
      oldDelegate.brightness != brightness ||
      oldDelegate.portrait != portrait ||
      oldDelegate.textDirection != textDirection ||
      oldDelegate.viewport.camera != viewport.camera ||
      oldDelegate.textScaler != textScaler;
}

class SpatialLibraryMinimapPainter extends CustomPainter {
  final RealMatchReplayData data;
  final double time;
  final RealMatchReplayCamera viewportCamera;
  final bool portrait;

  const SpatialLibraryMinimapPainter({
    required this.data,
    required this.time,
    required this.viewportCamera,
    required this.portrait,
  });

  List<int> get observedPlayerIds {
    final sample = data.renderSample(time);
    return <int>[
      for (var index = 0; index < data.players.length; index++)
        if (sample.players[index] != null) data.players[index].id,
    ];
  }

  Rect fieldBounds(Size size) {
    final available = (Offset.zero & size).deflate(4);
    final ratio = portrait
        ? data.pitchWidth / data.pitchLength
        : data.pitchLength / data.pitchWidth;
    final width = math.min(available.width, available.height * ratio);
    final height = width / ratio;
    return Rect.fromLTWH(
      available.right - width,
      available.center.dy - height / 2,
      width,
      height,
    );
  }

  Offset projectPoint(Size size, RealMatchReplayPoint point) {
    final field = fieldBounds(size);
    final nx = (point.x + data.pitchLength / 2) / data.pitchLength;
    final ny = (point.y + data.pitchWidth / 2) / data.pitchWidth;
    return portrait
        ? Offset(
            field.left + ny * field.width, field.bottom - nx * field.height)
        : Offset(field.left + nx * field.width, field.top + ny * field.height);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final field = fieldBounds(size);
    final outer = field.inflate(4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer, const Radius.circular(7)),
      Paint()..color = const Color(0xE810291F),
    );
    canvas.drawRect(field, Paint()..color = const Color(0xFF2A6245));
    canvas.drawRect(
      field,
      Paint()
        ..color = Colors.white70
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8,
    );
    Offset project(RealMatchReplayPoint point) => projectPoint(size, point);

    final cameraTopLeft = project(
      RealMatchReplayPoint(viewportCamera.minX, viewportCamera.minY),
    );
    final cameraBottomRight = project(
      RealMatchReplayPoint(viewportCamera.maxX, viewportCamera.maxY),
    );
    final cameraRect =
        Rect.fromPoints(cameraTopLeft, cameraBottomRight).intersect(field);
    canvas.drawRect(
      cameraRect,
      Paint()..color = const Color(0x26E0F59A),
    );
    canvas.drawRect(
      cameraRect,
      Paint()
        ..color = const Color(0xFFE0F59A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    final sample = data.renderSample(time);
    for (var index = 0; index < data.players.length; index++) {
      final point = sample.players[index];
      if (point == null) continue;
      final player = data.players[index];
      final jersey = _parseReplayColor(
        player.home ? data.scene.homeColor : data.scene.awayColor,
      );
      canvas.drawCircle(project(point), 2.1, Paint()..color = jersey);
    }
    final ball = project(sample.ball);
    canvas.drawCircle(ball, 2.8, Paint()..color = Colors.black87);
    canvas.drawCircle(ball, 1.8, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant SpatialLibraryMinimapPainter oldDelegate) =>
      oldDelegate.data != data ||
      oldDelegate.time != time ||
      oldDelegate.viewportCamera != viewportCamera ||
      oldDelegate.portrait != portrait;
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
    SpatialLearningTheme.combination => l10n.spatialSituationCombinationShort(
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
  final roles = scene.observedRoles(data, time);
  final ballSide = roles.role(SpatialObservedRoleKind.ballSidePlayer);
  if (time < scene.evidenceStart) {
    return _objective(l10n, scene.theme);
  }
  if (time < scene.evidenceEnd) {
    final reached = scene.evidenceAnchors
        .where((anchor) => anchor.time <= time)
        .toList(growable: false);
    if (reached.length > 1) {
      return l10n.spatialReachedConnectionCue(
        reached[reached.length - 2].playerName,
        reached.last.playerName,
      );
    }
    final start = data.sample(scene.evidenceStart).ball;
    final ball = data.renderSample(time).ball;
    final dx = (ball.x - start.x) * scene.attackDirection;
    final dy = (ball.y - start.y).abs();
    final distance = math.sqrt(
      math.pow(ball.x - start.x, 2) + math.pow(ball.y - start.y, 2),
    );
    final name = scene.evidenceAnchors.first.playerName;
    if (scene.theme == SpatialLearningTheme.pressureSupport) {
      final defender = roles.role(SpatialObservedRoleKind.nearbyDefender);
      if (ballSide != null && defender != null) {
        return l10n.spatialMovementPressureCue(
          defender.playerName,
          ballSide.playerName,
          defender.distanceMeters!.toStringAsFixed(1),
        );
      }
    }
    return switch (scene.theme) {
      SpatialLearningTheme.lateralSwitch =>
        l10n.spatialMovementLateralCue(name, dy.toStringAsFixed(1)),
      SpatialLearningTheme.forwardConnection => dx >= 0
          ? l10n.spatialMovementForwardCue(name, dx.toStringAsFixed(1))
          : l10n.spatialMovementBackwardCue(
              name,
              dx.abs().toStringAsFixed(1),
            ),
      SpatialLearningTheme.pressureSupport =>
        l10n.spatialMovementDistanceCue(name, distance.toStringAsFixed(1)),
      SpatialLearningTheme.carryThenConnect =>
        l10n.spatialMovementCarryCue(name, distance.toStringAsFixed(1)),
      SpatialLearningTheme.wideToInside => l10n.spatialMovementInsideCue(
          name,
          math.max(0, start.y.abs() - ball.y.abs()).toStringAsFixed(1),
        ),
      SpatialLearningTheme.combination =>
        l10n.spatialMovementCombinationCue(name, distance.toStringAsFixed(1)),
      SpatialLearningTheme.turnover =>
        l10n.spatialMovementTurnoverCue(name, distance.toStringAsFixed(1)),
      SpatialLearningTheme.recovery =>
        l10n.spatialMovementRecoveryCue(name, distance.toStringAsFixed(1)),
    };
  }
  if (time <= scene.evidenceEnd + 1.6) {
    return l10n.spatialAfterCue(_situation(l10n, scene));
  }
  return l10n.spatialSubsequentPlayCue;
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
