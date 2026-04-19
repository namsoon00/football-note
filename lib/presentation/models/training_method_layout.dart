import 'dart:convert';

class TrainingMethodLayout {
  final List<TrainingMethodPage> pages;

  const TrainingMethodLayout({required this.pages});

  factory TrainingMethodLayout.empty() {
    return const TrainingMethodLayout(
      pages: <TrainingMethodPage>[
        TrainingMethodPage(name: 'Board 1', items: <TrainingMethodItem>[]),
      ],
    );
  }

  factory TrainingMethodLayout.decode(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return TrainingMethodLayout.empty();
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        final rawPages = decoded['pages'];
        if (rawPages is List) {
          final pages = rawPages
              .whereType<Map>()
              .map((e) => TrainingMethodPage.fromMap(e.cast<String, dynamic>()))
              .toList(growable: false);
          if (pages.isNotEmpty) {
            return TrainingMethodLayout(pages: pages);
          }
        }
      }
      // Legacy v0 support: raw list of items.
      if (decoded is List) {
        final items = decoded
            .whereType<Map>()
            .toList(growable: false)
            .asMap()
            .entries
            .map(
              (entry) => TrainingMethodItem.fromMap(
                entry.value.cast<String, dynamic>(),
                fallbackId: 'item_${entry.key + 1}',
              ),
            )
            .toList(growable: false);
        return TrainingMethodLayout(
          pages: <TrainingMethodPage>[
            TrainingMethodPage(name: 'Board 1', items: items),
          ],
        );
      }
    } catch (_) {
      // ignore malformed payload
    }
    return TrainingMethodLayout.empty();
  }

  String encode() {
    return jsonEncode({
      'version': 2,
      'pages': pages.map((e) => e.toMap()).toList(growable: false),
    });
  }
}

class TrainingMethodPage {
  final String name;
  final String methodText;
  final List<TrainingMethodItem> items;
  final List<TrainingMethodStroke> strokes;
  final List<TrainingMethodRoute> routes;

  const TrainingMethodPage({
    required this.name,
    this.methodText = '',
    required this.items,
    this.strokes = const <TrainingMethodStroke>[],
    this.routes = const <TrainingMethodRoute>[],
  });

  factory TrainingMethodPage.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .toList(growable: false)
            .asMap()
            .entries
            .map(
              (entry) => TrainingMethodItem.fromMap(
                entry.value.cast<String, dynamic>(),
                fallbackId: 'item_${entry.key + 1}',
              ),
            )
            .toList(growable: false)
        : const <TrainingMethodItem>[];
    final routes = _decodeRoutes(map);
    return TrainingMethodPage(
      name: (map['name'] as String?)?.trim().isNotEmpty == true
          ? (map['name'] as String)
          : 'Board',
      methodText: (map['methodText'] as String?) ?? '',
      items: items,
      strokes: (map['strokes'] is List)
          ? (map['strokes'] as List)
              .whereType<Map>()
              .map(
                (e) => TrainingMethodStroke.fromMap(e.cast<String, dynamic>()),
              )
              .toList(growable: false)
          : const <TrainingMethodStroke>[],
      routes: routes,
    );
  }

  List<TrainingMethodPoint> get playerPath => _legacyPathFor(
        TrainingMethodRouteKind.player,
      );

  List<TrainingMethodPoint> get ballPath => _legacyPathFor(
        TrainingMethodRouteKind.ball,
      );

  List<TrainingMethodPoint> _legacyPathFor(TrainingMethodRouteKind kind) {
    final route = routes.firstWhere(
      (entry) => entry.kind == kind,
      orElse: () => const TrainingMethodRoute(
        id: '',
        kind: TrainingMethodRouteKind.player,
        points: <TrainingMethodPoint>[],
      ),
    );
    return route.kind == kind ? route.points : const <TrainingMethodPoint>[];
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'methodText': methodText,
        'items': items.map((e) => e.toMap()).toList(growable: false),
        'strokes': strokes.map((e) => e.toMap()).toList(growable: false),
        'routes': routes.map((e) => e.toMap()).toList(growable: false),
        'playerPath': playerPath.map((e) => e.toMap()).toList(growable: false),
        'ballPath': ballPath.map((e) => e.toMap()).toList(growable: false),
      };
}

