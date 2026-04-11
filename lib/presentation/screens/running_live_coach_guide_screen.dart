import 'package:flutter/material.dart';

import '../../gen/app_localizations.dart';

class RunningLiveCoachGuideScreen extends StatelessWidget {
  final VoidCallback? onStart;

  const RunningLiveCoachGuideScreen({
    super.key,
    this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.runningCoachLiveGuideScreenTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    scheme.primary.withAlpha(220),
                    scheme.secondaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.runningCoachLiveGuideHeroTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.runningCoachLiveGuideHeroBody,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: scheme.onPrimary,
                        ),
                  ),
                  const SizedBox(height: 18),
                  const _GuidePreviewIllustration(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _GuideTipCard(
            icon: Icons.view_sidebar_outlined,
            title: l10n.runningCoachLiveGuideTipSideTitle,
            body: l10n.runningCoachLiveGuideTipSideBody,
          ),
          const SizedBox(height: 12),
          _GuideTipCard(
            icon: Icons.fit_screen_outlined,
            title: l10n.runningCoachLiveGuideTipBodyTitle,
            body: l10n.runningCoachLiveGuideTipBodyBody,
          ),
          const SizedBox(height: 12),
          _GuideTipCard(
            icon: Icons.space_dashboard_outlined,
            title: l10n.runningCoachLiveGuideTipHudTitle,
            body: l10n.runningCoachLiveGuideTipHudBody,
          ),
          const SizedBox(height: 12),
          _GuideTipCard(
            icon: Icons.trip_origin_outlined,
            title: l10n.runningCoachLiveGuideTipCameraTitle,
            body: l10n.runningCoachLiveGuideTipCameraBody,
          ),
          if (onStart != null) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onStart?.call();
              },
              icon: const Icon(Icons.videocam_outlined),
              label: Text(l10n.runningCoachLiveAction),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0x22FFFFFF),
          borderRadius: BorderRadius.circular(28),
        ),
        child: const CustomPaint(
          painter: _GuidePreviewPainter(
            frameColor: Color(0xFF8BC34A),
            accentColor: Color(0xFF73F3B4),
          ),
        ),
      ),
    );
  }
}

class _GuidePreviewPainter extends CustomPainter {
  final Color frameColor;
  final Color accentColor;

  const _GuidePreviewPainter({
    required this.frameColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final frameRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.56,
      height: size.height * 0.78,
    );
    final framePaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, const Radius.circular(28)),
      framePaint,
    );

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
    return oldDelegate.frameColor != frameColor ||
        oldDelegate.accentColor != accentColor;
  }
}
