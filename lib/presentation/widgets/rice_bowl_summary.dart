import 'package:flutter/material.dart';

import '../../domain/entities/meal_entry.dart';
import '../../gen/app_localizations.dart';

class RiceBowlSummaryCard extends StatelessWidget {
  final MealEntry? entry;
  final String title;
  final String? subtitle;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? accentColor;
  final bool compact;
  final VoidCallback? onTap;

  const RiceBowlSummaryCard({
    super.key,
    required this.entry,
    required this.title,
    this.subtitle,
    this.padding = const EdgeInsets.fromLTRB(14, 14, 14, 14),
    this.backgroundColor,
    this.borderColor,
    this.accentColor,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final accent = accentColor ?? const Color(0xFFB45309);
    final surface =
        backgroundColor ?? theme.colorScheme.surface.withValues(alpha: 0.9);
    final edge = borderColor ?? accent.withValues(alpha: 0.18);
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: edge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 30 : 34,
                height: compact ? 30 : 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(compact ? 10 : 11),
                ),
                child: Icon(
                  Icons.rice_bowl_outlined,
                  color: accent,
                  size: compact ? 18 : 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          (compact
                                  ? theme.textTheme.titleSmall
                                  : theme.textTheme.titleMedium)
                              ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
          SizedBox(height: compact ? 10 : 14),
          Row(
            children: [
              Expanded(
                child: _RiceBowlMealItem(
                  label: l10n.mealBreakfast,
                  bowls: entry?.breakfastRiceBowls ?? 0,
                  accentColor: accent,
                  compact: compact,
                ),
              ),
              SizedBox(width: compact ? 8 : 10),
              Expanded(
                child: _RiceBowlMealItem(
                  label: l10n.mealLunch,
                  bowls: entry?.lunchRiceBowls ?? 0,
                  accentColor: accent,
                  compact: compact,
                ),
              ),
              SizedBox(width: compact ? 8 : 10),
              Expanded(
                child: _RiceBowlMealItem(
                  label: l10n.mealDinner,
                  bowls: entry?.dinnerRiceBowls ?? 0,
                  accentColor: accent,
                  compact: compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

class RiceBowlInlineSummary extends StatelessWidget {
  final MealEntry? entry;
  final Color accentColor;

  const RiceBowlInlineSummary({
    super.key,
    required this.entry,
    this.accentColor = const Color(0xFFB45309),
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _RiceBowlMealItem(
            label: l10n.mealBreakfast,
            bowls: entry?.breakfastRiceBowls ?? 0,
            accentColor: accentColor,
            compact: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _RiceBowlMealItem(
            label: l10n.mealLunch,
            bowls: entry?.lunchRiceBowls ?? 0,
            accentColor: accentColor,
            compact: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _RiceBowlMealItem(
            label: l10n.mealDinner,
            bowls: entry?.dinnerRiceBowls ?? 0,
            accentColor: accentColor,
            compact: true,
          ),
        ),
      ],
    );
  }
}

class RiceBowlStackVisual extends StatelessWidget {
  final double value;
  final Color accentColor;

  const RiceBowlStackVisual({
    super.key,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (value <= 0) {
      return Opacity(
        opacity: 0.45,
        child: _RiceBowlIcon(fillLevel: 0, accentColor: accentColor),
      );
    }

    final bowlCount = value < 1 ? 1 : value.ceil().clamp(1, 3);
    return SizedBox(
      width: 42,
      height: 32,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          for (var i = 0; i < bowlCount; i++)
            Positioned(
              bottom: (i * 7).toDouble(),
              child: Opacity(
                opacity: 1 - (i * 0.12),
                child: _RiceBowlIcon(
                  fillLevel: i == 0 && value < 1 ? 0.5 : 1,
                  accentColor: accentColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RiceBowlMealItem extends StatelessWidget {
  final String label;
  final double bowls;
  final Color accentColor;
  final bool compact;

  const _RiceBowlMealItem({
    required this.label,
    required this.bowls,
    required this.accentColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 6 : 10,
      ),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: compact ? 0.06 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.16)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: compact ? 11 : null,
            ),
          ),
          SizedBox(height: compact ? 2 : 8),
          compact
              ? RiceBowlStackVisual(value: bowls, accentColor: accentColor)
              : _RiceBowlIcon(
                  fillLevel: bowls <= 0
                      ? 0.0
                      : bowls < 1
                      ? 0.5
                      : 1.0,
                  accentColor: accentColor,
                ),
          SizedBox(height: compact ? 2 : 8),
          Text(
            compact ? _compactBowlsLabel(bowls) : _bowlsLabel(context, bowls),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 11 : null,
            ),
          ),
        ],
      ),
    );
  }

  String _compactBowlsLabel(double value) {
    if (value <= 0) return '-';
    return value == value.truncateToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }

  String _bowlsLabel(BuildContext context, double value) {
    final l10n = AppLocalizations.of(context)!;
    if (value <= 0) {
      return l10n.homeRiceBowlEmpty;
    }
    if (value < 1) {
      return l10n.homeRiceBowlHalf;
    }
    return l10n.homeRiceBowlFull;
  }
}

class _RiceBowlIcon extends StatelessWidget {
  final double fillLevel;
  final Color accentColor;

  const _RiceBowlIcon({required this.fillLevel, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 32,
      child: CustomPaint(
        painter: _RiceBowlPainter(
          fillLevel: fillLevel,
          accentColor: accentColor,
        ),
      ),
    );
  }
}

class _RiceBowlPainter extends CustomPainter {
  final double fillLevel;
  final Color accentColor;

  const _RiceBowlPainter({required this.fillLevel, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final bowlRect = Rect.fromLTWH(3, 8, size.width - 6, size.height - 11);
    final bowlPath = Path()
      ..moveTo(bowlRect.left, bowlRect.top + 1)
      ..quadraticBezierTo(
        bowlRect.left + (bowlRect.width * 0.08),
        bowlRect.bottom,
        bowlRect.center.dx,
        bowlRect.bottom,
      )
      ..quadraticBezierTo(
        bowlRect.right - (bowlRect.width * 0.08),
        bowlRect.bottom,
        bowlRect.right,
        bowlRect.top + 1,
      );
    final rimRect = Rect.fromLTWH(0, 5, size.width, 6);

    if (fillLevel > 0) {
      canvas.save();
      canvas.clipPath(bowlPath);
      final fillTop = bowlRect.bottom - (bowlRect.height * fillLevel);
      final fillRect = Rect.fromLTWH(
        bowlRect.left,
        fillTop,
        bowlRect.width,
        bowlRect.bottom - fillTop,
      );
      canvas.drawRect(
        fillRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFFF4D6),
              accentColor.withValues(alpha: 0.22),
            ],
          ).createShader(fillRect),
      );
      canvas.restore();
    }

    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = accentColor.withValues(alpha: fillLevel > 0 ? 0.82 : 0.5)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rimRect, const Radius.circular(8)),
      outlinePaint,
    );
    canvas.drawPath(bowlPath, outlinePaint);

    if (fillLevel <= 0) {
      final dashPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = accentColor.withValues(alpha: 0.45);
      const dashWidth = 4.0;
      const dashGap = 3.0;
      var x = bowlRect.left + 2;
      final y = bowlRect.center.dy;
      while (x < bowlRect.right - 1) {
        canvas.drawLine(Offset(x, y), Offset(x + dashWidth, y), dashPaint);
        x += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RiceBowlPainter oldDelegate) {
    return oldDelegate.fillLevel != fillLevel ||
        oldDelegate.accentColor != accentColor;
  }
}
