import 'dart:math' as math;

import 'package:flutter/material.dart';

enum SpatialKitFamily {
  plain,
  checkerboard,
  halvesWithCenterStripe,
  verticalStripes,
  centralBand,
  pinstripes,
  contrastSleeves,
  tonalPanels,
}

@immutable
class SpatialKitPresentation {
  final String? teamName;
  final SpatialKitFamily family;
  final Color primaryColor;
  final Color secondaryColor;
  final Color trimColor;
  final Color shortsColor;
  final Color numberColor;
  final bool curated;

  const SpatialKitPresentation({
    required this.teamName,
    required this.family,
    required this.primaryColor,
    required this.secondaryColor,
    required this.trimColor,
    required this.shortsColor,
    required this.numberColor,
    required this.curated,
  });

  Color get mainColor => primaryColor;

  factory SpatialKitPresentation.sourceFallback({
    required String shirtColor,
    required String numberColor,
  }) {
    final shirt = SpatialKitResolver.parseSourceColor(shirtColor);
    return SpatialKitPresentation(
      teamName: null,
      family: SpatialKitFamily.plain,
      primaryColor: shirt,
      secondaryColor: shirt,
      trimColor: shirt,
      shortsColor: shirt,
      numberColor: SpatialKitResolver.parseSourceColor(numberColor),
      curated: false,
    );
  }
}

class SpatialKitResolver {
  const SpatialKitResolver();

  static const Map<int, ({String home, String away})> _fixtures = {
    2068: (home: 'Inter', away: 'Juventus'),
    2269: (home: 'Paris', away: 'Marseille'),
    2417: (home: 'Bayern Munchen', away: 'Dortmund'),
    2440: (home: 'Liverpool', away: 'Manchester City'),
    2841: (home: 'FC Barcelona', away: 'Real Madrid'),
    3442: (home: 'Real Madrid', away: 'FC Barcelona'),
    3518: (home: 'Juventus', away: 'Inter'),
    3749: (home: 'Dortmund', away: 'Bayern Munchen'),
    4039: (home: 'Manchester City', away: 'Liverpool'),
    3857: (home: 'South Korea', away: 'Portugal'),
    10507: (home: 'Brazil', away: 'South Korea'),
    10517: (home: 'Argentina', away: 'France'),
  };

  SpatialKitPresentation resolve({
    required int fixtureId,
    required String homeTeam,
    required String awayTeam,
    required bool playerHome,
    required bool goalkeeper,
    required String sourceShirtColor,
    required String sourceNumberColor,
  }) {
    final fallback = SpatialKitPresentation.sourceFallback(
      shirtColor: sourceShirtColor,
      numberColor: sourceNumberColor,
    );
    final fixture = _fixtures[fixtureId];
    if (goalkeeper ||
        fixture == null ||
        fixture.home != homeTeam ||
        fixture.away != awayTeam) {
      return fallback;
    }
    final teamName = playerHome ? homeTeam : awayTeam;
    final teamKit = _teamKits[teamName];
    if (teamKit == null) return fallback;
    return SpatialKitPresentation(
      teamName: teamName,
      family: teamKit.family,
      primaryColor: teamKit.primaryColor,
      secondaryColor: teamKit.secondaryColor,
      trimColor: teamKit.trimColor,
      shortsColor: teamKit.shortsColor,
      numberColor: parseSourceColor(sourceNumberColor),
      curated: true,
    );
  }

  static Color parseSourceColor(String source) {
    final normalized = source.replaceFirst('#', '');
    final value = int.tryParse(normalized, radix: 16);
    if (value == null || normalized.length != 6) return Colors.white;
    return Color(0xFF000000 | value);
  }
}

