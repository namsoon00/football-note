import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/presentation/scan_pass/spatial_kit_presentation.dart';

void main() {
  const resolver = SpatialKitResolver();
  const fixtures = <({int id, String home, String away})>[
    (id: 2068, home: 'Inter', away: 'Juventus'),
    (id: 2269, home: 'Paris', away: 'Marseille'),
    (id: 2417, home: 'Bayern Munchen', away: 'Dortmund'),
    (id: 2440, home: 'Liverpool', away: 'Manchester City'),
    (id: 2841, home: 'FC Barcelona', away: 'Real Madrid'),
    (id: 3442, home: 'Real Madrid', away: 'FC Barcelona'),
    (id: 3518, home: 'Juventus', away: 'Inter'),
    (id: 3749, home: 'Dortmund', away: 'Bayern Munchen'),
    (id: 4039, home: 'Manchester City', away: 'Liverpool'),
  ];
  const expectedFamilies = <String, SpatialKitFamily>{
    'FC Barcelona': SpatialKitFamily.checkerboard,
    'Juventus': SpatialKitFamily.halvesWithCenterStripe,
    'Inter': SpatialKitFamily.verticalStripes,
    'Paris': SpatialKitFamily.centralBand,
    'Liverpool': SpatialKitFamily.pinstripes,
    'Manchester City': SpatialKitFamily.plain,
    'Real Madrid': SpatialKitFamily.plain,
    'Dortmund': SpatialKitFamily.contrastSleeves,
    'Bayern Munchen': SpatialKitFamily.tonalPanels,
    'Marseille': SpatialKitFamily.plain,
  };

  test('resolver scopes curated kits to all 18 known fixture sides', () {
    final resolvedByTeam = <String, SpatialKitPresentation>{};
    for (final fixture in fixtures) {
      for (final homeSide in <bool>[true, false]) {
        final team = homeSide ? fixture.home : fixture.away;
        final kit = resolver.resolve(
          fixtureId: fixture.id,
          homeTeam: fixture.home,
          awayTeam: fixture.away,
          playerHome: homeSide,
          goalkeeper: false,
          sourceShirtColor: '#abcdef',
          sourceNumberColor: '#123456',
        );
        expect(kit.curated, isTrue, reason: '${fixture.id} $team');
        expect(kit.teamName, team, reason: '${fixture.id} $team');
        expect(kit.family, expectedFamilies[team],
            reason: '${fixture.id} $team');
        expect(kit.numberColor, const Color(0xFF123456));
        final prior = resolvedByTeam[team];
        if (prior != null) {
          expect(kit.family, prior.family, reason: '$team changes by venue');
          expect(kit.mainColor, prior.mainColor,
              reason: '$team changes by venue');
        }
        resolvedByTeam[team] = kit;
      }
    }
    expect(resolvedByTeam.keys, expectedFamilies.keys.toSet());
  });

  test('unknown, mismatched, and goalkeeper kits stay source-color fallback',
      () {
    SpatialKitPresentation resolve({
      int fixtureId = 2841,
      String home = 'FC Barcelona',
      String away = 'Real Madrid',
      bool goalkeeper = false,
    }) =>
        resolver.resolve(
          fixtureId: fixtureId,
          homeTeam: home,
          awayTeam: away,
          playerHome: true,
          goalkeeper: goalkeeper,
          sourceShirtColor: '#31a5c8',
          sourceNumberColor: '#f4f0df',
        );

    for (final kit in <SpatialKitPresentation>[
      resolve(fixtureId: 9999),
      resolve(away: 'Future Madrid'),
      resolve(goalkeeper: true),
    ]) {
      expect(kit.curated, isFalse);
      expect(kit.teamName, isNull);
      expect(kit.family, SpatialKitFamily.plain);
      expect(kit.primaryColor, const Color(0xFF31A5C8));
      expect(kit.secondaryColor, const Color(0xFF31A5C8));
      expect(kit.trimColor, const Color(0xFF31A5C8));
      expect(kit.shortsColor, const Color(0xFF31A5C8));
      expect(kit.numberColor, const Color(0xFFF4F0DF));
    }
  });

  test('representative checkerboard and split kits render distinct panels',
      () async {
    final barcelona = resolver.resolve(
      fixtureId: 2841,
      homeTeam: 'FC Barcelona',
      awayTeam: 'Real Madrid',
      playerHome: true,
      goalkeeper: false,
      sourceShirtColor: '#0008ff',
      sourceNumberColor: '#ffc01a',
    );
    final juventus = resolver.resolve(
      fixtureId: 3518,
      homeTeam: 'Juventus',
      awayTeam: 'Inter',
      playerHome: true,
      goalkeeper: false,
      sourceShirtColor: '#ffffff',
      sourceNumberColor: '#000000',
    );

    final barcelonaPixels = await _renderKit(barcelona);
    expect(barcelonaPixels.near(barcelona.primaryColor), greaterThan(24));
    expect(barcelonaPixels.near(barcelona.secondaryColor), greaterThan(24));
    expect(barcelonaPixels.near(barcelona.shortsColor), greaterThan(12));

    final juventusPixels = await _renderKit(juventus);
    expect(juventusPixels.near(juventus.primaryColor), greaterThan(24));
    expect(juventusPixels.near(juventus.secondaryColor), greaterThan(24));
    expect(juventusPixels.near(juventus.trimColor), greaterThan(3));
    expect(juventusPixels.near(juventus.shortsColor), greaterThan(12));
  });

  test('shirt numbers add a contrasting fill and halo at badge scale',
      () async {
    final kit = resolver.resolve(
      fixtureId: 2841,
      homeTeam: 'FC Barcelona',
      awayTeam: 'Real Madrid',
      playerHome: false,
      goalkeeper: false,
      sourceShirtColor: '#ffffff',
      sourceNumberColor: '#bfb600',
    );
    final blank = await _renderKit(kit, radius: 13.2);
    final numbered = await _renderKit(kit, number: '10', radius: 13.2);

    expect(numbered.differenceFrom(blank), greaterThan(20));
    expect(numbered.near(kit.numberColor, tolerance: 12), greaterThan(2));
    expect(
      numbered.addedDarkPixelsComparedTo(blank),
      greaterThan(0),
      reason: 'The number adds a dark outline even when it covers shirt edges.',
    );
  });
}

