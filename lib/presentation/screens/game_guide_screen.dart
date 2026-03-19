import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';

class GameGuideScreen extends StatelessWidget {
  const GameGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.gameGuideTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _GuideSection(
            title: l10n.gameGuideQuickTitle,
            icon: Icons.flash_on_outlined,
            lines: [
              l10n.gameGuideQuickLine1,
              l10n.gameGuideQuickLine2,
              l10n.gameGuideQuickLine3,
              l10n.gameGuideQuickLine4,
            ],
          ),
          const SizedBox(height: 12),
          _GuideSection(
            title: l10n.gameGuideRiskTitle,
            icon: Icons.balance_outlined,
            lines: [
              l10n.gameGuideRiskLine1,
              l10n.gameGuideRiskLine2,
              l10n.gameGuideRiskLine3,
              l10n.gameGuideRiskLine4,
            ],
          ),
          const SizedBox(height: 12),
          _GuideSection(
            title: l10n.gameGuideFailureTitle,
            icon: Icons.rule_folder_outlined,
            lines: [
              l10n.gameGuideFailureLine1,
              l10n.gameGuideFailureLine2,
              l10n.gameGuideFailureLine3,
              l10n.gameGuideFailureLine4,
            ],
          ),
          const SizedBox(height: 12),
          _GuideSection(
            title: l10n.gameGuideRankingTitle,
            icon: Icons.emoji_events_outlined,
            lines: [
              l10n.gameGuideRankingLine1,
              l10n.gameGuideRankingLine2,
              l10n.gameGuideRankingLine3,
              l10n.gameGuideRankingLine4,
            ],
          ),
          const SizedBox(height: 12),
          _CharacterGuideCard(
            title: l10n.gameGuideCharPacTitle,
            subtitle: l10n.gameGuideCharPacSubtitle,
            color: const Color(0xFFFFC107),
            tag: l10n.gameGuideCharPacTag,
            painter: const _GuidePacmanPainter(color: Color(0xFFFFD54F)),
          ),
          const SizedBox(height: 10),
          _CharacterGuideCard(
            title: l10n.gameGuideCharBlueTitle,
            subtitle: l10n.gameGuideCharBlueSubtitle,
            color: const Color(0xFF42A5F5),
            tag: l10n.gameGuideCharBlueTag,
            painter: const _GuideGhostPainter(color: Color(0xFF42A5F5)),
          ),
          const SizedBox(height: 10),
          _CharacterGuideCard(
            title: l10n.gameGuideCharOrangeTitle,
            subtitle: l10n.gameGuideCharOrangeSubtitle,
            color: const Color(0xFFFFA726),
            tag: l10n.gameGuideCharOrangeTag,
            painter: const _GuideGhostPainter(color: Color(0xFFFFA726)),
          ),
          const SizedBox(height: 10),
          _CharacterGuideCard(
            title: l10n.gameGuideCharRedTitle,
            subtitle: l10n.gameGuideCharRedSubtitle,
            color: const Color(0xFFEF5350),
            tag: l10n.gameGuideCharRedTag,
            painter: const _GuideGhostPainter(color: Color(0xFFEF5350)),
          ),
          const SizedBox(height: 10),
          _CharacterGuideCard(
            title: l10n.gameGuideCharPinkTitle,
            subtitle: l10n.gameGuideCharPinkSubtitle,
            color: const Color(0xFFEC70C0),
            tag: l10n.gameGuideCharPinkTag,
            painter: const _GuideGhostPainter(color: Color(0xFFEC70C0)),
          ),
        ],
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> lines;

  const _GuideSection({
    required this.title,
    required this.icon,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final line in lines) ...[
              Text(line, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}

class _CharacterGuideCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String tag;
  final Color color;
  final CustomPainter painter;

  const _CharacterGuideCard({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.color,
    required this.painter,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.45)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: CustomPaint(painter: painter),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuidePacmanPainter extends CustomPainter {
  final Color color;

  const _GuidePacmanPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide * 0.48;
    final center = Offset(size.width / 2, size.height / 2);
    const mouth = 0.85;
    final fill = Paint()..color = color;
    final border = Paint()
      ..color = const Color(0xEEFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        mouth / 2,
        (3.14159265359 * 2) - mouth,
        false,
      )
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, border);

    final eye = Paint()..color = const Color(0xFF1F2937);
    canvas.drawCircle(
      Offset(center.dx + (radius * 0.15), center.dy - (radius * 0.34)),
      radius * 0.10,
      eye,
    );
  }

  @override
  bool shouldRepaint(covariant _GuidePacmanPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _GuideGhostPainter extends CustomPainter {
  final Color color;

  const _GuideGhostPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.20, h * 0.92)
      ..quadraticBezierTo(w * 0.25, h * 0.80, w * 0.30, h * 0.92)
      ..quadraticBezierTo(w * 0.38, h * 0.80, w * 0.46, h * 0.92)
      ..quadraticBezierTo(w * 0.54, h * 0.80, w * 0.62, h * 0.92)
      ..quadraticBezierTo(w * 0.70, h * 0.80, w * 0.78, h * 0.92)
      ..lineTo(w * 0.80, h * 0.38)
      ..arcToPoint(
        Offset(w * 0.20, h * 0.38),
        radius: Radius.elliptical(w * 0.30, h * 0.30),
        clockwise: false,
      )
      ..close();

    final fill = Paint()..color = color;
    final border = Paint()
      ..color = const Color(0xEEFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(path, fill);
    canvas.drawPath(path, border);

    final eyeWhite = Paint()..color = Colors.white.withValues(alpha: 0.93);
    final pupil = Paint()..color = const Color(0xFF111827);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.40, h * 0.50),
        width: w * 0.15,
        height: h * 0.21,
      ),
      eyeWhite,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.60, h * 0.50),
        width: w * 0.15,
        height: h * 0.21,
      ),
      eyeWhite,
    );
    canvas.drawCircle(Offset(w * 0.43, h * 0.52), w * 0.035, pupil);
    canvas.drawCircle(Offset(w * 0.63, h * 0.52), w * 0.035, pupil);
  }

  @override
  bool shouldRepaint(covariant _GuideGhostPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
