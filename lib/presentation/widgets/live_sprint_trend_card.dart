import 'package:flutter/material.dart';

import '../../application/live_sprint_trend_service.dart';
import '../../domain/entities/running_coach_session.dart';
import '../../gen/app_localizations.dart';

class LiveSprintTrendCard extends StatelessWidget {
  final LiveSprintTrendSummary summary;
  final Key? cardKey;
  final int maximumMetricRows;

  const LiveSprintTrendCard({
    super.key,
    required this.summary,
    this.cardKey,
    this.maximumMetricRows = 3,
  });

  @override
  Widget build(BuildContext context) {
    if (!summary.hasLiveSessions) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final trends = summary.highlightedMetricTrends
        .take(maximumMetricRows)
        .toList(growable: false);
    return Card(
      key: cardKey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline_rounded, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.runningCoachLiveTrendTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _statusBody(l10n),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (summary.isReady && trends.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (var index = 0; index < trends.length; index += 1) ...[
                _LiveSprintTrendMetricRow(trend: trends[index]),
                if (index != trends.length - 1) const Divider(height: 20),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _statusBody(AppLocalizations l10n) {
    return switch (summary.status) {
      LiveSprintTrendStatus.ready =>
        l10n.runningCoachLiveTrendReadyBody(summary.baselineSessionCount),
      LiveSprintTrendStatus.needsMoreSessions =>
        summary.additionalStableSessionsNeeded == 1
            ? l10n.runningCoachLiveTrendNeedOneSessionBody
            : l10n.runningCoachLiveTrendNeedSessionsBody(
                summary.additionalStableSessionsNeeded,
              ),
      LiveSprintTrendStatus.captureQualityLow =>
        l10n.runningCoachLiveTrendQualityBody,
      LiveSprintTrendStatus.noSessions => '',
    };
  }
}

class _LiveSprintTrendMetricRow extends StatelessWidget {
  final LiveSprintMetricTrend trend;

  const _LiveSprintTrendMetricRow({required this.trend});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final color = _trendColor(scheme, trend.signal);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(_metricIcon(trend.kind), color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _metricLabel(l10n, trend.kind),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                _signalLabel(l10n, trend.signal),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.runningCoachLiveTrendComparison(
                  _metricValue(l10n, trend.kind, trend.currentValue),
                  _metricValue(l10n, trend.kind, trend.baselineValue),
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Color _trendColor(ColorScheme scheme, LiveSprintTrendSignal signal) {
  return switch (signal) {
    LiveSprintTrendSignal.improved => scheme.tertiary,
    LiveSprintTrendSignal.steady => scheme.onSurfaceVariant,
    LiveSprintTrendSignal.needsAttention => scheme.error,
  };
}

String _signalLabel(
  AppLocalizations l10n,
  LiveSprintTrendSignal signal,
) {
  return switch (signal) {
    LiveSprintTrendSignal.improved => l10n.runningCoachLiveTrendImproved,
    LiveSprintTrendSignal.steady => l10n.runningCoachLiveTrendSteady,
    LiveSprintTrendSignal.needsAttention =>
      l10n.runningCoachLiveTrendNeedsAttention,
  };
}

IconData _metricIcon(LiveSprintMetricKind kind) {
  return switch (kind) {
    LiveSprintMetricKind.trunkAngle => Icons.straighten_rounded,
    LiveSprintMetricKind.kneeDrive => Icons.arrow_upward_rounded,
    LiveSprintMetricKind.cadence => Icons.speed_rounded,
    LiveSprintMetricKind.rhythm => Icons.graphic_eq_rounded,
    LiveSprintMetricKind.armBalance => Icons.compare_arrows_rounded,
    LiveSprintMetricKind.landing => Icons.south_rounded,
    LiveSprintMetricKind.flightRatio => Icons.flight_takeoff_rounded,
    LiveSprintMetricKind.lateForm => Icons.timer_outlined,
  };
}

String _metricLabel(AppLocalizations l10n, LiveSprintMetricKind kind) {
  return switch (kind) {
    LiveSprintMetricKind.trunkAngle => l10n.runningCoachSprintMetricTrunkLabel,
    LiveSprintMetricKind.kneeDrive =>
      l10n.runningCoachSprintMetricKneeDriveLabel,
    LiveSprintMetricKind.cadence => l10n.runningCoachSprintMetricCadenceLabel,
    LiveSprintMetricKind.rhythm => l10n.runningCoachSprintMetricRhythmLabel,
    LiveSprintMetricKind.armBalance =>
      l10n.runningCoachSprintMetricArmBalanceLabel,
    LiveSprintMetricKind.landing => l10n.runningCoachSprintMetricLandingLabel,
    LiveSprintMetricKind.flightRatio =>
      l10n.runningCoachSprintMetricFlightLabel,
    LiveSprintMetricKind.lateForm => l10n.runningCoachSprintMetricLateFormLabel,
  };
}

String _metricValue(
  AppLocalizations l10n,
  LiveSprintMetricKind kind,
  double value,
) {
  return switch (kind) {
    LiveSprintMetricKind.trunkAngle =>
      l10n.runningCoachSprintMetricTrunkValue(value.toStringAsFixed(1)),
    LiveSprintMetricKind.kneeDrive =>
      l10n.runningCoachSprintMetricKneeDriveValue((value * 100).round()),
    LiveSprintMetricKind.cadence =>
      l10n.runningCoachSprintMetricCadenceValue(value.round()),
    LiveSprintMetricKind.rhythm =>
      l10n.runningCoachSprintMetricRhythmValue(value.toStringAsFixed(0)),
    LiveSprintMetricKind.armBalance =>
      l10n.runningCoachSprintMetricArmBalanceValue((value * 100).round()),
    LiveSprintMetricKind.landing =>
      l10n.runningCoachLiveTrendLandingValue((value * 100).round()),
    LiveSprintMetricKind.flightRatio =>
      l10n.runningCoachSprintMetricFlightValue((value * 100).round()),
    LiveSprintMetricKind.lateForm =>
      l10n.runningCoachSprintMetricLateFormValue((value * 100).round()),
  };
}