Future<_KitPixels> _renderKit(
  SpatialKitPresentation kit, {
  String number = '',
  double radius = 16.2,
}) async {
  const size = 48;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  SpatialKitPainter.paint(
    canvas: canvas,
    center: const Offset(size / 2, size / 2),
    radius: radius,
    kit: kit,
    number: number,
    textDirection: TextDirection.ltr,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  picture.dispose();
  return _KitPixels(data!.buffer.asUint8List());
}

class _KitPixels {
  final List<int> rgba;

  const _KitPixels(this.rgba);

  int near(
    Color color, {
    int tolerance = 4,
    int alphaMinimum = 220,
  }) {
    final value = color.toARGB32();
    final red = value >> 16 & 0xff;
    final green = value >> 8 & 0xff;
    final blue = value & 0xff;
    var count = 0;
    for (var offset = 0; offset < rgba.length; offset += 4) {
      if ((rgba[offset] - red).abs() <= tolerance &&
          (rgba[offset + 1] - green).abs() <= tolerance &&
          (rgba[offset + 2] - blue).abs() <= tolerance &&
          rgba[offset + 3] > alphaMinimum) {
        count++;
      }
    }
    return count;
  }

  int addedDarkPixelsComparedTo(_KitPixels before) {
    bool isDark(List<int> pixels, int offset) =>
        pixels[offset + 3] > 150 &&
        pixels[offset] < 64 &&
        pixels[offset + 1] < 64 &&
        pixels[offset + 2] < 64;
    var count = 0;
    for (var offset = 0; offset < rgba.length; offset += 4) {
      // Glyphs can cover old garment edges; only newly drawn dark pixels
      // demonstrate the number outline, independently of that lost edge area.
      if (isDark(rgba, offset) && !isDark(before.rgba, offset)) count++;
    }
    return count;
  }

  int differenceFrom(_KitPixels other) {
    var count = 0;
    for (var offset = 0; offset < rgba.length; offset += 4) {
      if ((rgba[offset] - other.rgba[offset]).abs() > 8 ||
          (rgba[offset + 1] - other.rgba[offset + 1]).abs() > 8 ||
          (rgba[offset + 2] - other.rgba[offset + 2]).abs() > 8 ||
          (rgba[offset + 3] - other.rgba[offset + 3]).abs() > 8) {
        count++;
      }
    }
    return count;
  }
}