const Map<String, SpatialKitPresentation> _teamKits = {
  'Argentina': SpatialKitPresentation(
    teamName: 'Argentina',
    family: SpatialKitFamily.verticalStripes,
    primaryColor: Color(0xFFF7F7F2),
    secondaryColor: Color(0xFF75AADB),
    trimColor: Color(0xFF111827),
    shortsColor: Color(0xFF111827),
    numberColor: Color(0xFF111827),
    curated: true,
  ),
  'France': SpatialKitPresentation(
    teamName: 'France',
    family: SpatialKitFamily.plain,
    primaryColor: Color(0xFF0B1F4D),
    secondaryColor: Color(0xFF0B1F4D),
    trimColor: Color(0xFFC8A45A),
    shortsColor: Color(0xFF0B1F4D),
    numberColor: Color(0xFFC8A45A),
    curated: true,
  ),
  'Brazil': SpatialKitPresentation(
    teamName: 'Brazil',
    family: SpatialKitFamily.contrastSleeves,
    primaryColor: Color(0xFFF7E12B),
    secondaryColor: Color(0xFF1D7A45),
    trimColor: Color(0xFF1D4E9E),
    shortsColor: Color(0xFF1D4E9E),
    numberColor: Color(0xFF1D7A45),
    curated: true,
  ),
  'South Korea': SpatialKitPresentation(
    teamName: 'South Korea',
    family: SpatialKitFamily.plain,
    primaryColor: Color(0xFFE9153B),
    secondaryColor: Color(0xFFE9153B),
    trimColor: Color(0xFF111827),
    shortsColor: Color(0xFFE9153B),
    numberColor: Color(0xFF111827),
    curated: true,
  ),
  'Portugal': SpatialKitPresentation(
    teamName: 'Portugal',
    family: SpatialKitFamily.centralBand,
    primaryColor: Color(0xFFF7F7F2),
    secondaryColor: Color(0xFF8E1731),
    trimColor: Color(0xFF0C6B45),
    shortsColor: Color(0xFFF7F7F2),
    numberColor: Color(0xFF8E1731),
    curated: true,
  ),
  'FC Barcelona': SpatialKitPresentation(
    teamName: 'FC Barcelona',
    family: SpatialKitFamily.checkerboard,
    primaryColor: Color(0xFF071A3D),
    secondaryColor: Color(0xFFA50044),
    trimColor: Color(0xFFF2B705),
    shortsColor: Color(0xFF071A3D),
    numberColor: Color(0xFFF2B705),
    curated: true,
  ),
  'Juventus': SpatialKitPresentation(
    teamName: 'Juventus',
    family: SpatialKitFamily.halvesWithCenterStripe,
    primaryColor: Color(0xFFF4F2EC),
    secondaryColor: Color(0xFF111111),
    trimColor: Color(0xFFF09AB6),
    shortsColor: Color(0xFF111111),
    numberColor: Colors.white,
    curated: true,
  ),
  'Inter': SpatialKitPresentation(
    teamName: 'Inter',
    family: SpatialKitFamily.verticalStripes,
    primaryColor: Color(0xFF0873C1),
    secondaryColor: Color(0xFF111827),
    trimColor: Color(0xFFE8EDF2),
    shortsColor: Color(0xFF111827),
    numberColor: Colors.white,
    curated: true,
  ),
  'Paris': SpatialKitPresentation(
    teamName: 'Paris',
    family: SpatialKitFamily.centralBand,
    primaryColor: Color(0xFF071B3D),
    secondaryColor: Color(0xFFF7F7F2),
    trimColor: Color(0xFFD62839),
    shortsColor: Color(0xFF071B3D),
    numberColor: Colors.white,
    curated: true,
  ),
  'Liverpool': SpatialKitPresentation(
    teamName: 'Liverpool',
    family: SpatialKitFamily.pinstripes,
    primaryColor: Color(0xFFA50026),
    secondaryColor: Color(0xFFF1D5B2),
    trimColor: Color(0xFFF1D5B2),
    shortsColor: Color(0xFFA50026),
    numberColor: Colors.white,
    curated: true,
  ),
  'Manchester City': SpatialKitPresentation(
    teamName: 'Manchester City',
    family: SpatialKitFamily.plain,
    primaryColor: Color(0xFF6CABDD),
    secondaryColor: Color(0xFF6CABDD),
    trimColor: Color(0xFF63318A),
    shortsColor: Color(0xFFF7F8F3),
    numberColor: Colors.white,
    curated: true,
  ),
  'Real Madrid': SpatialKitPresentation(
    teamName: 'Real Madrid',
    family: SpatialKitFamily.plain,
    primaryColor: Color(0xFFF5F1E6),
    secondaryColor: Color(0xFFF5F1E6),
    trimColor: Color(0xFFC5A253),
    shortsColor: Color(0xFFF7F6F0),
    numberColor: Color(0xFFC5A253),
    curated: true,
  ),
  'Dortmund': SpatialKitPresentation(
    teamName: 'Dortmund',
    family: SpatialKitFamily.contrastSleeves,
    primaryColor: Color(0xFFFDE100),
    secondaryColor: Color(0xFF111111),
    trimColor: Color(0xFF111111),
    shortsColor: Color(0xFF111111),
    numberColor: Colors.black,
    curated: true,
  ),
  'Bayern Munchen': SpatialKitPresentation(
    teamName: 'Bayern Munchen',
    family: SpatialKitFamily.tonalPanels,
    primaryColor: Color(0xFFD0021B),
    secondaryColor: Color(0xFFA80E2A),
    trimColor: Color(0xFFF2E9E4),
    shortsColor: Color(0xFFD0021B),
    numberColor: Colors.white,
    curated: true,
  ),
  'Marseille': SpatialKitPresentation(
    teamName: 'Marseille',
    family: SpatialKitFamily.plain,
    primaryColor: Color(0xFFF6F8F5),
    secondaryColor: Color(0xFFF6F8F5),
    trimColor: Color(0xFF69BFE5),
    shortsColor: Color(0xFFF6F8F5),
    numberColor: Color(0xFF69BFE5),
    curated: true,
  ),
};

