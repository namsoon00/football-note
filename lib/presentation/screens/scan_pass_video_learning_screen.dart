part of 'scan_pass_game_screen.dart';

typedef VideoLearningCatalogLoader = Future<VideoLearningCatalog> Function();

class _InjectedVideoLearningRepository implements VideoLearningRepository {
  final VideoLearningCatalogLoader loader;

  const _InjectedVideoLearningRepository(this.loader);

  @override
  Future<VideoLearningCatalog> loadCatalog() => loader();
}

enum _VideoLearningMode { whole, parts }

class ScanPassVideoLearningScreen extends StatefulWidget {
  final OptionRepository optionRepository;
  final VideoLearningCatalogLoader? catalogLoader;
  final VideoLearningPlayerPort? player;
  final MatchMomentSourceLauncher? sourceLauncher;

  const ScanPassVideoLearningScreen({
    super.key,
    required this.optionRepository,
    this.catalogLoader,
    this.player,
    this.sourceLauncher,
  });

  @override
  State<ScanPassVideoLearningScreen> createState() =>
      _ScanPassVideoLearningScreenState();
}

class _ScanPassVideoLearningScreenState
    extends State<ScanPassVideoLearningScreen> with WidgetsBindingObserver {
  late final VideoLearningPlayerPort _player;
  late final VideoLearningService _service;
  StreamSubscription<VideoLearningPlayerEvent>? _playerSubscription;
  Timer? _readyTimeout;
  int _catalogGeneration = 0;
  int _selectionGeneration = 0;
  int _loadGeneration = 0;
  bool _disposed = false;

  VideoLearningCatalog? _catalog;
  VideoLearningScene? _scene;
  VideoLearningScene? _pendingScene;
  Object? _catalogError;
  VideoLearningPlayerState _playerState = VideoLearningPlayerState.idle;
  String? _playerError;
  List<double> _supportedRates = const <double>[];
  double _mediaTime = 0;
  double _rate = 1;
  bool _foreground = true;
  bool _wasPlayingBeforeSeek = false;
  bool _handledWholeCompletion = false;
  _VideoLearningMode _mode = _VideoLearningMode.whole;
  int _selectedPhase = 0;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;
  bool get _ready =>
      _playerState == VideoLearningPlayerState.ready ||
      _playerState == VideoLearningPlayerState.playing ||
      _playerState == VideoLearningPlayerState.paused ||
      _playerState == VideoLearningPlayerState.ended;
  bool get _playing => _playerState == VideoLearningPlayerState.playing;

  VideoLearningPhase? get _currentPhase {
    final scene = _scene;
    if (scene == null) return null;
    if (_mode == _VideoLearningMode.parts) {
      return scene.phases[_selectedPhase];
    }
    return scene.phaseAt(_mediaTime);
  }

  VideoLearningClipRange? get _activeRange {
    final scene = _scene;
    if (scene == null) return null;
    return _mode == _VideoLearningMode.whole
        ? scene.clip
        : scene.phases[_selectedPhase].range;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _player = widget.player ?? createYouTubeVideoLearningPlayer();
    final assets = VideoLearningAssetRepository();
    _service = VideoLearningService(
      catalogRepository: _InjectedVideoLearningRepository(
        widget.catalogLoader ?? assets.loadCatalog,
      ),
      optionRepository: widget.optionRepository,
    );
    _rate = _service.preferences.playbackRate;
    _playerSubscription = _player.events.listen(_handlePlayerEvent);
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    final generation = ++_catalogGeneration;
    setState(() => _catalogError = null);
    try {
      final catalog = await _service.loadCatalog();
      if (_disposed || !mounted || generation != _catalogGeneration) return;
      final preferredId = _service.preferences.lastSceneId;
      final scene = catalog.scenes.firstWhere(
        (value) => value.id == preferredId,
        orElse: () => catalog.scenes.first,
      );
      setState(() {
        _catalog = catalog;
        _scene = scene;
        _mediaTime = _service.resumeTime(scene);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && generation == _catalogGeneration) {
          _loadPlayer(scene, initialTime: _mediaTime);
        }
      });
    } catch (error) {
      if (_disposed || !mounted || generation != _catalogGeneration) return;
      setState(() => _catalogError = error);
    }
  }

  Future<void> _loadPlayer(
    VideoLearningScene scene, {
    required double initialTime,
  }) async {
    final generation = ++_loadGeneration;
    _readyTimeout?.cancel();
    _service.resetTelemetry();
    setState(() {
      _playerState = VideoLearningPlayerState.loading;
      _playerError = null;
      _supportedRates = const <double>[];
      _handledWholeCompletion = false;
      _mediaTime = scene.clip.clamp(initialTime);
    });
    await _player.load(scene, initialTime: _mediaTime, autoplay: false);
    if (_disposed ||
        !mounted ||
        generation != _loadGeneration ||
        _scene?.id != scene.id ||
        _ready ||
        _playerState == VideoLearningPlayerState.error) {
      return;
    }
    _readyTimeout = Timer(const Duration(seconds: 12), () {
      if (_disposed ||
          !mounted ||
          generation != _loadGeneration ||
          _scene?.id != scene.id ||
          _ready ||
          _playerState == VideoLearningPlayerState.error) {
        return;
      }
      setState(() {
        _playerState = VideoLearningPlayerState.error;
        _playerError = 'timeout';
      });
    });
  }

  void _handlePlayerEvent(VideoLearningPlayerEvent event) {
    final scene = _scene;
    if (_disposed ||
        !mounted ||
        scene == null ||
        (event.sceneId != null && event.sceneId != scene.id)) {
      return;
    }
    if (event.state == VideoLearningPlayerState.ready) {
      _readyTimeout?.cancel();
      final supported = event.supportedRates
          .where((value) => const <double>[.5, .75, 1].contains(value))
          .toSet()
          .toList(growable: false)
        ..sort();
      final desired = supported.contains(_rate)
          ? _rate
          : supported.contains(1)
              ? 1.0
              : supported.isEmpty
                  ? 1.0
                  : supported.last;
      setState(() {
        _playerState = event.state;
        _playerError = null;
        _supportedRates = List.unmodifiable(supported);
        _rate = desired;
        _mediaTime = scene.clip.clamp(event.mediaTime);
      });
      if (supported.contains(desired)) {
        unawaited(_player.setPlaybackRate(desired));
      }
      return;
    }
    if (event.state == VideoLearningPlayerState.rateChanged) {
      final actualRate = event.playbackRate;
      if (actualRate != null && _supportedRates.contains(actualRate)) {
        setState(() => _rate = actualRate);
      }
      return;
    }
    if (event.state == VideoLearningPlayerState.error) {
      _readyTimeout?.cancel();
    }
    unawaited(_service.recordPlayerEvent(
      scene,
      event,
      foreground: _foreground,
    ));
    final time = scene.clip.clamp(event.mediaTime);
    final activeRange = _activeRange;
    if (_mode == _VideoLearningMode.parts &&
        activeRange != null &&
        event.state == VideoLearningPlayerState.playing &&
        time >= activeRange.end - .03) {
      _service.resetTelemetry();
      unawaited(_player.pause());
      unawaited(_player.seek(activeRange.end));
      setState(() {
        _mediaTime = activeRange.end;
        _playerState = VideoLearningPlayerState.paused;
      });
      return;
    }
    setState(() {
      _mediaTime = time;
      _playerState = event.state;
      if (event.supportedRates.isNotEmpty) {
        _supportedRates = event.supportedRates
            .where((rate) => const <double>[.5, .75, 1].contains(rate))
            .toSet()
            .toList()
          ..sort();
      }
      if (event.state == VideoLearningPlayerState.error) {
        _playerError = event.errorCode ?? 'player_error';
      }
    });
    if (event.state == VideoLearningPlayerState.ended &&
        _mode == _VideoLearningMode.whole &&
        !_handledWholeCompletion) {
      _handledWholeCompletion = true;
      unawaited(_completeWholePlay());
    }
  }

  Future<void> _completeWholePlay() async {
    final selectionGeneration = _selectionGeneration;
    final scene = _scene;
    final catalog = _catalog;
    if (scene == null || catalog == null) return;
    await _service.flush();
    if (!mounted || selectionGeneration != _selectionGeneration) return;
    _showPersistenceFailureIfNeeded();
    if (!_service.preferences.autoNext) return;
    final next = _nextUnseenAfter(scene);
    if (next != null && selectionGeneration == _selectionGeneration) {
      await _selectScene(next);
    }
  }

  VideoLearningScene? _nextUnseenAfter(VideoLearningScene current) {
    final catalog = _catalog;
    if (catalog == null) return null;
    final start = catalog.scenes.indexWhere((scene) => scene.id == current.id);
    if (start < 0) return null;
    for (var index = start + 1; index < catalog.scenes.length; index++) {
      final candidate = catalog.scenes[index];
      if (!_matchesTeam(candidate) || _service.isWatched(candidate)) continue;
      final filter = _service.preferences.watchFilter;
      if (filter == VideoLearningWatchFilter.watched) continue;
      return candidate;
    }
    return null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final active = state == AppLifecycleState.resumed;
    _foreground = active;
    if (!active) {
      _service.resetTelemetry();
      unawaited(_player.pause());
      unawaited(_service.flush());
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _catalogGeneration++;
    _selectionGeneration++;
    _loadGeneration++;
    WidgetsBinding.instance.removeObserver(this);
    _readyTimeout?.cancel();
    _service.resetTelemetry();
    unawaited(_service.flush());
    unawaited(_player.pause());
    unawaited(_playerSubscription?.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _selectScene(
    VideoLearningScene scene, {
    bool restoreResume = false,
  }) async {
    final generation = ++_selectionGeneration;
    setState(() => _pendingScene = scene);
    _readyTimeout?.cancel();
    _loadGeneration++;
    final previous = _scene;
    final previousTime = _mediaTime;
    await _player.pause();
    if (_disposed || !mounted || generation != _selectionGeneration) return;
    if (previous != null) {
      await _service.selectScene(previous, resumeTime: previousTime);
    }
    if (_disposed || !mounted || generation != _selectionGeneration) return;
    final start = restoreResume ? _service.resumeTime(scene) : scene.clip.start;
    await _service.selectScene(scene, resumeTime: start);
    if (_disposed || !mounted || generation != _selectionGeneration) return;
    setState(() {
      _scene = scene;
      _pendingScene = null;
      _selectedPhase = 0;
      _mode = _VideoLearningMode.whole;
      _mediaTime = start;
    });
    await _loadPlayer(scene, initialTime: start);
    if (_disposed || !mounted || generation != _selectionGeneration) return;
    _showPersistenceFailureIfNeeded();
  }

  Future<void> _togglePlay() async {
    final range = _activeRange;
    if (!_ready || range == null) return;
    if (_playing) {
      await _player.pause();
      await _service.flush();
      if (mounted) _showPersistenceFailureIfNeeded();
      return;
    }
    if (_mediaTime >= range.end - .03 || _mediaTime < range.start) {
      _service.resetTelemetry();
      await _player.seek(range.start);
      if (mounted) setState(() => _mediaTime = range.start);
    }
    await _player.play();
  }

  Future<void> _replay() async {
    final range = _activeRange;
    if (!_ready || range == null) return;
    _service.resetTelemetry();
    await _player.pause();
    await _player.seek(range.start);
    if (mounted) {
      setState(() {
        _mediaTime = range.start;
        _playerState = VideoLearningPlayerState.paused;
      });
    }
  }

  Future<void> _setMode(_VideoLearningMode mode) async {
    if (_mode == mode) return;
    final wasPlaying = _playing;
    await _player.pause();
    _service.resetTelemetry();
    final scene = _scene;
    if (!mounted || scene == null) return;
    final phaseIndex = scene.phases.indexOf(scene.phaseAt(_mediaTime));
    final nextTime = mode == _VideoLearningMode.parts
        ? scene.phases[phaseIndex].range.start
        : scene.clip.clamp(_mediaTime);
    await _player.seek(nextTime);
    setState(() {
      _mode = mode;
      _selectedPhase = phaseIndex;
      _mediaTime = nextTime;
      _playerState = VideoLearningPlayerState.paused;
    });
    if (wasPlaying) await _player.play();
  }

  Future<void> _selectPhase(int index) async {
    final scene = _scene;
    if (scene == null || index < 0 || index >= scene.phases.length) return;
    await _player.pause();
    _service.resetTelemetry();
    final time = scene.phases[index].range.start;
    await _player.seek(time);
    if (!mounted) return;
    setState(() {
      _selectedPhase = index;
      _mediaTime = time;
      _playerState = VideoLearningPlayerState.paused;
    });
  }

  Future<void> _setRate(double rate) async {
    if (!_ready || !_supportedRates.contains(rate)) return;
    await _player.setPlaybackRate(rate);
    await _service.setPlaybackRate(rate);
    if (!mounted) return;
    setState(() => _rate = rate);
    _showPersistenceFailureIfNeeded();
  }

  void _beginSeek(double _) {
    _wasPlayingBeforeSeek = _playing;
    _service.resetTelemetry();
    unawaited(_player.pause());
  }

  void _seek(double relativeTime) {
    final range = _activeRange;
    if (range == null) return;
    final absolute = range.clamp(range.start + relativeTime);
    setState(() {
      _mediaTime = absolute;
      _playerState = VideoLearningPlayerState.paused;
    });
    unawaited(_player.seek(absolute));
  }

  Future<void> _endSeek(double relativeTime) async {
    _seek(relativeTime);
    if (_wasPlayingBeforeSeek) await _player.play();
    _wasPlayingBeforeSeek = false;
  }

  bool _matchesTeam(VideoLearningScene scene) {
    final team = _service.preferences.teamFilter;
    return team == null || scene.teamIds.contains(team);
  }

  List<VideoLearningScene> get _filteredScenes {
    final catalog = _catalog;
    if (catalog == null) return const <VideoLearningScene>[];
    return catalog.filtered(
      teamId: _service.preferences.teamFilter,
      watchFilter: _service.preferences.watchFilter,
      isWatched: (id) {
        final scene = catalog.scenes.firstWhere((value) => value.id == id);
        return _service.isWatched(scene);
      },
    );
  }

  VideoLearningScene? _relativeScene(int delta) {
    final current = _pendingScene ?? _scene;
    final filtered = _filteredScenes;
    if (current == null || filtered.isEmpty) return null;
    final index = filtered.indexWhere((scene) => scene.id == current.id);
    if (index >= 0) {
      final target = index + delta;
      return target >= 0 && target < filtered.length ? filtered[target] : null;
    }
    final all = _catalog!.scenes;
    final currentIndex = all.indexWhere((scene) => scene.id == current.id);
    final candidates = delta > 0 ? filtered : filtered.reversed;
    for (final candidate in candidates) {
      final candidateIndex =
          all.indexWhere((scene) => scene.id == candidate.id);
      if ((delta > 0 && candidateIndex > currentIndex) ||
          (delta < 0 && candidateIndex < currentIndex)) {
        return candidate;
      }
    }
    return null;
  }

  Future<void> _openSceneSheet() async {
    final catalog = _catalog;
    final scene = _scene;
    if (catalog == null || scene == null) return;
    await _player.pause();
    if (!mounted) return;
    final selected = await showModalBottomSheet<VideoLearningScene>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _VideoLearningSceneSheet(
        catalog: catalog,
        selectedSceneId: scene.id,
        service: _service,
        onFiltersChanged: () {
          if (mounted) setState(() {});
        },
      ),
    );
    if (!mounted) return;
    _showPersistenceFailureIfNeeded();
    if (selected == null || selected.id == scene.id) return;
    await _selectScene(selected);
  }

  Future<void> _openSettings() async {
    final scene = _scene;
    if (scene == null) return;
    await _player.pause();
    if (!mounted) return;
    final openSpatialLibrary = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _VideoLearningSettingsSheet(
        scene: scene,
        autoNext: _service.preferences.autoNext,
        mode: _mode,
        selectedPhase: _selectedPhase,
        playbackRate: _rate,
        supportedRates: _supportedRates,
        playerReady: _ready,
        onModeChanged: _setMode,
        onPhaseChanged: _selectPhase,
        onRateChanged: _setRate,
        onAutoNextChanged: (value) async {
          await _service.setAutoNext(value);
          if (mounted) setState(() {});
        },
        onOpenVideo: () => _openUri(scene.officialVideoUrlAt(_mediaTime)),
        onOpenReport: () => _openUri(scene.reportUrl),
        onOpenChannel: () => _openUri(scene.channelUrl),
        onOpenSpatialLibrary: () => Navigator.pop(context, true),
      ),
    );
    if (openSpatialLibrary == true && mounted) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => ScanPassSpatialLibraryScreen(
            sourceLauncher: widget.sourceLauncher,
          ),
        ),
      );
    }
    if (mounted) _showPersistenceFailureIfNeeded();
  }

  Future<void> _openUri(Uri uri) async {
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

  void _showPersistenceFailureIfNeeded() {
    if (!_service.hasPersistenceError || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_l10n.videoLearningPersistenceFailed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = _catalog;
    final scene = _scene;
    if (_catalogError != null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.ondemand_video_outlined, size: 48),
                const SizedBox(height: 12),
                Text(
                  _l10n.videoLearningLoadFailed,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _loadCatalog,
                  child: Text(_l10n.videoLearningRetry),
                ),
              ]),
            ),
          ),
        ),
      );
    }
    if (catalog == null || scene == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final phase = _currentPhase!;
    return PopScope(
      onPopInvokedWithResult: (_, __) {
        _service.resetTelemetry();
        unawaited(_player.pause());
        unawaited(_service.flush());
      },
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 840;
            final compactHeight = constraints.maxHeight <= 400;
            final horizontal = desktop ? 24.0 : 12.0;
            return Column(children: [
              Expanded(
                child: SingleChildScrollView(
                  key: const ValueKey<String>('video-learning-scroll'),
                  padding: EdgeInsets.fromLTRB(
                    horizontal,
                    compactHeight ? 4 : 10,
                    horizontal,
                    compactHeight ? 6 : 12,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1240),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (compactHeight && !desktop)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildHeader(scene, phase, true),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildMedia(
                                    scene,
                                    phase,
                                    false,
                                    true,
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            _buildHeader(scene, phase, false),
                            const SizedBox(height: 12),
                            _buildMedia(scene, phase, desktop, false),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  0,
                  horizontal,
                  compactHeight ? 4 : 10,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1240),
                    child: _buildControls(
                      scene,
                      compact: compactHeight,
                    ),
                  ),
                ),
              ),
            ]);
          }),
        ),
      ),
    );
  }

  Widget _buildHeader(
    VideoLearningScene scene,
    VideoLearningPhase phase,
    bool compact,
  ) {
    final canPop = Navigator.of(context).canPop();
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (canPop)
        IconButton(
          key: const ValueKey<String>('video-learning-back'),
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
      Expanded(
        child: Padding(
          padding: EdgeInsets.only(top: canPop ? 2 : 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                videoLearningLocalizedCopy(_l10n, scene.titleKey),
                key: const ValueKey<String>('video-learning-title'),
                maxLines: compact ? null : 3,
                overflow:
                    compact ? TextOverflow.visible : TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                _phaseInstruction(phase),
                key: const ValueKey<String>('video-learning-focus'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Row(children: [
                _KitDot(kit: scene.homeTeam.kit),
                const SizedBox(width: 3),
                _KitDot(kit: scene.awayTeam.kit),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _l10n.videoLearningMatchLine(
                      scene.homeTeam.name,
                      scene.awayTeam.name,
                      scene.date,
                    ),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    ]);
  }

  String _phaseInstruction(VideoLearningPhase phase) {
    final instruction = videoLearningLocalizedCopy(_l10n, phase.watchKey);
    final byId = <String, VideoLearningDiagramPlayer>{
      for (final player in phase.diagram.players) player.id: player,
    };
    final players = phase.diagram.focusIds
        .map((id) => byId[id])
        .whereType<VideoLearningDiagramPlayer>()
        .map(
          (player) => _l10n.videoLearningPlayerNumber(
            player.number,
            player.name,
          ),
        )
        .join(' · ');
    return players.isEmpty
        ? instruction
        : _l10n.videoLearningFocusInstruction(players, instruction);
  }

  Widget _buildMedia(
    VideoLearningScene scene,
    VideoLearningPhase phase,
    bool desktop,
    bool compactHeight,
  ) {
    Widget videoSurface = _playerState == VideoLearningPlayerState.error
        ? _buildPlayerFallback(scene)
        : VideoLearningSurface(
            key: const ValueKey<String>('video-learning-surface'),
            player: _player,
            semanticsLabel: _l10n.videoLearningVideoSemantics,
            unavailableLabel: _l10n.videoLearningNativeUnavailable,
          );
    final video = _VideoLearningCard(
      child: LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          height: math.max(200.0, constraints.maxWidth * 9 / 16),
          child: videoSurface,
        ),
      ),
    );
    final diagram = _VideoLearningCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            _l10n.videoLearningAuthoredDiagramDisclosure,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        AspectRatio(
          aspectRatio: desktop ? 16 / 9 : 1.55,
          child: CustomPaint(
            key: ValueKey<String>('video-diagram-${phase.id}'),
            painter: VideoLearningDiagramPainter(
              diagram: phase.diagram,
              homeKit: scene.homeTeam.kit,
              awayKit: scene.awayTeam.kit,
              attackDirection: scene.attackDirection,
              textDirection: Directionality.of(context),
              fontFamily: Theme.of(context).textTheme.labelMedium?.fontFamily,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 9, 12, 11),
          child: Column(children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 4,
              children: [
                _VideoDiagramLegend(
                  color: const Color(0xFFFFC94A),
                  label: _l10n.videoLearningPassLegend,
                ),
                _VideoDiagramLegend(
                  color: const Color(0xFF57B9E8),
                  label: _l10n.videoLearningRunLegend,
                ),
                _VideoDiagramLegend(
                  color: const Color(0xFFD7A6FF),
                  label: _l10n.videoLearningCarryLegend,
                ),
                _VideoDiagramLegend(
                  color: const Color(0xFFFFA66B),
                  label: _l10n.videoLearningShotLegend,
                ),
                _VideoDiagramLegend(
                  color: const Color(0xFFFFE082),
                  label: _l10n.videoLearningOpenSpace,
                ),
              ],
            ),
          ]),
        ),
      ]),
    );
    if (desktop) {
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 3, child: video),
        const SizedBox(width: 14),
        Expanded(flex: 2, child: diagram),
      ]);
    }
    return Column(children: [video, const SizedBox(height: 10), diagram]);
  }

  Widget _buildPlayerFallback(VideoLearningScene scene) => ColoredBox(
        color: const Color(0xFF111827),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.video_library_outlined,
                  color: Colors.white70, size: 28),
              const SizedBox(height: 6),
              Text(
                _playerError == 'native_unavailable'
                    ? _l10n.videoLearningNativeUnavailable
                    : _playerError == 'timeout'
                        ? _l10n.videoLearningPlayerTimeout
                        : _l10n.videoLearningPlayerError,
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ]),
          ),
        ),
      );

  Widget _buildControls(
    VideoLearningScene scene, {
    required bool compact,
  }) {
    final range = _activeRange!;
    final relative = (range.clamp(_mediaTime) - range.start)
        .clamp(0, range.duration)
        .toDouble();
    final previous = _relativeScene(-1);
    final next = _relativeScene(1);
    return _VideoLearningCard(
      key: const ValueKey<String>('video-learning-controls'),
      child: Padding(
        padding: compact
            ? const EdgeInsets.fromLTRB(8, 4, 8, 4)
            : const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (compact)
            Row(children: [
              Expanded(
                child: SizedBox(
                  height: 30,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 12),
                    ),
                    child: Slider(
                      key: const ValueKey<String>('video-learning-slider'),
                      value: relative,
                      min: 0,
                      max: math.max(.001, range.duration),
                      onChangeStart: _ready ? _beginSeek : null,
                      onChanged: _ready ? _seek : null,
                      onChangeEnd: _ready ? _endSeek : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _l10n.videoLearningElapsed(
                  _clock(relative),
                  _clock(range.duration),
                ),
                key: const ValueKey<String>('video-learning-elapsed'),
                maxLines: 1,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ])
          else ...[
            Slider(
              key: const ValueKey<String>('video-learning-slider'),
              value: relative,
              min: 0,
              max: math.max(.001, range.duration),
              onChangeStart: _ready ? _beginSeek : null,
              onChanged: _ready ? _seek : null,
              onChangeEnd: _ready ? _endSeek : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(children: [
                Flexible(
                  child: Text(
                    _l10n.videoLearningElapsed(
                      _clock(relative),
                      _clock(range.duration),
                    ),
                    key: const ValueKey<String>('video-learning-elapsed'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                const Spacer(),
                Text(
                  _rateLabel(_rate),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ]),
            ),
            const SizedBox(height: 4),
          ],
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(
              key: const ValueKey<String>('video-learning-previous'),
              onPressed: previous == null ? null : () => _selectScene(previous),
              icon: const Icon(Icons.skip_previous),
              tooltip: previous == null
                  ? _l10n.videoLearningNoPrevious
                  : _l10n.videoLearningPrevious,
            ),
            IconButton(
              key: const ValueKey<String>('video-learning-replay'),
              onPressed: _ready ? _replay : null,
              icon: const Icon(Icons.replay),
              tooltip: _l10n.videoLearningReplay,
            ),
            IconButton.filled(
              key: const ValueKey<String>('video-learning-play'),
              onPressed: _ready ? _togglePlay : null,
              icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
              tooltip:
                  _playing ? _l10n.videoLearningPause : _l10n.videoLearningPlay,
            ),
            IconButton(
              key: const ValueKey<String>('video-learning-next'),
              onPressed: next == null ? null : () => _selectScene(next),
              icon: const Icon(Icons.skip_next),
              tooltip: next == null
                  ? _l10n.videoLearningNoNext
                  : _l10n.videoLearningNext,
            ),
            IconButton(
              key: const ValueKey<String>('video-learning-scenes'),
              onPressed: _openSceneSheet,
              icon: const Icon(Icons.video_library_outlined),
              tooltip: _l10n.videoLearningScenesTitle,
            ),
          ]),
          TextButton.icon(
            key: const ValueKey<String>('video-learning-settings'),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 34),
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: _openSettings,
            icon: const Icon(Icons.expand_more, size: 18),
            label: Text(
              _l10n.videoLearningPlaybackOptions(
                _mode == _VideoLearningMode.whole
                    ? _l10n.videoLearningWholeMode
                    : _l10n.videoLearningPartsMode,
                _rateLabel(_rate),
              ),
            ),
          ),
          if (_playerState == VideoLearningPlayerState.error ||
              _playerState == VideoLearningPlayerState.loading) ...[
            const SizedBox(height: 9),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                if (_playerState == VideoLearningPlayerState.error &&
                    _playerError != 'native_unavailable')
                  OutlinedButton(
                    key: const ValueKey<String>('video-learning-retry-player'),
                    onPressed: () => _loadPlayer(
                      scene,
                      initialTime: scene.clip.clamp(_mediaTime),
                    ),
                    child: Text(_l10n.videoLearningRetryPlayer),
                  ),
                FilledButton.tonalIcon(
                  key: const ValueKey<String>('video-learning-open-source'),
                  onPressed: () =>
                      _openUri(scene.officialVideoUrlAt(_mediaTime)),
                  icon: const Icon(Icons.open_in_new),
                  label: Text(_l10n.videoLearningOpenSource),
                ),
              ],
            ),
          ],
        ]),
      ),
    );
  }
}

