part of 'scan_pass_game_screen.dart';

typedef MatchMomentSourceLauncher = Future<bool> Function(Uri uri);

enum _MatchMomentMode {
  leading,
  choosing,
  executing,
  review,
  replaying,
  compare
}

class ScanPassMatchMomentScreen extends StatefulWidget {
  final MatchMomentEpisode episode;
  final Duration leadInDuration;
  final Duration actionDuration;
  final MatchMomentSourceLauncher? sourceLauncher;
  final bool referenceOnly;

  const ScanPassMatchMomentScreen({
    super.key,
    this.episode = const MatchMomentEpisode(),
    this.leadInDuration = const Duration(milliseconds: 1200),
    this.actionDuration = const Duration(milliseconds: 1250),
    this.sourceLauncher,
    this.referenceOnly = false,
  });

  @override
  State<ScanPassMatchMomentScreen> createState() =>
      _ScanPassMatchMomentScreenState();
}

class _ScanPassMatchMomentScreenState extends State<ScanPassMatchMomentScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  late MatchMomentFrame _current;

  _MatchMomentMode _mode = _MatchMomentMode.leading;
  MatchMomentBeat _beat = MatchMomentBeat.receive;
  List<MatchMomentChoiceId> _choices = const <MatchMomentChoiceId>[];
  List<MatchMomentSegment> _history = const <MatchMomentSegment>[];
  List<MatchMomentSegment> _activeSegments = const <MatchMomentSegment>[];
  MatchMomentChoiceId? _activeChoice;
  MatchMomentAttempt? _attempt;
  bool _foreground = true;
  bool _modalOpen = false;
  bool _manualPlaybackPause = false;

  bool get _busy =>
      _mode == _MatchMomentMode.leading ||
      _mode == _MatchMomentMode.executing ||
      _mode == _MatchMomentMode.replaying ||
      (_mode == _MatchMomentMode.compare && _activeSegments.isNotEmpty);

  AppLocalizations get _l10n => AppLocalizations.of(context)!;
  bool get _portraitView {
    final size = MediaQuery.sizeOf(context);
    return size.width < size.height;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(vsync: this)
      ..addStatusListener(_handleAnimationStatus);
    _current = widget.episode.initialFrame;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.referenceOnly) {
        _startReferenceOnly();
      } else {
        _startLeadIn();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _foreground = false;
      _controller.stop();
      return;
    }
    if (state != AppLifecycleState.resumed) return;
    _foreground = true;
    _resumeAnimation();
  }

  void _startLeadIn() {
    _current = widget.episode.initialFrame;
    _choices = const <MatchMomentChoiceId>[];
    _history = const <MatchMomentSegment>[];
    _attempt = null;
    _beat = MatchMomentBeat.receive;
    _mode = _MatchMomentMode.leading;
    _activeChoice = null;
    _manualPlaybackPause = false;
    _playSegments([widget.episode.leadIn], widget.leadInDuration);
  }

  void _startReferenceOnly() {
    final reference = widget.episode.historicalAttempt;
    setState(() {
      _current = widget.episode.initialFrame;
      _choices = const <MatchMomentChoiceId>[];
      _history = const <MatchMomentSegment>[];
      _attempt = null;
      _mode = _MatchMomentMode.compare;
      _activeChoice = null;
      _manualPlaybackPause = false;
    });
    final segments = [widget.episode.leadIn, ...reference.segments];
    _playSegments(segments, _durationFor(segments));
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    final completed = _activeSegments;
    if (completed.isEmpty) return;
    final lastFrame = completed.last.after;
    setState(() {
      _activeSegments = const <MatchMomentSegment>[];
      _controller.value = 0;
      if (_mode == _MatchMomentMode.leading) {
        _current = lastFrame;
        _mode = _MatchMomentMode.choosing;
        _beat = MatchMomentBeat.receive;
      } else if (_mode == _MatchMomentMode.executing) {
        _current = lastFrame;
        _history = List.unmodifiable([..._history, ...completed]);
        if (_choices.length == 3) {
          _attempt = widget.episode.buildAttempt(_choices);
          _mode = _MatchMomentMode.review;
        } else {
          _beat = _choices.length == 1
              ? MatchMomentBeat.firstTouch
              : MatchMomentBeat.nextAction;
          _mode = _MatchMomentMode.choosing;
        }
      } else if (_mode == _MatchMomentMode.replaying) {
        _mode = _MatchMomentMode.review;
        _current = _attempt?.finalFrame ?? _current;
      } else if (_mode == _MatchMomentMode.compare) {
        _current = widget.episode.historicalAttempt.finalFrame;
      }
      _activeChoice = null;
    });
  }

  void _playSegments(List<MatchMomentSegment> segments, Duration duration) {
    _controller.stop();
    setState(() {
      _activeSegments = List.unmodifiable(segments);
      _manualPlaybackPause = false;
    });
    final resolvedDuration =
        duration == Duration.zero || AppMotion.reduceMotion(context)
            ? Duration.zero
            : duration;
    _controller.duration = resolvedDuration;
    if (resolvedDuration == Duration.zero) {
      _controller.value = 1;
      _handleAnimationStatus(AnimationStatus.completed);
      return;
    }
    _controller.value = 0;
    _resumeAnimation();
  }

  void _resumeAnimation() {
    if (!_foreground ||
        _modalOpen ||
        _manualPlaybackPause ||
        _activeSegments.isEmpty ||
        _controller.isCompleted) {
      return;
    }
    unawaited(_controller.forward());
  }

  void _togglePlaybackPause() {
    if (_activeSegments.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _manualPlaybackPause = !_manualPlaybackPause;
      if (_manualPlaybackPause) {
        _controller.stop();
      }
    });
    if (!_manualPlaybackPause) _resumeAnimation();
  }

  void _stepPlayback(int direction) {
    if (_activeSegments.isEmpty) return;
    final snapshot = _playbackSnapshot;
    if (snapshot == null) return;
    HapticFeedback.selectionClick();
    var targetIndex = snapshot.index;
    if (direction < 0) {
      targetIndex =
          snapshot.localProgress > .08 ? snapshot.index : snapshot.index - 1;
    } else if (direction > 0) {
      targetIndex = snapshot.index + 1;
    }
    final lastIndex = _activeSegments.length - 1;
    final clampedIndex = targetIndex.clamp(0, lastIndex).toInt();
    var target = direction > 0 && snapshot.index == lastIndex
        ? _progressForSegmentEnd(lastIndex)
        : _progressForSegmentStart(clampedIndex);
    if (direction > 0 && clampedIndex > snapshot.index) {
      target += .000001;
    }
    setState(() {
      _manualPlaybackPause = true;
      _controller.stop();
      _controller.value = target.clamp(0.0, .999999).toDouble();
    });
  }

  double _progressForSegmentStart(int index) {
    final total = _activeDuration;
    if (total <= 0) return 0;
    var elapsed = 0.0;
    for (var i = 0; i < index && i < _activeSegments.length; i += 1) {
      elapsed += _activeSegments[i].duration;
    }
    return elapsed / total;
  }

  double _progressForSegmentEnd(int index) {
    final total = _activeDuration;
    if (total <= 0) return 1;
    var elapsed = 0.0;
    for (var i = 0; i <= index && i < _activeSegments.length; i += 1) {
      elapsed += _activeSegments[i].duration;
    }
    return elapsed / total;
  }

  double get _activeDuration => _activeSegments.fold<double>(
        0,
        (sum, segment) => sum + segment.duration,
      );

  _MatchPlaybackSnapshot? get _playbackSnapshot {
    if (_activeSegments.isEmpty) return null;
    final total = _activeDuration;
    if (total <= 0) {
      return _MatchPlaybackSnapshot(
        index: _activeSegments.length - 1,
        localProgress: 1,
        segment: _activeSegments.last,
        completedBefore: _activeSegments.take(_activeSegments.length - 1),
      );
    }
    var elapsed = total * _controller.value.clamp(0.0, 1.0).toDouble();
    for (var index = 0; index < _activeSegments.length; index += 1) {
      final segment = _activeSegments[index];
      if (elapsed < segment.duration || index == _activeSegments.length - 1) {
        final local = segment.duration <= 0 ? 1.0 : elapsed / segment.duration;
        return _MatchPlaybackSnapshot(
          index: index,
          localProgress: local.clamp(0.0, 1.0).toDouble(),
          segment: segment,
          completedBefore: _activeSegments.take(index),
        );
      }
      elapsed -= segment.duration;
    }
    return null;
  }

  void _choose(MatchMomentChoiceId id) {
    if (_mode != _MatchMomentMode.choosing || _busy) return;
    final branch = widget.episode.applyChoice(_current, _choices, id);
    HapticFeedback.selectionClick();
    setState(() {
      _choices = List.unmodifiable([..._choices, id]);
      _activeChoice = id;
      _mode = _MatchMomentMode.executing;
    });
    _playSegments(branch.segments, _durationFor(branch.segments));
  }

  Duration _durationFor(List<MatchMomentSegment> segments) {
    if (widget.actionDuration == Duration.zero) return Duration.zero;
    final seconds = segments.fold<double>(
      0,
      (sum, segment) => sum + segment.duration,
    );
    return Duration(
      milliseconds: math.max(
        1,
        (seconds * widget.actionDuration.inMilliseconds).round(),
      ),
    );
  }

  MatchMomentFrame get _displayFrame {
    if (_activeSegments.isNotEmpty) {
      return _frameForProgress(_activeSegments, _controller.value);
    }
    if (_mode == _MatchMomentMode.compare) {
      return widget.episode.historicalAttempt.finalFrame;
    }
    return _current;
  }

  MatchMomentFrame _frameForProgress(
    List<MatchMomentSegment> segments,
    double progress,
  ) {
    final total = segments.fold<double>(
      0,
      (sum, segment) => sum + segment.duration,
    );
    var elapsed = total * progress.clamp(0.0, 1.0).toDouble();
    for (final segment in segments) {
      if (elapsed <= segment.duration) {
        final local = segment.duration == 0 ? 1.0 : elapsed / segment.duration;
        return segment.frame(local);
      }
      elapsed -= segment.duration;
    }
    return segments.last.after;
  }

  void _retryLastDecision() {
    final attempt = _attempt;
    if (attempt == null || _busy) return;
    final prefixChoices = attempt.choices.take(2).toList(growable: false);
    final prefixSegments = attempt.segments
        .where((segment) =>
            segment.choiceId == MatchMomentChoiceId.receiveInside ||
            segment.choiceId == MatchMomentChoiceId.receiveWide ||
            segment.choiceId == MatchMomentChoiceId.receiveCheck ||
            segment.choiceId == MatchMomentChoiceId.touchInside ||
            segment.choiceId == MatchMomentChoiceId.touchLine ||
            segment.choiceId == MatchMomentChoiceId.touchSet)
        .toList(growable: false);
    setState(() {
      _choices = List.unmodifiable(prefixChoices);
      _history = List.unmodifiable(prefixSegments);
      _current = attempt.frameBefore(MatchMomentBeat.nextAction);
      _beat = MatchMomentBeat.nextAction;
      _attempt = null;
      _activeSegments = const <MatchMomentSegment>[];
      _activeChoice = null;
      _manualPlaybackPause = false;
      _mode = _MatchMomentMode.choosing;
    });
  }

  void _replayLearner() {
    final attempt = _attempt;
    if (attempt == null || _busy) return;
    setState(() {
      _mode = _MatchMomentMode.replaying;
      _current = widget.episode.initialFrame;
      _activeChoice = null;
      _manualPlaybackPause = false;
    });
    _playSegments(
      [widget.episode.leadIn, ...attempt.segments],
      _durationFor([widget.episode.leadIn, ...attempt.segments]),
    );
  }

  void _showReference() {
    if (_busy) return;
    final reference = widget.episode.historicalAttempt;
    setState(() {
      _mode = _MatchMomentMode.compare;
      _current = widget.episode.initialFrame;
      _activeChoice = null;
      _manualPlaybackPause = false;
    });
    _playSegments(
      [widget.episode.leadIn, ...reference.segments],
      _durationFor([widget.episode.leadIn, ...reference.segments]),
    );
  }

  void _returnToLearnerReview() {
    final attempt = _attempt;
    if (attempt == null || _busy) return;
    setState(() {
      _mode = _MatchMomentMode.review;
      _current = attempt.finalFrame;
      _activeSegments = const <MatchMomentSegment>[];
      _activeChoice = null;
      _manualPlaybackPause = false;
    });
  }

  Future<void> _openSource(String url) async {
    final uri = Uri.parse(url);
    final launcher = widget.sourceLauncher ??
        (Uri uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
    var opened = false;
    try {
      opened = await launcher(uri);
    } catch (_) {
      opened = false;
    }
    if (!mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_l10n.matchMomentSourceUnavailable)),
    );
  }

  Future<void> _pauseForMenu(Future<void> Function() work) async {
    if (_modalOpen) return;
    _modalOpen = true;
    _controller.stop();
    try {
      await work();
    } finally {
      if (mounted) {
        _modalOpen = false;
        _resumeAnimation();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    final colors = _ScanPassColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(widget.referenceOnly
            ? l10n.matchMomentReferenceTitle
            : l10n.matchMomentTitle),
        backgroundColor: colors.surface,
        foregroundColor: colors.text,
        surfaceTintColor: Colors.transparent,
        actions: [
          AppBarActionMenuButton<VoidCallback>(
            key: const ValueKey<String>('match-more'),
            tooltip: l10n.flowMore,
            icon: Icons.more_horiz,
            onOpened: () {
              _modalOpen = true;
              _controller.stop();
            },
            onCanceled: () {
              _modalOpen = false;
              _resumeAnimation();
            },
            onSelected: (action) {
              _modalOpen = false;
              action();
              _resumeAnimation();
            },
            itemBuilder: (context) => [
              if (_attempt != null)
                PopupMenuItem(
                  key: const ValueKey<String>('match-replay-mine'),
                  value: _replayLearner,
                  child: Text(l10n.matchMomentReplayMine),
                ),
              PopupMenuItem(
                key: const ValueKey<String>('match-restart'),
                value:
                    widget.referenceOnly ? _startReferenceOnly : _startLeadIn,
                child: Text(l10n.matchMomentRestart),
              ),
              PopupMenuItem(
                key: const ValueKey<String>('match-sources'),
                value: () => unawaited(_pauseForMenu(_showSourceSheet)),
                child: Text(l10n.matchMomentSourcesTitle),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => _buildBody(l10n),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    return LayoutBuilder(builder: (context, constraints) {
      final landscape = constraints.maxWidth > constraints.maxHeight * 1.25;
      final reviewVisible = _mode == _MatchMomentMode.review ||
          (_mode == _MatchMomentMode.compare && !_busy);
      final field = Padding(
        padding: EdgeInsets.fromLTRB(
          landscape ? 12 : 12,
          landscape ? 10 : 12,
          landscape && reviewVisible ? 6 : 12,
          landscape ? 10 : 8,
        ),
        child: _buildField(l10n),
      );
      if (!reviewVisible) return field;
      final review = _buildReviewPanel(l10n, landscape: landscape);
      if (landscape) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: field),
            SizedBox(
              width: math.min(360.0, constraints.maxWidth * .38),
              child: review,
            ),
          ],
        );
      }
      return Column(
        children: [
          Expanded(flex: 6, child: field),
          Flexible(flex: 5, child: review),
        ],
      );
    });
  }

  Widget _buildField(AppLocalizations l10n) {
    final choices = _mode == _MatchMomentMode.choosing
        ? widget.episode.choicesFor(_beat, _current)
        : const <MatchMomentChoice>[];
    final motion = _motionVisual;
    return RepaintBoundary(
      key: const ValueKey<String>('match-moment-capture'),
      child: LayoutBuilder(builder: (context, constraints) {
        final playback = _playbackSnapshot != null;
        final wide = constraints.maxWidth >= 700;
        return Column(
          key: const ValueKey<String>('match-moment-field'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (playback && wide)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _buildFieldHeader(l10n)),
                const SizedBox(width: 8),
                SizedBox(width: 390, child: _buildPlaybackControls(l10n)),
              ])
            else ...[
              _buildFieldHeader(l10n),
              if (playback) ...[
                const SizedBox(height: 4),
                _buildPlaybackControls(l10n),
              ],
            ],
            const SizedBox(height: 4),
            Expanded(
              child: Semantics(
                image: true,
                label: l10n.matchMomentFieldSemantics,
                child: Stack(fit: StackFit.expand, children: [
                  CustomPaint(
                    key: const ValueKey<String>('match-moment-pitch'),
                    painter: _MatchMomentPitchPainter(
                      episode: widget.episode,
                      portrait: _portraitView,
                      frame: _displayFrame,
                      completedSegments: motion.completedSegments,
                      activeSegment: motion.activeSegment,
                      activeSegmentProgress: motion.activeProgress,
                      names: _localizedPlayerNames(l10n),
                      reference: _mode == _MatchMomentMode.compare,
                      brightness: Theme.of(context).brightness,
                      fontFamily:
                          Theme.of(context).textTheme.bodyMedium?.fontFamily,
                    ),
                  ),
                  if (choices.isNotEmpty) _buildChoiceLayer(l10n, choices),
                ]),
              ),
            ),
          ],
        );
      }),
    );
  }

  _MatchMotionVisual get _motionVisual {
    final snapshot = _playbackSnapshot;
    if (snapshot != null) {
      final completed = _mode == _MatchMomentMode.executing
          ? <MatchMomentSegment>[
              widget.episode.leadIn,
              ..._history,
              ...snapshot.completedBefore,
            ]
          : snapshot.completedBefore.toList(growable: false);
      return _MatchMotionVisual(
        completedSegments: List.unmodifiable(completed),
        activeSegment: snapshot.segment,
        activeProgress: snapshot.localProgress,
      );
    }
    if (_mode == _MatchMomentMode.compare) {
      return _MatchMotionVisual(
        completedSegments: [
          widget.episode.leadIn,
          ...widget.episode.historicalAttempt.segments,
        ],
      );
    }
    if (_mode == _MatchMomentMode.review && _attempt != null) {
      return _MatchMotionVisual(
        completedSegments: [widget.episode.leadIn, ..._attempt!.segments],
      );
    }
    return _MatchMotionVisual(
      completedSegments: [widget.episode.leadIn, ..._history],
    );
  }

  Widget _buildFieldHeader(AppLocalizations l10n) {
    final compact = !_portraitView && MediaQuery.sizeOf(context).height < 500;
    final colors = _ScanPassColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: .92),
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              compact
                  ? l10n.matchMomentContextLine.replaceAll('\n', ' · ')
                  : l10n.matchMomentContextLine,
              key: const ValueKey<String>('match-moment-context'),
              maxLines: compact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 3),
            Text(
              _busy ? l10n.matchMomentMotionLegend : _instruction(l10n),
              key: const ValueKey<String>('match-moment-instruction'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.muted,
                    height: 1.15,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaybackControls(AppLocalizations l10n) {
    final snapshot = _playbackSnapshot;
    if (snapshot == null) return const SizedBox.shrink();
    final colors = _ScanPassColors.of(context);
    final segment = snapshot.segment;
    final progress =
        _mode == _MatchMomentMode.compare || _mode == _MatchMomentMode.replaying
            ? l10n.matchMomentActionProgress(
                _playbackDisplayIndex(snapshot), _playbackDisplayTotal)
            : l10n.matchMomentActionIndex(_playbackDisplayIndex(snapshot));
    final detail = _actionDetail(l10n, segment);
    final metric = _actionMetric(l10n, segment);
    return DecoratedBox(
      key: const ValueKey<String>('match-playback-panel'),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: .94),
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .12),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Row(
          children: [
            _playbackControl(
              key: const ValueKey<String>('match-playback-prev'),
              icon: Icons.skip_previous,
              tooltip: l10n.matchMomentPreviousAction,
              onPressed: snapshot.index == 0 && snapshot.localProgress < .08
                  ? null
                  : () => _stepPlayback(-1),
            ),
            _playbackControl(
              key: const ValueKey<String>('match-playback-toggle'),
              icon: _manualPlaybackPause ? Icons.play_arrow : Icons.pause,
              tooltip: _manualPlaybackPause
                  ? l10n.matchMomentResumePlayback
                  : l10n.matchMomentPausePlayback,
              onPressed: _togglePlaybackPause,
            ),
            _playbackControl(
              key: const ValueKey<String>('match-playback-next'),
              icon: Icons.skip_next,
              tooltip: l10n.matchMomentNextActionControl,
              onPressed: snapshot.index == _activeSegments.length - 1 &&
                      snapshot.localProgress > .94
                  ? null
                  : () => _stepPlayback(1),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 2,
                    children: [
                      Text(
                        progress,
                        key: const ValueKey<String>(
                          'match-playback-progress',
                        ),
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: colors.accent,
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      Text(
                        detail,
                        key: const ValueKey<String>(
                          'match-playback-detail',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: colors.text,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    metric,
                    key: const ValueKey<String>('match-playback-metric'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.muted,
                          height: 1.12,
                        ),
                  ),
                  Row(children: [
                    SizedBox(
                        width: 36,
                        height: 14,
                        child: CustomPaint(
                          key: const ValueKey<String>('match-height-profile'),
                          painter: _MatchHeightProfilePainter(
                              height: segment.ballHeight, color: colors.text),
                        )),
                    const SizedBox(width: 5),
                    Expanded(
                        child: Text(
                      l10n.matchMomentHeightDiagram(
                          _heightLabel(l10n, segment.ballHeight)),
                      key: const ValueKey<String>('match-height-caption'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.muted,
                            height: 1.12,
                            fontSize: 10.5,
                          ),
                    )),
                  ]),
                  Text(l10n.matchMomentBodyLegend,
                      key: const ValueKey<String>('match-body-legend'),
                      maxLines: 2,
                      style: TextStyle(
                          color: colors.muted, fontSize: 10.5, height: 1.12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _playbackDisplayIndex(_MatchPlaybackSnapshot snapshot) {
    if (_mode == _MatchMomentMode.executing) {
      return _history.length + snapshot.index + 2;
    }
    return snapshot.index + 1;
  }

  int get _playbackDisplayTotal {
    if (_mode == _MatchMomentMode.executing) {
      return _history.length + _activeSegments.length + 1;
    }
    return _activeSegments.length;
  }

  Widget _playbackControl({
    required Key key,
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) =>
      AppBarActionButton.icon(
        key: key,
        icon: icon,
        tooltip: tooltip,
        onPressed: onPressed,
        compact: true,
        margin: const EdgeInsetsDirectional.only(end: 3),
      );

  String _actionDetail(AppLocalizations l10n, MatchMomentSegment segment) {
    final actor = _numberFor(segment.actorId);
    final receiver =
        segment.receiverId == null ? null : _numberFor(segment.receiverId!);
    if (segment.kind == MatchMomentActionKind.pass &&
        segment.after.outcome == MatchMomentOutcome.turnover &&
        segment.after.carrierId != null) {
      return l10n.matchMomentInterceptedPassDetail(
          actor, receiver ?? actor, _numberFor(segment.after.carrierId!));
    }
    return switch (segment.kind) {
      MatchMomentActionKind.leadIn => l10n.matchMomentActionDetailLead(actor),
      MatchMomentActionKind.receivePass ||
      MatchMomentActionKind.pass =>
        l10n.matchMomentActionDetailPass(actor, receiver ?? actor),
      MatchMomentActionKind.firstTouch =>
        l10n.matchMomentActionDetailFirstTouch(actor),
      MatchMomentActionKind.carry => l10n.matchMomentActionDetailCarry(actor),
      MatchMomentActionKind.shot => l10n.matchMomentActionDetailShot(actor),
    };
  }

  String _actionMetric(AppLocalizations l10n, MatchMomentSegment segment) {
    final metres = _metresText(segment.groundDistanceMetres);
    final actor = _numberFor(segment.actorId);
    final receiver =
        segment.receiverId == null ? null : _numberFor(segment.receiverId!);
    final height = _heightLabel(l10n, segment.ballHeight);
    return switch (segment.kind) {
      MatchMomentActionKind.receivePass ||
      MatchMomentActionKind.pass =>
        l10n.matchMomentPassMetricApprox(
          actor,
          receiver ?? actor,
          metres,
          height,
        ),
      MatchMomentActionKind.firstTouch =>
        l10n.matchMomentTouchMetricApprox(metres),
      MatchMomentActionKind.carry => l10n.matchMomentCarryMetricApprox(metres),
      MatchMomentActionKind.shot =>
        l10n.matchMomentShotMetricApprox(metres, height),
      MatchMomentActionKind.leadIn => l10n.matchMomentCarryMetricApprox(metres),
    };
  }

  String _heightLabel(AppLocalizations l10n, MatchMomentBallHeight height) {
    return switch (height) {
      MatchMomentBallHeight.ground => l10n.matchMomentHeightGround,
      MatchMomentBallHeight.low => l10n.matchMomentHeightLow,
      MatchMomentBallHeight.lofted => l10n.matchMomentHeightLofted,
      MatchMomentBallHeight.unknown => l10n.matchMomentHeightUnknown,
    };
  }

  String _metresText(double metres) {
    if (metres < 9.95) return metres.toStringAsFixed(1);
    return metres.round().toString();
  }

  int _numberFor(String playerId) {
    return widget.episode.roster
        .firstWhere((player) => player.id == playerId)
        .number;
  }

  Widget _buildChoiceLayer(
    AppLocalizations l10n,
    List<MatchMomentChoice> choices,
  ) {
    return Positioned.fill(
      child: LayoutBuilder(builder: (context, constraints) {
        final geometry = _MatchPitchGeometry(
          Size(constraints.maxWidth, constraints.maxHeight),
          portrait: _portraitView,
        );
        final fieldSize = Size(constraints.maxWidth, constraints.maxHeight);
        final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
        final occupied = <Rect>[
          for (final actor in _current.actors.values)
            Rect.fromCenter(
              center: geometry.toOffset(actor.position) - const Offset(0, 10),
              width: 42,
              height: 62,
            ),
        ];
        final targets = <_ChoiceTargetData>[];
        for (final choice in choices) {
          final endpoint = geometry.toOffset(choice.target);
          final title = _choiceTitle(l10n, choice.id);
          final destination = _choiceDestination(l10n, choice.id);
          final cardSize = Size(
            math.min(156.0, math.max(132.0, fieldSize.width * .30)),
            math.max(64.0, 52 * textScale),
          );
          final source =
              geometry.toOffset(_current.actor(choice.actorId).position);
          final rect = _placeChoiceRect(endpoint, source, cardSize, fieldSize,
              geometry.headerHeight, occupied);
          occupied.add(rect.inflate(10));
          final playerCenter = endpoint - const Offset(0, 9);
          targets.add(_ChoiceTargetData(
            choice: choice,
            buttonKey:
                ValueKey<String>('match-choice-${_choiceKey(choice.id)}'),
            endpointCenter: endpoint,
            direction: endpoint - source,
            controlCenter: choice.playerRing ? playerCenter : rect.center,
            controlSize: choice.playerRing ? const Size.square(54) : cardSize,
            labelRect: choice.playerRing ? rect : null,
            title: title,
            destination: destination,
            semanticsLabel: l10n.matchMomentChoiceSemantics(title, destination),
          ));
        }
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (final target in targets)
              if (target.linked || target.labelRect != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _ChoiceLeaderPainter(
                        from: target.labelRect?.center ?? target.controlCenter,
                        to: target.endpointCenter,
                        color: _ScanPassColors.of(context).accent,
                      ),
                      size: fieldSize,
                    ),
                  ),
                ),
            for (final target in targets) ...[
              _MatchMomentChoiceButton(
                data: target,
                onPressed: () => _choose(target.choice.id),
              ),
              if (target.labelRect != null)
                _MatchMomentChoiceLabel(
                    data: target, onPressed: () => _choose(target.choice.id)),
            ],
          ],
        );
      }),
    );
  }

  Widget _buildReviewPanel(AppLocalizations l10n, {required bool landscape}) {
    final colors = _ScanPassColors.of(context);
    final comparing = _mode == _MatchMomentMode.compare;
    final attempt = _attempt;
    final title = comparing
        ? l10n.matchMomentReferenceTitle
        : l10n.matchMomentReviewTitle;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          left: landscape ? BorderSide(color: colors.line) : BorderSide.none,
          top: landscape ? BorderSide.none : BorderSide(color: colors.line),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          landscape ? 14 : 16,
          12,
          landscape ? 14 : 16,
          14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              key: const ValueKey<String>('match-review-title'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            if (widget.referenceOnly) ...[
              Text(
                l10n.matchMomentReferenceBody,
                style: TextStyle(color: colors.muted, height: 1.35),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const ValueKey<String>('match-reference-replay'),
                onPressed: _busy ? null : _startReferenceOnly,
                icon: const Icon(Icons.replay),
                label: Text(l10n.matchMomentReplayReference),
              ),
              const SizedBox(height: 10),
              _buildOfficialFootage(l10n),
              const SizedBox(height: 8),
              _buildProvenance(l10n),
              const SizedBox(height: 10),
              OutlinedButton(
                key: const ValueKey<String>('match-reference-close'),
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.close),
              ),
            ] else if (attempt != null && !comparing) ...[
              _buildReviewActions(l10n),
              const SizedBox(height: 12),
              _reviewLine(
                l10n.matchMomentReviewObserveLabel,
                _observeReview(l10n, attempt.choices[0]),
              ),
              _reviewLine(
                l10n.matchMomentReviewActionLabel,
                _actionReview(l10n, attempt),
              ),
              _reviewLine(
                l10n.matchMomentReviewEffectLabel,
                _effectReview(l10n, attempt),
              ),
              const SizedBox(height: 12),
              _buildOfficialFootage(l10n),
              const SizedBox(height: 8),
              _buildProvenance(l10n),
            ] else ...[
              Text(
                l10n.matchMomentReferenceBody,
                style: TextStyle(color: colors.muted, height: 1.35),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const ValueKey<String>('match-reference-replay'),
                onPressed: _busy ? null : _showReference,
                icon: const Icon(Icons.replay),
                label: Text(l10n.matchMomentReplayReference),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                key: const ValueKey<String>('match-return-review'),
                onPressed: _busy ? null : _returnToLearnerReview,
                icon: const Icon(Icons.keyboard_return),
                label: Text(l10n.matchMomentReturnToReview),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _reviewLine(String label, String body) {
    final colors = _ScanPassColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.accent,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 3),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.text,
                  height: 1.28,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewActions(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
            child: OutlinedButton(
          key: const ValueKey<String>('match-retry-last'),
          onPressed: _busy ? null : _retryLastDecision,
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
          child:
              Text(l10n.matchMomentRetryDecision, textAlign: TextAlign.center),
        )),
        const SizedBox(width: 8),
        Expanded(
            child: FilledButton(
          key: const ValueKey<String>('match-reference'),
          onPressed: _busy ? null : _showReference,
          style: FilledButton.styleFrom(
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
          child: Text(l10n.matchMomentReferenceAction,
              textAlign: TextAlign.center),
        )),
      ],
    );
  }

  Widget _buildOfficialFootage(AppLocalizations l10n) {
    final colors = _ScanPassColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.matchMomentOfficialFootageTitle,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 5),
            Text(
              l10n.matchMomentOfficialFootageBody,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.muted,
                    height: 1.28,
                  ),
            ),
            const SizedBox(height: 8),
            MatchMomentOfficialVideo(
              playLabel: l10n.matchMomentPlayOfficialHighlight,
              title: l10n.matchMomentOfficialHighlightTitle,
              embedUrl: MatchMomentEpisode.officialEnglandHighlightEmbedUrl,
            ),
            const SizedBox(height: 8),
            LayoutBuilder(builder: (context, constraints) {
              final maxButtonWidth = math.min(constraints.maxWidth, 260.0);
              return Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _sourceButton(
                    key: const ValueKey<String>('match-open-uefa-goal'),
                    maxWidth: maxButtonWidth,
                    label: l10n.matchMomentOpenUefaGoal,
                    onPressed: () => unawaited(
                      _openSource(MatchMomentEpisode.officialGoalPageUrl),
                    ),
                  ),
                  _sourceButton(
                    key: const ValueKey<String>(
                      'match-open-england-highlight',
                    ),
                    maxWidth: maxButtonWidth,
                    label: l10n.matchMomentOpenEnglandHighlight,
                    onPressed: () => unawaited(
                      _openSource(
                        MatchMomentEpisode.officialEnglandHighlightsUrl,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _sourceButton({
    required Key key,
    required double maxWidth,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: OutlinedButton(
        key: key,
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.open_in_new, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProvenance(AppLocalizations l10n) {
    final colors = _ScanPassColors.of(context);
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: const ValueKey<String>('match-provenance'),
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Text(
          l10n.matchMomentSourcesTitle,
          style: TextStyle(color: colors.text, fontWeight: FontWeight.w700),
        ),
        children: [
          Text(
            l10n.matchMomentSourcesBody,
            style: TextStyle(color: colors.muted, height: 1.35),
          ),
          const SizedBox(height: 6),
          Text(
            '${l10n.matchMomentBodyLegend}\n${l10n.matchMomentSourceFeintLimit}',
            style: TextStyle(color: colors.muted, height: 1.35),
          ),
          const SizedBox(height: 8),
          _sourceLink(l10n.matchMomentSourceLineup,
              MatchMomentEpisode.officialLineupUrl),
          _sourceLink(l10n.matchMomentSourceTechnical,
              MatchMomentEpisode.technicalReportUrl),
          _sourceLink(
              l10n.matchMomentSourceRecord, MatchMomentEpisode.matchRecordUrl),
        ],
      ),
    );
  }

  Widget _sourceLink(String label, String url) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: () => unawaited(_openSource(url)),
        child: Text(label),
      ),
    );
  }

  Future<void> _showSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) {
        final colors = _ScanPassColors.of(context);
        final l10n = AppLocalizations.of(context)!;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.matchMomentSourcesTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.matchMomentSourcesBody,
                  style: TextStyle(color: colors.muted, height: 1.35),
                ),
                const SizedBox(height: 8),
                Text(
                  '${l10n.matchMomentBodyLegend}\n${l10n.matchMomentSourceFeintLimit}',
                  style: TextStyle(color: colors.muted, height: 1.35),
                ),
                const SizedBox(height: 10),
                _sourceLink(l10n.matchMomentSourceLineup,
                    MatchMomentEpisode.officialLineupUrl),
                _sourceLink(l10n.matchMomentSourceTechnical,
                    MatchMomentEpisode.technicalReportUrl),
                _sourceLink(l10n.matchMomentSourceRecord,
                    MatchMomentEpisode.matchRecordUrl),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.close),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _instruction(AppLocalizations l10n) {
    if (_mode == _MatchMomentMode.leading) {
      return l10n.matchMomentLeadInstruction;
    }
    if (_mode == _MatchMomentMode.executing && _activeChoice != null) {
      return l10n.matchMomentExecutingInstruction(
        _choiceTitle(l10n, _activeChoice!),
        _choiceDestination(l10n, _activeChoice!),
      );
    }
    if (_mode == _MatchMomentMode.replaying) {
      return l10n.matchMomentReplayInstruction;
    }
    if (_mode == _MatchMomentMode.compare) {
      return l10n.matchMomentReferenceInstruction;
    }
    if (_mode == _MatchMomentMode.review) {
      return l10n.matchMomentReviewInstruction;
    }
    return switch (_beat) {
      MatchMomentBeat.receive => l10n.matchMomentReceiveInstruction,
      MatchMomentBeat.firstTouch => l10n.matchMomentFirstTouchInstruction,
      MatchMomentBeat.nextAction => l10n.matchMomentNextActionInstruction,
    };
  }

  String _observeReview(AppLocalizations l10n, MatchMomentChoiceId choice) {
    return switch (choice) {
      MatchMomentChoiceId.receiveInside => l10n.matchMomentReviewObserveInside,
      MatchMomentChoiceId.receiveWide => l10n.matchMomentReviewObserveWide,
      MatchMomentChoiceId.receiveCheck => l10n.matchMomentReviewObserveCheck,
      _ => l10n.matchMomentReviewObserveInside,
    };
  }

  String _actionReview(AppLocalizations l10n, MatchMomentAttempt attempt) {
    return l10n.matchMomentReviewActionLine(
      _choiceDestination(l10n, attempt.choices[1]),
      _choiceTitle(l10n, attempt.choices[2]),
    );
  }

  String _effectReview(AppLocalizations l10n, MatchMomentAttempt attempt) {
    if (attempt.reviewCues.last == MatchMomentReviewCue.williamsIntercepted) {
      return l10n.matchMomentReviewEffectIntercepted;
    }
    if (attempt.reviewCues.last == MatchMomentReviewCue.carrySaved) {
      return l10n.matchMomentReviewEffectCarrySaved;
    }
    return switch (attempt.outcome) {
      MatchMomentOutcome.goal => l10n.matchMomentReviewEffectGoal,
      MatchMomentOutcome.saved => l10n.matchMomentReviewEffectSaved,
      MatchMomentOutcome.turnover => l10n.matchMomentReviewEffectTurnover,
      MatchMomentOutcome.retained => l10n.matchMomentReviewEffectRetained,
    };
  }

  String _choiceTitle(AppLocalizations l10n, MatchMomentChoiceId id) {
    return switch (id) {
      MatchMomentChoiceId.receiveInside => l10n.matchMomentChoiceReceiveInside,
      MatchMomentChoiceId.receiveWide => l10n.matchMomentChoiceReceiveWide,
      MatchMomentChoiceId.receiveCheck => l10n.matchMomentChoiceReceiveCheck,
      MatchMomentChoiceId.touchInside => l10n.matchMomentChoiceTouchInside,
      MatchMomentChoiceId.touchLine => l10n.matchMomentChoiceTouchLine,
      MatchMomentChoiceId.touchSet => l10n.matchMomentChoiceTouchSet,
      MatchMomentChoiceId.passWilliams => l10n.matchMomentChoicePassWilliams,
      MatchMomentChoiceId.passMorata => l10n.matchMomentChoicePassMorata,
      MatchMomentChoiceId.carryInside => l10n.matchMomentChoiceCarryInside,
    };
  }

  String _choiceDestination(AppLocalizations l10n, MatchMomentChoiceId id) {
    return switch (id) {
      MatchMomentChoiceId.receiveInside =>
        l10n.matchMomentDestinationReceiveInside,
      MatchMomentChoiceId.receiveWide => l10n.matchMomentDestinationReceiveWide,
      MatchMomentChoiceId.receiveCheck =>
        l10n.matchMomentDestinationReceiveCheck,
      MatchMomentChoiceId.touchInside => l10n.matchMomentDestinationTouchInside,
      MatchMomentChoiceId.touchLine => l10n.matchMomentDestinationTouchLine,
      MatchMomentChoiceId.touchSet => l10n.matchMomentDestinationTouchSet,
      MatchMomentChoiceId.passWilliams =>
        l10n.matchMomentDestinationPassWilliams,
      MatchMomentChoiceId.passMorata => l10n.matchMomentDestinationPassMorata,
      MatchMomentChoiceId.carryInside => l10n.matchMomentDestinationCarryInside,
    };
  }

  String _choiceKey(MatchMomentChoiceId id) {
    return switch (id) {
      MatchMomentChoiceId.receiveInside => 'receive-inside',
      MatchMomentChoiceId.receiveWide => 'receive-wide',
      MatchMomentChoiceId.receiveCheck => 'receive-check',
      MatchMomentChoiceId.touchInside => 'touch-inside',
      MatchMomentChoiceId.touchLine => 'touch-line',
      MatchMomentChoiceId.touchSet => 'touch-set',
      MatchMomentChoiceId.passWilliams => 'pass-williams',
      MatchMomentChoiceId.passMorata => 'pass-morata',
      MatchMomentChoiceId.carryInside => 'carry-inside',
    };
  }

  Rect _placeChoiceRect(Offset endpoint, Offset source, Size card, Size field,
      double header, List<Rect> occupied) {
    final bounds =
        Rect.fromLTRB(8, header + 12, field.width - 8, field.height - 10);
    final direction = endpoint - source;
    final angle = math.atan2(direction.dy, direction.dx);
    final candidates = <Offset>[];
    for (final radius in [82.0, 124.0, 166.0, 214.0, 270.0]) {
      for (final turn in [0.0, -.65, .65, -1.3, 1.3, -2.1, 2.1, math.pi]) {
        candidates.add(endpoint +
            Offset(math.cos(angle + turn), math.sin(angle + turn)) * radius);
      }
    }
    for (var y = bounds.top + card.height / 2; y < bounds.bottom; y += 36) {
      for (var x = bounds.left + card.width / 2; x < bounds.right; x += 36) {
        candidates.add(Offset(x, y));
      }
    }
    var best = Rect.fromCenter(
        center: bounds.center, width: card.width, height: card.height);
    var bestScore = double.infinity;
    for (final candidate in candidates) {
      final center = Offset(
        candidate.dx.clamp(
            bounds.left + card.width / 2,
            math.max(
                bounds.left + card.width / 2, bounds.right - card.width / 2)),
        candidate.dy.clamp(
            bounds.top + card.height / 2,
            math.max(
                bounds.top + card.height / 2, bounds.bottom - card.height / 2)),
      );
      final rect = Rect.fromCenter(
          center: center, width: card.width, height: card.height);
      var score = (center - endpoint).distance;
      for (final obstacle in occupied) {
        final overlap = rect.inflate(5).intersect(obstacle);
        if (!overlap.isEmpty) score += overlap.width * overlap.height * 30;
      }
      if (score < bestScore) {
        best = rect;
        bestScore = score;
      }
    }
    return best;
  }

  Map<String, String> _localizedPlayerNames(AppLocalizations l10n) => {
        MatchMomentEpisode.spain23: l10n.matchMomentPlayerUnaiSimon,
        MatchMomentEpisode.spain2: l10n.matchMomentPlayerDaniCarvajal,
        MatchMomentEpisode.spain3: l10n.matchMomentPlayerRobinLeNormand,
        MatchMomentEpisode.spain7: l10n.matchMomentPlayerAlvaroMorata,
        MatchMomentEpisode.spain8: l10n.matchMomentPlayerFabianRuiz,
        MatchMomentEpisode.spain10: l10n.matchMomentPlayerDaniOlmo,
        MatchMomentEpisode.spain14: l10n.matchMomentPlayerAymericLaporte,
        MatchMomentEpisode.spain17: l10n.matchMomentPlayerNicoWilliams,
        MatchMomentEpisode.spain18: l10n.matchMomentPlayerMartinZubimendi,
        MatchMomentEpisode.spain19: l10n.matchMomentPlayerLamineYamal,
        MatchMomentEpisode.spain24: l10n.matchMomentPlayerMarcCucurella,
        MatchMomentEpisode.england1: l10n.matchMomentPlayerJordanPickford,
        MatchMomentEpisode.england2: l10n.matchMomentPlayerKyleWalker,
        MatchMomentEpisode.england3: l10n.matchMomentPlayerLukeShaw,
        MatchMomentEpisode.england4: l10n.matchMomentPlayerDeclanRice,
        MatchMomentEpisode.england5: l10n.matchMomentPlayerJohnStones,
        MatchMomentEpisode.england6: l10n.matchMomentPlayerMarcGuehi,
        MatchMomentEpisode.england7: l10n.matchMomentPlayerBukayoSaka,
        MatchMomentEpisode.england9: l10n.matchMomentPlayerHarryKane,
        MatchMomentEpisode.england10: l10n.matchMomentPlayerJudeBellingham,
        MatchMomentEpisode.england11: l10n.matchMomentPlayerPhilFoden,
        MatchMomentEpisode.england26: l10n.matchMomentPlayerKobbieMainoo,
      };
}

class _MatchPlaybackSnapshot {
  final int index;
  final double localProgress;
  final MatchMomentSegment segment;
  final Iterable<MatchMomentSegment> completedBefore;

  const _MatchPlaybackSnapshot({
    required this.index,
    required this.localProgress,
    required this.segment,
    required this.completedBefore,
  });
}

class _MatchMotionVisual {
  final List<MatchMomentSegment> completedSegments;
  final MatchMomentSegment? activeSegment;
  final double activeProgress;

  const _MatchMotionVisual({
    required this.completedSegments,
    this.activeSegment,
    this.activeProgress = 0,
  });
}

class _ChoiceTargetData {
  final MatchMomentChoice choice;
  final Key buttonKey;
  final Offset endpointCenter;
  final Offset direction;
  final Offset controlCenter;
  final Size controlSize;
  final Rect? labelRect;
  final String title;
  final String destination;
  final String semanticsLabel;

  const _ChoiceTargetData({
    required this.choice,
    required this.buttonKey,
    required this.endpointCenter,
    required this.direction,
    required this.controlCenter,
    required this.controlSize,
    this.labelRect,
    required this.title,
    required this.destination,
    required this.semanticsLabel,
  });

  bool get linked => (controlCenter - endpointCenter).distance > 4;
}

class _MatchMomentChoiceButton extends StatelessWidget {
  final _ChoiceTargetData data;
  final VoidCallback onPressed;

  const _MatchMomentChoiceButton({
    required this.data,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _ScanPassColors.of(context);
    return Positioned(
      left: data.controlCenter.dx - data.controlSize.width / 2,
      top: data.controlCenter.dy - data.controlSize.height / 2,
      width: data.controlSize.width,
      height: data.controlSize.height,
      child: Semantics(
        button: true,
        label: data.semanticsLabel,
        onTap: onPressed,
        child: Tooltip(
          message: data.semanticsLabel,
          child: OutlinedButton(
            key: data.buttonKey,
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              shape: data.choice.playerRing
                  ? const CircleBorder()
                  : RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              backgroundColor:
                  data.choice.playerRing ? Colors.transparent : colors.surface,
              foregroundColor: colors.accent,
              side: BorderSide(
                color: data.choice.playerRing
                    ? colors.accent
                    : colors.text.withValues(alpha: .75),
                width: data.choice.playerRing ? 2.2 : 1.6,
              ),
            ),
            child: data.choice.playerRing
                ? const SizedBox.shrink()
                : _MatchChoiceText(data: data),
          ),
        ),
      ),
    );
  }
}

class _MatchMomentChoiceLabel extends StatelessWidget {
  final _ChoiceTargetData data;
  final VoidCallback onPressed;
  const _MatchMomentChoiceLabel({required this.data, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = _ScanPassColors.of(context);
    return Positioned.fromRect(
      rect: data.labelRect!,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: colors.surface,
          foregroundColor: colors.text,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _MatchChoiceText(data: data),
      ),
    );
  }
}

class _MatchChoiceText extends StatelessWidget {
  final _ChoiceTargetData data;
  const _MatchChoiceText({required this.data});
  @override
  Widget build(BuildContext context) {
    final colors = _ScanPassColors.of(context);
    return Row(children: [
      Transform.rotate(
          angle: data.direction.direction,
          child: Icon(Icons.arrow_forward, size: 16, color: colors.accent)),
      const SizedBox(width: 4),
      Expanded(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
              child: Text(data.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      height: 1.15,
                      color: colors.text,
                      fontWeight: FontWeight.w800))),
          const SizedBox(height: 3),
          Flexible(
              child: Text(data.destination,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 10.5, height: 1.1, color: colors.muted))),
        ],
      )),
    ]);
  }
}

class _ChoiceLeaderPainter extends CustomPainter {
  final Offset from;
  final Offset to;
  final Color color;

  const _ChoiceLeaderPainter({
    required this.from,
    required this.to,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: .78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(from, to, paint);
    canvas.drawCircle(
      to,
      5.0,
      Paint()..color = color.withValues(alpha: .20),
    );
    canvas.drawCircle(
      to,
      5.0,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  @override
  bool shouldRepaint(covariant _ChoiceLeaderPainter oldDelegate) =>
      oldDelegate.from != from ||
      oldDelegate.to != to ||
      oldDelegate.color != color;
}

class _MatchMomentPitchPainter extends CustomPainter {
  final MatchMomentEpisode episode;
  final bool portrait;
  final MatchMomentFrame frame;
  final List<MatchMomentSegment> completedSegments;
  final MatchMomentSegment? activeSegment;
  final double activeSegmentProgress;
  final Map<String, String> names;
  final bool reference;
  final Brightness brightness;
  final String? fontFamily;
  final Rect? viewBounds;
  final bool emphasizePlayers;
  final List<MatchMomentPlayerDefinition>? rosterOverride;

  const _MatchMomentPitchPainter({
    required this.episode,
    required this.portrait,
    required this.frame,
    required this.completedSegments,
    required this.activeSegment,
    required this.activeSegmentProgress,
    required this.names,
    required this.reference,
    required this.brightness,
    required this.fontFamily,
    this.viewBounds,
    this.emphasizePlayers = false,
    this.rosterOverride,
  });

  bool get _dark => brightness == Brightness.dark;

  Offset offsetFor(ScanPassPoint point, Size size) => _MatchPitchGeometry(
        size,
        portrait: portrait,
        viewBounds: viewBounds,
      ).toOffset(point);

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = _MatchPitchGeometry(
      size,
      portrait: portrait,
      viewBounds: viewBounds,
    );
    _drawPitch(canvas, geometry);
    canvas.save();
    canvas.clipRect(geometry.playArea);
    _drawMotionAnnotations(canvas, geometry);
    _drawGoal(canvas, geometry);
    final roster = (rosterOverride ?? episode.roster).toList(growable: false)
      ..sort((a, b) {
        if (a.goalkeeper != b.goalkeeper) return a.goalkeeper ? -1 : 1;
        if (a.subdued != b.subdued) return a.subdued ? -1 : 1;
        if (a.team != b.team) {
          return a.team == MatchMomentTeam.england ? -1 : 1;
        }
        return a.number.compareTo(b.number);
      });
    for (final player in roster) {
      final state = frame.actors[player.id];
      if (state == null) continue;
      _drawPlayer(canvas, geometry, player, state);
    }
    _drawTouchDetail(canvas, geometry);
    _drawBall(canvas, geometry);
    _drawAttackArrow(canvas, geometry);
    canvas.restore();
  }

  /// Repaints only the current roster and ball above lesson annotations.
  ///
  /// The historical painter's normal paint order is unchanged. Pressure-lesson
  /// review uses this foreground pass so route evidence cannot cover live shirt
  /// numbers while all marks retain the same geometry.
  void paintRosterAndBall(Canvas canvas, Size size) {
    final geometry = _MatchPitchGeometry(
      size,
      portrait: portrait,
      viewBounds: viewBounds,
    );
    canvas.save();
    canvas.clipRect(geometry.playArea);
    final roster = (rosterOverride ?? episode.roster).toList(growable: false)
      ..sort((a, b) {
        if (a.goalkeeper != b.goalkeeper) return a.goalkeeper ? -1 : 1;
        if (a.subdued != b.subdued) return a.subdued ? -1 : 1;
        if (a.team != b.team) {
          return a.team == MatchMomentTeam.england ? -1 : 1;
        }
        return a.number.compareTo(b.number);
      });
    for (final player in roster) {
      final state = frame.actors[player.id];
      if (state == null) continue;
      _drawPlayer(canvas, geometry, player, state);
    }
    _drawBall(canvas, geometry);
    canvas.restore();
  }

  void _drawPitch(Canvas canvas, _MatchPitchGeometry geometry) {
    final pitch = _dark ? const Color(0xFF203A33) : const Color(0xFFDDE8DC);
    final stripe = _dark ? const Color(0xFF19332C) : const Color(0xFFD2E0D3);
    final line = _dark ? const Color(0xFF89A096) : const Color(0xFF758D82);
    canvas.drawRRect(
      BorderRadius.circular(7).toRRect(Offset.zero & geometry.size),
      Paint()..color = pitch,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, geometry.size.width, geometry.headerHeight + 8),
      Paint()
        ..color = (_dark ? const Color(0xFF17262B) : Colors.white)
            .withValues(alpha: .80),
    );
    canvas.save();
    canvas.clipRect(geometry.playArea);
    for (var i = 0; i < 7; i += 2) {
      canvas.drawRect(
          geometry.rectFor(i / 7 * _MatchPitchGeometry.defaultMaxX, 0,
              (i + 1) / 7 * _MatchPitchGeometry.defaultMaxX, 1),
          Paint()..color = stripe.withValues(alpha: .55));
    }
    final paint = Paint()
      ..color = line.withValues(alpha: .82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(geometry.fieldRect, paint);
    canvas.drawLine(
      geometry.toOffset(const ScanPassPoint(.5, 0)),
      geometry.toOffset(const ScanPassPoint(.5, 1)),
      paint,
    );
    canvas.drawCircle(
      geometry.toOffset(const ScanPassPoint(.5, .5)),
      9.15 * geometry.scale,
      paint,
    );
    canvas.drawRect(geometry.rectFor(.83, .21, 1.0, .79), paint);
    canvas.drawRect(geometry.rectFor(.94, .392, 1.0, .608), paint);
    canvas.restore();
  }

  void _drawGoal(Canvas canvas, _MatchPitchGeometry geometry) {
    final post = Paint()
      ..color = _dark ? Colors.white70 : Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final net = Paint()
      ..color = (_dark ? Colors.white70 : const Color(0xFF60756E))
          .withValues(alpha: .45)
      ..strokeWidth = .8
      ..style = PaintingStyle.stroke;
    final top = geometry.toOffset(const ScanPassPoint(1.0, .446));
    final bottom = geometry.toOffset(const ScanPassPoint(1.0, .554));
    final backTop = geometry.toOffset(const ScanPassPoint(1.04, .430));
    final backBottom = geometry.toOffset(const ScanPassPoint(1.04, .570));
    canvas.drawLine(top, bottom, post);
    canvas.drawLine(top, backTop, post);
    canvas.drawLine(bottom, backBottom, post);
    for (var i = 1; i < 5; i += 1) {
      final t = i / 5;
      canvas.drawLine(
        Offset.lerp(top, bottom, t)!,
        Offset.lerp(backTop, backBottom, t)!,
        net,
      );
    }
    for (var i = 1; i < 4; i += 1) {
      final t = i / 4;
      canvas.drawLine(
        Offset.lerp(top, backTop, t)!,
        Offset.lerp(bottom, backBottom, t)!,
        net,
      );
    }
  }

  void _drawMotionAnnotations(Canvas canvas, _MatchPitchGeometry geometry) {
    for (var index = 0; index < completedSegments.length; index += 1) {
      _drawSegmentAnnotation(
        canvas,
        geometry,
        completedSegments[index],
        progress: 1,
        sequence: index + 1,
        active: false,
      );
    }
    final active = activeSegment;
    if (active != null) {
      _drawSegmentPlan(canvas, geometry, active);
      _drawSegmentAnnotation(
        canvas,
        geometry,
        active,
        progress: activeSegmentProgress,
        sequence: completedSegments.length + 1,
        active: true,
      );
    }
  }

  void _drawSegmentPlan(
    Canvas canvas,
    _MatchPitchGeometry geometry,
    MatchMomentSegment segment,
  ) {
    final paint = _ballPaint(segment, active: true)
      ..color = _ballPaint(segment, active: true).color.withValues(alpha: .82)
      ..strokeWidth = 2.8;
    final points = segment
        .sampleBallPath(count: 18)
        .map(geometry.toOffset)
        .toList(growable: false);
    _drawPathForKind(canvas, points, paint, segment.kind);
    if (segment.groundDistanceMetres >= 3) {
      _drawSequenceMarker(
          canvas, points[points.length ~/ 2], completedSegments.length + 1,
          active: true);
    }
    _drawActorRuns(canvas, geometry, segment, 1, active: false, planned: true);
  }

  void _drawSegmentAnnotation(
    Canvas canvas,
    _MatchPitchGeometry geometry,
    MatchMomentSegment segment, {
    required double progress,
    required int sequence,
    required bool active,
  }) {
    final clamped = progress.clamp(0.0, 1.0).toDouble();
    final points = segment
        .sampleBallPath(count: active ? 18 : 12, progress: clamped)
        .map(geometry.toOffset)
        .toList(growable: false);
    final ballPaint = _ballPaint(segment, active: active);
    _drawPathForKind(canvas, points, ballPaint, segment.kind);
    if (!active && points.length > 1 && segment.groundDistanceMetres >= 3) {
      final marker = points[(points.length / 2).floor()];
      _drawSequenceMarker(canvas, marker, sequence, active: active);
    }
    _drawActorRuns(canvas, geometry, segment, clamped, active: active);
  }

  Paint _ballPaint(MatchMomentSegment segment, {required bool active}) {
    final color = switch (segment.kind) {
      MatchMomentActionKind.receivePass ||
      MatchMomentActionKind.pass =>
        reference
            ? (_dark ? const Color(0xFF8EC5FF) : const Color(0xFF005A8D))
            : (_dark ? const Color(0xFFFFD166) : const Color(0xFF8A5A00)),
      MatchMomentActionKind.firstTouch =>
        _dark ? const Color(0xFF54D6A4) : const Color(0xFF007B52),
      MatchMomentActionKind.carry ||
      MatchMomentActionKind.leadIn =>
        _dark ? const Color(0xFF24C6DC) : const Color(0xFF006D7A),
      MatchMomentActionKind.shot =>
        _dark ? const Color(0xFFFF5A7A) : const Color(0xFFC0183A),
    };
    return Paint()
      ..color = color.withValues(alpha: active ? .98 : .42)
      ..strokeWidth = active ? 4.4 : 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
  }

  void _drawPathForKind(
    Canvas canvas,
    List<Offset> points,
    Paint paint,
    MatchMomentActionKind kind, {
    bool arrow = true,
  }) {
    if (points.length < 2) return;
    if (kind == MatchMomentActionKind.pass ||
        kind == MatchMomentActionKind.receivePass) {
      _drawDashedPolyline(canvas, points, paint, dash: 10, gap: 7);
    } else {
      _drawPolyline(canvas, points, paint);
    }
    if (arrow) _drawArrowHeadForPath(canvas, points, paint);
  }

  void _drawActorRuns(
    Canvas canvas,
    _MatchPitchGeometry geometry,
    MatchMomentSegment segment,
    double progress, {
    required bool active,
    bool planned = false,
  }) {
    final frameAtProgress = segment.frame(progress);
    final runIds = <String>{
      segment.actorId,
      if (segment.receiverId != null) segment.receiverId!,
      ...const [
        MatchMomentEpisode.spain19,
        MatchMomentEpisode.spain2,
        MatchMomentEpisode.spain17,
        MatchMomentEpisode.spain7,
        MatchMomentEpisode.spain10,
        MatchMomentEpisode.england3,
        MatchMomentEpisode.england4,
        MatchMomentEpisode.england5,
        MatchMomentEpisode.england6,
        MatchMomentEpisode.england2,
      ],
    };
    for (final id in runIds) {
      if (id == segment.actorId &&
          (segment.kind == MatchMomentActionKind.carry ||
              segment.kind == MatchMomentActionKind.firstTouch ||
              segment.kind == MatchMomentActionKind.leadIn)) {
        continue;
      }
      final start = segment.before.actors[id]?.position;
      final end = frameAtProgress.actors[id]?.position;
      if (start == null || end == null || start.distanceTo(end) < .010) {
        continue;
      }
      final spain = id.startsWith('esp-');
      final paint = Paint()
        ..color = (spain
                ? (_dark ? const Color(0xFFB6E07E) : const Color(0xFF3C7A20))
                : (_dark ? const Color(0xFFFF9F6E) : const Color(0xFFC45525)))
            .withValues(alpha: active ? .95 : (planned ? .72 : .25))
        ..strokeWidth = active ? 2.8 : (planned ? 2.0 : 1.25)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final from = geometry.toOffset(start);
      final to = geometry.toOffset(end);
      _drawDashedLine(canvas, from, to, paint, dash: spain ? 8 : 5);
      _drawArrowHead(canvas, from, to, paint);
    }
  }

  void _drawSequenceMarker(
    Canvas canvas,
    Offset center,
    int sequence, {
    required bool active,
  }) {
    final radius = active ? 8.5 : 6.5;
    final fill = Paint()
      ..color = (active ? const Color(0xFF17252A) : const Color(0xFF31454A))
          .withValues(alpha: active ? .92 : .68);
    canvas.drawCircle(center, radius, fill);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: active ? .95 : .70)
        ..style = PaintingStyle.stroke
        ..strokeWidth = active ? 1.3 : .9,
    );
    _drawText(
      canvas,
      sequence.toString(),
      center,
      color: Colors.white,
      size: active ? 9.5 : 7.5,
      weight: FontWeight.w900,
      anchorMode: _TextAnchor.center,
    );
  }

  void _drawPlayer(
    Canvas canvas,
    _MatchPitchGeometry geometry,
    MatchMomentPlayerDefinition player,
    MatchMomentActorState state,
  ) {
    final feet = geometry.toOffset(state.position);
    final scale =
        (player.essential ? 1.0 : .88) * (emphasizePlayers ? 1.18 : 1.0);
    final r = math.max(9.5, geometry.size.shortestSide * .027) * scale;
    final center = feet - Offset(0, r * 1.55);
    final alpha = emphasizePlayers ? 1.0 : (player.subdued ? .58 : 1.0);
    final kit = _kitFor(player);
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: _dark ? .30 : .18);
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, r * 1.25),
        width: r * 1.5,
        height: r * .34,
      ),
      shadow,
    );
    final body = Path()
      ..moveTo(center.dx - r * .42, center.dy - r * .58)
      ..lineTo(center.dx - r * .92, center.dy - r * .20)
      ..lineTo(center.dx - r * .62, center.dy + r * .20)
      ..lineTo(center.dx - r * .40, center.dy + r * .04)
      ..lineTo(center.dx - r * .36, center.dy + r * .76)
      ..lineTo(center.dx + r * .36, center.dy + r * .76)
      ..lineTo(center.dx + r * .40, center.dy + r * .04)
      ..lineTo(center.dx + r * .62, center.dy + r * .20)
      ..lineTo(center.dx + r * .92, center.dy - r * .20)
      ..lineTo(center.dx + r * .42, center.dy - r * .58)
      ..close();
    canvas.drawPath(body, Paint()..color = kit.shirt.withValues(alpha: alpha));
    final trim = Paint()
      ..color = kit.trim.withValues(alpha: alpha)
      ..strokeWidth = math.max(1, r * .10)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    if (!player.goalkeeper && player.team == MatchMomentTeam.spain) {
      final shoulder = Paint()
        ..color = kit.trim.withValues(alpha: alpha)
        ..strokeWidth = math.max(.7, r * .05);
      for (final side in [-1.0, 1.0]) {
        for (var stripe = 0; stripe < 3; stripe++) {
          final y = -r * .50 + stripe * r * .085;
          canvas.drawLine(center + Offset(side * r * .42, y),
              center + Offset(side * r * .73, y + r * .21), shoulder);
        }
        final panel = Path()
          ..moveTo(center.dx + side * r * .39, center.dy - r * .10)
          ..quadraticBezierTo(center.dx + side * r * .51, center.dy + r * .35,
              center.dx + side * r * .30, center.dy + r * .70);
        canvas.drawPath(panel, trim);
      }
      canvas.drawLine(center + Offset(-r * .24, -r * .47),
          center + Offset(r * .24, -r * .47), trim);
    } else if (!player.goalkeeper) {
      final collar = Path()
        ..moveTo(center.dx - r * .22, center.dy - r * .57)
        ..lineTo(center.dx, center.dy - r * .37)
        ..lineTo(center.dx + r * .22, center.dy - r * .57);
      canvas.drawPath(collar, trim..strokeWidth = r * .14);
      for (final side in [-1.0, 1.0]) {
        canvas.drawLine(
            center + Offset(side * r * .83, -r * .13),
            center + Offset(side * r * .65, r * .14),
            trim..strokeWidth = r * .08);
        canvas.drawLine(
            center + Offset(side * r * .87, -r * .10),
            center + Offset(side * r * .69, r * .17),
            Paint()
              ..color = const Color(0xFFBB3341).withValues(alpha: alpha)
              ..strokeWidth = r * .04);
      }
    } else {
      canvas.drawLine(center + Offset(-r * .26, -r * .47),
          center + Offset(r * .26, -r * .47), trim);
      for (var i = 0; i < 3; i++) {
        canvas.drawLine(
            center + Offset(-r * .33, r * (.12 + i * .19)),
            center + Offset(r * .33, r * (.02 + i * .19)),
            Paint()
              ..color = kit.trim.withValues(alpha: alpha * .13)
              ..strokeWidth = 1);
      }
    }
    canvas.drawRect(
      Rect.fromCenter(
        center: center + Offset(0, r * .83),
        width: r * .86,
        height: r * .34,
      ),
      Paint()..color = kit.shorts.withValues(alpha: alpha),
    );
    final sockPaint = Paint()
      ..color = kit.socks.withValues(alpha: alpha)
      ..strokeWidth = r * .16
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center + Offset(-r * .20, r * .98),
      center + Offset(-r * .38, r * 1.38),
      sockPaint,
    );
    canvas.drawLine(
      center + Offset(r * .20, r * .98),
      center + Offset(r * .38, r * 1.38),
      sockPaint,
    );
    canvas.drawCircle(
      center + Offset(0, -r * .88),
      r * .23,
      Paint()..color = const Color(0xFFC89369).withValues(alpha: alpha),
    );
    if (player.id == frame.carrierId ||
        player.id == MatchMomentEpisode.spain19) {
      canvas.drawCircle(
        center,
        r * 1.32,
        Paint()
          ..color = player.id == MatchMomentEpisode.spain19
              ? const Color(0xFF238A91)
              : const Color(0xFFE2C57E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    if (player.essential || player.id == frame.carrierId) {
      _drawFacingIndicator(canvas, geometry, state, alpha: alpha);
    }
    _drawText(
      canvas,
      player.number.toString(),
      center + Offset(0, r * .12),
      color: kit.number.withValues(alpha: alpha),
      size: math.max(10.5, r * .68),
      weight: FontWeight.w900,
      anchorMode: _TextAnchor.center,
    );
    // Keep tactical routes and shirt numbers clear in a crowded final third.
    // The current actor/receiver and the two wide attackers retain name labels.
    if (player.id == activeSegment?.actorId ||
        player.id == activeSegment?.receiverId ||
        player.id == frame.carrierId ||
        player.id == MatchMomentEpisode.spain19 ||
        player.id == MatchMomentEpisode.spain17) {
      final label = _shortName(names[player.id] ?? '');
      _drawText(
        canvas,
        label,
        feet + Offset(0, r * .94),
        color: (_dark ? Colors.white : const Color(0xFF17252A))
            .withValues(alpha: .88),
        size: math.max(9.5, geometry.size.shortestSide * .018),
        weight: FontWeight.w700,
        anchorMode: _TextAnchor.center,
      );
    }
  }

  void _drawFacingIndicator(
    Canvas canvas,
    _MatchPitchGeometry geometry,
    MatchMomentActorState state, {
    required double alpha,
  }) {
    final from = state.position;
    final to = ScanPassPoint(
      from.x + math.cos(state.facingRadians) * .018,
      from.y + math.sin(state.facingRadians) * .018,
    );
    final start = geometry.toOffset(from);
    final end = geometry.toOffset(to);
    final paint = Paint()
      ..color = const Color(0xFF2A8FBD).withValues(alpha: alpha * .58)
      ..strokeWidth = 1.15
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, paint);
    _drawArrowHead(canvas, start, end, paint);
  }

  void _drawTouchDetail(Canvas canvas, _MatchPitchGeometry geometry) {
    final segment = activeSegment;
    if (segment == null || segment.kind != MatchMomentActionKind.firstTouch) {
      return;
    }
    final from = geometry.toOffset(segment.before.ball);
    final to = geometry.toOffset(segment.after.ball);
    // The actual short endpoint can sit beneath a jersey in this top-down
    // view. A parallel leader preserves exact direction and length without
    // covering the shirt number or exaggerating the touch distance.
    final side = Offset(from.dx > geometry.size.width / 2 ? -32 : 32, 0);
    final paint = _ballPaint(segment, active: true)..strokeWidth = 2.6;
    final leader = Paint()
      ..color = paint.color.withValues(alpha: .60)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    _drawDashedLine(canvas, from, from + side, leader, dash: 3, gap: 3);
    _drawDashedLine(canvas, to, to + side, leader, dash: 3, gap: 3);
    canvas.drawLine(from + side, to + side, paint);
    _drawArrowHead(canvas, from + side, to + side, paint);
    canvas.drawCircle(to, 4, leader..strokeWidth = 1.5);
  }

  void _drawBall(Canvas canvas, _MatchPitchGeometry geometry) {
    final center = geometry.toOffset(frame.ball);
    final radius =
        math.max(3.5, math.min(6.0, geometry.size.shortestSide * .007));
    canvas.drawCircle(
      center + Offset(radius * .25, radius * .35),
      radius * 1.08,
      Paint()..color = Colors.black.withValues(alpha: .22),
    );
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);
    final outline = Paint()
      ..color = const Color(0xFF101010)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius, outline);
    final pentagon = Path();
    for (var i = 0; i < 5; i++) {
      final angle = -math.pi / 2 + i * math.pi * 2 / 5;
      final unit = Offset(math.cos(angle), math.sin(angle));
      final inner = center + unit * radius * .43;
      if (i == 0) {
        pentagon.moveTo(inner.dx, inner.dy);
      } else {
        pentagon.lineTo(inner.dx, inner.dy);
      }
      canvas.drawLine(
          inner, center + unit * radius, outline..strokeWidth = .65);
      canvas.drawCircle(center + unit * radius * .88, radius * .13,
          Paint()..color = const Color(0xFF101010));
    }
    pentagon.close();
    canvas.drawPath(pentagon, Paint()..color = const Color(0xFF101010));
  }

  void _drawAttackArrow(Canvas canvas, _MatchPitchGeometry geometry) {
    final paint = Paint()
      ..color = (_dark ? Colors.white70 : const Color(0xFF4E655E))
          .withValues(alpha: .72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final start = geometry.attackArrowStart;
    final end = geometry.attackArrowEnd;
    canvas.drawLine(start, end, paint);
    _drawArrowHead(canvas, start, end, paint);
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset point, {
    required Color color,
    required double size,
    required FontWeight weight,
    required _TextAnchor anchorMode,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
          fontFamily: fontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: 120);
    final dx = switch (anchorMode) {
      _TextAnchor.left => point.dx,
      _TextAnchor.center => point.dx - painter.width / 2,
      _TextAnchor.right => point.dx - painter.width,
    };
    painter.paint(canvas, Offset(dx, point.dy - painter.height / 2));
  }

  void _drawArrowHead(Canvas canvas, Offset from, Offset to, Paint paint) {
    final delta = to - from;
    if (delta.distance < 2) return;
    final direction = delta / delta.distance;
    final side = Offset(-direction.dy, direction.dx);
    final path = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo((to - direction * 9 + side * 5).dx,
          (to - direction * 9 + side * 5).dy)
      ..moveTo(to.dx, to.dy)
      ..lineTo((to - direction * 9 - side * 5).dx,
          (to - direction * 9 - side * 5).dy);
    canvas.drawPath(path, paint);
  }

  void _drawArrowHeadForPath(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) return;
    final end = points.last;
    for (var index = points.length - 2; index >= 0; index -= 1) {
      final start = points[index];
      if ((end - start).distance >= 3) {
        _drawArrowHead(canvas, start, end, paint);
        return;
      }
    }
    _drawArrowHead(canvas, points.first, end, paint);
  }

  void _drawPolyline(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
  }

  void _drawDashedPolyline(
    Canvas canvas,
    List<Offset> points,
    Paint paint, {
    double dash = 8,
    double gap = 6,
  }) {
    for (var index = 1; index < points.length; index += 1) {
      _drawDashedLine(
        canvas,
        points[index - 1],
        points[index],
        paint,
        dash: dash,
        gap: gap,
      );
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset from,
    Offset to,
    Paint paint, {
    double dash = 6,
    double gap = 5,
  }) {
    final delta = to - from;
    final length = delta.distance;
    if (length < 2) return;
    final direction = delta / length;
    var travelled = 0.0;
    while (travelled < length) {
      final start = from + direction * travelled;
      final end = from + direction * math.min(travelled + dash, length);
      canvas.drawLine(start, end, paint);
      travelled += dash + gap;
    }
  }

  _MatchKit _kitFor(MatchMomentPlayerDefinition player) {
    if (player.goalkeeper) {
      return player.team == MatchMomentTeam.england
          ? const _MatchKit(
              shirt: Color(0xFFF2CF32),
              trim: Color(0xFF2B2B20),
              shorts: Color(0xFFF2CF32),
              socks: Color(0xFFF2CF32),
              number: Color(0xFF26302A),
            )
          : const _MatchKit(
              shirt: Color(0xFF5BA0D7),
              trim: Color(0xFF0D3155),
              shorts: Color(0xFF143D68),
              socks: Color(0xFF5BA0D7),
              number: Colors.white,
            );
    }
    if (player.team == MatchMomentTeam.spain) {
      return const _MatchKit(
        shirt: Color(0xFFC80F24),
        trim: Color(0xFFFFD447),
        shorts: Color(0xFF174591),
        socks: Color(0xFFC80F24),
        number: Color(0xFFFFD447),
      );
    }
    return const _MatchKit(
      shirt: Color(0xFFF7F7F2),
      trim: Color(0xFF172A55),
      shorts: Color(0xFFF7F7F2),
      socks: Color(0xFFF7F7F2),
      number: Color(0xFF172A55),
    );
  }

  String _shortName(String name) {
    final parts = name.split(' ');
    return parts.isEmpty ? name : parts.last;
  }

  @override
  bool shouldRepaint(covariant _MatchMomentPitchPainter oldDelegate) =>
      oldDelegate.portrait != portrait ||
      oldDelegate.frame != frame ||
      oldDelegate.completedSegments != completedSegments ||
      oldDelegate.activeSegment != activeSegment ||
      oldDelegate.activeSegmentProgress != activeSegmentProgress ||
      oldDelegate.reference != reference ||
      oldDelegate.brightness != brightness ||
      oldDelegate.viewBounds != viewBounds ||
      oldDelegate.emphasizePlayers != emphasizePlayers ||
      oldDelegate.rosterOverride != rosterOverride ||
      oldDelegate.names != names;
}

