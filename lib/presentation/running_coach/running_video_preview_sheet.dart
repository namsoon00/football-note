import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../application/running_video_analysis_service.dart';
import '../../application/running_coach_evidence_archive.dart';
import '../../domain/entities/running_video_analysis_result.dart';
import '../../gen/app_localizations.dart';
import 'running_pose_overlay.dart';
import '../screens/running_video_player_source.dart';

enum RunningVideoPreviewAction { confirm, change, retake, cancel }

class RunningVideoPreviewResult {
  final RunningVideoPreviewAction action;
  final XFile? video;
  final RunningVideoAnalysisResult? analysis;

  const RunningVideoPreviewResult(this.action, [this.video, this.analysis]);
}

typedef RunningVideoPosePreviewAnalyzer = Future<RunningVideoPosePreviewResult>
    Function(XFile video);

Future<RunningVideoPreviewResult?> showRunningVideoPreviewSheet({
  required BuildContext context,
  required List<XFile> candidates,
  required bool isCapturedVideo,
  String? runnerDisplayName,
  RunningVideoPosePreviewAnalyzer? analyzer,
  Duration previewTimeout =
      RunningVideoAnalysisService.previewPoseAnalysisTimeout,
}) {
  if (candidates.isEmpty) return Future.value(null);
  return showModalBottomSheet<RunningVideoPreviewResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => SizedBox(
      height: MediaQuery.sizeOf(sheetContext).height * 0.92,
      child: RunningVideoPreviewSheet(
        candidates: candidates,
        isCapturedVideo: isCapturedVideo,
        runnerDisplayName: runnerDisplayName,
        analyzer: analyzer,
        previewTimeout: previewTimeout,
      ),
    ),
  );
}

class RunningVideoPreviewSheet extends StatefulWidget {
  final List<XFile> candidates;
  final bool isCapturedVideo;
  final String? runnerDisplayName;
  final RunningVideoPosePreviewAnalyzer? analyzer;
  final Duration previewTimeout;

  const RunningVideoPreviewSheet({
    super.key,
    required this.candidates,
    required this.isCapturedVideo,
    this.runnerDisplayName,
    this.analyzer,
    this.previewTimeout =
        RunningVideoAnalysisService.previewPoseAnalysisTimeout,
  });

  @override
  State<RunningVideoPreviewSheet> createState() =>
      _RunningVideoPreviewSheetState();
}

class _RunningVideoPreviewSheetState extends State<RunningVideoPreviewSheet> {
  VideoPlayerController? _controller;
  var _selectedIndex = 0;
  var _loadGeneration = 0;
  var _isLoading = true;
  var _isUnavailable = false;
  int? _videoBytes;
  final Map<int, Uint8List> _thumbnails = <int, Uint8List>{};
  final Map<int, RunningVideoPosePreviewResult> _analyses =
      <int, RunningVideoPosePreviewResult>{};
  final Map<int, Future<RunningVideoPosePreviewResult>> _analysisRequests =
      <int, Future<RunningVideoPosePreviewResult>>{};
  var _isAnalyzingPreview = false;
  var _previewAnalysisFailed = false;

  XFile get _selected => widget.candidates[_selectedIndex];

  @override
  void initState() {
    super.initState();
    unawaited(_loadSelected());
    unawaited(_loadCandidateThumbnails());
  }

  Future<void> _loadCandidateThumbnails() async {
    // Extraction is intentionally sequential so candidate selection never
    // holds several video decoders/controllers at once.
    for (var index = 0; index < widget.candidates.length; index += 1) {
      if (_thumbnails.containsKey(index)) continue;
      final bytes = await extractRunningVideoThumbnail(
        widget.candidates[index],
      );
      if (!mounted) return;
      if (bytes != null && bytes.isNotEmpty) {
        setState(() => _thumbnails[index] = bytes);
      }
    }
  }

  @override
  void dispose() {
    _loadGeneration += 1;
    unawaited(_controller?.dispose());
    super.dispose();
  }