class _VideoLearningCard extends StatelessWidget {
  final Widget child;

  const _VideoLearningCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppSurfaces.cardColor(
              Theme.of(context).colorScheme,
              Theme.of(context).brightness,
            ),
            border: Border.all(
              color: AppSurfaces.borderColor(
                Theme.of(context).colorScheme,
                Theme.of(context).brightness,
              ),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: child,
        ),
      );
}

class _VideoDiagramLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _VideoDiagramLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 160),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: Colors.black26, width: .5),
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ],
        ),
      );
}

class _VideoLearningSceneSheet extends StatefulWidget {
  final VideoLearningCatalog catalog;
  final String selectedSceneId;
  final VideoLearningService service;
  final VoidCallback onFiltersChanged;

  const _VideoLearningSceneSheet({
    required this.catalog,
    required this.selectedSceneId,
    required this.service,
    required this.onFiltersChanged,
  });

  @override
  State<_VideoLearningSceneSheet> createState() =>
      _VideoLearningSceneSheetState();
}

class _VideoLearningSceneSheetState extends State<_VideoLearningSceneSheet> {
  late String? _teamId = widget.service.preferences.teamFilter;
  late VideoLearningWatchFilter _watchFilter =
      widget.service.preferences.watchFilter;

  List<VideoLearningScene> get _scenes => widget.catalog.filtered(
        teamId: _teamId,
        watchFilter: _watchFilter,
        isWatched: (id) {
          final scene =
              widget.catalog.scenes.firstWhere((value) => value.id == id);
          return widget.service.isWatched(scene);
        },
      );