class _MatchHeightProfilePainter extends CustomPainter {
  final MatchMomentBallHeight height;
  final Color color;
  const _MatchHeightProfilePainter({required this.height, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: .65)
      ..strokeWidth = 1.2;
    final baseline = size.height - 2;
    canvas.drawLine(
        Offset(1, baseline), Offset(size.width - 1, baseline), paint);
    if (height == MatchMomentBallHeight.unknown) {
      for (var x = 3.0; x < size.width - 3; x += 7) {
        canvas.drawLine(Offset(x, 4), Offset(x + 3, 4), paint);
      }
      return;
    }
    final lift = switch (height) {
      MatchMomentBallHeight.ground => 0.0,
      MatchMomentBallHeight.low => 4.0,
      MatchMomentBallHeight.lofted => 8.0,
      MatchMomentBallHeight.unknown => 0.0,
    };
    canvas.drawCircle(
        Offset(size.width / 2, baseline - 2.4 - lift), 2.4, paint);
  }

  @override
  bool shouldRepaint(covariant _MatchHeightProfilePainter oldDelegate) =>
      oldDelegate.height != height || oldDelegate.color != color;
}

class _MatchPitchGeometry {
  static const double defaultMaxX = 1.04;
  final Size size;
  final bool? portrait;
  final Rect? viewBounds;
  late final bool vertical = portrait ?? size.width < size.height * .72;
  late final bool compact = size.height < 420 && !vertical;
  final double headerHeight = 0;
  late final double minX =
      viewBounds?.left ?? (vertical ? .38 : (compact ? .38 : .28));
  late final double maxX = viewBounds?.right ?? defaultMaxX;
  late final double minY =
      viewBounds?.top ?? (vertical ? .14 : (compact ? .23 : 0));
  late final double maxY =
      viewBounds?.bottom ?? (vertical ? .86 : (compact ? .80 : 1));
  late final double lengthMetres = 105 * (maxX - minX);
  late final double widthMetres = 68 * (maxY - minY);
  late final Rect playArea =
      Rect.fromLTRB(0, headerHeight + 8, size.width, size.height);
  late final Rect available = Rect.fromLTWH(
      12,
      headerHeight + 16,
      math.max(1, size.width - 24),
      math.max(1, size.height - headerHeight - 28));
  late final double scale = vertical
      ? math.min(available.width / widthMetres, available.height / lengthMetres)
      : math.min(
          available.width / lengthMetres, available.height / widthMetres);
  late final Rect viewportRect = Rect.fromCenter(
    center: available.center,
    width: (vertical ? widthMetres : lengthMetres) * scale,
    height: (vertical ? lengthMetres : widthMetres) * scale,
  );
  late final Rect fieldRect = rectFor(0, 0, 1, 1);