class TrainingMethodItem {
  final String id;
  final String type;
  final double x;
  final double y;
  final double size;
  final double rotationDeg;
  final int colorValue;

  const TrainingMethodItem({
    this.id = '',
    required this.type,
    required this.x,
    required this.y,
    this.size = 32,
    this.rotationDeg = 0,
    this.colorValue = 0xFFFFFFFF,
  });

  factory TrainingMethodItem.fromMap(
    Map<String, dynamic> map, {
    required String fallbackId,
  }) {
    final x = (map['x'] as num?)?.toDouble() ?? 0.5;
    final y = (map['y'] as num?)?.toDouble() ?? 0.5;
    return TrainingMethodItem(
      id: ((map['id'] as String?) ?? fallbackId).trim().isEmpty
          ? fallbackId
          : (map['id'] as String?)!.trim(),
      type: (map['type'] as String?) ?? 'cone',
      x: x.clamp(0.03, 0.97),
      y: y.clamp(0.03, 0.97),
      size: ((map['size'] as num?)?.toDouble() ?? 32).clamp(18, 56),
      rotationDeg: ((map['rotationDeg'] as num?)?.toDouble() ?? 0).clamp(
        -180,
        180,
      ),
      colorValue: (map['colorValue'] as num?)?.toInt() ?? 0xFFFFFFFF,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'x': x,
        'y': y,
        'size': size,
        'rotationDeg': rotationDeg,
        'colorValue': colorValue,
      };
}

class TrainingMethodStroke {
  final List<TrainingMethodPoint> points;
  final int colorValue;
  final double width;

  const TrainingMethodStroke({
    required this.points,
    this.colorValue = 0xFFFFFFFF,
    this.width = 3.0,
  });

  factory TrainingMethodStroke.fromMap(Map<String, dynamic> map) {
    final rawPoints = map['points'];
    final parsedPoints = rawPoints is List
        ? rawPoints
            .whereType<Map>()
            .map(
              (e) => TrainingMethodPoint.fromMap(e.cast<String, dynamic>()),
            )
            .toList(growable: false)
        : const <TrainingMethodPoint>[];
    return TrainingMethodStroke(
      points: parsedPoints,
      colorValue: (map['colorValue'] as num?)?.toInt() ?? 0xFFFFFFFF,
      width: ((map['width'] as num?)?.toDouble() ?? 3.0).clamp(1.0, 12.0),
    );
  }

  Map<String, dynamic> toMap() => {
        'points': points.map((e) => e.toMap()).toList(growable: false),
        'colorValue': colorValue,
        'width': width,
      };
}

enum TrainingMethodRouteKind { player, ball }

class TrainingMethodRoute {
  final String id;
  final TrainingMethodRouteKind kind;
  final String? linkedItemId;
  final List<TrainingMethodPoint> points;
  final int colorValue;
  final double width;

  const TrainingMethodRoute({
    this.id = '',
    required this.kind,
    required this.points,
    this.linkedItemId,
    this.colorValue = 0xFF80D8FF,
    this.width = 4.0,
  });