  Future<void> _setFilters({
    required String? teamId,
    required VideoLearningWatchFilter filter,
  }) async {
    setState(() {
      _teamId = teamId;
      _watchFilter = filter;
    });
    await widget.service.setFilters(teamId: teamId, watchFilter: filter);
    widget.onFiltersChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scenes = _scenes;
    return FractionallySizedBox(
      heightFactor: .9,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(children: [
            Expanded(
              child: Text(
                l10n.videoLearningScenesTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            DropdownButtonFormField<String?>(
              key: const ValueKey<String>('video-team-filter'),
              initialValue: _teamId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.videoLearningAllTeams,
                isDense: true,
              ),
              items: <DropdownMenuItem<String?>>[
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(
                    l10n.videoLearningAllTeams,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                for (final team in widget.catalog.teams)
                  DropdownMenuItem<String?>(
                    value: team.id,
                    child: Text(
                      team.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) =>
                  _setFilters(teamId: value, filter: _watchFilter),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 7, runSpacing: 7, children: [
              for (final filter in VideoLearningWatchFilter.values)
                ChoiceChip(
                  key: ValueKey<String>('video-watch-filter-${filter.name}'),
                  selected: _watchFilter == filter,
                  onSelected: (_) =>
                      _setFilters(teamId: _teamId, filter: filter),
                  label: Text(switch (filter) {
                    VideoLearningWatchFilter.all => l10n.videoLearningAllStatus,
                    VideoLearningWatchFilter.watched =>
                      l10n.videoLearningWatchedFilter,
                    VideoLearningWatchFilter.unwatched =>
                      l10n.videoLearningUnwatchedFilter,
                  }),
                ),
            ]),
            const SizedBox(height: 6),
            Text(
              l10n.videoLearningVisibleCount(
                scenes.length,
                widget.catalog.scenes.length,
              ),
              key: const ValueKey<String>('video-visible-count'),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ]),
        ),
        const Divider(),
        Expanded(
          child: scenes.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(l10n.videoLearningEmptyScenes),
                    const SizedBox(height: 8),
                    TextButton(
                      key: const ValueKey<String>('video-reset-filters'),
                      onPressed: () => _setFilters(
                        teamId: null,
                        filter: VideoLearningWatchFilter.all,
                      ),
                      child: Text(l10n.videoLearningResetFilters),
                    ),
                  ]),
                )
              : ListView.builder(
                  itemCount: scenes.length,
                  itemBuilder: (context, index) {
                    final scene = scenes[index];
                    final fraction = widget.service.coverageFraction(scene);
                    final watched = widget.service.isWatched(scene);
                    final status = watched
                        ? l10n.videoLearningWatchedStatus
                        : fraction > 0
                            ? l10n.videoLearningPartialStatus(
                                (fraction * 100).floor(),
                              )
                            : l10n.videoLearningNewStatus;
                    return ListTile(
                      key: ValueKey<String>('video-scene-${scene.id}'),
                      selected: scene.id == widget.selectedSceneId,
                      onTap: () => Navigator.pop(context, scene),
                      leading: _VideoTeamKitPair(scene: scene),
                      title: Text(
                        videoLearningLocalizedCopy(l10n, scene.titleKey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.videoLearningMatchLine(
                              scene.homeTeam.name,
                              scene.awayTeam.name,
                              scene.date,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(children: [
                            Expanded(
                              flex: 4,
                              child: Row(children: [
                                const Icon(Icons.schedule, size: 14),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    l10n.videoLearningClipDuration(
                                      _clock(scene.clip.duration),
                                    ),
                                    key: ValueKey<String>(
                                      'video-scene-duration-${scene.id}',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ]),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              flex: 6,
                              child: Row(children: [
                                Icon(
                                  watched
                                      ? Icons.check_circle_outline
                                      : fraction > 0
                                          ? Icons.timelapse
                                          : Icons.fiber_new_outlined,
                                  size: 14,
                                ),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    status,
                                    key: ValueKey<String>(
                                      'video-scene-status-${scene.id}',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ]),
                            ),
                          ]),
                        ],
                      ),
                      isThreeLine: true,
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

class _VideoLearningSettingsSheet extends StatefulWidget {
  final VideoLearningScene scene;
  final bool autoNext;
  final _VideoLearningMode mode;
  final int selectedPhase;
  final double playbackRate;
  final List<double> supportedRates;
  final bool playerReady;
  final Future<void> Function(_VideoLearningMode) onModeChanged;
  final Future<void> Function(int) onPhaseChanged;
  final Future<void> Function(double) onRateChanged;
  final ValueChanged<bool> onAutoNextChanged;
  final VoidCallback onOpenVideo;
  final VoidCallback onOpenReport;
  final VoidCallback onOpenChannel;
  final VoidCallback onOpenSpatialLibrary;

  const _VideoLearningSettingsSheet({
    required this.scene,
    required this.autoNext,
    required this.mode,
    required this.selectedPhase,
    required this.playbackRate,
    required this.supportedRates,
    required this.playerReady,
    required this.onModeChanged,
    required this.onPhaseChanged,
    required this.onRateChanged,
    required this.onAutoNextChanged,
    required this.onOpenVideo,
    required this.onOpenReport,
    required this.onOpenChannel,
    required this.onOpenSpatialLibrary,
  });

  @override
  State<_VideoLearningSettingsSheet> createState() =>
      _VideoLearningSettingsSheetState();
}

class _VideoLearningSettingsSheetState
    extends State<_VideoLearningSettingsSheet> {
  late bool _autoNext = widget.autoNext;
  late _VideoLearningMode _mode = widget.mode;
  late int _selectedPhase = widget.selectedPhase;
  late double _rate = widget.playbackRate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FractionallySizedBox(
      heightFactor: .9,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
            child: Row(children: [
              Expanded(
                child: Text(
                  l10n.videoLearningSettings,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              ),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              children: [
                Text(
                  l10n.videoLearningPlaybackSpeed,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    SegmentedButton<_VideoLearningMode>(
                      segments: <ButtonSegment<_VideoLearningMode>>[
                        ButtonSegment(
                          value: _VideoLearningMode.whole,
                          label: Text(l10n.videoLearningWholeMode),
                        ),
                        ButtonSegment(
                          value: _VideoLearningMode.parts,
                          label: Text(l10n.videoLearningPartsMode),
                        ),
                      ],
                      selected: <_VideoLearningMode>{_mode},
                      onSelectionChanged: (values) async {
                        final value = values.single;
                        await widget.onModeChanged(value);
                        if (mounted) setState(() => _mode = value);
                      },
                    ),
                    for (final rate in const <double>[.5, .75, 1])
                      if (!widget.playerReady ||
                          widget.supportedRates.contains(rate))
                        ChoiceChip(
                          key: ValueKey<String>('video-rate-$rate'),
                          label: Text(_rateLabel(rate)),
                          selected: _rate == rate,
                          onSelected: widget.playerReady &&
                                  widget.supportedRates.contains(rate)
                              ? (_) async {
                                  await widget.onRateChanged(rate);
                                  if (mounted) setState(() => _rate = rate);
                                }
                              : null,
                        ),
                  ],
                ),
                if (_mode == _VideoLearningMode.parts) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    alignment: WrapAlignment.center,
                    children: [
                      for (var index = 0;
                          index < widget.scene.phases.length;
                          index++)
                        ChoiceChip(
                          key: ValueKey<String>('video-phase-$index'),
                          selected: index == _selectedPhase,
                          onSelected: (_) async {
                            await widget.onPhaseChanged(index);
                            if (mounted) setState(() => _selectedPhase = index);
                          },
                          label: Text(
                            l10n.videoLearningPhaseRange(
                              videoLearningLocalizedCopy(
                                l10n,
                                widget.scene.phases[index].titleKey,
                              ),
                              _rangeClock(
                                widget.scene.phases[index].range,
                                widget.scene.clip,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const Divider(),
                SwitchListTile(
                  key: const ValueKey<String>('video-auto-next'),
                  contentPadding: EdgeInsets.zero,
                  value: _autoNext,
                  onChanged: (value) {
                    setState(() => _autoNext = value);
                    widget.onAutoNextChanged(value);
                  },
                  title: Text(l10n.videoLearningAutoNext),
                  subtitle: Text(l10n.videoLearningAutoNextDetail),
                ),
                const Divider(),
                Text(
                  l10n.videoLearningSourceSection,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(l10n.videoLearningSourceChannel(widget.scene.channel)),
                const SizedBox(height: 4),
                Text(
                  l10n.videoLearningTimingTolerance(
                    _compactNumber(widget.scene.timestampTolerance),
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: widget.onOpenVideo,
                  icon: const Icon(Icons.open_in_new),
                  label: Text(l10n.videoLearningOpenSource),
                ),
                OutlinedButton.icon(
                  onPressed: widget.onOpenReport,
                  icon: const Icon(Icons.article_outlined),
                  label: Text(l10n.videoLearningOpenReport),
                ),
                OutlinedButton.icon(
                  onPressed: widget.onOpenChannel,
                  icon: const Icon(Icons.smart_display_outlined),
                  label: Text(l10n.videoLearningOpenChannel),
                ),
                const Divider(),
                ListTile(
                  key: const ValueKey<String>('video-open-spatial-library'),
                  contentPadding: EdgeInsets.zero,
                  onTap: widget.onOpenSpatialLibrary,
                  leading: const Icon(Icons.grid_4x4),
                  title: Text(l10n.videoLearningLegacyLibrary),
                  subtitle: Text(l10n.videoLearningLegacyLibraryDetail),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoTeamKitPair extends StatelessWidget {
  final VideoLearningScene scene;

  const _VideoTeamKitPair({required this.scene});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 42,
        child: Stack(children: [
          Positioned(
            left: 0,
            top: 3,
            child: _KitDot(kit: scene.homeTeam.kit),
          ),
          Positioned(
            right: 0,
            bottom: 3,
            child: _KitDot(kit: scene.awayTeam.kit),
          ),
        ]),
      );
}

class _KitDot extends StatelessWidget {
  final FootballKit kit;

  const _KitDot({required this.kit});

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: const Size(25, 25),
        painter: _KitDotPainter(kit),
      );
}

class _KitDotPainter extends CustomPainter {
  final FootballKit kit;

  const _KitDotPainter(this.kit);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final clip = Path()..addOval(rect.deflate(1));
    canvas.save();
    canvas.clipPath(clip);
    _paintKitPattern(canvas, rect, kit);
    canvas.restore();
    canvas.drawOval(
      rect.deflate(1),
      Paint()
        ..color = Colors.black54
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _KitDotPainter oldDelegate) =>
      oldDelegate.kit != kit;
}

class VideoLearningDiagramPainter extends CustomPainter {
  final VideoLearningDiagram diagram;
  final FootballKit homeKit;
  final FootballKit awayKit;
  final int attackDirection;
  final TextDirection textDirection;
  final String? fontFamily;

  const VideoLearningDiagramPainter({
    required this.diagram,
    required this.homeKit,
    required this.awayKit,
    this.attackDirection = 1,
    required this.textDirection,
    this.fontFamily,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final field = Offset.zero & size;
    canvas.drawRect(field, Paint()..color = const Color(0xFF285E43));
    for (var stripe = 0; stripe < 8; stripe++) {
      if (stripe.isEven) {
        canvas.drawRect(
          Rect.fromLTWH(
            stripe * size.width / 8,
            0,
            size.width / 8,
            size.height,
          ),
          Paint()..color = const Color(0x1426A269),
        );
      }
    }
    final line = Paint()
      ..color = const Color(0xFFD9E8DE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRect(field.deflate(8), line);
    final goalOnRight = attackDirection == 1;
    final penaltyArea = goalOnRight
        ? Rect.fromLTRB(
            size.width * .72,
            size.height * .18,
            size.width - 8,
            size.height * .82,
          )
        : Rect.fromLTRB(
            8,
            size.height * .18,
            size.width * .28,
            size.height * .82,
          );
    final sixYardArea = goalOnRight
        ? Rect.fromLTRB(
            size.width * .9,
            size.height * .34,
            size.width - 8,
            size.height * .66,
          )
        : Rect.fromLTRB(
            8,
            size.height * .34,
            size.width * .1,
            size.height * .66,
          );
    final goal = goalOnRight
        ? Rect.fromLTRB(
            size.width - 8,
            size.height * .41,
            size.width - 2,
            size.height * .59,
          )
        : Rect.fromLTRB(
            2,
            size.height * .41,
            8,
            size.height * .59,
          );
    canvas.drawRect(penaltyArea, line);
    canvas.drawRect(sixYardArea, line);
    canvas.drawRect(goal, line);
    canvas.drawCircle(
      Offset(
        goalOnRight ? size.width * .82 : size.width * .18,
        size.height / 2,
      ),
      2.2,
      Paint()..color = line.color,
    );
    final space = diagram.space;
    if (space != null) {
      final rect = Rect.fromLTWH(
        (attackDirection == 1 ? space.x : 1 - space.x - space.width) *
            size.width,
        space.y * size.height,
        space.width * size.width,
        space.height * size.height,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        Paint()..color = const Color(0x3DFFE082),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        Paint()
          ..color = const Color(0xCCFFE082)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
    for (final arrow in diagram.arrows) {
      final isRun = arrow.kind == VideoLearningArrowKind.run;
      final color = switch (arrow.kind) {
        VideoLearningArrowKind.pass => const Color(0xFFFFE082),
        VideoLearningArrowKind.run => const Color(0xFF9AD8F5),
        VideoLearningArrowKind.carry => const Color(0xFFD7A6FF),
        VideoLearningArrowKind.shot => const Color(0xFFFFA66B),
      };
      _drawArrow(
        canvas,
        _project(arrow.from, size),
        _project(arrow.to, size),
        color,
        dashed: isRun,
      );
    }
    for (final player in diagram.players) {
      final center = _project(player.position, size);
      if (diagram.focusIds.contains(player.id)) {
        canvas.drawCircle(
          center,
          math.min(18.0, size.shortestSide * .065) + 5,
          Paint()
            ..color = const Color(0xFFFFD45C)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4,
        );
      }
      _drawShirt(
        canvas,
        center,
        math.min(18.0, size.shortestSide * .065),
        player.home ? homeKit : awayKit,
        player.number,
      );
    }
    final ball = _project(diagram.ball, size);
    canvas.drawCircle(ball, 5.5, Paint()..color = Colors.white);
    canvas.drawCircle(
      ball,
      5.5,
      Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  Offset _project(VideoLearningPoint point, Size size) => Offset(
        (attackDirection == 1 ? point.x : 1 - point.x) * size.width,
        point.y * size.height,
      );

  void _drawShirt(
    Canvas canvas,
    Offset center,
    double radius,
    FootballKit kit,
    int number,
  ) {
    final path = Path()
      ..moveTo(center.dx - radius * .45, center.dy - radius * .75)
      ..lineTo(center.dx - radius, center.dy - radius * .25)
      ..lineTo(center.dx - radius * .68, center.dy + radius * .12)
      ..lineTo(center.dx - radius * .45, center.dy)
      ..lineTo(center.dx - radius * .38, center.dy + radius * .82)
      ..lineTo(center.dx + radius * .38, center.dy + radius * .82)
      ..lineTo(center.dx + radius * .45, center.dy)
      ..lineTo(center.dx + radius * .68, center.dy + radius * .12)
      ..lineTo(center.dx + radius, center.dy - radius * .25)
      ..lineTo(center.dx + radius * .45, center.dy - radius * .75)
      ..close();
    final bounds = path.getBounds();
    canvas.save();
    canvas.clipPath(path);
    _paintKitPattern(canvas, bounds, kit);
    canvas.restore();
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black54
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8,
    );
    final outlinePainter = TextPainter(
      text: TextSpan(
        text: '$number',
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: radius * .82,
          fontWeight: FontWeight.w900,
          height: 1,
          foreground: Paint()
            ..color = Colors.black87
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2,
        ),
      ),
      textDirection: textDirection,
    )..layout();
    final painter = TextPainter(
      text: TextSpan(
        text: '$number',
        style: TextStyle(
          color: _parseVideoColor(kit.number),
          fontFamily: fontFamily,
          fontSize: radius * .82,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
      textDirection: textDirection,
    )..layout();
    final offset = center - Offset(painter.width / 2, painter.height / 2);
    outlinePainter.paint(canvas, offset);
    painter.paint(
      canvas,
      offset,
    );
  }

  void _drawArrow(
    Canvas canvas,
    Offset from,
    Offset to,
    Color color, {
    required bool dashed,
  }) {
    final vector = to - from;
    if (vector.distance < 2) return;
    final direction = vector / vector.distance;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    if (dashed) {
      for (double distance = 0;
          distance < vector.distance - 9;
          distance += 10) {
        canvas.drawLine(
          from + direction * distance,
          from + direction * math.min(distance + 5, vector.distance - 9),
          paint,
        );
      }
    } else {
      canvas.drawLine(from, to - direction * 8, paint);
    }
    final side = Offset(-direction.dy, direction.dx);
    final head = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(
        to.dx - direction.dx * 10 + side.dx * 4,
        to.dy - direction.dy * 10 + side.dy * 4,
      )
      ..lineTo(
        to.dx - direction.dx * 10 - side.dx * 4,
        to.dy - direction.dy * 10 - side.dy * 4,
      )
      ..close();
    canvas.drawPath(head, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant VideoLearningDiagramPainter oldDelegate) =>
      oldDelegate.diagram != diagram ||
      oldDelegate.homeKit != homeKit ||
      oldDelegate.awayKit != awayKit ||
      oldDelegate.attackDirection != attackDirection ||
      oldDelegate.textDirection != textDirection ||
      oldDelegate.fontFamily != fontFamily;
}

void _paintKitPattern(
  Canvas canvas,
  Rect rect,
  FootballKit kit,
) {
  final primary = _parseVideoColor(kit.primary);
  final secondary = _parseVideoColor(kit.secondary);
  canvas.drawRect(rect, Paint()..color = primary);
  switch (kit.pattern) {
    case FootballKitPattern.solid:
      canvas.drawRect(
        Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height * .12),
        Paint()..color = _parseVideoColor(kit.accent),
      );
      break;
    case FootballKitPattern.verticalStripes:
      final width = rect.width / 5;
      for (var stripe = 1; stripe < 5; stripe += 2) {
        canvas.drawRect(
          Rect.fromLTWH(
              rect.left + width * stripe, rect.top, width, rect.height),
          Paint()..color = secondary,
        );
      }
      break;
    case FootballKitPattern.halves:
      canvas.drawRect(
        Rect.fromLTWH(
          rect.center.dx,
          rect.top,
          rect.width / 2,
          rect.height,
        ),
        Paint()..color = secondary,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          rect.center.dx - rect.width * .035,
          rect.top,
          rect.width * .07,
          rect.height,
        ),
        Paint()..color = _parseVideoColor(kit.accent),
      );
      break;
    case FootballKitPattern.centerStripe:
      canvas.drawRect(
        Rect.fromLTWH(
          rect.center.dx - rect.width * .13,
          rect.top,
          rect.width * .26,
          rect.height,
        ),
        Paint()..color = secondary,
      );
      final accent = _parseVideoColor(kit.accent);
      for (final direction in <double>[-1, 1]) {
        canvas.drawRect(
          Rect.fromLTWH(
            rect.center.dx + direction * rect.width * .15 - rect.width * .02,
            rect.top,
            rect.width * .04,
            rect.height,
          ),
          Paint()..color = accent,
        );
      }
      break;
    case FootballKitPattern.checkerboard:
      const columns = 4;
      const rows = 4;
      final cellWidth = rect.width / columns;
      final cellHeight = rect.height / rows;
      for (var row = 0; row < rows; row++) {
        for (var column = 0; column < columns; column++) {
          if ((row + column).isEven) continue;
          canvas.drawRect(
            Rect.fromLTWH(
              rect.left + column * cellWidth,
              rect.top + row * cellHeight,
              cellWidth,
              cellHeight,
            ),
            Paint()..color = secondary,
          );
        }
      }
      break;
  }
}

FootballKit? _verifiedLegacyKit(String date, String team) {
  if (date == '2019-10-27') {
    if (team == 'Paris') {
      return const FootballKit(
        primary: '#003A67',
        secondary: '#D71920',
        accent: '#FFFFFF',
        number: '#FFFFFF',
        pattern: FootballKitPattern.centerStripe,
      );
    }
    if (team == 'Marseille') {
      return const FootballKit(
        primary: '#FFFFFF',
        secondary: '#85C5E3',
        accent: '#85C5E3',
        number: '#85C5E3',
        pattern: FootballKitPattern.solid,
      );
    }
  }
  if (date == '2019-11-09' || date == '2020-05-26') {
    if (team == 'Bayern Munchen') {
      return const FootballKit(
        primary: '#E4070C',
        secondary: '#FFFFFF',
        accent: '#FFFFFF',
        number: '#FFFFFF',
        pattern: FootballKitPattern.solid,
      );
    }
    if (team == 'Dortmund') {
      return const FootballKit(
        primary: '#F4E422',
        secondary: '#111111',
        accent: '#111111',
        number: '#111111',
        pattern: FootballKitPattern.solid,
      );
    }
  }
  if (date == '2019-11-10') {
    if (team == 'Liverpool') {
      return const FootballKit(
        primary: '#C10021',
        secondary: '#FFFFFF',
        accent: '#FFFFFF',
        number: '#FFFFFF',
        pattern: FootballKitPattern.solid,
      );
    }
    if (team == 'Manchester City') {
      return const FootballKit(
        primary: '#57A0D3',
        secondary: '#FFFFFF',
        accent: '#FFFFFF',
        number: '#FFFFFF',
        pattern: FootballKitPattern.solid,
      );
    }
  }
  if (date == '2019-12-18' || date == '2020-03-01') {
    if (team == 'FC Barcelona') {
      return const FootballKit(
        primary: '#163E87',
        secondary: '#A51E3E',
        accent: '#F4CF45',
        number: '#F4CF45',
        pattern: FootballKitPattern.checkerboard,
      );
    }
    if (team == 'Real Madrid') {
      return const FootballKit(
        primary: '#FFFFFF',
        secondary: '#C4A83A',
        accent: '#C4A83A',
        number: '#9A842A',
        pattern: FootballKitPattern.solid,
      );
    }
  }
  if (date == '2020-07-02') {
    if (team == 'Manchester City') {
      return const FootballKit(
        primary: '#6CABDD',
        secondary: '#FFFFFF',
        accent: '#FFFFFF',
        number: '#173B63',
        pattern: FootballKitPattern.solid,
      );
    }
    if (team == 'Liverpool') {
      return const FootballKit(
        primary: '#C8102E',
        secondary: '#FFFFFF',
        accent: '#FFFFFF',
        number: '#FFFFFF',
        pattern: FootballKitPattern.solid,
      );
    }
  }
  if (date == '2020-03-08' || date == '2019-10-06') {
    if (team == 'Juventus') {
      return const FootballKit(
        primary: '#FFFFFF',
        secondary: '#161616',
        accent: '#ED709C',
        number: '#F8F8F8',
        pattern: FootballKitPattern.halves,
      );
    }
    if (team == 'Inter') {
      return const FootballKit(
        primary: '#1478CD',
        secondary: '#111823',
        accent: '#111823',
        number: '#FFFFFF',
        pattern: FootballKitPattern.verticalStripes,
      );
    }
  }
  return null;
}

Color _parseVideoColor(String value) {
  final hex = value.replaceFirst('#', '');
  return Color(int.parse('FF$hex', radix: 16));
}

String _clock(double seconds) {
  final value = math.max(0, seconds.round());
  final minutes = value ~/ 60;
  final remainder = value % 60;
  return '$minutes:${remainder.toString().padLeft(2, '0')}';
}

String _rangeClock(
  VideoLearningClipRange range,
  VideoLearningClipRange clip,
) =>
    '${_clock(range.start - clip.start)}–${_clock(range.end - clip.start)}';

String _rateLabel(double rate) =>
    rate == rate.roundToDouble() ? '${rate.toInt()}×' : '$rate×';

String _compactNumber(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);

String videoLearningLocalizedCopy(AppLocalizations l10n, String key) {
  return switch (key) {
    'videoMessiWinnerTitle' => l10n.videoMessiWinnerTitle,
    'videoMessiWinnerFocus' => l10n.videoMessiWinnerFocus,
    'videoMessiWinnerPhase1Title' => l10n.videoMessiWinnerPhase1Title,
    'videoMessiWinnerPhase1Watch' => l10n.videoMessiWinnerPhase1Watch,
    'videoMessiWinnerPhase2Title' => l10n.videoMessiWinnerPhase2Title,
    'videoMessiWinnerPhase2Watch' => l10n.videoMessiWinnerPhase2Watch,
    'videoMessiWinnerPhase3Title' => l10n.videoMessiWinnerPhase3Title,
    'videoMessiWinnerPhase3Watch' => l10n.videoMessiWinnerPhase3Watch,
    'videoMessiFirstTitle' => l10n.videoMessiFirstTitle,
    'videoMessiFirstFocus' => l10n.videoMessiFirstFocus,
    'videoMessiFirstPhase1Title' => l10n.videoMessiFirstPhase1Title,
    'videoMessiFirstPhase1Watch' => l10n.videoMessiFirstPhase1Watch,
    'videoMessiFirstPhase2Title' => l10n.videoMessiFirstPhase2Title,
    'videoMessiFirstPhase2Watch' => l10n.videoMessiFirstPhase2Watch,
    'videoMessiFirstPhase3Title' => l10n.videoMessiFirstPhase3Title,
    'videoMessiFirstPhase3Watch' => l10n.videoMessiFirstPhase3Watch,
    'videoFodenTitle' => l10n.videoFodenTitle,
    'videoFodenFocus' => l10n.videoFodenFocus,
    'videoFodenPhase1Title' => l10n.videoFodenPhase1Title,
    'videoFodenPhase1Watch' => l10n.videoFodenPhase1Watch,
    'videoFodenPhase2Title' => l10n.videoFodenPhase2Title,
    'videoFodenPhase2Watch' => l10n.videoFodenPhase2Watch,
    'videoFodenPhase3Title' => l10n.videoFodenPhase3Title,
    'videoFodenPhase3Watch' => l10n.videoFodenPhase3Watch,
    'videoDybalaControlTitle' => l10n.videoDybalaControlTitle,
    'videoDybalaControlFocus' => l10n.videoDybalaControlFocus,
    'videoDybalaControlPhase1Title' => l10n.videoDybalaControlPhase1Title,
    'videoDybalaControlPhase1Watch' => l10n.videoDybalaControlPhase1Watch,
    'videoDybalaControlPhase2Title' => l10n.videoDybalaControlPhase2Title,
    'videoDybalaControlPhase2Watch' => l10n.videoDybalaControlPhase2Watch,
    'videoDybalaControlPhase3Title' => l10n.videoDybalaControlPhase3Title,
    'videoDybalaControlPhase3Watch' => l10n.videoDybalaControlPhase3Watch,
    'videoHiguainTitle' => l10n.videoHiguainTitle,
    'videoHiguainFocus' => l10n.videoHiguainFocus,
    'videoHiguainPhase1Title' => l10n.videoHiguainPhase1Title,
    'videoHiguainPhase1Watch' => l10n.videoHiguainPhase1Watch,
    'videoHiguainPhase2Title' => l10n.videoHiguainPhase2Title,
    'videoHiguainPhase2Watch' => l10n.videoHiguainPhase2Watch,
    'videoHiguainPhase3Title' => l10n.videoHiguainPhase3Title,
    'videoHiguainPhase3Watch' => l10n.videoHiguainPhase3Watch,
    'videoDybalaDepthTitle' => l10n.videoDybalaDepthTitle,
    'videoDybalaDepthFocus' => l10n.videoDybalaDepthFocus,
    'videoDybalaDepthPhase1Title' => l10n.videoDybalaDepthPhase1Title,
    'videoDybalaDepthPhase1Watch' => l10n.videoDybalaDepthPhase1Watch,
    'videoDybalaDepthPhase2Title' => l10n.videoDybalaDepthPhase2Title,
    'videoDybalaDepthPhase2Watch' => l10n.videoDybalaDepthPhase2Watch,
    'videoDybalaDepthPhase3Title' => l10n.videoDybalaDepthPhase3Title,
    'videoDybalaDepthPhase3Watch' => l10n.videoDybalaDepthPhase3Watch,
    'videoRamseyTitle' => l10n.videoRamseyTitle,
    'videoRamseyFocus' => l10n.videoRamseyFocus,
    'videoRamseyPhase1Title' => l10n.videoRamseyPhase1Title,
    'videoRamseyPhase1Watch' => l10n.videoRamseyPhase1Watch,
    'videoRamseyPhase2Title' => l10n.videoRamseyPhase2Title,
    'videoRamseyPhase2Watch' => l10n.videoRamseyPhase2Watch,
    'videoRamseyPhase3Title' => l10n.videoRamseyPhase3Title,
    'videoRamseyPhase3Watch' => l10n.videoRamseyPhase3Watch,
    _ => l10n.videoLearningTitle,
  };
}
