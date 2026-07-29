import 'package:flutter/material.dart';

class RunningThreeDRunnerPlatformView extends StatelessWidget {
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
            unavailableLabel,
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