  Future<void> _loadSelected() async {
    final generation = ++_loadGeneration;
    final previous = _controller;
    _controller = null;
    setState(() {
      _isLoading = true;
      _isUnavailable = false;
      _videoBytes = null;
      _isAnalyzingPreview = false;
      _previewAnalysisFailed = false;
    });
    await previous?.dispose();
    if (!mounted || generation != _loadGeneration) return;
    unawaited(_loadSelectedLength(_selected, generation));
    VideoPlayerController? controller;
    try {
      controller = await openRunningVideoPlayer(_selected.path);
      if (controller == null) throw StateError('preview_unavailable');
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (!mounted || generation != _loadGeneration) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _isLoading = false;
      });
      unawaited(_loadSelectedAnalysis(generation));
    } catch (_) {
      await controller?.dispose();
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _isLoading = false;
        _isUnavailable = true;
      });
    }
  }

  Future<void> _loadSelectedAnalysis(int generation) async {
    final analyzer = widget.analyzer;
    if (analyzer == null || _analyses.containsKey(_selectedIndex)) return;
    final index = _selectedIndex;
    setState(() {
      _isAnalyzingPreview = true;
      _previewAnalysisFailed = false;
    });
    try {
      final result = await _analysisRequests.putIfAbsent(
        index,
        () => analyzer(widget.candidates[index]).timeout(
          widget.previewTimeout,
        ),
      );
      if (result.poseFrames.isEmpty) {
        throw StateError('preview_pose_unavailable');
      }
      if (!mounted ||
          generation != _loadGeneration ||
          index != _selectedIndex) {
        return;
      }
      setState(() {
        _analyses[index] = result;
        _isAnalyzingPreview = false;
      });
    } catch (_) {
      _analysisRequests.remove(index);
      if (!mounted ||
          generation != _loadGeneration ||
          index != _selectedIndex) {
        return;
      }
      setState(() {
        _isAnalyzingPreview = false;
        _previewAnalysisFailed = true;
      });
    }
  }

  void _retryPreviewAnalysis() {
    _analysisRequests.remove(_selectedIndex);
    _analyses.remove(_selectedIndex);
    unawaited(_loadSelectedAnalysis(_loadGeneration));
  }

  void _confirmSelected() {
    final index = _selectedIndex;
    final video = widget.candidates[index];
    if (!mounted) return;
    Navigator.of(context).pop(
      RunningVideoPreviewResult(
        RunningVideoPreviewAction.confirm,
        video,
      ),
    );
  }

  Future<void> _loadSelectedLength(XFile video, int generation) async {
    try {
      final length = await video.length();
      if (!mounted || generation != _loadGeneration) return;
      setState(() => _videoBytes = length);
    } catch (_) {
      // Size is advisory. Preview and analysis can continue when a picker
      // implementation cannot expose it independently of reading the file.
    }
  }

  void _selectCandidate(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    unawaited(_loadSelected());
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    if (mounted) setState(() {});
  }

  Future<void> _scrubTo(double milliseconds) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    await controller.seekTo(Duration(milliseconds: milliseconds.round()));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = _controller;
    final value = controller?.value;
    final duration = value?.duration ?? Duration.zero;
    final previewAnalysis = _analyses[_selectedIndex];
    final perspective = previewAnalysis?.perspectiveQuality;
    final warnings = <String>[
      if (duration > const Duration(seconds: 60))
        l10n.runningCoachPreviewLongVideoWarning,
      if (kIsWeb && (_videoBytes ?? 0) > 64 * 1024 * 1024)
        l10n.runningCoachPreviewLargeWebVideoWarning,
      if (!kIsWeb &&
          (_videoBytes ?? 0) >
              RunningVideoAnalysisService.proxyPreferredVideoBytes)
        l10n.runningCoachPreviewLargeVideoWarning,
      if (value != null &&
          value.isInitialized &&
          (value.size.width < 320 || value.size.height < 240))
        l10n.runningCoachPreviewResolutionWarning,
    ];
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isCapturedVideo
                      ? l10n.runningCoachCapturedPreviewTitle
                      : l10n.runningCoachCandidatePreviewTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                if (widget.runnerDisplayName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.runningCoachRunnerTarget(widget.runnerDisplayName!),
                    key: const ValueKey(
                      'running-coach-preview-runner-name',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (widget.candidates.length > 1)
            SizedBox(
              key: const ValueKey('running-coach-video-candidates'),
              height: 76,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: widget.candidates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final selected = index == _selectedIndex;
                  return InkWell(
                    key: ValueKey('running-coach-video-candidate-$index'),
                    onTap: () => _selectCandidate(index),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 144,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              key: ValueKey(
                                'running-coach-video-thumbnail-$index',
                              ),
                              width: 42,
                              height: 48,
                              child: _thumbnails[index] == null
                                  ? ColoredBox(
                                      color: Colors.black,
                                      child: Icon(
                                        selected
                                            ? Icons.play_circle_fill_rounded
                                            : Icons.movie_outlined,
                                        color: Colors.white70,
                                      ),
                                    )
                                  : Image.memory(
                                      _thumbnails[index]!,
                                      fit: BoxFit.cover,
                                      gaplessPlayback: true,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.candidates[index].name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ColoredBox(
                        color: Colors.black,
                        child: Center(
                          child: _isLoading
                              ? const Icon(
                                  Icons.video_file_outlined,
                                  color: Colors.white70,
                                  size: 36,
                                )
                              : _isUnavailable || value == null
                                  ? Text(
                                      l10n.runningCoachPreviewUnavailable,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    )
                                  : AspectRatio(
                                      aspectRatio: value.aspectRatio <= 0
                                          ? 16 / 9
                                          : value.aspectRatio,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          VideoPlayer(controller!),
                                          if (previewAnalysis != null)
                                            Positioned.fill(
                                              child: IgnorePointer(
                                                child: AnimatedBuilder(
                                                  animation: controller,
                                                  builder: (context, _) {
                                                    final frame =
                                                        runningPoseFrameAtPosition(
                                                      frames: previewAnalysis
                                                          .poseFrames,
                                                      position: controller
                                                          .value.position,
                                                    );
                                                    final scheme =
                                                        Theme.of(context)
                                                            .colorScheme;
                                                    return CustomPaint(
                                                      key: const ValueKey(
                                                        'running-coach-preview-pose-overlay',
                                                      ),
                                                      painter:
                                                          RunningPoseFrameOverlayPainter(
                                                        poseFrame: frame,
                                                        fit: BoxFit.contain,
                                                        primaryColor:
                                                            scheme.primary,
                                                        secondaryColor:
                                                            scheme.tertiary,
                                                        jointColor:
                                                            Colors.white,
                                                        focusColor:
                                                            scheme.secondary,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          if (_isAnalyzingPreview)
                                            Positioned(
                                              top: 10,
                                              right: 10,
                                              child: _PreviewAnalysisBadge(
                                                label: l10n
                                                    .runningCoachPreviewPoseAnalyzing,
                                                isLoading: true,
                                              ),
                                            )
                                          else if (_previewAnalysisFailed)
                                            Positioned(
                                              top: 10,
                                              right: 10,
                                              child: _PreviewAnalysisBadge(
                                                label: l10n
                                                    .runningCoachPreviewPoseUnavailable,
                                                isLoading: false,
                                                actionLabel: l10n
                                                    .runningCoachPreviewPoseRetryAction,
                                                onActionPressed:
                                                    _retryPreviewAnalysis,
                                              ),
                                            ),
                                          Center(
                                            child: IconButton.filledTonal(
                                              key: const ValueKey(
                                                'running-coach-preview-play',
                                              ),
                                              onPressed: _togglePlayback,
                                              icon: Icon(
                                                value.isPlaying
                                                    ? Icons.pause_rounded
                                                    : Icons.play_arrow_rounded,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (value?.isInitialized == true)
                    AnimatedBuilder(
                      animation: controller!,
                      builder: (context, _) {
                        final current = controller.value.position;
                        final total = controller.value.duration;
                        final maximum = mathMaxMilliseconds(total);
                        return Column(
                          children: [
                            Slider(
                              key: const ValueKey(
                                'running-coach-preview-scrubber',
                              ),
                              min: 0,
                              max: maximum.toDouble(),
                              value: current.inMilliseconds
                                  .clamp(0, maximum)
                                  .toDouble(),
                              onChanged: _scrubTo,
                            ),
                            Text(
                              l10n.runningCoachPreviewTimeline(
                                _durationText(current),
                                _durationText(total),
                              ),
                              key: const ValueKey(
                                'running-coach-preview-timeline',
                              ),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        );
                      },
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selected.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        l10n.runningCoachPreviewVideoInfo(
                          _durationText(duration),
                          _sizeText(l10n, _videoBytes),
                          value == null
                              ? l10n.runningCoachPreviewUnknownInfo
                              : '${value.size.width.round()}×${value.size.height.round()}',
                        ),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _PreviewCheckChip(
                        icon: Icons.accessibility_new_rounded,
                        label: l10n.runningCoachPreviewCheckFullBody,
                        isReady: perspective == null
                            ? null
                            : !perspective.issues.contains(
                                RunningVideoQualityIssue.bodyCutOff,
                              ),
                      ),
                      _PreviewCheckChip(
                        icon: Icons.compare_arrows_rounded,
                        label: l10n.runningCoachPreviewCheckSide,
                        isReady: perspective == null
                            ? null
                            : !perspective.issues.contains(
                                RunningVideoQualityIssue.notSideOn,
                              ),
                      ),
                      _PreviewCheckChip(
                        icon: Icons.hd_outlined,
                        label: l10n.runningCoachPreviewCheckClarity,
                        isReady: previewAnalysis == null
                            ? null
                            : previewAnalysis.validFrameCoverage >= 0.55,
                      ),
                    ],
                  ),
                  if (warnings.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        warnings.first,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('running-coach-preview-change'),
                    onPressed: () => Navigator.of(context).pop(
                      RunningVideoPreviewResult(
                        widget.isCapturedVideo
                            ? RunningVideoPreviewAction.retake
                            : RunningVideoPreviewAction.change,
                      ),
                    ),
                    child: Text(
                      widget.isCapturedVideo
                          ? l10n.runningCoachCaptureAgainAction
                          : l10n.runningCoachChangeVideoAction,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('running-coach-preview-confirm'),
                    onPressed: _confirmSelected,
                    child: Text(
                      l10n.runningCoachPreviewAnalyzeAction,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewCheckChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool? isReady;

  const _PreviewCheckChip({
    required this.icon,
    required this.label,
    required this.isReady,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (isReady) {
      true => scheme.primary,
      false => scheme.error,
      null => scheme.onSurfaceVariant,
    };
    final stateIcon = switch (isReady) {
      true => Icons.check_circle_rounded,
      false => Icons.error_outline_rounded,
      null => icon,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(stateIcon, size: 15, color: color),
            const SizedBox(width: 4),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _PreviewAnalysisBadge extends StatelessWidget {
  final String label;
  final bool isLoading;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  const _PreviewAnalysisBadge({
    required this.label,
    required this.isLoading,
    this.actionLabel,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox.square(
                dimension: 13,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: Colors.white,
                ),
              )
            else
              const Icon(Icons.visibility_off_outlined,
                  size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(width: 6),
              TextButton(
                key: const ValueKey('running-coach-preview-pose-retry'),
                onPressed: onActionPressed,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                  minimumSize: const Size(44, 28),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  actionLabel!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

int mathMaxMilliseconds(Duration duration) =>
    duration.inMilliseconds <= 0 ? 1 : duration.inMilliseconds;

String _durationText(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60);
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

String _sizeText(AppLocalizations l10n, int? bytes) {
  if (bytes == null || bytes <= 0) return l10n.runningCoachPreviewUnknownInfo;
  final megabytes = bytes / (1024 * 1024);
  return l10n.runningCoachPreviewMegabytes(
    megabytes.toStringAsFixed(megabytes >= 10 ? 0 : 1),
  );
}
