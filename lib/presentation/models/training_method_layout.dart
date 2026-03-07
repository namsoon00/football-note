import 'dart:convert';

class TrainingMethodLayout {
  final List<TrainingMethodPage> pages;

  const TrainingMethodLayout({required this.pages});

  factory TrainingMethodLayout.empty() {
    return const TrainingMethodLayout(
      pages: <TrainingMethodPage>[
        TrainingMethodPage(name: 'Step 1', items: <TrainingMethodItem>[]),
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
            .map((e) => TrainingMethodItem.fromMap(e.cast<String, dynamic>()))
            .toList(growable: false);
        return TrainingMethodLayout(
          pages: <TrainingMethodPage>[
            TrainingMethodPage(name: 'Step 1', items: items),
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
      'version': 1,
      'pages': pages.map((e) => e.toMap()).toList(growable: false),
    });
  }
}

class TrainingMethodPage {
  final String name;
  final String methodText;
  final List<TrainingMethodItem> items;
  final List<TrainingMethodStroke> strokes;

  const TrainingMethodPage({
    required this.name,
    this.methodText = '',
    required this.items,
    this.strokes = const <TrainingMethodStroke>[],
  });

  factory TrainingMethodPage.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'];
    return TrainingMethodPage(
      name: (map['name'] as String?)?.trim().isNotEmpty == true
          ? (map['name'] as String)
          : 'Step',
      methodText: (map['methodText'] as String?) ?? '',
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((e) => TrainingMethodItem.fromMap(e.cast<String, dynamic>()))
              .toList(growable: false)
          : const <TrainingMethodItem>[],
      strokes: (map['strokes'] is List)
          ? (map['strokes'] as List)
              .whereType<Map>()
              .map(
                (e) => TrainingMethodStroke.fromMap(e.cast<String, dynamic>()),
              )
              .toList(growable: false)
          : const <TrainingMethodStroke>[],
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'methodText': methodText,
        'items': items.map((e) => e.toMap()).toList(growable: false),
        'strokes': strokes.map((e) => e.toMap()).toList(growable: false),
      };
}

class TrainingMethodItem {
  final String type;
  final double x;
  final double y;
  final double size;
  final double rotationDeg;
  final int colorValue;

  const TrainingMethodItem({
    required this.type,
    required this.x,
    required this.y,
    this.size = 32,
    this.rotationDeg = 0,
    this.colorValue = 0xFFFFFFFF,
  });

  factory TrainingMethodItem.fromMap(Map<String, dynamic> map) {
    final x = (map['x'] as num?)?.toDouble() ?? 0.5;
    final y = (map['y'] as num?)?.toDouble() ?? 0.5;
    return TrainingMethodItem(
      type: (map['type'] as String?) ?? 'cone',
      x: x.clamp(0.03, 0.97),
      y: y.clamp(0.03, 0.97),
      size: ((map['size'] as num?)?.toDouble() ?? 32).clamp(18, 56),
      rotationDeg:
          ((map['rotationDeg'] as num?)?.toDouble() ?? 0).clamp(-180, 180),
      colorValue: (map['colorValue'] as num?)?.toInt() ?? 0xFFFFFFFF,
    );
  }

  Map<String, dynamic> toMap() => {
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
              .map((e) => TrainingMethodPoint.fromMap(e.cast<String, dynamic>()))
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