class SpatialKitPainter {
  const SpatialKitPainter._();

  static void paint({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required SpatialKitPresentation kit,
    required String number,
    required TextDirection textDirection,
    double opacity = 1,
  }) {
    final shirt = _shirtPath(center, radius);
    final shorts = _shortsPath(center, radius);
    final outline = Paint()
      ..color = Colors.black.withValues(alpha: .62 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, radius * .075)
      ..strokeJoin = StrokeJoin.round;

    canvas.save();
    canvas.clipPath(shirt);
    _paintShirtPattern(canvas, center, radius, kit, opacity);
    canvas.restore();
    canvas.drawPath(shirt, outline);

    canvas.drawPath(
      shorts,
      Paint()..color = kit.shortsColor.withValues(alpha: opacity),
    );
    canvas.drawPath(shorts, outline);
    _paintTrim(canvas, center, radius, kit.trimColor, opacity);
    _paintNumber(
      canvas,
      center: center - Offset(0, radius * .13),
      radius: radius,
      number: number,
      color: kit.numberColor.withValues(alpha: opacity),
      textDirection: textDirection,
      opacity: opacity,
    );
  }

  static Path _shirtPath(Offset center, double radius) {
    Offset p(double x, double y) => center + Offset(x * radius, y * radius);
    return Path()
      ..moveTo(p(-.22, -.76).dx, p(-.22, -.76).dy)
      ..lineTo(p(-.42, -.67).dx, p(-.42, -.67).dy)
      ..lineTo(p(-.68, -.57).dx, p(-.68, -.57).dy)
      ..lineTo(p(-.91, -.20).dx, p(-.91, -.20).dy)
      ..lineTo(p(-.67, -.04).dx, p(-.67, -.04).dy)
      ..lineTo(p(-.51, -.23).dx, p(-.51, -.23).dy)
      ..lineTo(p(-.47, .25).dx, p(-.47, .25).dy)
      ..lineTo(p(.47, .25).dx, p(.47, .25).dy)
      ..lineTo(p(.51, -.23).dx, p(.51, -.23).dy)
      ..lineTo(p(.67, -.04).dx, p(.67, -.04).dy)
      ..lineTo(p(.91, -.20).dx, p(.91, -.20).dy)
      ..lineTo(p(.68, -.57).dx, p(.68, -.57).dy)
      ..lineTo(p(.42, -.67).dx, p(.42, -.67).dy)
      ..lineTo(p(.22, -.76).dx, p(.22, -.76).dy)
      ..quadraticBezierTo(
        p(0, -.61).dx,
        p(0, -.61).dy,
        p(-.22, -.76).dx,
        p(-.22, -.76).dy,
      )
      ..close();
  }

  static Path _shortsPath(Offset center, double radius) {
    Offset p(double x, double y) => center + Offset(x * radius, y * radius);
    return Path()
      ..moveTo(p(-.47, .34).dx, p(-.47, .34).dy)
      ..lineTo(p(.47, .34).dx, p(.47, .34).dy)
      ..lineTo(p(.42, .78).dx, p(.42, .78).dy)
      ..lineTo(p(.04, .78).dx, p(.04, .78).dy)
      ..lineTo(p(0, .58).dx, p(0, .58).dy)
      ..lineTo(p(-.04, .78).dx, p(-.04, .78).dy)
      ..lineTo(p(-.42, .78).dx, p(-.42, .78).dy)
      ..close();
  }

