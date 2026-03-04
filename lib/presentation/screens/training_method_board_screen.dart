import 'dart:convert';

import 'package:flutter/material.dart';

class TrainingMethodBoardScreen extends StatefulWidget {
  final String initialLayoutJson;

  const TrainingMethodBoardScreen({
    super.key,
    required this.initialLayoutJson,
  });

  @override
  State<TrainingMethodBoardScreen> createState() =>
      _TrainingMethodBoardScreenState();
}

class _TrainingMethodBoardScreenState extends State<TrainingMethodBoardScreen> {
  final List<_BoardItem> _items = <_BoardItem>[];
  int _nextId = 1;

  @override
  void initState() {
    super.initState();
    _restoreInitialItems();
  }

  void _restoreInitialItems() {
    final raw = widget.initialLayoutJson.trim();
    if (raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      for (final e in decoded) {
        if (e is! Map) continue;
        final typeRaw = e['type']?.toString() ?? '';
        final type = _itemTypeFromString(typeRaw);
        if (type == null) continue;
        final x = (e['x'] as num?)?.toDouble() ?? 0.5;
        final y = (e['y'] as num?)?.toDouble() ?? 0.5;
        final item = _BoardItem(
          id: _nextId++,
          type: type,
          x: x.clamp(0.03, 0.97),
          y: y.clamp(0.03, 0.97),
        );
        _items.add(item);
      }
    } catch (_) {
      // Ignore malformed prototype payload and start empty.
    }
  }

  void _addItem(_BoardItemType type) {
    setState(() {
      _items.add(_BoardItem(id: _nextId++, type: type, x: 0.5, y: 0.5));
    });
  }

  void _removeItem(int id) {
    setState(() {
      _items.removeWhere((e) => e.id == id);
    });
  }

  String _serialize() {
    final payload = _items
        .map(
          (e) => <String, dynamic>{
            'type': e.type.name,
            'x': e.x,
            'y': e.y,
          },
        )
        .toList(growable: false);
    return jsonEncode(payload);
  }

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    return Scaffold(
      appBar: AppBar(
        title: Text(isKo ? '훈련 방법 보드' : 'Training Method Board'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_serialize()),
            child: Text(isKo ? '저장' : 'Save'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final height = constraints.maxHeight;
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                      ),
                    ),
                    child: Stack(
                      children: [
                        CustomPaint(
                          size: Size(width, height),
                          painter: _PitchPainter(),
                        ),
                        for (final item in _items)
                          Positioned(
                            left: (item.x * width) - 16,
                            top: (item.y * height) - 16,
                            child: GestureDetector(
                              onLongPress: () => _removeItem(item.id),
                              onPanUpdate: (details) {
                                final dx = details.delta.dx / width;
                                final dy = details.delta.dy / height;
                                setState(() {
                                  item.x = (item.x + dx).clamp(0.03, 0.97);
                                  item.y = (item.y + dy).clamp(0.03, 0.97);
                                });
                              },
                              child: _BoardToken(type: item.type),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _addButton(
                  isKo: isKo,
                  labelKo: '콘',
                  labelEn: 'Cone',
                  icon: Icons.change_history,
                  onTap: () => _addItem(_BoardItemType.cone),
                ),
                _addButton(
                  isKo: isKo,
                  labelKo: '사람',
                  labelEn: 'Player',
                  icon: Icons.person,
                  onTap: () => _addItem(_BoardItemType.player),
                ),
                _addButton(
                  isKo: isKo,
                  labelKo: '공',
                  labelEn: 'Ball',
                  icon: Icons.sports_soccer,
                  onTap: () => _addItem(_BoardItemType.ball),
                ),
                _addButton(
                  isKo: isKo,
                  labelKo: '사다리',
                  labelEn: 'Ladder',
                  icon: Icons.view_week,
                  onTap: () => _addItem(_BoardItemType.ladder),
                ),
                OutlinedButton.icon(
                  onPressed: () => setState(_items.clear),
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: Text(isKo ? '초기화' : 'Clear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _addButton({
    required bool isKo,
    required String labelKo,
    required String labelEn,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(isKo ? labelKo : labelEn),
    );
  }
}

_BoardItemType? _itemTypeFromString(String raw) {
  for (final type in _BoardItemType.values) {
    if (type.name == raw) return type;
  }
  return null;
}

class _BoardItem {
  final int id;
  final _BoardItemType type;
  double x;
  double y;

  _BoardItem({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
  });
}

enum _BoardItemType { cone, player, ball, ladder }

class _BoardToken extends StatelessWidget {
  final _BoardItemType type;

  const _BoardToken({required this.type});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      _BoardItemType.cone => (Icons.change_history, const Color(0xFFFFB300)),
      _BoardItemType.player => (Icons.person, const Color(0xFF42A5F5)),
      _BoardItemType.ball => (Icons.sports_soccer, const Color(0xFFFFFFFF)),
      _BoardItemType.ladder => (Icons.view_week, const Color(0xFFE53935)),
    };
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    canvas.drawRect(
      Rect.fromLTWH(8, 8, size.width - 16, size.height - 16),
      line,
    );
    canvas.drawLine(Offset(centerX, 8), Offset(centerX, size.height - 8), line);
    canvas.drawCircle(Offset(centerX, centerY), 42, line);
    canvas.drawRect(
      Rect.fromLTWH(8, (size.height / 2) - 56, 74, 112),
      line,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width - 82, (size.height / 2) - 56, 74, 112),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
