import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/training_method_layout.dart';

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
  late List<_BoardPageState> _pages;
  int _pageIndex = 0;
  int _nextId = 1;
  int? _selectedItemId;
  bool _snapToGrid = true;
  bool _playMode = false;

  _BoardPageState get _currentPage => _pages[_pageIndex];

  @override
  void initState() {
    super.initState();
    _restore();
  }

  void _restore() {
    final layout = TrainingMethodLayout.decode(widget.initialLayoutJson);
    _pages = layout.pages.asMap().entries.map((entry) {
      final i = entry.key;
      final page = entry.value;
      return _BoardPageState(
        name: page.name.trim().isEmpty ? 'Step ${i + 1}' : page.name,
        items: page.items
            .map(
              (e) => _BoardItem(
                id: _nextId++,
                type: _boardItemTypeFromString(e.type) ?? _BoardItemType.cone,
                x: e.x,
                y: e.y,
                size: e.size,
                rotationDeg: e.rotationDeg,
                color: Color(e.colorValue),
              ),
            )
            .toList(growable: true),
      );
    }).toList(growable: true);
    if (_pages.isEmpty) {
      _pages = <_BoardPageState>[
        const _BoardPageState(name: 'Step 1', items: <_BoardItem>[])
      ];
    }
  }

  String _serialize() {
    final layout = TrainingMethodLayout(
      pages: _pages
          .map(
            (p) => TrainingMethodPage(
              name: p.name,
              items: p.items
                  .map(
                    (e) => TrainingMethodItem(
                      type: e.type.name,
                      x: e.x,
                      y: e.y,
                      size: e.size,
                      rotationDeg: e.rotationDeg,
                      colorValue: e.color.toARGB32(),
                    ),
                  )
                  .toList(growable: false),
            ),
          )
          .toList(growable: false),
    );
    return layout.encode();
  }

  _BoardItem? get _selectedItem {
    final id = _selectedItemId;
    if (id == null) return null;
    for (final item in _currentPage.items) {
      if (item.id == id) return item;
    }
    return null;
  }

  void _addItem(_BoardItemType type) {
    setState(() {
      final item = _BoardItem(
        id: _nextId++,
        type: type,
        x: 0.5,
        y: 0.5,
        size: 32,
        rotationDeg: 0,
        color: _defaultColorFor(type),
      );
      _currentPage.items.add(item);
      _selectedItemId = item.id;
    });
  }

  void _removeSelected() {
    final id = _selectedItemId;
    if (id == null) return;
    setState(() {
      _currentPage.items.removeWhere((e) => e.id == id);
      _selectedItemId = null;
    });
  }

  void _addPage() {
    setState(() {
      _pages.add(_BoardPageState(
          name: 'Step ${_pages.length + 1}', items: <_BoardItem>[]));
      _pageIndex = _pages.length - 1;
      _selectedItemId = null;
    });
  }

  void _deleteCurrentPage() {
    if (_pages.length <= 1) return;
    setState(() {
      _pages.removeAt(_pageIndex);
      _pageIndex = _pageIndex.clamp(0, _pages.length - 1);
      _selectedItemId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    return Scaffold(
      appBar: AppBar(
        title: Text(isKo ? '훈련 방법 보드' : 'Training Method Board'),
        actions: [
          IconButton(
            tooltip: isKo ? '재생 모드' : 'Play mode',
            icon: Icon(_playMode ? Icons.pause_circle : Icons.play_circle),
            onPressed: () => setState(() => _playMode = !_playMode),
          ),
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
            _buildPageHeader(isKo),
            const SizedBox(height: 8),
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
                          painter: _PitchPainter(
                              showGrid: _snapToGrid && !_playMode),
                        ),
                        for (final item in _currentPage.items)
                          Positioned(
                            left: (item.x * width) - (item.size / 2),
                            top: (item.y * height) - (item.size / 2),
                            child: GestureDetector(
                              onTap: _playMode
                                  ? null
                                  : () =>
                                      setState(() => _selectedItemId = item.id),
                              onLongPress: _playMode
                                  ? null
                                  : () => setState(() {
                                        _currentPage.items.removeWhere(
                                            (e) => e.id == item.id);
                                        if (_selectedItemId == item.id) {
                                          _selectedItemId = null;
                                        }
                                      }),
                              onPanUpdate: _playMode
                                  ? null
                                  : (details) {
                                      final dx = details.delta.dx / width;
                                      final dy = details.delta.dy / height;
                                      var nextX =
                                          (item.x + dx).clamp(0.03, 0.97);
                                      var nextY =
                                          (item.y + dy).clamp(0.03, 0.97);
                                      if (_snapToGrid) {
                                        const grid = 0.04;
                                        nextX = (nextX / grid).round() * grid;
                                        nextY = (nextY / grid).round() * grid;
                                      }
                                      setState(() {
                                        item.x = nextX.clamp(0.03, 0.97);
                                        item.y = nextY.clamp(0.03, 0.97);
                                      });
                                    },
                              child: _BoardToken(
                                item: item,
                                selected:
                                    !_playMode && item.id == _selectedItemId,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            if (!_playMode) _buildToolButtons(isKo),
            if (!_playMode) const SizedBox(height: 8),
            if (!_playMode) _buildItemEditor(isKo),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader(bool isKo) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: _pageIndex,
            decoration: InputDecoration(
              isDense: true,
              labelText: isKo ? '스텝' : 'Step',
              border: const OutlineInputBorder(),
            ),
            items: _pages
                .asMap()
                .entries
                .map(
                  (e) => DropdownMenuItem<int>(
                    value: e.key,
                    child: Text(e.value.name),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _pageIndex = value;
                _selectedItemId = null;
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _addPage,
          icon: const Icon(Icons.add_box_outlined),
          tooltip: isKo ? '스텝 추가' : 'Add step',
        ),
        IconButton(
          onPressed: _pages.length <= 1 ? null : _deleteCurrentPage,
          icon: const Icon(Icons.indeterminate_check_box_outlined),
          tooltip: isKo ? '스텝 삭제' : 'Remove step',
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isKo ? '격자' : 'Grid'),
            Switch(
              value: _snapToGrid,
              onChanged:
                  _playMode ? null : (v) => setState(() => _snapToGrid = v),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolButtons(bool isKo) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _toolButton(
            isKo: isKo,
            ko: '콘',
            en: 'Cone',
            icon: Icons.change_history,
            onTap: () => _addItem(_BoardItemType.cone)),
        _toolButton(
            isKo: isKo,
            ko: '사람',
            en: 'Player',
            icon: Icons.person,
            onTap: () => _addItem(_BoardItemType.player)),
        _toolButton(
            isKo: isKo,
            ko: '공',
            en: 'Ball',
            icon: Icons.sports_soccer,
            onTap: () => _addItem(_BoardItemType.ball)),
        _toolButton(
            isKo: isKo,
            ko: '사다리',
            en: 'Ladder',
            icon: Icons.view_week,
            onTap: () => _addItem(_BoardItemType.ladder)),
        OutlinedButton.icon(
          onPressed: () => setState(() {
            _currentPage.items.clear();
            _selectedItemId = null;
          }),
          icon: const Icon(Icons.delete_sweep_outlined),
          label: Text(isKo ? '초기화' : 'Clear'),
        ),
      ],
    );
  }

  Widget _toolButton({
    required bool isKo,
    required String ko,
    required String en,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(isKo ? ko : en),
    );
  }

  Widget _buildItemEditor(bool isKo) {
    final selected = _selectedItem;
    if (selected == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          isKo ? '요소를 탭해서 편집하세요.' : 'Tap an item to edit.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isKo ? '선택 요소 편집' : 'Selected item',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                onPressed: _removeSelected,
                icon: const Icon(Icons.delete_outline),
                tooltip: isKo ? '삭제' : 'Delete',
              ),
            ],
          ),
          _sliderRow(
            label: isKo ? '크기' : 'Size',
            value: selected.size,
            min: 18,
            max: 56,
            onChanged: (v) => setState(() => selected.size = v),
          ),
          _sliderRow(
            label: isKo ? '회전' : 'Rotation',
            value: selected.rotationDeg,
            min: -180,
            max: 180,
            onChanged: (v) => setState(() => selected.rotationDeg = v),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tokenColors.map((c) {
              final selectedColor = c.toARGB32() == selected.color.toARGB32();
              return InkWell(
                onTap: () => setState(() => selected.color = c),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c,
                    border: Border.all(
                      color: selectedColor ? Colors.white : Colors.black26,
                      width: selectedColor ? 2.4 : 1.0,
                    ),
                  ),
                ),
              );
            }).toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _sliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(width: 64, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: 36, child: Text(value.round().toString())),
      ],
    );
  }
}

class _BoardPageState {
  final String name;
  final List<_BoardItem> items;

  const _BoardPageState({required this.name, required this.items});
}

class _BoardItem {
  final int id;
  final _BoardItemType type;
  double x;
  double y;
  double size;
  double rotationDeg;
  Color color;

  _BoardItem({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.size,
    required this.rotationDeg,
    required this.color,
  });
}

enum _BoardItemType { cone, player, ball, ladder }

_BoardItemType? _boardItemTypeFromString(String raw) {
  for (final value in _BoardItemType.values) {
    if (value.name == raw) return value;
  }
  return null;
}

Color _defaultColorFor(_BoardItemType type) {
  return switch (type) {
    _BoardItemType.cone => const Color(0xFFFFB300),
    _BoardItemType.player => const Color(0xFF42A5F5),
    _BoardItemType.ball => const Color(0xFFFFFFFF),
    _BoardItemType.ladder => const Color(0xFFE53935),
  };
}

const List<Color> _tokenColors = <Color>[
  Color(0xFFFFFFFF),
  Color(0xFFFFB300),
  Color(0xFF42A5F5),
  Color(0xFFE53935),
  Color(0xFFAB47BC),
  Color(0xFF26A69A),
  Color(0xFFFF7043),
  Color(0xFF8D6E63),
];

class _BoardToken extends StatelessWidget {
  final _BoardItem item;
  final bool selected;

  const _BoardToken({required this.item, required this.selected});

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.type) {
      _BoardItemType.cone => Icons.change_history,
      _BoardItemType.player => Icons.person,
      _BoardItemType.ball => Icons.sports_soccer,
      _BoardItemType.ladder => Icons.view_week,
    };
    return Transform.rotate(
      angle: (item.rotationDeg * math.pi) / 180,
      child: Container(
        width: item.size,
        height: item.size,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.18),
          shape: BoxShape.circle,
          border: Border.all(
            color:
                selected ? Colors.white : Colors.white.withValues(alpha: 0.55),
            width: selected ? 2.2 : 1.2,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(icon, size: item.size * 0.55, color: item.color),
      ),
    );
  }
}

class _PitchPainter extends CustomPainter {
  final bool showGrid;

  const _PitchPainter({required this.showGrid});

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    if (showGrid) {
      final grid = Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..strokeWidth = 1;
      for (double x = 0; x <= size.width; x += size.width * 0.08) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
      }
      for (double y = 0; y <= size.height; y += size.height * 0.08) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
      }
    }

    canvas.drawRect(
        Rect.fromLTWH(8, 8, size.width - 16, size.height - 16), line);
    canvas.drawLine(Offset(centerX, 8), Offset(centerX, size.height - 8), line);
    canvas.drawCircle(Offset(centerX, centerY), 42, line);
    canvas.drawRect(Rect.fromLTWH(8, (size.height / 2) - 56, 74, 112), line);
    canvas.drawRect(
      Rect.fromLTWH(size.width - 82, (size.height / 2) - 56, 74, 112),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant _PitchPainter oldDelegate) {
    return oldDelegate.showGrid != showGrid;
  }
}
