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
  final List<TrainingMethodItem> items;

  const TrainingMethodPage({required this.name, required this.items});

  factory TrainingMethodPage.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'];
    return TrainingMethodPage(
      name: (map['name'] as String?)?.trim().isNotEmpty == true
          ? (map['name'] as String)
          : 'Step',
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((e) => TrainingMethodItem.fromMap(e.cast<String, dynamic>()))
              .toList(growable: false)
          : const <TrainingMethodItem>[],
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'items': items.map((e) => e.toMap()).toList(growable: false),
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