  factory TrainingMethodRoute.fromMap(Map<String, dynamic> map) {
    final parsedKind = _routeKindFromRaw(map['kind'] as String?);
    final fallbackKind = parsedKind ?? TrainingMethodRouteKind.player;
    final rawId = (map['id'] as String?)?.trim();
    return TrainingMethodRoute(
      id: rawId == null || rawId.isEmpty ? 'route_${fallbackKind.name}' : rawId,
      kind: fallbackKind,
      linkedItemId: (map['linkedItemId'] as String?)?.trim().isEmpty == true
          ? null
          : (map['linkedItemId'] as String?),
      points: (map['points'] is List)
          ? (map['points'] as List)
              .whereType<Map>()
              .map(
                (e) => TrainingMethodPoint.fromMap(e.cast<String, dynamic>()),
              )
              .toList(growable: false)
          : const <TrainingMethodPoint>[],
      colorValue: (map['colorValue'] as num?)?.toInt() ??
          _defaultColorForRouteKind(fallbackKind),
      width: ((map['width'] as num?)?.toDouble() ??
              _defaultWidthForRouteKind(fallbackKind))
          .clamp(1.0, 12.0),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'kind': kind.name,
        if (linkedItemId != null) 'linkedItemId': linkedItemId,
        'points': points.map((e) => e.toMap()).toList(growable: false),
        'colorValue': colorValue,
        'width': width,
      };
}

class TrainingMethodPoint {
  final double x;
  final double y;

  const TrainingMethodPoint({required this.x, required this.y});

  factory TrainingMethodPoint.fromMap(Map<String, dynamic> map) {
    return TrainingMethodPoint(
      x: ((map['x'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0),
      y: ((map['y'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0),
    );
  }

  Map<String, dynamic> toMap() => {'x': x, 'y': y};
}

List<TrainingMethodRoute> _decodeRoutes(Map<String, dynamic> map) {
  final rawRoutes = map['routes'];
  if (rawRoutes is List) {
    final parsedRoutes = rawRoutes
        .whereType<Map>()
        .map((e) => TrainingMethodRoute.fromMap(e.cast<String, dynamic>()))
        .where((route) => route.points.length >= 2)
        .toList(growable: false);
    if (parsedRoutes.isNotEmpty) {
      return parsedRoutes;
    }
  }

  final legacyRoutes = <TrainingMethodRoute>[];
  final playerPoints = _decodeLegacyPoints(map['playerPath']);
  if (playerPoints.length >= 2) {
    legacyRoutes.add(
      TrainingMethodRoute(
        id: 'legacy_player_1',
        kind: TrainingMethodRouteKind.player,
        points: playerPoints,
        colorValue: _defaultColorForRouteKind(TrainingMethodRouteKind.player),
        width: _defaultWidthForRouteKind(TrainingMethodRouteKind.player),
      ),
    );
  }
  final ballPoints = _decodeLegacyPoints(map['ballPath']);
  if (ballPoints.length >= 2) {
    legacyRoutes.add(
      TrainingMethodRoute(
        id: 'legacy_ball_1',
        kind: TrainingMethodRouteKind.ball,
        points: ballPoints,
        colorValue: _defaultColorForRouteKind(TrainingMethodRouteKind.ball),
        width: _defaultWidthForRouteKind(TrainingMethodRouteKind.ball),
      ),
    );
  }
  return legacyRoutes;
}

List<TrainingMethodPoint> _decodeLegacyPoints(Object? raw) {
  if (raw is! List) return const <TrainingMethodPoint>[];
  return raw
      .whereType<Map>()
      .map((e) => TrainingMethodPoint.fromMap(e.cast<String, dynamic>()))
      .toList(growable: false);
}

TrainingMethodRouteKind? _routeKindFromRaw(String? raw) {
  for (final value in TrainingMethodRouteKind.values) {
    if (value.name == raw) return value;
  }
  return null;
}

int _defaultColorForRouteKind(TrainingMethodRouteKind kind) {
  return switch (kind) {
    TrainingMethodRouteKind.player => 0xFF80D8FF,
    TrainingMethodRouteKind.ball => 0xFFFFCA28,
  };
}

double _defaultWidthForRouteKind(TrainingMethodRouteKind kind) {
  return switch (kind) {
    TrainingMethodRouteKind.player => 4.0,
    TrainingMethodRouteKind.ball => 3.0,
  };
}