  _MatchPitchGeometry(
    this.size, {
    this.portrait,
    this.viewBounds,
  });

  Offset toOffset(ScanPassPoint point) {
    // Lateral episode coordinates run from Spain's right flank to its left.
    // Preserve that football direction in both portrait and landscape views.
    if (vertical) {
      return Offset(viewportRect.right - (point.y - minY) * 68 * scale,
          viewportRect.bottom - (point.x - minX) * 105 * scale);
    }
    return Offset(viewportRect.left + (point.x - minX) * 105 * scale,
        viewportRect.bottom - (point.y - minY) * 68 * scale);
  }

  Rect rectFor(double x1, double y1, double x2, double y2) {
    final a = toOffset(ScanPassPoint(x1, y1));
    final b = toOffset(ScanPassPoint(x2, y2));
    return Rect.fromLTRB(math.min(a.dx, b.dx), math.min(a.dy, b.dy),
        math.max(a.dx, b.dx), math.max(a.dy, b.dy));
  }

  Offset get attackArrowStart => vertical
      ? Offset(viewportRect.right - 14, viewportRect.top + 76)
      : Offset(viewportRect.right - 84, viewportRect.top + 15);
  Offset get attackArrowEnd => vertical
      ? Offset(viewportRect.right - 14, viewportRect.top + 18)
      : Offset(viewportRect.right - 18, viewportRect.top + 15);
}

class _MatchKit {
  final Color shirt;
  final Color trim;
  final Color shorts;
  final Color socks;
  final Color number;

  const _MatchKit({
    required this.shirt,
    required this.trim,
    required this.shorts,
    required this.socks,
    required this.number,
  });
}
