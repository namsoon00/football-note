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
  static bool _licenseRegistered = false;

  late final AnimationController _controller;
  RealMatchReplayCatalog? _catalog;
  RealMatchReplayData? _data;
  RealMatchReplayCoachingPlan? _plan;
  Object? _loadError;
  int _sceneIndex = 0;
  int _loadGeneration = 0;
  int _playGeneration = 0;
  int? _targetMomentIndex;
  bool _playing = false;
  final Map<RealMatchReplayStep, RealMatchReplayActionDetail?> _actionDetails =
      Map<RealMatchReplayStep, RealMatchReplayActionDetail?>.identity();

  AppLocalizations get _l10n => AppLocalizations.of(context)!;
  double get _time => (_data?.duration ?? 0) * _controller.value;
  bool get _finished => _data != null && _time >= _data!.duration - 1e-6;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      animationBehavior: AnimationBehavior.preserve,
    )..addListener(_handleTick);
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
      _validateLoadedScene(catalog.scenes.first, data);
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
    _playGeneration++;
    _controller
      ..stop()
      ..value = 0;
    setState(() {
      _playing = false;
      _targetMomentIndex = null;
      _sceneIndex = index;
      _data = null;
      _plan = null;
      _loadError = null;
    });
    try {
      final entry = catalog.scenes[index];
      final data = await _loadSceneData(entry);
      if (!mounted || generation != _loadGeneration) return;
      _validateLoadedScene(entry, data);
      _applyLoaded(catalog, data, sceneIndex: index);
    } catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() => _loadError = error);
    }
  }

  void _validateLoadedScene(
    RealMatchReplayCatalogScene entry,
    RealMatchReplayData data,
  ) {
    if (data.scene.id != entry.id ||
        data.match.id != entry.matchId ||
        data.sourceCommit != entry.sourceCommit ||
        data.sourceUrl != entry.sourceUrl ||
        data.scene.titleKey != entry.titleKey ||
        data.scene.focusKey != entry.focusKey ||
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
      ..duration = _playbackDuration(data.duration)
      ..value = 0;
    setState(() {
      _actionDetails.clear();
      _catalog = catalog;
      _data = data;
      _plan = RealMatchReplayCoachingPlan.forData(data);
      _sceneIndex = sceneIndex;
      _loadError = null;
      _playing = false;
      _targetMomentIndex = null;
    });
  }

  Duration _playbackDuration(double seconds) =>
      Duration(milliseconds: (seconds * 1000).round());

  void _handleTick() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.inactive &&
        state != AppLifecycleState.paused &&
        state != AppLifecycleState.detached &&
        state != AppLifecycleState.hidden) {
      return;
    }
    _pausePlayback();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _loadGeneration++;
    _playGeneration++;
    _controller
      ..removeListener(_handleTick)
      ..dispose();
    super.dispose();
  }

  void _togglePlayback() {
    final data = _data;
    final plan = _plan;
    if (data == null || plan == null) return;
    if (_playing) {
      _pausePlayback();
      return;
    }
    if (_finished) {
      _playGeneration++;
      _targetMomentIndex = null;
      _controller.value = 0;
    }
    final pending = _targetMomentIndex;
    final nextIndex = pending != null &&
            pending < plan.moments.length &&
            plan.moments[pending].time > _time + 1e-6
        ? pending
        : plan.nextMomentIndex(_time);
    if (nextIndex == null) return;
    _playToMoment(nextIndex);
  }

  void _pausePlayback() {
    if (!_playing) return;
    _playGeneration++;
    _controller.stop();
    if (mounted) setState(() => _playing = false);
  }

  void _playToMoment(int momentIndex) {
    final data = _data;
    final plan = _plan;
    if (data == null || plan == null) return;
    final target = plan.moments[momentIndex].time;
    final remaining = math.max(0.001, target - _time);
    final generation = ++_playGeneration;
    setState(() {
      _targetMomentIndex = momentIndex;
      _playing = true;
    });
    unawaited(() async {
      try {
        await _controller
            .animateTo(
              target / data.duration,
              duration: _playbackDuration(remaining),
              curve: Curves.linear,
            )
            .orCancel;
      } on TickerCanceled {
        return;
      }
      if (!mounted || generation != _playGeneration) return;
      setState(() {
        _playing = false;
        _targetMomentIndex = null;
      });
    }());
  }

  Future<void> _openSource() async {
    final data = _data;
    if (data == null) return;
    final uri = Uri.parse(data.sourceUrl);
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
    final viewport = MediaQuery.sizeOf(context);
    final useSideControls = viewport.width > viewport.height &&
        viewport.height < 520 &&
        _data != null &&
        _catalog != null &&
        _plan != null &&
        _loadError == null;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: useSideControls
          ? null
          : AppBar(
              title: Text(_l10n.realMatchReplayAppBarTitle),
              backgroundColor: colors.surface,
              foregroundColor: colors.text,
              surfaceTintColor: Colors.transparent,
              actions: _viewerActions(),
            ),
      body:
          SafeArea(child: _buildBody(colors, useSideControls: useSideControls)),
    );
  }

  List<Widget> _viewerActions() {
    final catalog = _catalog;
    if (catalog == null) return const <Widget>[];
    return <Widget>[
      AppBarActionMenuButton<VoidCallback>(
        key: const ValueKey<String>('replay-more'),
        tooltip: _l10n.flowMore,
        icon: Icons.more_horiz,
        onOpened: _pausePlayback,
        onSelected: (action) => action(),
        itemBuilder: (context) => <PopupMenuEntry<VoidCallback>>[
          if (catalog.scenes.length > 1)
            PopupMenuItem<VoidCallback>(
              key: const ValueKey<String>('replay-choose-scene'),
              value: () => unawaited(_openSceneLibrary()),
              child: Text(_l10n.realMatchReplayChooseScene),
            ),
          if (_data != null)
            PopupMenuItem<VoidCallback>(
              key: const ValueKey<String>('replay-scene-info'),
              value: () => unawaited(_openSceneInfo()),
              child: Text(_l10n.realMatchReplaySceneInfo),
            ),
        ],
      ),
    ];
  }

  Widget _buildBody(_ScanPassColors colors, {required bool useSideControls}) {
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
    final plan = _plan;
    if (data == null || catalog == null || plan == null) {
      return Center(
        child: Semantics(
          label: _l10n.realMatchReplayLoading,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    return LayoutBuilder(builder: (context, constraints) {
      if (useSideControls) {
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: _buildField(data, plan)),
            const SizedBox(width: 12),
            SizedBox(
              width: math.min(260, math.max(232, constraints.maxWidth * .26)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    if (Navigator.of(context).canPop())
                      BackButton(color: colors.text),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          _l10n.realMatchReplayAppBarTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                    ..._viewerActions(),
                  ]),
                  const SizedBox(height: 12),
                  _buildSituationTitle(data, colors,
                      compact: false, extended: true),
                  const Spacer(),
                  _buildPrimaryControl(colors, compact: true),
                ],
              ),
            ),
          ]),
        );
      }
      final shortLandscape = constraints.maxWidth > constraints.maxHeight &&
          constraints.maxHeight < 520;
      return Padding(
        padding: EdgeInsets.fromLTRB(8, shortLandscape ? 4 : 8, 8, 8),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSituationTitle(data, colors, compact: shortLandscape),
                const SizedBox(height: 4),
                Expanded(child: _buildField(data, plan)),
                _buildPrimaryControl(colors, compact: shortLandscape),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSituationTitle(
    RealMatchReplayData data,
    _ScanPassColors colors, {
    required bool compact,
    bool extended = false,
  }) {
    final title = Text(
      _sceneTitle(_l10n, data.scene.titleKey),
      key: const ValueKey<String>('replay-scene-title'),
      maxLines: compact
          ? 1
          : extended
              ? 3
              : 2,
      overflow: TextOverflow.ellipsis,
      style: (compact
              ? Theme.of(context).textTheme.titleMedium
              : Theme.of(context).textTheme.titleLarge)
          ?.copyWith(color: colors.text, fontWeight: FontWeight.w600),
    );
    final match = Text(
      _l10n.realMatchReplaySelectedMatch(
        data.match.home,
        data.match.away,
      ),
      key: const ValueKey<String>('replay-scene-match'),
      maxLines: extended ? 2 : 1,
      overflow: TextOverflow.ellipsis,
      style:
          Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.muted),
    );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: compact ? 1 : 3),
      child: compact
          ? Row(children: [
              Expanded(flex: 3, child: title),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: match),
            ])
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, match],
            ),
    );
  }

  Widget _buildField(
    RealMatchReplayData data,
    RealMatchReplayCoachingPlan plan,
  ) {
    final momentIndex = plan.momentIndexAt(_time);
    final moment = plan.activeMomentAt(data, _time);
    final step = moment.step;
    final stepLabel = _stepLabel(_l10n, step.kind, step.runType);
    final cue = _coachingCue(_l10n, data, moment);
    // Short source actions can share a teaching stop. Inspect the action
    // actually playing, including a carry shortly after a reception.
    final detailStep = data.stepAt(_time);
    final detailStepLabel =
        _stepLabel(_l10n, detailStep.kind, detailStep.runType);
    final detail = _actionDetails.putIfAbsent(
      detailStep,
      () => RealMatchReplayActionDetail.forStep(data, detailStep),
    );
    final camera = data.displayOverviewCamera;
    final showsReconstructedPositions =
        data.displaySample(_time).hasReconstructedPositions;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(children: [
        Positioned.fill(
          child: Semantics(
            image: true,
            label: data.hasDisplayReconstruction
                ? _l10n.realMatchReplayPitchSemanticsReconstructed(
                    data.match.home,
                    data.match.away,
                    _sceneTitle(_l10n, data.scene.titleKey),
                  )
                : _l10n.realMatchReplayPitchSemanticsGeneric(
                    data.match.home,
                    data.match.away,
                    _sceneTitle(_l10n, data.scene.titleKey),
                  ),
            value: cue,
            child: ExcludeSemantics(
              child: CustomPaint(
                key: const ValueKey<String>('replay-pitch'),
                painter: _RealMatchReplayPainter(
                  data: data,
                  plan: plan,
                  moment: moment,
                  time: _time,
                  camera: camera,
                  cue: cue,
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
          left: 10,
          right: 10,
          top: 9,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: _buildActionBadge(
              data: data,
              detail: detail,
              momentIndex: momentIndex,
              momentCount: plan.moments.length,
              stepLabel: detail == null ? stepLabel : detailStepLabel,
            ),
          ),
        ),
        if (showsReconstructedPositions)
          PositionedDirectional(
            key: const ValueKey<String>('replay-reconstructed-legend'),
            end: 10,
            bottom: 8,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF183B2E).withValues(alpha: .94),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 12,
                      height: 7,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFF4F8ED),
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _l10n.realMatchReplayReconstructedLegend,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: const Color(0xFFF4F8ED),
                          ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _buildActionBadge({
    required RealMatchReplayData data,
    required RealMatchReplayActionDetail? detail,
    required int momentIndex,
    required int momentCount,
    required String stepLabel,
  }) {
    final count = _l10n.realMatchReplayActionCount(
      momentIndex + 1,
      momentCount,
      stepLabel,
    );
    final style = Theme.of(context)
        .textTheme
        .labelSmall
        ?.copyWith(color: const Color(0xFFF4F8ED));
    final decoration = BoxDecoration(
      color: const Color(0xFF183B2E).withValues(alpha: .94),
      borderRadius: BorderRadius.circular(7),
    );
    if (detail == null) {
      return IgnorePointer(
        child: DecoratedBox(
          decoration: decoration,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            child: Text(
              count,
              key: ValueKey<String>('replay-moment-$momentIndex'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ),
      );
    }
    final openLabel = _l10n.realMatchReplayOpenActionDetailLabel(stepLabel);
    return Tooltip(
      message: openLabel,
      child: Semantics(
        button: true,
        label: openLabel,
        child: Material(
          key: ValueKey<String>('replay-moment-$momentIndex'),
          color: Colors.transparent,
          child: Ink(
            decoration: decoration,
            child: InkWell(
              key: const ValueKey<String>('replay-action-detail-open'),
              borderRadius: BorderRadius.circular(7),
              onTap: () => unawaited(_openActionDetail(data, detail)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Flexible(
                      child: Text(
                        count,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: style,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.zoom_in,
                      size: 16,
                      color: Color(0xFFF4F8ED),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _l10n.realMatchReplayActionDetailAffordance,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: style?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openActionDetail(
    RealMatchReplayData data,
    RealMatchReplayActionDetail detail,
  ) async {
    _pausePlayback();
    final sourceTime = _time;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _ReplayActionDetailSheet(
        data: data,
        detail: detail,
        openedAtSourceTime: sourceTime,
      ),
      constraints: const BoxConstraints(maxWidth: 1100),
    );
  }

  Widget _buildPrimaryControl(
    _ScanPassColors colors, {
    required bool compact,
  }) {
    final label = _playing
        ? _l10n.realMatchReplayPauseAction
        : _finished
            ? _l10n.realMatchReplayReplayAction
            : _l10n.realMatchReplayNextAction;
    return Padding(
      padding: EdgeInsets.fromLTRB(8, compact ? 5 : 9, 8, compact ? 1 : 3),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 150, maxWidth: 280),
          child: FilledButton.icon(
            key: const ValueKey<String>('replay-play'),
            onPressed: _togglePlayback,
            icon: Icon(
              _playing
                  ? Icons.pause
                  : _finished
                      ? Icons.replay
                      : Icons.play_arrow,
              size: 19,
            ),
            label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            style: FilledButton.styleFrom(
              minimumSize: Size(0, compact ? 44 : 48),
              maximumSize: const Size(280, 56),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openSceneLibrary() async {
    final catalog = _catalog;
    if (catalog == null) return;
    _pausePlayback();
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

  Future<void> _openSceneInfo() async {
    final data = _data;
    final catalog = _catalog;
    if (data == null || catalog == null) return;
    _pausePlayback();
    final entry = catalog.scenes[_sceneIndex];
    final colors = _ScanPassColors.of(context);
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * .9,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            key: const ValueKey<String>('replay-info-scroll'),
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Expanded(
                  child: Text(
                    _l10n.realMatchReplaySceneInfo,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                AppBarActionButton(
                  compact: true,
                  margin: EdgeInsets.zero,
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.pop(sheetContext),
                  icon: const Icon(Icons.close),
                ),
              ]),
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  _sceneTitle(_l10n, data.scene.titleKey),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 7,
                runSpacing: 5,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _ReplayTeamDot(color: _replayColor(data.scene.homeColor)),
                  Text(data.match.home),
                  Text(_l10n.realMatchReplayVersus),
                  _ReplayTeamDot(
                    color: _replayColor(data.scene.awayColor),
                    outlined: true,
                  ),
                  Text(data.match.away),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  _l10n.realMatchReplaySceneDateClock(
                    entry.date,
                    _l10n.realMatchReplayMatchClock(
                      _matchClock(entry.startClock),
                      _matchClock(entry.startClock + entry.duration),
                    ),
                  ),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: colors.muted),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  data.coverage == RealMatchReplayCoverage.broadcastVisible
                      ? _l10n.realMatchReplayBroadcastDisclosure
                      : data.hasRecordedPose
                          ? _l10n.realMatchReplayDisclosure
                          : _l10n.realMatchReplayTrackingDisclosure,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: colors.muted),
                ),
              ),
              if (!data.ballHeightAvailable) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    _l10n.realMatchReplayBallHeightUnavailable,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: colors.muted),
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  _l10n.realMatchReplaySourceCommit(data.sourceCommit),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: colors.muted),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  key: const ValueKey<String>('replay-source'),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    unawaited(_openSource());
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(Icons.open_in_new, size: 17),
                      const SizedBox(width: 8),
                      Text(_l10n.realMatchReplaySource),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
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
                          l10n.realMatchReplaySelectedMatch(
                            scene.home,
                            scene.away,
                          ),
                          l10n.realMatchReplaySceneDateClock(
                            scene.date,
                            _formatCatalogClock(scene.startClock),
                          ),
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

class _RealMatchReplayPainter extends CustomPainter {
  final RealMatchReplayData data;
  final RealMatchReplayCoachingPlan plan;
  final RealMatchReplayCoachingMoment moment;
  final double time;
  final RealMatchReplayCamera camera;
  final String cue;
  final Brightness brightness;
  final TextDirection textDirection;
  final TextScaler textScaler;
  final RealMatchReplayActionDetail? actionDetail;

  const _RealMatchReplayPainter({
    required this.data,
    required this.plan,
    required this.moment,
    required this.time,
    required this.camera,
    required this.cue,
    required this.brightness,
    required this.textDirection,
    required this.textScaler,
    this.actionDetail,
  });

  bool get isActionDetail => actionDetail != null;
  double get bodyScaleMinimum => isActionDetail ? 38 : 15;
  double get bodyScaleMaximum => isActionDetail ? 54 : 32;
  double get bodyScaleFactor => isActionDetail ? 1.9 : 1.45;

  bool get _dark => brightness == Brightness.dark;
  Color get _pitch => _dark ? const Color(0xFF183D2B) : const Color(0xFF214936);
  Color get _stripe =>
      _dark ? const Color(0xFF235034) : const Color(0xFF254E3B);
  Color get _line => _dark ? const Color(0xFFA9C6AE) : const Color(0xFFC2D4C4);
  Color get _surface =>
      _dark ? const Color(0xFF112D22) : const Color(0xFF183B2E);
  Color get _text => const Color(0xFFF4F8ED);
  Color get _good => const Color(0xFFD4EF9D);
  Color get _pressure => const Color(0xFFF5AC92);
  Color get _shadow => const Color(0xFF102E23);

  @override
  void paint(Canvas canvas, Size size) {
    final sourceSample = data.renderSample(time);
    final displaySample = isActionDetail
        ? RealMatchReplayDisplaySample(
            time: sourceSample.time,
            sourceFrame: sourceSample.sourceFrame,
            players: sourceSample.players,
            reconstructed: List<bool>.filled(data.players.length, false),
            ball: sourceSample.ball,
          )
        : data.displaySample(time);
    final geometry = ReplayPitchGeometry.forSize(
      size,
      camera: camera,
      attackDirection: data.scene.attackDirection,
      view: isActionDetail
          ? ReplayPitchView.actionDetail
          : ReplayPitchView.coaching,
      pitchLength: data.pitchLength,
      pitchWidth: data.pitchWidth,
      fitPlayerBodies: true,
      bodyScaleMinimum: bodyScaleMinimum,
      bodyScaleMaximum: bodyScaleMaximum,
      bodyScaleFactor: bodyScaleFactor,
      rotatePitch: size.width < size.height,
      headerInset: isActionDetail
          ? textScaler.scale(14) + 28
          : math.max(
              56, textScaler.scale(size.width > size.height ? 16 : 28) + 22),
      bottomInset: !isActionDetail && displaySample.hasReconstructedPositions
          ? textScaler.scale(14) + (size.width > size.height ? 22 : 31)
          : isActionDetail
              ? textScaler.scale(12) + 28
              : 18,
    );
    _drawPitch(canvas, size, geometry);
    if (isActionDetail) {
      _drawActionDetailTrails(canvas, geometry);
    }
    final mark = isActionDetail
        ? null
        : _drawCoachingCue(canvas, geometry, sourceSample);
    final occupied = _drawPeople(canvas, geometry, displaySample);
    _drawBall(canvas, geometry, sourceSample.ball);
    if (mark != null) {
      _drawLabel(canvas, size, geometry, sourceSample, mark, occupied);
    }
  }

  void _drawActionDetailTrails(
    Canvas canvas,
    ReplayPitchGeometry geometry,
  ) {
    final detail = actionDetail!;
    final actionTime = detail.step.time.clamp(detail.start, detail.end);
    switch (detail.step.kind) {
      case RealMatchReplayStepKind.receive:
        _drawPlayerTrail(
          canvas,
          geometry,
          detail.actorIndex,
          detail.start,
          actionTime,
          _text.withValues(alpha: .74),
          sourceOnly: true,
        );
        _drawPlayerTrail(
          canvas,
          geometry,
          detail.actorIndex,
          actionTime,
          detail.end,
          _good,
          sourceOnly: true,
        );
        _drawBallTrail(
          canvas,
          geometry,
          detail.start,
          detail.end,
          _pressure,
        );
        break;
      case RealMatchReplayStepKind.pass:
        _drawPlayerTrail(
          canvas,
          geometry,
          detail.actorIndex,
          detail.start,
          actionTime,
          _good,
          sourceOnly: true,
        );
        _drawBallTrail(
          canvas,
          geometry,
          actionTime,
          detail.end,
          _pressure,
        );
        break;
      case RealMatchReplayStepKind.carry:
        _drawPlayerTrail(
          canvas,
          geometry,
          detail.actorIndex,
          actionTime,
          detail.end,
          _good,
          sourceOnly: true,
        );
        _drawBallTrail(
          canvas,
          geometry,
          actionTime,
          detail.end,
          _pressure,
        );
        break;
      case RealMatchReplayStepKind.observe:
      case RealMatchReplayStepKind.run:
      case RealMatchReplayStepKind.pressure:
      case RealMatchReplayStepKind.outcome:
        break;
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

  _ReplayMark _drawCoachingCue(
    Canvas canvas,
    ReplayPitchGeometry geometry,
    RealMatchReplaySample sample,
  ) {
    final step = moment.step;
    final momentIndex = plan.moments.indexOf(moment);
    final nextTime = momentIndex >= 0 && momentIndex + 1 < plan.moments.length
        ? plan.moments[momentIndex + 1].time
        : data.duration;
    final trailEnd = math.min(
      nextTime,
      math.min(
        step.end ?? data.duration,
        step.kind == RealMatchReplayStepKind.outcome
            ? moment.time + 2.8
            : math.max(time, moment.time + 2.8),
      ),
    );
    final tone =
        step.kind == RealMatchReplayStepKind.pressure ? _pressure : _good;
    RealMatchReplayPoint anchor;
    switch (step.kind) {
      case RealMatchReplayStepKind.pass:
      case RealMatchReplayStepKind.outcome:
        _drawBallTrail(canvas, geometry, moment.time, trailEnd, tone);
        anchor = data.sample(trailEnd).ball;
        break;
      case RealMatchReplayStepKind.run:
        final actorIndex = data.playerIndex(step.actorId);
        _drawPlayerTrail(
          canvas,
          geometry,
          actorIndex,
          moment.time,
          trailEnd,
          tone,
        );
        anchor =
            _lastVisiblePoint(actorIndex, moment.time, trailEnd) ?? sample.ball;
        break;
      case RealMatchReplayStepKind.carry:
      case RealMatchReplayStepKind.receive:
        final actorIndex = data.playerIndex(step.actorId);
        _drawPlayerTrail(
          canvas,
          geometry,
          actorIndex,
          moment.time,
          trailEnd,
          tone,
        );
        anchor = step.kind == RealMatchReplayStepKind.receive
            ? sample.players[actorIndex] ??
                data.playerPointAt(moment.time, step.actorId) ??
                sample.ball
            : _lastVisiblePoint(actorIndex, moment.time, trailEnd) ??
                sample.ball;
        break;
      case RealMatchReplayStepKind.pressure:
        final pressureId = step.secondaryId ?? step.actorId;
        final pressureIndex = data.playerIndex(pressureId);
        _drawPlayerTrail(
          canvas,
          geometry,
          pressureIndex,
          moment.time,
          trailEnd,
          tone,
        );
        anchor = _lastVisiblePoint(pressureIndex, moment.time, trailEnd) ??
            sample.ball;
        break;
      case RealMatchReplayStepKind.observe:
        final targetId = step.targetId ?? step.actorId;
        anchor = sample.players[data.playerIndex(targetId)] ??
            data.playerPointAt(moment.time, targetId) ??
            sample.ball;
        break;
    }
    return _ReplayMark(cue, anchor, tone);
  }

  void _drawPlayerTrail(Canvas canvas, ReplayPitchGeometry geometry,
      int playerIndex, double from, double to, Color color,
      {bool sourceOnly = false}) {
    if (to <= from) return;
    final segments = <List<RealMatchReplayPoint>>[];
    var points = <RealMatchReplayPoint>[];
    void add(RealMatchReplayPoint? point) {
      if (point == null) {
        if (points.length >= 2) segments.add(points);
        points = <RealMatchReplayPoint>[];
        return;
      }
      points.add(point);
    }

    for (var cursor = from; cursor < to; cursor += .12) {
      add((sourceOnly ? data.sample(cursor) : data.renderSample(cursor))
          .players[playerIndex]);
    }
    add((sourceOnly ? data.sample(to) : data.renderSample(to))
        .players[playerIndex]);
    if (points.length >= 2) segments.add(points);
    for (var index = 0; index < segments.length; index++) {
      _drawWorldPath(
        canvas,
        geometry,
        segments[index],
        color.withValues(alpha: .82),
        2,
        dashed: true,
        arrow: index == segments.length - 1,
      );
    }
  }

  RealMatchReplayPoint? _lastVisiblePoint(
    int playerIndex,
    double from,
    double to,
  ) {
    for (var cursor = to; cursor >= from; cursor -= .05) {
      final point = data.renderSample(cursor).players[playerIndex];
      if (point != null) return point;
    }
    return data.renderSample(from).players[playerIndex];
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
    RealMatchReplayDisplaySample sample,
  ) {
    final entries = <int>[
      for (var index = 0; index < data.players.length; index++)
        if (sample.players[index] != null &&
            (!isActionDetail || index == actionDetail!.actorIndex))
          index,
    ]..sort((a, b) => geometry
        .project(sample.players[a]!.x, sample.players[a]!.y)
        .dy
        .compareTo(
            geometry.project(sample.players[b]!.x, sample.players[b]!.y).dy));
    final occupied = <Rect>[];
    final bodyScale = math.max(
      bodyScaleMinimum,
      math.min(bodyScaleMaximum, geometry.scale * bodyScaleFactor),
    );
    final step = moment.step;
    for (final index in entries) {
      final base = sample.players[index]!;
      final ground = geometry.project(base.x, base.y);
      canvas.drawOval(
        Rect.fromCenter(center: ground.translate(0, 1), width: 16, height: 6),
        Paint()..color = _shadow.withValues(alpha: .2),
      );
      if (sample.reconstructed[index]) {
        canvas.drawOval(
          Rect.fromCenter(center: ground.translate(0, 1), width: 13, height: 6),
          Paint()
            ..color = _text.withValues(alpha: .86)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.1,
        );
      }
      final measured = isActionDetail && !actionDetail!.hasRecordedPose
          ? null
          : data.poseAt(time, index);
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
          player.id == step.actorId ||
          player.id == step.secondaryId) {
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
    final playerNumber = player.number;
    if (playerNumber != null) {
      final numberPainter = TextPainter(
        text: TextSpan(
          text: '$playerNumber',
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
    }
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

  void _drawLabel(
    Canvas canvas,
    Size size,
    ReplayPitchGeometry geometry,
    RealMatchReplaySample sample,
    _ReplayMark mark,
    List<Rect> occupied,
  ) {
    final painter = TextPainter(
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
      ellipsis: '…',
    )..layout(maxWidth: math.min(160, size.width * .54));
    final anchor = geometry.project(mark.at.x, mark.at.y, mark.at.z);
    final ball = geometry.project(sample.ball.x, sample.ball.y, sample.ball.z);
    final step = moment.step;
    final importantPoints = <RealMatchReplayPoint>[
      for (final id in <int>{
        data.scene.focusPlayerId,
        step.actorId,
        if (step.targetId != null) step.targetId!,
        if (step.secondaryId != null) step.secondaryId!,
      })
        if (sample.players[data.playerIndex(id)] case final point?) point,
    ];
    final protected = <Rect>[
      Rect.fromCircle(center: ball, radius: 10),
      for (final point in importantPoints)
        Rect.fromCenter(
          center: geometry.project(point.x, point.y).translate(0, -16),
          width: 38,
          height: 56,
        ),
    ];
    final rects = ReplayLabelLayout.place(
      stageSize: size,
      topInset: textScaler.scale(28) + 28,
      bottomInset: geometry.bottomInset + 4,
      labelSizes: <Size>[Size(painter.width + 16, painter.height + 12)],
      anchors: <Offset>[anchor],
      obstacles: <Rect>[
        ...occupied,
        ...protected,
      ],
      protectedObstacles: protected,
    );
    final rect = rects.single;
    if (rect.isEmpty) {
      painter.dispose();
      return;
    }
    final edge = Offset(
      anchor.dx.clamp(rect.left, rect.right),
      anchor.dy.clamp(rect.top, rect.bottom),
    );
    canvas.drawLine(
      edge,
      anchor,
      Paint()
        ..color = mark.tone
        ..strokeWidth = 1,
    );
    canvas.drawCircle(anchor, 2.2, Paint()..color = mark.tone);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      Paint()..color = _surface.withValues(alpha: .96),
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.top + 5, 2, rect.height - 10),
      Paint()..color = mark.tone,
    );
    painter.paint(canvas, rect.topLeft + const Offset(8, 6));
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant _RealMatchReplayPainter oldDelegate) =>
      data != oldDelegate.data ||
      plan != oldDelegate.plan ||
      moment != oldDelegate.moment ||
      time != oldDelegate.time ||
      camera != oldDelegate.camera ||
      cue != oldDelegate.cue ||
      brightness != oldDelegate.brightness ||
      textDirection != oldDelegate.textDirection ||
      textScaler != oldDelegate.textScaler ||
      actionDetail != oldDelegate.actionDetail;
}

class _ReplayMark {
  final String text;
  final RealMatchReplayPoint at;
  final Color tone;

  const _ReplayMark(this.text, this.at, this.tone);
}

Color _replayColor(String value) {
  final hex = value.substring(1);
  final parsed = int.parse(hex, radix: 16);
  return Color(hex.length == 6 ? 0xFF000000 | parsed : parsed);
}

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

String _coachingCue(
  AppLocalizations l10n,
  RealMatchReplayData data,
  RealMatchReplayCoachingMoment moment,
) {
  final step = moment.step;
  final actor = data.player(step.actorId).number!;
  final target =
      step.targetId == null ? null : data.player(step.targetId!).number!;
  final secondary =
      step.secondaryId == null ? null : data.player(step.secondaryId!).number!;
  return switch (moment.cue) {
    RealMatchReplayCoachingCue.observeTarget =>
      l10n.realMatchReplayCueObserve(actor, target!),
    RealMatchReplayCoachingCue.observeSpace =>
      l10n.realMatchReplayCueObserveSpace(actor),
    RealMatchReplayCoachingCue.carry => l10n.realMatchReplayCueCarry(actor),
    RealMatchReplayCoachingCue.carryTurn =>
      l10n.realMatchReplayCueCarryTurn(actor),
    RealMatchReplayCoachingCue.pass => target == null
        ? l10n.realMatchReplayCuePassSpace(actor)
        : l10n.realMatchReplayCuePass(actor, target),
    RealMatchReplayCoachingCue.passIntoRun =>
      l10n.realMatchReplayCuePassIntoRun(actor, target!),
    RealMatchReplayCoachingCue.receive => l10n.realMatchReplayCueReceive(actor),
    RealMatchReplayCoachingCue.run => l10n.realMatchReplayCueRun(actor),
    RealMatchReplayCoachingCue.runBehind =>
      l10n.realMatchReplayCueRunBehind(actor),
    RealMatchReplayCoachingCue.overlap => l10n.realMatchReplayCueOverlap(actor),
    RealMatchReplayCoachingCue.underlap =>
      l10n.realMatchReplayCueUnderlap(actor),
    RealMatchReplayCoachingCue.crossArrival =>
      l10n.realMatchReplayCueCrossArrival(actor),
    RealMatchReplayCoachingCue.pressure => secondary == null
        ? l10n.realMatchReplayCuePressureAround(actor)
        : l10n.realMatchReplayCuePressure(secondary, actor),
    RealMatchReplayCoachingCue.outcome => l10n.realMatchReplayCueOutcome(
        _replayOutcomeLabel(l10n, data.scene.outcome),
      ),
  };
}

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
      'replaySceneDeBruynePressureReceive' =>
        l10n.replaySceneDeBruynePressureReceive,
      'replaySceneSalahRightRecycle' => l10n.replaySceneSalahRightRecycle,
      'replaySceneMessiRightConnection' => l10n.replaySceneMessiRightConnection,
      'replaySceneKroosCentralRecycle' => l10n.replaySceneKroosCentralRecycle,
      'replaySceneViniciusCarryInside' => l10n.replaySceneViniciusCarryInside,
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
      'replayFocusDeBruynePressureReceive' =>
        l10n.replayFocusDeBruynePressureReceive,
      'replayFocusSalahRightRecycle' => l10n.replayFocusSalahRightRecycle,
      'replayFocusMessiRightConnection' => l10n.replayFocusMessiRightConnection,
      'replayFocusKroosCentralRecycle' => l10n.replayFocusKroosCentralRecycle,
      'replayFocusViniciusCarryInside' => l10n.replayFocusViniciusCarryInside,
      _ => key,
    };
