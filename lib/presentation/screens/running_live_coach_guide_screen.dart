import 'package:flutter/material.dart';

import '../../gen/app_localizations.dart';
import '../theme/app_theme.dart';

class RunningLiveCoachGuideScreen extends StatelessWidget {
  final VoidCallback? onStart;
  final String? primaryStartLabel;
  final IconData? primaryStartIcon;
  final VoidCallback? secondaryStart;
  final String? secondaryStartLabel;
  final IconData? secondaryStartIcon;

  const RunningLiveCoachGuideScreen({
    super.key,
    this.onStart,
    this.primaryStartLabel,
    this.primaryStartIcon,
    this.secondaryStart,
    this.secondaryStartLabel,
    this.secondaryStartIcon,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.runningCoachLiveGuideScreenTitle)),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          Container(
            decoration: AppSurfaces.heroDecoration(
              scheme,
              theme.brightness,
              accent: scheme.primary,
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.runningCoachLiveGuideHeroTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.runningCoachLiveGuideHeroBody,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 18),
                const _GuidePreviewIllustration(),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _GuideTipCard(
            icon: Icons.view_sidebar_outlined,
            title: l10n.runningCoachLiveGuideTipSideTitle,
            body: l10n.runningCoachLiveGuideTipSideBody,
          ),
          const SizedBox(height: AppSpacing.sm),
          _GuideTipCard(
            icon: Icons.fit_screen_outlined,
            title: l10n.runningCoachLiveGuideTipBodyTitle,
            body: l10n.runningCoachLiveGuideTipBodyBody,
          ),
          const SizedBox(height: AppSpacing.sm),
          _GuideTipCard(
            icon: Icons.space_dashboard_outlined,
            title: l10n.runningCoachLiveGuideTipHudTitle,
            body: l10n.runningCoachLiveGuideTipHudBody,
          ),
          const SizedBox(height: AppSpacing.sm),
          _GuideTipCard(
            icon: Icons.trip_origin_outlined,
            title: l10n.runningCoachLiveGuideTipCameraTitle,
            body: l10n.runningCoachLiveGuideTipCameraBody,
          ),
          if (onStart != null || secondaryStart != null) ...[
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (onStart != null)
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onStart?.call();
                    },
                    icon: Icon(primaryStartIcon ?? Icons.videocam_outlined),
                    label: Text(
                      primaryStartLabel ?? l10n.runningCoachLiveAction,
                    ),
                  ),
                if (secondaryStart != null)
                  FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      secondaryStart?.call();
                    },
                    icon: Icon(
                      secondaryStartIcon ?? Icons.directions_run_rounded,
                    ),
                    label: Text(
                      secondaryStartLabel ?? l10n.runningCoachSprintLiveAction,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GuideTipCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _GuideTipCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      decoration: AppSurfaces.cardDecoration(scheme, theme.brightness),
      child: Padding(
        padding: AppSpacing.card,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: AppRadius.control,
              ),
              child: Icon(icon),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuidePreviewIllustration extends StatelessWidget {
  const _GuidePreviewIllustration();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: AppRadius.surface,
        ),
        child: CustomPaint(
          painter: _GuidePreviewPainter(accentColor: scheme.secondaryContainer),
        ),
      ),
    );
  }
}

class _GuidePreviewPainter extends CustomPainter {
  final Color accentColor;

  const _GuidePreviewPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final labelPaint = Paint()
      ..color = Colors.white.withAlpha(38)
      ..style = PaintingStyle.fill;
    final leftHud = RRect.fromRectAndRadius(
      Rect.fromLTWH(12, size.height - 104, 92, 72),
      const Radius.circular(18),
    );
    final rightHud = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width - 104, size.height * 0.28, 92, 124),
      const Radius.circular(18),
    );
    canvas.drawRRect(leftHud, labelPaint);
    canvas.drawRRect(rightHud, labelPaint);

    final bodyPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final shoulderCenter = Offset(size.width / 2, size.height * 0.32);
    final hipCenter = Offset(size.width / 2, size.height * 0.52);
    final frontKnee = Offset(size.width * 0.58, size.height * 0.65);
    final rearKnee = Offset(size.width * 0.46, size.height * 0.7);
    final frontFoot = Offset(size.width * 0.62, size.height * 0.82);
    final rearFoot = Offset(size.width * 0.44, size.height * 0.84);
    final head = Offset(size.width / 2, size.height * 0.19);
    final bodyOutline = Path()
      ..moveTo(size.width * 0.47, size.height * 0.12)
      ..quadraticBezierTo(
        size.width * 0.62,
        size.height * 0.18,
        size.width * 0.62,
        size.height * 0.44,
      )
      ..quadraticBezierTo(
        size.width * 0.66,
        size.height * 0.68,
        size.width * 0.62,
        size.height * 0.86,
      )
      ..lineTo(size.width * 0.42, size.height * 0.88)
      ..quadraticBezierTo(
        size.width * 0.36,
        size.height * 0.62,
        size.width * 0.38,
        size.height * 0.28,
      )
      ..close();
    final outlineFillPaint = Paint()
      ..color = accentColor.withAlpha(20)
      ..style = PaintingStyle.fill;
    final outlineStrokePaint = Paint()
      ..color = accentColor.withAlpha(170)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(bodyOutline, outlineFillPaint);
    canvas.drawPath(bodyOutline, outlineStrokePaint);

    canvas.drawCircle(head, 14, bodyPaint);
    canvas.drawLine(
      shoulderCenter.translate(-22, 0),
      shoulderCenter.translate(22, 2),
      bodyPaint,
    );
    canvas.drawLine(shoulderCenter, hipCenter, bodyPaint);
    canvas.drawLine(
      shoulderCenter.translate(-18, 8),
      shoulderCenter.translate(-42, 34),
      bodyPaint,
    );
    canvas.drawLine(
      shoulderCenter.translate(18, 8),
      shoulderCenter.translate(36, 42),
      bodyPaint,
    );
    canvas.drawLine(hipCenter, frontKnee, bodyPaint);
    canvas.drawLine(frontKnee, frontFoot, bodyPaint);
    canvas.drawLine(hipCenter, rearKnee, bodyPaint);
    canvas.drawLine(rearKnee, rearFoot, bodyPaint);
  }

  @override
  bool shouldRepaint(covariant _GuidePreviewPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor;
  }
}