  static void _paintShirtPattern(
    Canvas canvas,
    Offset center,
    double radius,
    SpatialKitPresentation kit,
    double opacity,
  ) {
    final primary = kit.primaryColor.withValues(alpha: opacity);
    final secondary = kit.secondaryColor.withValues(alpha: opacity);
    final trim = kit.trimColor.withValues(alpha: opacity);
    final bounds = Rect.fromCenter(
      center: center - Offset(0, radius * .2),
      width: radius * 2,
      height: radius * 1.3,
    );
    canvas.drawRect(bounds, Paint()..color = primary);
    switch (kit.family) {
      case SpatialKitFamily.plain:
        break;
      case SpatialKitFamily.checkerboard:
        const columns = 2;
        const rows = 3;
        final cellWidth = bounds.width / columns;
        final cellHeight = bounds.height / rows;
        for (var row = 0; row < rows; row++) {
          for (var column = 0; column < columns; column++) {
            if ((row + column).isOdd) {
              canvas.drawRect(
                Rect.fromLTWH(
                  bounds.left + column * cellWidth,
                  bounds.top + row * cellHeight,
                  cellWidth,
                  cellHeight,
                ),
                Paint()..color = secondary,
              );
            }
          }
        }
        break;
      case SpatialKitFamily.halvesWithCenterStripe:
        canvas.drawRect(
          Rect.fromLTRB(center.dx, bounds.top, bounds.right, bounds.bottom),
          Paint()..color = secondary,
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: bounds.center,
            width: radius * .13,
            height: bounds.height,
          ),
          Paint()..color = trim,
        );
        break;
      case SpatialKitFamily.verticalStripes:
        canvas.drawRect(bounds, Paint()..color = secondary);
        for (final x in <double>[-.58, -.18, .22, .62]) {
          canvas.drawRect(
            Rect.fromLTWH(
              center.dx + radius * x,
              bounds.top,
              radius * .21,
              bounds.height,
            ),
            Paint()..color = primary,
          );
        }
        break;
      case SpatialKitFamily.centralBand:
        canvas.drawRect(
          Rect.fromCenter(
            center: bounds.center,
            width: radius * .38,
            height: bounds.height,
          ),
          Paint()..color = secondary,
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: bounds.center,
            width: radius * .13,
            height: bounds.height,
          ),
          Paint()..color = trim,
        );
        break;
      case SpatialKitFamily.pinstripes:
        for (final x in <double>[-.48, -.16, .16, .48]) {
          canvas.drawRect(
            Rect.fromLTWH(
              center.dx + radius * x,
              bounds.top,
              math.max(.6, radius * .035),
              bounds.height,
            ),
            Paint()..color = secondary.withValues(alpha: .82 * opacity),
          );
        }
        break;
      case SpatialKitFamily.contrastSleeves:
        canvas.drawRect(
          Rect.fromLTRB(
              bounds.left, bounds.top, center.dx - radius * .47, bounds.bottom),
          Paint()..color = secondary,
        );
        canvas.drawRect(
          Rect.fromLTRB(center.dx + radius * .47, bounds.top, bounds.right,
              bounds.bottom),
          Paint()..color = secondary,
        );
        break;
      case SpatialKitFamily.tonalPanels:
        final left = Path()
          ..moveTo(bounds.left, bounds.top)
          ..lineTo(center.dx - radius * .18, bounds.top)
          ..lineTo(center.dx - radius * .39, bounds.bottom)
          ..lineTo(bounds.left, bounds.bottom)
          ..close();
        final right = Path()
          ..moveTo(bounds.right, bounds.top)
          ..lineTo(center.dx + radius * .18, bounds.top)
          ..lineTo(center.dx + radius * .39, bounds.bottom)
          ..lineTo(bounds.right, bounds.bottom)
          ..close();
        canvas.drawPath(left, Paint()..color = secondary);
        canvas.drawPath(right, Paint()..color = secondary);
        break;
    }
  }

  static void _paintTrim(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double opacity,
  ) {
    final trim = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.8, radius * .075)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final collar = Path()
      ..moveTo(center.dx - radius * .20, center.dy - radius * .73)
      ..quadraticBezierTo(
        center.dx,
        center.dy - radius * .57,
        center.dx + radius * .20,
        center.dy - radius * .73,
      );
    canvas.drawPath(collar, trim);
    canvas.drawLine(
      center + Offset(-radius * .83, -radius * .18),
      center + Offset(-radius * .65, -radius * .06),
      trim,
    );
    canvas.drawLine(
      center + Offset(radius * .83, -radius * .18),
      center + Offset(radius * .65, -radius * .06),
      trim,
    );
  }

  static void _paintNumber(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required String number,
    required Color color,
    required TextDirection textDirection,
    required double opacity,
  }) {
    if (number.isEmpty) return;
    final luminance = color.computeLuminance();
    // Compare both outlines against the number, including mid-tone gold.
    final blackContrast = (luminance + .05) / .05;
    final whiteContrast = 1.05 / (luminance + .05);
    final halo = blackContrast >= whiteContrast ? Colors.black : Colors.white;
    TextPainter painter(Paint foreground) => TextPainter(
          text: TextSpan(
            text: number,
            style: TextStyle(
              foreground: foreground,
              fontSize: radius * .88,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          textDirection: textDirection,
        )..layout();
    final stroke = painter(
      Paint()
        ..color = halo.withValues(alpha: .94 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.25, radius * .13)
        ..strokeJoin = StrokeJoin.round,
    );
    final fill = painter(Paint()..color = color);
    final offset = center - Offset(stroke.width / 2, stroke.height / 2);
    stroke.paint(canvas, offset);
    fill.paint(canvas, offset);
  }
}
