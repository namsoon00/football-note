import 'dart:math' as math;

import 'package:flutter/material.dart';

class FortuneSections {
  final List<String> bodyLines;
  final List<String> luckyInfoLines;

  const FortuneSections({
    required this.bodyLines,
    required this.luckyInfoLines,
  });

  factory FortuneSections.fromComment(String fortuneComment) {
    final lines = fortuneComment
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    final bodyLines = <String>[];
    final luckyInfoLines = <String>[];
    var inLuckySection = false;

    for (final line in lines) {
      if (_isLuckyInfoHeader(line)) {
        inLuckySection = true;
        continue;
      }
      if (inLuckySection || _isLuckyInfoLine(line)) {
        luckyInfoLines.add(line);
        continue;
      }
      bodyLines.add(line);
    }

    return FortuneSections(
      bodyLines: bodyLines,
      luckyInfoLines: luckyInfoLines,
    );
  }

  int get totalCount => bodyLines.length + luckyInfoLines.length;

  static bool _isLuckyInfoHeader(String line) {
    return line == '[행운 정보]' || line == '[Lucky info]';
  }

  static bool _isLuckyInfoLine(String line) {
    return line.startsWith('행운 ') || line.startsWith('Lucky ');
  }
}

class FortuneCard extends StatelessWidget {
  final FortuneSections sections;
  final String title;
  final String subtitle;
  final String luckyInfoTitle;
  final String overviewTitle;
  final String overallFortuneLabel;
  final String overallFortuneCount;
  final String luckyInfoLabel;
  final String luckyInfoCount;
  final String? encouragement;
  final String? actionLabel;
  final bool compact;
  final bool showOverview;
  final bool isKo;
  final VoidCallback? onActionPressed;

