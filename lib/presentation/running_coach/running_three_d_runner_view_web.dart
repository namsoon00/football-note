// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

import 'running_three_d_runner.dart';

class RunningThreeDRunnerPlatformView extends StatefulWidget {
  final String payloadJson;
  final String loadingLabel;
  final String unavailableLabel;

  const RunningThreeDRunnerPlatformView({
    super.key,
    required this.payloadJson,
    required this.loadingLabel,
    required this.unavailableLabel,
  });

  @override
  State<RunningThreeDRunnerPlatformView> createState() =>
      _RunningThreeDRunnerPlatformViewState();
}

class _RunningThreeDRunnerPlatformViewState
    extends State<RunningThreeDRunnerPlatformView> {
  static int _nextViewId = 0;

  late final String _viewType;
  html.IFrameElement? _iframe;
  StreamSubscription<html.Event>? _loadSubscription;

  @override
  void initState() {
    super.initState();
    _viewType = 'football-note-running-3d-runner-${_nextViewId++}';
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = _rendererAssetUrl()
          ..title = widget.loadingLabel
          ..style.border = '0'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.display = 'block'
          ..setAttribute('scrolling', 'no');
        _iframe = iframe;
        _loadSubscription?.cancel();
        _loadSubscription = iframe.onLoad.listen((_) => _postPayload());
        scheduleMicrotask(_postPayload);
        return iframe;
      },
    );
  }

  @override
  void didUpdateWidget(covariant RunningThreeDRunnerPlatformView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.payloadJson != widget.payloadJson) {
      _postPayload();
    }
  }

  @override
  void dispose() {
    _loadSubscription?.cancel();
    super.dispose();
  }

  void _postPayload() {
    final iframe = _iframe;
    final targetWindow = iframe?.contentWindow;
    if (targetWindow == null) return;
    targetWindow.postMessage(
      <String, Object?>{
        'type': 'football-note-running-3d-runner-payload',
        'payload': widget.payloadJson,
      },
      '*',
    );
  }

  String _rendererAssetUrl() {
    final assetUri =
        Uri.base.resolve('assets/assets/running_coach_3d_runner/runner.html');
    return assetUri.replace(
      queryParameters: <String, String>{
        'v': runningThreeDRendererVersion,
      },
    ).toString();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(
      key: const ValueKey('running-coach-3d-runner-html-view'),
      viewType: _viewType,
    );
  }
}
