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
  guidedReplay,
  sourceInfo,
  officialVideo,
}

enum _SpatialCuePhase { context, connection, aftermath, continuation, review }

class _SpatialPhaseCue {
  final _SpatialCuePhase phase;
  final String text;
  final int? targetPlayerId;

  const _SpatialPhaseCue({
    required this.phase,
    required this.text,
    required this.targetPlayerId,
  });
}

class ScanPassSpatialLibraryScreen extends StatefulWidget {
  final OptionRepository? optionRepository;
  final MatchMomentSourceLauncher? sourceLauncher;
  final ScanPassSpatialCatalogLoader? catalogLoader;
  final ScanPassSpatialSceneLoader? sceneLoader;
  final AuthoredTouchSampleLoader? authoredSampleLoader;

  const ScanPassSpatialLibraryScreen({
    super.key,
    this.optionRepository,
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
  String? _cuePlacementKey;
  Rect? _cuePlacementRect;
  String? _directionPlacementKey;
  Rect? _directionPlacementRect;
  String? _nameLabelPlacementKey;
  Map<int, int> _nameLabelPlacements = const <int, int>{};

  AppLocalizations get _l10n => AppLocalizations.of(context)!;
  SpatialLibraryScene? get _scene => _catalog?.scenes[_sceneIndex];
  double get _time => (_data?.duration ?? 0) * _controller.value;
  bool get _finished =>
      _data != null && _time >= _data!.duration - 1 / _data!.fps;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PaintingBinding.instance.systemFonts.addListener(_handleSystemFontsChanged);
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
    PaintingBinding.instance.systemFonts
        .removeListener(_handleSystemFontsChanged);
    _loadGeneration++;
    _playGeneration++;
    _controller
      ..removeListener(_tick)
      ..dispose();
    super.dispose();
  }

  void _handleSystemFontsChanged() {
    if (!mounted) return;
    setState(() {
      _cuePlacementKey = null;
      _cuePlacementRect = null;
      _directionPlacementKey = null;
      _directionPlacementRect = null;
      _nameLabelPlacementKey = null;
      _nameLabelPlacements = const <int, int>{};
    });
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
    _controller.value = 0;
    final generation = ++_playGeneration;
    setState(() {
      _playing = true;
      _focusedReplay = true;
    });
    unawaited(() async {
      try {
        await _controller
            .animateTo(
              scene.evidenceStart / data.duration,
              duration: Duration(
                milliseconds: (scene.evidenceStart * 1000).round(),
              ),
              curve: Curves.linear,
            )
            .orCancel;
        if (!mounted || generation != _playGeneration) return;
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
      setState(() {
        _playing = false;
        _focusedReplay = false;
      });
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
      case _SpatialMenuAction.guidedReplay:
        _playFocusReplay();
        break;
      case _SpatialMenuAction.sourceInfo:
        await _openInfo();
        break;
      case _SpatialMenuAction.officialVideo:
        final optionRepository = widget.optionRepository;
        if (optionRepository == null) return;
        _stopPlayback();
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (context) => ScanPassVideoLearningScreen(
              optionRepository: optionRepository,
              sourceLauncher: widget.sourceLauncher,
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
      final textScaler = MediaQuery.textScalerOf(context);
      final cue = _phaseCue(_l10n, scene, data, _time);
      final cardWidth = math.min(
        size.width - 16,
        portrait
            ? (size.width * .78).clamp(210.0, 360.0)
            : (size.width * .38).clamp(240.0, 300.0),
      );
      final cardHeight = _teachingCardHeight(
        cue.text,
        cardWidth,
        compact: compact,
        textScaler: textScaler,
      );
      final actionRect = Rect.fromLTRB(2, 2, size.width - 2, size.height - 2);
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
      final pitchOverlayBounds = Rect.fromPoints(
        viewport.project(RealMatchReplayPoint(
          -data.pitchLength / 2,
          -data.pitchWidth / 2,
        )),
        viewport.project(RealMatchReplayPoint(
          data.pitchLength / 2,
          data.pitchWidth / 2,
        )),
      ).intersect(viewport.view);
      final roles = scene.observedRoles(data, _time);
      final sample = data.renderSample(_time);
      final cueActorPoint = cue.targetPlayerId == null
          ? null
          : sample.players[data.playerIndex(cue.targetPlayerId!)];
      final cueTarget = viewport.project(cueActorPoint ?? sample.ball);
      final sourceFrame = (_time.clamp(0.0, data.duration) * data.fps)
          .floor()
          .clamp(0, data.frames.length - 1);
      final currentOwner = data.sourcePossessionOwners.isEmpty
          ? null
          : data.sourcePossessionOwners[sourceFrame];
      final protectedPlayerIds = _requiredCueActorIds(
        scene: scene,
        data: data,
        time: _time,
        cue: cue,
        roles: roles,
        currentOwner: currentOwner,
      );
      final occupied = <Rect>[
        Rect.fromCircle(center: viewport.project(sample.ball), radius: 14),
        for (final playerId in protectedPlayerIds)
          if (sample.players[data.playerIndex(playerId)] case final point?)
            Rect.fromCircle(center: viewport.project(point), radius: 28),
      ];
      if (_time >= scene.evidenceStart) {
        final traceEnd = math.min(_time, scene.evidenceEnd);
        final tracePoints = <Offset>[
          for (var frame = (scene.evidenceStart * data.fps).ceil();
              frame <= (traceEnd * data.fps).floor();
              frame++)
            viewport.project(data.sample(frame / data.fps).ball),
        ];
        if (tracePoints.isNotEmpty) {
          occupied.add(
            Rect.fromLTRB(
              tracePoints.map((point) => point.dx).reduce(math.min),
              tracePoints.map((point) => point.dy).reduce(math.min),
              tracePoints.map((point) => point.dx).reduce(math.max),
              tracePoints.map((point) => point.dy).reduce(math.max),
            ).inflate(10),
          );
        }
      }
      final attackingTeamName = scene.attackingHome ? scene.home : scene.away;
      final directionLabel = _l10n.spatialDirectionCompact(attackingTeamName);
      final directionTextPainter = TextPainter(
        text: TextSpan(
          text: directionLabel,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        maxLines: 1,
        locale: Localizations.localeOf(context),
        textScaler: textScaler,
        textDirection: Directionality.of(context),
      )..layout(maxWidth: math.min(130, size.width * .36));
      final directionSize = Size(
        (directionTextPainter.width + 36).clamp(
          68.0,
          math.min(168.0, size.width * .48),
        ),
        compact ? 28 : 31,
      );
      final pitchCanFitOverlays = pitchOverlayBounds.width >= cardWidth + 14 &&
          pitchOverlayBounds.height >= cardHeight + 14 &&
          (pitchOverlayBounds.height >=
                  cardHeight + directionSize.height + 35 ||
              pitchOverlayBounds.width >= cardWidth + directionSize.width + 35);
      // Prefer the painted pitch itself. On a very short landscape surface the
      // uniformly scaled pitch can be narrower than the minimum readable cue;
      // in that case the surrounding pitch viewport is the only honest place
      // to keep the source actors and full, untruncated cue visible together.
      final initialOverlayBounds =
          pitchCanFitOverlays ? pitchOverlayBounds : viewport.view;
      final placementKey = '${scene.id}:${cue.phase.name}:'
          '${size.width.toStringAsFixed(1)}x${size.height.toStringAsFixed(1)}:'
          '${cardWidth.toStringAsFixed(1)}x${cardHeight.toStringAsFixed(1)}:'
          '${cue.text.hashCode}';
      final placementOccupied = placementKey == _cuePlacementKey
          ? occupied
          : <Rect>[
              ...occupied,
              ..._phaseOccupiedRects(
                data: data,
                scene: scene,
                focusPlan: focusPlan,
                phase: cue.phase,
                size: size,
                actionRect: actionRect,
                rotated: rotated,
              ),
            ];
      var cardRect = SpatialCuePlacement.place(
        bounds: initialOverlayBounds,
        fallbackBounds: viewport.view,
        size: Size(cardWidth, cardHeight),
        target: cueTarget,
        occupied: placementOccupied,
        preferred: placementKey == _cuePlacementKey ? _cuePlacementRect : null,
      );
      if (occupied.any(cardRect.overlaps)) {
        cardRect = SpatialCuePlacement.place(
          bounds: initialOverlayBounds,
          fallbackBounds: viewport.view,
          size: Size(cardWidth, cardHeight),
          target: cueTarget,
          occupied: occupied,
        );
      }
      _cuePlacementKey = placementKey;
      _cuePlacementRect = cardRect;
      occupied.add(cardRect.inflate(4));
      final directionPlacementKey = '${scene.id}:$rotated:'
          '${size.width.toStringAsFixed(1)}x${size.height.toStringAsFixed(1)}:'
          '${directionSize.width.toStringAsFixed(1)}:$pitchCanFitOverlays';
      final directionRect = SpatialCuePlacement.placeBadge(
        bounds: initialOverlayBounds,
        size: directionSize,
        occupied: occupied,
        preferred: directionPlacementKey == _directionPlacementKey
            ? _directionPlacementRect
            : null,
      );
      _directionPlacementKey = directionPlacementKey;
      _directionPlacementRect = directionRect;
      final nameLabelPlayerIds = <int>{
        scene.focusPlayerId,
        if (currentOwner != null) currentOwner,
        if (cueActorPoint != null) cue.targetPlayerId!,
        for (final role in roles.values)
          if (role.kind != SpatialObservedRoleKind.nearbyDefender)
            role.playerId,
        if (_time < scene.evidenceEnd)
          for (final player in data.players)
            if (cue.text.contains(_cuePlayerLabel(data, player.id))) player.id,
      };
      final locale = Localizations.localeOf(context);
      final nameLabelPlacementKey = '${scene.id}:$rotated:'
          '${size.width.toStringAsFixed(1)}x${size.height.toStringAsFixed(1)}:'
          '${textScaler.scale(10).toStringAsFixed(1)}:'
          '${locale.toLanguageTag()}';
      final pitchPainter = SpatialLibraryPitchPainter(
        data: data,
        scene: scene,
        focusPlan: focusPlan,
        viewport: viewport,
        time: _time,
        brightness: Theme.of(context).brightness,
        portrait: rotated,
        textDirection: Directionality.of(context),
        textScaler: textScaler,
        locale: locale,
        roles: roles,
        cuePlayerId: cueActorPoint == null ? null : cue.targetPlayerId,
        requiredPlayerIds: protectedPlayerIds,
        nameLabelPlayerIds: nameLabelPlayerIds,
        cueRect: cardRect,
        cueTarget: cueTarget,
        reservedOverlayRects: [cardRect, directionRect],
        preferredNameLabelPlacements:
            nameLabelPlacementKey == _nameLabelPlacementKey
                ? _nameLabelPlacements
                : const <int, int>{},
      );
      final nextNameLabelPlacements =
          nameLabelPlacementKey == _nameLabelPlacementKey
              ? Map<int, int>.of(_nameLabelPlacements)
              : <int, int>{};
      for (final label in pitchPainter.playerNameLabels) {
        nextNameLabelPlacements[label.playerId] = label.placementIndex;
      }
      _nameLabelPlacementKey = nameLabelPlacementKey;
      _nameLabelPlacements = nextNameLabelPlacements;
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
                  painter: pitchPainter,
                ),
              ),
            ),
          ),
          Positioned.fromRect(
            rect: cardRect,
            child: _buildTeachingCard(cue.text, compact),
          ),
          Positioned.fromRect(
            rect: directionRect,
            child: _buildDirectionBadge(
              scene,
              rotated: rotated,
              compact: compact,
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

  List<Rect> _phaseOccupiedRects({
    required RealMatchReplayData data,
    required SpatialLibraryScene scene,
    required SpatialFocusPlan focusPlan,
    required _SpatialCuePhase phase,
    required Size size,
    required Rect actionRect,
    required bool rotated,
  }) {
    final (start, end) = switch (phase) {
      _SpatialCuePhase.context => (0.0, scene.evidenceStart),
      _SpatialCuePhase.connection => (scene.evidenceStart, scene.evidenceEnd),
      _SpatialCuePhase.aftermath => (
          scene.evidenceEnd,
          math.min(data.duration, scene.evidenceEnd + 1.6),
        ),
      _SpatialCuePhase.continuation => (
          math.min(data.duration, scene.evidenceEnd + 1.6),
          math.max(0.0, data.duration - 1 / data.fps),
        ),
      _SpatialCuePhase.review => (
          math.max(0.0, data.duration - 1 / data.fps),
          data.duration,
        ),
    };
    final firstFrame = (start * data.fps).floor();
    final lastFrame = (end * data.fps).ceil().clamp(0, data.frames.length - 1);
    final frameStep = math.max(1, (data.fps / 5).round());
    final values = <Rect>[];
    for (var frame = firstFrame; frame <= lastFrame; frame += frameStep) {
      final time = frame / data.fps;
      final sample = data.renderSample(time);
      final viewport = SpatialPitchViewport.fit(
        focusPlan.cameraAt(time),
        size,
        portrait: rotated,
        viewRect: actionRect,
        fieldLength: data.pitchLength,
        fieldWidth: data.pitchWidth,
      );
      values.add(
        Rect.fromCircle(center: viewport.project(sample.ball), radius: 14),
      );
      final ids = <int>{...focusPlan.relevantPlayerIdsAt(time)};
      if (data.sourcePossessionOwners.isNotEmpty) {
        final owner = data.sourcePossessionOwners[frame];
        if (owner != null) ids.add(owner);
      }
      for (final id in ids) {
        final point = sample.players[data.playerIndex(id)];
        if (point != null) {
          values.add(
            Rect.fromCircle(center: viewport.project(point), radius: 28),
          );
        }
      }
    }
    return values;
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

  Widget _buildDirectionBadge(
    SpatialLibraryScene scene, {
    required bool rotated,
    required bool compact,
  }) {
    final attackingTeamName = scene.attackingHome ? scene.home : scene.away;
    final positive = scene.attackDirection > 0;
    final icon = rotated
        ? (positive ? Icons.arrow_upward : Icons.arrow_downward)
        : (positive ? Icons.arrow_forward : Icons.arrow_back);
    final direction = rotated
        ? (positive ? _l10n.spatialDirectionUp : _l10n.spatialDirectionDown)
        : (positive ? _l10n.spatialDirectionRight : _l10n.spatialDirectionLeft);
    return Semantics(
      label: _l10n.spatialAttackDirection(attackingTeamName, direction),
      child: IgnorePointer(
        child: DecoratedBox(
          key: const ValueKey<String>('spatial-attack-direction'),
          decoration: BoxDecoration(
            color: const Color(0xC710291F),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white30),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: compact ? 14 : 16, color: Colors.white),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  _l10n.spatialDirectionCompact(attackingTeamName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  double _teachingCardHeight(
    String cue,
    double width, {
    required bool compact,
    required TextScaler textScaler,
  }) {
    final horizontal = compact ? 8.0 : 10.0;
    final vertical = compact ? 4.0 : 7.0;
    double heightFor(String text, TextStyle? style, int maxLines) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        maxLines: maxLines,
        ellipsis: '…',
        locale: Localizations.localeOf(context),
        textDirection: Directionality.of(context),
        textScaler: textScaler,
      )..layout(maxWidth: math.max(1, width - horizontal * 2));
      return painter.height;
    }

    final cueStyle = _teachingCueStyle();
    // Keep the pitch geometry steady when the brief teaching cue changes phase.
    return vertical * 2 + heightFor(cue, cueStyle, 6);
  }

  Widget _buildTeachingCard(
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
            vertical: compact ? 4 : 7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cue,
                key: const ValueKey<String>('spatial-cue-line'),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: _teachingCueStyle(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle? _teachingCueStyle() =>
      Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white,
            height: 1.15,
            fontWeight: FontWeight.w600,
          );

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
            value: _SpatialMenuAction.guidedReplay,
            child: Text(_l10n.spatialFocusReplay),
          ),
          PopupMenuItem(
            key: const ValueKey<String>('spatial-source-info'),
            value: _SpatialMenuAction.sourceInfo,
            child: Text(_l10n.spatialSourceInfo),
          ),
          if (widget.optionRepository != null)
            PopupMenuItem(
              key: const ValueKey<String>('spatial-official-video'),
              value: _SpatialMenuAction.officialVideo,
              child: Text(_l10n.spatialOfficialVideoViewer),
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
    final themes = widget.catalog.themes.toList(growable: false)
      ..sort((a, b) => a.index.compareTo(b.index));
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
            for (final theme in themes)
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
                        l10n.spatialSceneIdentityRow(
                          scene.home,
                          scene.away,
                          _catalogClock(scene.startClock),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Container(
                        key: ValueKey<String>(
                          'spatial-duration-${scene.id}',
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          l10n.spatialDurationBadge(
                            scene.duration.toStringAsFixed(1),
                          ),
                          key: ValueKey<String>(
                            'spatial-duration-text-${scene.id}',
                          ),
                          maxLines: 1,
                          softWrap: false,
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
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
          const SizedBox(height: 8),
          Text(
            l10n.spatialDurationRange(
              catalog.scenes
                  .map((value) => value.duration)
                  .reduce(math.min)
                  .toStringAsFixed(1),
              catalog.scenes
                  .map((value) => value.duration)
                  .reduce(math.max)
                  .toStringAsFixed(1),
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

class SpatialCuePlacement {
  const SpatialCuePlacement._();

  static Rect placeBadge({
    required Rect bounds,
    required Size size,
    required List<Rect> occupied,
    Rect? preferred,
  }) {
    final safe = bounds.deflate(7);
    final width = math.min(size.width, safe.width);
    final height = math.min(size.height, safe.height);
    bool fits(Rect rect) =>
        (rect.width - width).abs() < .1 &&
        (rect.height - height).abs() < .1 &&
        rect.left >= safe.left &&
        rect.top >= safe.top &&
        rect.right <= safe.right &&
        rect.bottom <= safe.bottom;
    bool clear(Rect rect) => !occupied.any(rect.overlaps);
    if (preferred != null && fits(preferred) && clear(preferred)) {
      return preferred;
    }
    final candidates = <Rect>[
      Rect.fromLTWH(safe.left, safe.top, width, height),
      Rect.fromLTWH(safe.right - width, safe.top, width, height),
      Rect.fromLTWH(safe.left, safe.bottom - height, width, height),
      Rect.fromLTWH(
        safe.right - width,
        safe.bottom - height,
        width,
        height,
      ),
      for (var row = 0; row <= 6; row++)
        for (final left in <double>[safe.left, safe.right - width])
          Rect.fromLTWH(
            left,
            safe.top + (safe.height - height) * row / 6,
            width,
            height,
          ),
    ];
    for (final candidate in candidates) {
      if (clear(candidate)) return candidate;
    }
    candidates.sort((a, b) => occupied
        .fold<double>(
          0,
          (value, rect) => value + _intersectionArea(a.intersect(rect)),
        )
        .compareTo(occupied.fold<double>(
          0,
          (value, rect) => value + _intersectionArea(b.intersect(rect)),
        )));
    return candidates.first;
  }

  static Rect place({
    required Rect bounds,
    Rect? fallbackBounds,
    required Size size,
    required Offset target,
    required List<Rect> occupied,
    Rect? preferred,
  }) {
    // The card has its own rounded border and may use the field edge. Keeping
    // an extra inset here wastes the only actor-clear strip on short
    // landscape pitches and forces an avoidable overlap.
    final fallbackSafe = (fallbackBounds ?? bounds).deflate(.5);
    final width = math.min(size.width, fallbackSafe.width);
    final height = math.min(size.height, fallbackSafe.height);

    bool fits(Rect candidate, Rect safe) {
      return (candidate.width - width).abs() < .1 &&
          (candidate.height - height).abs() < .1 &&
          candidate.left >= safe.left &&
          candidate.top >= safe.top &&
          candidate.right <= safe.right &&
          candidate.bottom <= safe.bottom;
    }

    if (preferred != null &&
        fits(preferred, fallbackSafe) &&
        !occupied.any(preferred.overlaps)) {
      return preferred;
    }

    List<Rect> candidatesIn(Rect safe) {
      if (safe.width + .1 < width || safe.height + .1 < height) return const [];
      final origins = <Offset>[
        target + Offset(24, -height - 24),
        target + Offset(-width - 24, -height - 24),
        target + const Offset(24, 24),
        target + Offset(-width - 24, 24),
        Offset(safe.left, safe.top),
        Offset(safe.right - width, safe.top),
        Offset(safe.left, safe.bottom - height),
        Offset(safe.right - width, safe.bottom - height),
        Offset(safe.center.dx - width / 2, safe.top),
        Offset(safe.center.dx - width / 2, safe.bottom - height),
        for (var row = 0; row <= 16; row++)
          for (var column = 0; column <= 8; column++)
            Offset(
              safe.left + (safe.width - width) * column / 8,
              safe.top + (safe.height - height) * row / 16,
            ),
      ];
      Rect clamp(Offset origin) => Rect.fromLTWH(
            origin.dx.clamp(safe.left, safe.right - width),
            origin.dy.clamp(safe.top, safe.bottom - height),
            width,
            height,
          );
      final values = <Rect>[];
      for (final origin in origins) {
        final value = clamp(origin);
        if (!values.contains(value)) values.add(value);
      }
      return values;
    }

    final primary = candidatesIn(bounds.deflate(.5));
    final fallback = candidatesIn(fallbackSafe);
    final candidateGroups = <List<Rect>>[
      primary,
      if (fallbackBounds != null && fallbackSafe != bounds.deflate(.5))
        fallback,
    ];
    for (final candidates in candidateGroups) {
      for (final candidate in candidates) {
        if (isClear(rect: candidate, target: target, occupied: occupied)) {
          return candidate;
        }
      }
      final labelClear = candidates
          .where((candidate) => !occupied.any(candidate.overlaps))
          .toList(growable: false);
      if (labelClear.isNotEmpty) {
        return _minByDistance(
          labelClear,
          preferred?.center ?? target,
        );
      }
    }
    final leastOverlap = fallback.isNotEmpty ? fallback : primary;
    leastOverlap.sort((a, b) {
      double score(Rect candidate) =>
          occupied.fold<double>(
            0,
            (value, rect) =>
                value + _intersectionArea(candidate.intersect(rect)),
          ) +
          (candidate.center - target).distance * .01;
      return score(a).compareTo(score(b));
    });
    return leastOverlap.first;
  }

  static Rect _minByDistance(List<Rect> values, Offset target) {
    final sorted = List<Rect>.of(values)
      ..sort((a, b) => (a.center - target)
          .distanceSquared
          .compareTo((b.center - target).distanceSquared));
    return sorted.first;
  }

  static bool isClear({
    required Rect rect,
    required Offset target,
    required List<Rect> occupied,
  }) {
    if (occupied.any(rect.overlaps)) return false;
    return isConnectorClear(
      rect: rect,
      target: target,
      occupied: occupied,
    );
  }

  static bool isConnectorClear({
    required Rect rect,
    required Offset target,
    required List<Rect> occupied,
  }) {
    final start = connectorStart(rect, target);
    return occupied
        .where((value) => !value.contains(target))
        .every((value) => !_segmentIntersectsRect(start, target, value));
  }

  static Offset connectorStart(Rect rect, Offset target) => Offset(
        target.dx.clamp(rect.left, rect.right),
        target.dy.clamp(rect.top, rect.bottom),
      );

  static double _intersectionArea(Rect rect) =>
      rect.isEmpty ? 0 : rect.width * rect.height;

  static bool _segmentIntersectsRect(Offset a, Offset b, Rect rect) {
    final steps = math.max(1, ((b - a).distance / 4).ceil());
    for (var index = 0; index <= steps; index++) {
      if (rect.contains(Offset.lerp(a, b, index / steps)!)) return true;
    }
    return false;
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

class SpatialPlayerNameLabelGeometry {
  final int playerId;
  final String sourceName;
  final String displayName;
  final Rect rect;
  final Rect badgeRect;
  final int placementIndex;
  final Offset? connectorStart;
  final Offset? connectorEnd;

  const SpatialPlayerNameLabelGeometry({
    required this.playerId,
    required this.sourceName,
    required this.displayName,
    required this.rect,
    required this.badgeRect,
    required this.placementIndex,
    this.connectorStart,
    this.connectorEnd,
  });

  bool get hasConnector => connectorStart != null && connectorEnd != null;
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
  final Locale locale;
  final SpatialObservedRoles roles;
  final int? cuePlayerId;
  final Set<int> requiredPlayerIds;
  final Set<int> nameLabelPlayerIds;
  final Rect cueRect;
  final Offset cueTarget;
  final List<Rect> reservedOverlayRects;
  final Map<int, int> preferredNameLabelPlacements;
  late final List<
      ({
        SpatialPlayerNameLabelGeometry geometry,
        TextPainter painter,
        Color tone,
      })> _playerNameLayouts = _layoutPlayerNameLabels(data.renderSample(time));

  SpatialLibraryPitchPainter({
    required this.data,
    required this.scene,
    required this.focusPlan,
    required this.viewport,
    required this.time,
    required this.brightness,
    required this.portrait,
    required this.textDirection,
    required this.textScaler,
    this.locale = const Locale('en'),
    required this.roles,
    this.cuePlayerId,
    this.requiredPlayerIds = const <int>{},
    this.nameLabelPlayerIds = const <int>{},
    this.cueRect = Rect.zero,
    this.cueTarget = Offset.zero,
    this.reservedOverlayRects = const [],
    this.preferredNameLabelPlacements = const <int, int>{},
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

  int? get currentSourceOwnerId {
    if (data.sourcePossessionOwners.isEmpty) return null;
    final frame = (time.clamp(0.0, data.duration) * data.fps)
        .floor()
        .clamp(0, data.sourcePossessionOwners.length - 1);
    return data.sourcePossessionOwners[frame];
  }

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
    _drawPlayerNameConnectors(canvas);
    _drawCueConnector(canvas);
    _drawEvidence(canvas, view);
    _drawRoleGap(canvas, view);
    _drawTails(canvas, view);
    _drawPlayers(canvas, view, sample);
    _drawPlayerNameLabels(canvas);
    _drawBall(canvas, view, sample.ball);
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

  void _drawCueConnector(Canvas canvas) {
    final connectorObstacles = <Rect>[
      ballSafetyRect,
      ...keyPlayerSafetyRects,
    ].where((rect) => !rect.contains(cueTarget)).toList(growable: false);
    if (!SpatialCuePlacement.isConnectorClear(
      rect: cueRect,
      target: cueTarget,
      occupied: connectorObstacles,
    )) {
      return;
    }
    final start = SpatialCuePlacement.connectorStart(cueRect, cueTarget);
    canvas.drawLine(
      start,
      cueTarget,
      Paint()
        ..color = const Color(0xB3E0F59A)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      cueTarget,
      7.5,
      Paint()
        ..color = const Color(0x99E0F59A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

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
      final cueActor = player.id == cuePlayerId;
      final involved = role != null || cueActor;
      final marker = involved ? 16.2 : 13.2;
      final badgeCenter = center - Offset(0, marker * .38);
      final jersey = _parseReplayColor(
        player.home ? data.scene.homeColor : data.scene.awayColor,
      );
      final numberColor = _parseReplayColor(
        player.home ? data.scene.homeNumberColor : data.scene.awayNumberColor,
      );
      canvas.drawLine(
        badgeCenter,
        center,
        Paint()
          ..color = Colors.black.withValues(alpha: .72)
          ..strokeWidth = 2,
      );
      canvas.drawCircle(
        center,
        3.2,
        Paint()..color = const Color(0xFFF4F7E8),
      );
      canvas.drawCircle(
        center,
        3.2,
        Paint()
          ..color = Colors.black87
          ..style = PaintingStyle.stroke
          ..strokeWidth = .9,
      );
      if (involved) {
        canvas.drawCircle(
          badgeCenter,
          marker + 3.2,
          Paint()
            ..color = cueActor ? _focus : _roleColor(role!.kind)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4,
        );
      }
      canvas.drawCircle(
        badgeCenter,
        marker,
        Paint()..color = involved ? jersey : jersey.withValues(alpha: .84),
      );
      canvas.drawCircle(
        badgeCenter,
        marker,
        Paint()
          ..color = Colors.black.withValues(alpha: .55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
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
        canvas,
        badgeCenter - Offset(painter.width / 2, painter.height / 2),
      );
    }
  }

  Map<int, ({Offset center, double radius, Rect rect})> _playerBadges(
    RealMatchReplaySample sample,
  ) {
    final roleById = <int, SpatialObservedRole>{
      for (final role in roles.values) role.playerId: role,
    };
    return <int, ({Offset center, double radius, Rect rect})>{
      for (var index = 0; index < data.players.length; index++)
        if (sample.players[index] case final point?)
          data.players[index].id: () {
            final playerId = data.players[index].id;
            final involved =
                roleById.containsKey(playerId) || playerId == cuePlayerId;
            final radius = involved ? 16.2 : 13.2;
            final center =
                _project(viewport.view, point) - Offset(0, radius * .38);
            final outerRadius = involved ? radius + 3.2 : radius + 1;
            return (
              center: center,
              radius: radius,
              rect: Rect.fromCircle(center: center, radius: outerRadius),
            );
          }(),
    };
  }

  List<Rect> get playerBadgeSafetyRects =>
      _playerBadges(data.renderSample(time))
          .values
          .map((badge) => badge.rect)
          .toList(growable: false);

  List<SpatialPlayerNameLabelGeometry> get playerNameLabels =>
      _playerNameLayouts
          .map((layout) => layout.geometry)
          .toList(growable: false);

  List<
      ({
        SpatialPlayerNameLabelGeometry geometry,
        TextPainter painter,
        Color tone,
      })> _layoutPlayerNameLabels(RealMatchReplaySample sample) {
    final badges = _playerBadges(sample);
    final occupied = <Rect>[
      ...reservedOverlayRects.map((rect) => rect.inflate(3)),
      ballSafetyRect,
      ...badges.values.map((badge) => badge.rect.inflate(2)),
    ];
    final roleById = <int, SpatialObservedRole>{
      for (final role in roles.values) role.playerId: role,
    };
    final prioritizedIds = <int>[];
    void addPriority(int? playerId) {
      if (playerId != null &&
          nameLabelPlayerIds.contains(playerId) &&
          !prioritizedIds.contains(playerId)) {
        prioritizedIds.add(playerId);
      }
    }

    addPriority(currentSourceOwnerId);
    addPriority(scene.focusPlayerId);
    addPriority(cuePlayerId);
    for (final role in roles.values) {
      if (role.kind == SpatialObservedRoleKind.connectedTeammate) {
        addPriority(role.playerId);
      }
    }
    for (final role in roles.values) {
      if (role.kind == SpatialObservedRoleKind.ballSidePlayer) {
        addPriority(role.playerId);
      }
    }
    for (final playerId in nameLabelPlayerIds) {
      addPriority(playerId);
    }

    final layouts = <({
      SpatialPlayerNameLabelGeometry geometry,
      TextPainter painter,
      Color tone,
    })>[];
    final safeView = viewport.view.deflate(4);
    final cueConnectorStart = cueRect == Rect.zero
        ? null
        : SpatialCuePlacement.connectorStart(cueRect, cueTarget);
    for (final playerId in prioritizedIds) {
      final badge = badges[playerId];
      if (badge == null || !safeView.contains(badge.center)) continue;
      final player = data.player(playerId);
      final sourceName = player.name?.trim() ?? '';
      if (sourceName.isEmpty) continue;
      final displayName = _spatialShortPlayerName(sourceName);
      final painter = TextPainter(
        text: TextSpan(
          text: displayName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        maxLines: 1,
        ellipsis: '…',
        locale: locale,
        textScaler: textScaler,
        textDirection: textDirection,
      )..layout(
          maxWidth: math.max(
            48,
            math.min(176, viewport.view.width * .55) - 12,
          ),
        );
      final labelSize = Size(painter.width + 12, painter.height + 8);
      final center = badge.center;
      final rect = badge.rect;
      final adjacentCandidates = <Rect>[
        Rect.fromLTWH(
          rect.right + 6,
          center.dy - labelSize.height / 2,
          labelSize.width,
          labelSize.height,
        ),
        Rect.fromLTWH(
          rect.left - labelSize.width - 6,
          center.dy - labelSize.height / 2,
          labelSize.width,
          labelSize.height,
        ),
        Rect.fromLTWH(
          rect.right + 6,
          rect.bottom + 5,
          labelSize.width,
          labelSize.height,
        ),
        Rect.fromLTWH(
          rect.left - labelSize.width - 6,
          rect.bottom + 5,
          labelSize.width,
          labelSize.height,
        ),
        Rect.fromLTWH(
          rect.right + 6,
          rect.top - labelSize.height - 5,
          labelSize.width,
          labelSize.height,
        ),
        Rect.fromLTWH(
          rect.left - labelSize.width - 6,
          rect.top - labelSize.height - 5,
          labelSize.width,
          labelSize.height,
        ),
        Rect.fromLTWH(
          center.dx - labelSize.width / 2,
          rect.bottom + 7,
          labelSize.width,
          labelSize.height,
        ),
        Rect.fromLTWH(
          center.dx - labelSize.width / 2,
          rect.top - labelSize.height - 7,
          labelSize.width,
          labelSize.height,
        ),
      ];
      final allowsDistantFallback =
          playerId == currentSourceOwnerId || playerId == scene.focusPlayerId;
      final displacedCandidates = <Rect>[
        for (var row = -8; row <= 8; row++)
          for (var column = -8; column <= 8; column++)
            if (row != 0 || column != 0)
              Rect.fromCenter(
                center: center + Offset(column * 18, row * 18),
                width: labelSize.width,
                height: labelSize.height,
              ),
      ]..sort((left, right) {
          final distanceOrder = (left.center - center)
              .distanceSquared
              .compareTo((right.center - center).distanceSquared);
          if (distanceOrder != 0) return distanceOrder;
          final verticalOrder = left.center.dy.compareTo(right.center.dy);
          return verticalOrder != 0
              ? verticalOrder
              : left.center.dx.compareTo(right.center.dx);
        });
      // Dense short-landscape scenes can consume every player-adjacent slot.
      // Keep the usual attached positions first, then let only the owner or
      // focus player use the wider viewport with an unambiguous connector.
      // These cells stay in a fixed order so a retained placement does not
      // jump merely because the player moves a few pixels between frames.
      final distantFallbackCandidates = <Rect>[
        if (allowsDistantFallback)
          for (var row = 0; row <= 16; row++)
            for (var column = 0; column <= 32; column++)
              Rect.fromLTWH(
                safeView.left +
                    1 +
                    (safeView.width - labelSize.width - 2) * column / 32,
                safeView.top +
                    1 +
                    (safeView.height - labelSize.height - 2) * row / 16,
                labelSize.width,
                labelSize.height,
              ),
      ];
      final candidates = <Rect>[
        ...adjacentCandidates,
        ...displacedCandidates,
        ...distantFallbackCandidates,
      ];
      final preferred = preferredNameLabelPlacements[playerId];
      final distantFallbackStart =
          adjacentCandidates.length + displacedCandidates.length;
      final distantFallbackIndices = <int>[
        for (var index = distantFallbackStart;
            index < candidates.length;
            index++)
          index,
      ]..sort((left, right) => (candidates[left].center - center)
          .distanceSquared
          .compareTo((candidates[right].center - center).distanceSquared));
      final candidateIndices = <int>[
        if (preferred != null && preferred < candidates.length) preferred,
        for (var index = 0; index < distantFallbackStart; index++)
          if (index != preferred) index,
        for (final index in distantFallbackIndices)
          if (index != preferred) index,
      ];
      final connectorObstacles = <Rect>[
        ...reservedOverlayRects.map((value) => value.inflate(3)),
        for (final layout in layouts) layout.geometry.rect.inflate(2),
      ];
      Rect? chosen;
      int? placementIndex;
      Offset? connectorStart;
      Offset? connectorEnd;
      for (final candidateIndex in candidateIndices) {
        final candidate = candidates[candidateIndex];
        if (!safeView.contains(candidate.topLeft) ||
            !safeView.contains(candidate.bottomRight) ||
            occupied.any(candidate.overlaps) ||
            // The teaching connector ends at the cue player's badge, so its
            // own attached name may share that final strip. Other names keep
            // the connector fully visible.
            (playerId != cuePlayerId &&
                cueConnectorStart != null &&
                SpatialCuePlacement._segmentIntersectsRect(
                  cueConnectorStart,
                  cueTarget,
                  candidate.inflate(2),
                ))) {
          continue;
        }
        if (candidateIndex >= 8) {
          final candidateConnectorStart = SpatialCuePlacement.connectorStart(
            candidate,
            center,
          );
          final vector = candidateConnectorStart - center;
          final candidateConnectorEnd = vector.distance <= badge.radius
              ? center
              : center + vector / vector.distance * (badge.radius + 1.5);
          if (connectorObstacles.any(
            (obstacle) => SpatialCuePlacement._segmentIntersectsRect(
              candidateConnectorStart,
              candidateConnectorEnd,
              obstacle,
            ),
          )) {
            continue;
          }
          connectorStart = candidateConnectorStart;
          connectorEnd = candidateConnectorEnd;
        }
        chosen = candidate;
        placementIndex = candidateIndex;
        break;
      }
      if (chosen == null || placementIndex == null) continue;
      occupied.add(chosen.inflate(2));
      final role = roleById[playerId];
      final tone = playerId == currentSourceOwnerId ||
              playerId == scene.focusPlayerId ||
              playerId == cuePlayerId
          ? _focus
          : role?.kind == SpatialObservedRoleKind.nearbyDefender
              ? _turnover
              : _connection;
      layouts.add((
        geometry: SpatialPlayerNameLabelGeometry(
          playerId: playerId,
          sourceName: sourceName,
          displayName: displayName,
          rect: chosen,
          badgeRect: badge.rect,
          placementIndex: placementIndex,
          connectorStart: connectorStart,
          connectorEnd: connectorEnd,
        ),
        painter: painter,
        tone: tone,
      ));
    }
    return layouts;
  }

  void _drawPlayerNameConnectors(Canvas canvas) {
    for (final layout in _playerNameLayouts) {
      final geometry = layout.geometry;
      if (geometry.connectorStart case final start?) {
        canvas.drawLine(
          start,
          geometry.connectorEnd!,
          Paint()
            ..color = layout.tone.withValues(alpha: .68)
            ..strokeWidth = 1.1
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  void _drawPlayerNameLabels(Canvas canvas) {
    for (final layout in _playerNameLayouts) {
      final geometry = layout.geometry;
      final background = brightness == Brightness.dark
          ? const Color(0xEB0C1B15)
          : const Color(0xE6173025);
      final shape = RRect.fromRectAndRadius(
        geometry.rect,
        const Radius.circular(5),
      );
      canvas.drawRRect(shape, Paint()..color = background);
      canvas.drawRRect(
        shape,
        Paint()
          ..color = layout.tone.withValues(alpha: .82)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      layout.painter.paint(
        canvas,
        Offset(
          geometry.rect.left + 6,
          geometry.rect.top +
              (geometry.rect.height - layout.painter.height) / 2,
        ),
      );
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

  // Kept for compatibility with source-regression geometry checks.
  List<Rect> get calloutRects => const <Rect>[];

  Rect get ballSafetyRect => Rect.fromCircle(
        center: _project(viewport.view, data.renderSample(time).ball),
        radius: 12,
      );

  List<Rect> get keyPlayerSafetyRects => [
        for (final playerId in requiredPlayerIds)
          if (data.renderSample(time).players[data.playerIndex(playerId)]
              case final point?)
            Rect.fromCircle(
              center: _project(viewport.view, point),
              radius: 25,
            ),
      ];

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
      oldDelegate.locale != locale ||
      oldDelegate.viewport.camera != viewport.camera ||
      oldDelegate.cuePlayerId != cuePlayerId ||
      !setEquals(oldDelegate.nameLabelPlayerIds, nameLabelPlayerIds) ||
      oldDelegate.cueRect != cueRect ||
      oldDelegate.cueTarget != cueTarget ||
      oldDelegate.textScaler != textScaler ||
      !mapEquals(
        oldDelegate.preferredNameLabelPlacements,
        preferredNameLabelPlacements,
      );
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

Set<int> _requiredCueActorIds({
  required SpatialLibraryScene scene,
  required RealMatchReplayData data,
  required double time,
  required _SpatialPhaseCue cue,
  required SpatialObservedRoles roles,
  required int? currentOwner,
}) {
  final ids = <int>{
    ...roles.playerIds,
    if (cue.targetPlayerId != null) cue.targetPlayerId!,
    if (currentOwner != null) currentOwner,
  };
  if (time >= scene.coreStart - .0001 && time <= scene.coreEnd + .0001) {
    ids.addAll(scene.highlightPlayerIds);
  }
  // Before the recorded connection completes, every player explicitly named
  // by the current cue must remain readable even when that player is not the
  // owner or the cue target at this exact source frame.
  if (time < scene.evidenceEnd) {
    for (final player in data.players) {
      if (cue.text.contains(_cuePlayerLabel(data, player.id))) {
        ids.add(player.id);
      }
    }
  }
  // The pressure-support aftermath explicitly compares the receiver with the
  // observed support. Keep both clear for the complete comparison window.
  if (scene.theme == SpatialLearningTheme.pressureSupport &&
      time >= scene.evidenceEnd &&
      time <= scene.evidenceEnd + 1.6) {
    ids
      ..add(scene.evidenceAnchors.last.playerId)
      ..addAll(scene.supportPlayerIds);
  }
  return ids;
}

_SpatialPhaseCue _phaseCue(
  AppLocalizations l10n,
  SpatialLibraryScene scene,
  RealMatchReplayData data,
  double time,
) {
  final finished = time >= data.duration - 1 / data.fps;
  final phase = finished
      ? _SpatialCuePhase.review
      : time < scene.evidenceStart
          ? _SpatialCuePhase.context
          : time < scene.evidenceEnd
              ? _SpatialCuePhase.connection
              : time <= scene.evidenceEnd + 1.6
                  ? _SpatialCuePhase.aftermath
                  : _SpatialCuePhase.continuation;
  final anchors = scene.evidenceAnchors;
  final first = anchors.first;
  final second = anchors.length > 1 ? anchors[1] : first;
  final third = anchors.length > 2 ? anchors[2] : second;
  final sample = data.sample(time);
  bool isVisible(int id) => sample.players[data.playerIndex(id)] != null;
  var currentAnchor = first;
  for (final anchor in anchors) {
    if (anchor.time > time) break;
    currentAnchor = anchor;
  }
  final supportId = scene.supportPlayerIds.first;
  final pressureGap = scene.observedNearbyDefender(data, scene.evidenceStart);
  final defenderId =
      pressureGap?.defenderId ?? scene.opponentContextPlayerIds.first;
  final firstLabel = _cuePlayerLabel(data, first.playerId);
  final secondLabel = _cuePlayerLabel(data, second.playerId);
  final thirdLabel = _cuePlayerLabel(data, third.playerId);
  final supportLabel = _cuePlayerLabel(data, supportId);
  final defenderLabel = _cuePlayerLabel(data, defenderId);
  final contextReady = time >= scene.coreStart &&
      switch (scene.theme) {
        SpatialLearningTheme.lateralSwitch =>
          isVisible(first.playerId) && isVisible(second.playerId),
        SpatialLearningTheme.pressureSupport => isVisible(first.playerId) &&
            isVisible(defenderId) &&
            isVisible(supportId),
        SpatialLearningTheme.combination =>
          anchors.map((anchor) => anchor.playerId).toSet().every(isVisible),
        _ => isVisible(first.playerId),
      };
  final isReturnCombination = first.playerId == third.playerId;

  String? approvedText;
  switch (scene.theme) {
    case SpatialLearningTheme.lateralSwitch:
      approvedText = switch (phase) {
        _SpatialCuePhase.context => contextReady
            ? l10n.spatialLateralContextCue(firstLabel, secondLabel)
            : l10n.spatialLateralEarlyContextCue,
        _SpatialCuePhase.connection => l10n.spatialLateralConnectionCue(
            firstLabel,
            secondLabel,
          ),
        _SpatialCuePhase.aftermath =>
          l10n.spatialLateralAftermathCue(secondLabel),
        _SpatialCuePhase.continuation => l10n.spatialLateralContinuationCue,
        _SpatialCuePhase.review =>
          l10n.spatialLateralReviewCue(firstLabel, secondLabel),
      };
      break;
    case SpatialLearningTheme.pressureSupport:
      approvedText = switch (phase) {
        _SpatialCuePhase.context => contextReady
            ? l10n.spatialPressureContextCue(
                firstLabel,
                defenderLabel,
                supportLabel,
              )
            : l10n.spatialPressureEarlyContextCue,
        _SpatialCuePhase.connection => l10n.spatialPressureConnectionCue(
            firstLabel,
            secondLabel,
            supportLabel,
          ),
        _SpatialCuePhase.aftermath => l10n.spatialPressureAftermathCue(
            secondLabel,
            supportLabel,
          ),
        _SpatialCuePhase.continuation => l10n.spatialPressureContinuationCue,
        _SpatialCuePhase.review => l10n.spatialPressureReviewCue(
            firstLabel,
            secondLabel,
            supportLabel,
          ),
      };
      break;
    case SpatialLearningTheme.combination:
      approvedText = isReturnCombination
          ? switch (phase) {
              _SpatialCuePhase.context => contextReady
                  ? l10n.spatialCombinationReturnContextCue(
                      firstLabel,
                      secondLabel,
                    )
                  : l10n.spatialCombinationEarlyContextCue,
              _SpatialCuePhase.connection =>
                l10n.spatialCombinationReturnConnectionCue(
                  firstLabel,
                  secondLabel,
                ),
              _SpatialCuePhase.aftermath =>
                l10n.spatialCombinationReturnAftermathCue(firstLabel),
              _SpatialCuePhase.continuation =>
                l10n.spatialCombinationContinuationCue,
              _SpatialCuePhase.review => l10n.spatialCombinationReturnReviewCue(
                  firstLabel,
                  secondLabel,
                ),
            }
          : switch (phase) {
              _SpatialCuePhase.context => contextReady
                  ? l10n.spatialCombinationContextCue(
                      firstLabel,
                      secondLabel,
                      thirdLabel,
                    )
                  : l10n.spatialCombinationEarlyContextCue,
              _SpatialCuePhase.connection =>
                l10n.spatialCombinationConnectionCue(
                  firstLabel,
                  secondLabel,
                  thirdLabel,
                ),
              _SpatialCuePhase.aftermath => l10n.spatialCombinationAftermathCue(
                  firstLabel,
                  secondLabel,
                  thirdLabel,
                ),
              _SpatialCuePhase.continuation =>
                l10n.spatialCombinationContinuationCue,
              _SpatialCuePhase.review => l10n.spatialCombinationReviewCue(
                  firstLabel,
                  secondLabel,
                  thirdLabel,
                ),
            };
      break;
    case SpatialLearningTheme.forwardConnection:
    case SpatialLearningTheme.carryThenConnect:
    case SpatialLearningTheme.wideToInside:
    case SpatialLearningTheme.turnover:
    case SpatialLearningTheme.recovery:
      break;
  }
  return _SpatialPhaseCue(
    phase: phase,
    text: approvedText ?? _legacyPhaseCueText(l10n, scene, data, time),
    targetPlayerId: switch (phase) {
      _SpatialCuePhase.context => contextReady ? first.playerId : null,
      _SpatialCuePhase.connection =>
        isVisible(currentAnchor.playerId) ? currentAnchor.playerId : null,
      _SpatialCuePhase.aftermath =>
        isVisible(anchors.last.playerId) ? anchors.last.playerId : null,
      _SpatialCuePhase.continuation => null,
      _SpatialCuePhase.review => null,
    },
  );
}

String _cuePlayerLabel(RealMatchReplayData data, int playerId) {
  final player = data.player(playerId);
  final fullName = player.name?.trim() ?? '';
  final shortName =
      fullName.isEmpty ? playerId.toString() : fullName.split(' ').last;
  return player.number == null ? shortName : '#${player.number} $shortName';
}

String _spatialShortPlayerName(String sourceName) {
  final parts = sourceName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.length <= 1) return sourceName.trim();
  var firstFamilyPart = parts.length - 1;
  const familyParticles = <String>{
    'da',
    'de',
    'del',
    'der',
    'di',
    'dos',
    'la',
    'le',
    'ter',
    'van',
    'von',
  };
  while (firstFamilyPart > 0 &&
      familyParticles.contains(parts[firstFamilyPart - 1].toLowerCase())) {
    firstFamilyPart--;
  }
  return parts.sublist(firstFamilyPart).join(' ');
}

String _legacyPhaseCueText(
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