  const FortuneCard({
    super.key,
    required this.sections,
    required this.title,
    required this.subtitle,
    required this.luckyInfoTitle,
    required this.overviewTitle,
    required this.overallFortuneLabel,
    required this.overallFortuneCount,
    required this.luckyInfoLabel,
    required this.luckyInfoCount,
    required this.isKo,
    this.encouragement,
    this.actionLabel,
    this.compact = false,
    this.showOverview = true,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _FortunePalette.fromTheme(theme);
    final total = math.max(sections.totalCount, 1);
    final bodyFraction = sections.bodyLines.length / total;
    final luckyFraction = sections.luckyInfoLines.length / total;
    final bodyTextStyle = theme.textTheme.bodyMedium?.copyWith(
      color: palette.bodyColor,
      height: compact ? 1.52 : 1.58,
      fontWeight: FontWeight.w700,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 24 : 32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.backdropGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.34 : 0.15,
            ),
            blurRadius: compact ? 18 : 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: compact ? 14 : 18,
            right: compact ? 16 : 20,
            child: Icon(
              Icons.auto_awesome,
              color: palette.frameColor.withValues(alpha: 0.24),
              size: compact ? 42 : 54,
            ),
          ),
          Positioned(
            left: compact ? 12 : 14,
            top: compact ? 42 : 56,
            child: Icon(
              Icons.wb_sunny_outlined,
              color: palette.frameColor.withValues(alpha: 0.18),
              size: compact ? 56 : 72,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(compact ? 12 : 14),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(compact ? 22 : 28),
                border: Border.all(color: palette.frameColor, width: 1.4),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: palette.cardGradient,
                ),
              ),
              child: Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(compact ? 18 : 22),
                  border: Border.all(
                    color: palette.frameSoftColor.withValues(alpha: 0.9),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 18 : 22,
                    compact ? 18 : 20,
                    compact ? 18 : 22,
                    compact ? 16 : 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: compact ? 46 : 56,
                              height: compact ? 46 : 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: palette.badgeColor,
                                border: Border.all(
                                  color: palette.frameColor,
                                  width: 1.3,
                                ),
                              ),
                              child: Icon(
                                Icons.auto_awesome,
                                color: palette.accentColor,
                                size: compact ? 24 : 28,
                              ),
                            ),
                            SizedBox(height: compact ? 10 : 12),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: palette.titleColor,
                                letterSpacing: isKo ? 0.2 : 0.8,
                                fontSize: compact ? 20 : null,
                              ),
                            ),
                            if (subtitle.trim().isNotEmpty) ...[
                              SizedBox(height: compact ? 4 : 6),
                              Text(
                                subtitle,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: palette.bodyColor.withValues(
                                    alpha: 0.76,
                                  ),
                                  fontStyle: FontStyle.italic,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: compact ? 14 : 18),
                      if (showOverview) ...[
                        _FortuneOverviewCard(
                          palette: palette,
                          title: overviewTitle,
                          firstLabel: overallFortuneLabel,
                          firstValue: overallFortuneCount,
                          firstFraction: bodyFraction,
                          secondLabel: luckyInfoLabel,
                          secondValue: luckyInfoCount,
                          secondFraction: luckyFraction,
                          compact: compact,
                        ),
                        SizedBox(height: compact ? 12 : 14),
                      ],
                      _FortuneSectionCard(
                        palette: palette,
                        lines: sections.bodyLines,
                        textStyle: bodyTextStyle,
                        compact: compact,
                      ),
                      if (sections.luckyInfoLines.isNotEmpty) ...[
                        SizedBox(height: compact ? 12 : 14),
                        _FortuneSectionCard(
                          palette: palette,
                          title: luckyInfoTitle,
                          lines: sections.luckyInfoLines,
                          textStyle: bodyTextStyle,
                          compact: compact,
                          highlighted: true,
                        ),
                      ],
                      if (encouragement != null &&
                          encouragement!.trim().isNotEmpty) ...[
                        SizedBox(height: compact ? 12 : 16),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 12 : 14,
                            vertical: compact ? 10 : 12,
                          ),
                          decoration: BoxDecoration(
                            color: palette.panelColor.withValues(alpha: 0.82),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            encouragement!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: palette.titleColor,
                              height: 1.45,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      if (actionLabel != null && onActionPressed != null) ...[
                        SizedBox(height: compact ? 12 : 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: onActionPressed,
                            style: FilledButton.styleFrom(
                              backgroundColor: palette.accentColor,
                              foregroundColor: palette.buttonForeground,
                              padding: EdgeInsets.symmetric(
                                vertical: compact ? 12 : 14,
                              ),
                              textStyle: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            child: Text(actionLabel!),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FortuneOverviewCard extends StatelessWidget {
  final _FortunePalette palette;
  final String title;
  final String firstLabel;
  final String firstValue;
  final double firstFraction;
  final String secondLabel;
  final String secondValue;
  final double secondFraction;
  final bool compact;

  const _FortuneOverviewCard({
    required this.palette,
    required this.title,
    required this.firstLabel,
    required this.firstValue,
    required this.firstFraction,
    required this.secondLabel,
    required this.secondValue,
    required this.secondFraction,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 16,
        compact ? 14 : 16,
        compact ? 14 : 16,
        compact ? 12 : 14,
      ),
      decoration: BoxDecoration(
        color: palette.panelColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: palette.frameSoftColor.withValues(alpha: 0.9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: palette.titleColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: compact ? 10 : 12),
          Row(
            children: [
              Expanded(
                child: _FortuneOverviewMetric(
                  palette: palette,
                  label: firstLabel,
                  value: firstValue,
                  fraction: firstFraction,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FortuneOverviewMetric(
                  palette: palette,
                  label: secondLabel,
                  value: secondValue,
                  fraction: secondFraction,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FortuneOverviewMetric extends StatelessWidget {
  final _FortunePalette palette;
  final String label;
  final String value;
  final double fraction;

  const _FortuneOverviewMetric({
    required this.palette,
    required this.label,
    required this.value,
    required this.fraction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: palette.metricColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.frameColor.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: palette.bodyColor.withValues(alpha: 0.88),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              color: palette.titleColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: fraction.clamp(0, 1),
              backgroundColor: palette.frameColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(palette.accentColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _FortuneSectionCard extends StatelessWidget {
  final _FortunePalette palette;
  final List<String> lines;
  final TextStyle? textStyle;
  final bool compact;
  final bool highlighted;
  final String? title;

  const _FortuneSectionCard({
    required this.palette,
    required this.lines,
    required this.textStyle,
    required this.compact,
    this.highlighted = false,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 16,
        compact ? 14 : 16,
        compact ? 14 : 16,
        compact ? 12 : 14,
      ),
      decoration: BoxDecoration(
        color: highlighted ? palette.luckyCardColor : palette.panelColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (highlighted ? palette.frameColor : palette.frameSoftColor)
              .withValues(alpha: highlighted ? 0.72 : 0.92),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && title!.trim().isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.wb_sunny_outlined,
                  color: palette.accentColor,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  title!,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: palette.titleColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          for (var i = 0; i < lines.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == lines.length - 1 ? 0 : 8),
              child: Text(lines[i], style: textStyle),
            ),
        ],
      ),
    );
  }
}

class _FortunePalette {
  final List<Color> backdropGradient;
  final List<Color> cardGradient;
  final Color frameColor;
  final Color frameSoftColor;
  final Color accentColor;
  final Color titleColor;
  final Color bodyColor;
  final Color luckyCardColor;
  final Color panelColor;
  final Color metricColor;
  final Color badgeColor;
  final Color buttonForeground;

  const _FortunePalette({
    required this.backdropGradient,
    required this.cardGradient,
    required this.frameColor,
    required this.frameSoftColor,
    required this.accentColor,
    required this.titleColor,
    required this.bodyColor,
    required this.luckyCardColor,
    required this.panelColor,
    required this.metricColor,
    required this.badgeColor,
    required this.buttonForeground,
  });

  factory _FortunePalette.fromTheme(ThemeData theme) {
    if (theme.brightness == Brightness.dark) {
      return const _FortunePalette(
        backdropGradient: <Color>[
          Color(0xFF1A1E28),
          Color(0xFF251F38),
          Color(0xFF10242A),
        ],
        cardGradient: <Color>[
          Color(0xFF222938),
          Color(0xFF312A45),
          Color(0xFF1C2D35),
        ],
        frameColor: Color(0xFFE2BC67),
        frameSoftColor: Color(0xFF84724A),
        accentColor: Color(0xFFFFD36B),
        titleColor: Color(0xFFFFF3CF),
        bodyColor: Color(0xFFE7DCC0),
        luckyCardColor: Color(0xFF3A3322),
        panelColor: Color(0xFF242B38),
        metricColor: Color(0xFF1E2430),
        badgeColor: Color(0xFF30384A),
        buttonForeground: Color(0xFF2E220A),
      );
    }
    return const _FortunePalette(
      backdropGradient: <Color>[
        Color(0xFFFFF6D7),
        Color(0xFFFFE8C2),
        Color(0xFFF8F3FF),
      ],
      cardGradient: <Color>[
        Color(0xFFFFFDF6),
        Color(0xFFFFF4DB),
        Color(0xFFFFF9EC),
      ],
      frameColor: Color(0xFFE6C16A),
      frameSoftColor: Color(0xFFF7E3A4),
      accentColor: Color(0xFFAA7A14),
      titleColor: Color(0xFF493116),
      bodyColor: Color(0xFF5E4323),
      luckyCardColor: Color(0xFFFFF3CC),
      panelColor: Color(0xFFFCF9EF),
      metricColor: Color(0xFFFFFCF5),
      badgeColor: Color(0xFFFDFBF3),
      buttonForeground: Colors.white,
    );
  }
}
