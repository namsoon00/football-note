import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  MethodChannel? _channel;

  @override
  void didUpdateWidget(covariant RunningThreeDRunnerPlatformView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.payloadJson != widget.payloadJson) {
      _sendPayload();
    }
  }

  Future<void> _sendPayload() async {
    final channel = _channel;
    if (channel == null) return;
    try {
      await channel.invokeMethod<void>('setPayload', widget.payloadJson);
    } on MissingPluginException {
      // The visible platform state below covers non-iOS runtimes.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS) {
      return _UnavailablePanel(message: widget.unavailableLabel);
    }
    return UiKitView(
      key: const ValueKey('running-coach-3d-runner-uikit-view'),
      viewType: 'football_note/running_3d_runner',
      creationParams: <String, Object?>{
        'payload': widget.payloadJson,
        'loadingLabel': widget.loadingLabel,
      },
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: (id) {
        _channel = MethodChannel('football_note/running_3d_runner/$id');
        _sendPayload();
      },
    );
  }
}

class _UnavailablePanel extends StatelessWidget {
  final String message;

  const _UnavailablePanel({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      key: const ValueKey('running-coach-3d-runner-platform-unavailable'),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ),
    );
  }
}
