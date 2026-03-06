import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/training_method_layout.dart';

class TrainingMethodBoardScreen extends StatefulWidget {
  final String initialLayoutJson;
  final List<TrainingBoardPreset> presets;

  const TrainingMethodBoardScreen({
    super.key,
    required this.initialLayoutJson,
    this.presets = const <TrainingBoardPreset>[],
  });

  @override
  State<TrainingMethodBoardScreen> createState() =>
      _TrainingMethodBoardScreenState();
}

class _TrainingMethodBoardScreenState extends State<TrainingMethodBoardScreen> {
  late List<_BoardPageState> _pages;
  final TextEditingController _methodController = TextEditingController();
  int _pageIndex = 0;
  int _nextId = 1;
  int? _selectedItemId;

  _BoardPageState get _currentPage => _pages[_pageIndex];

  @override
  void initState() {
    super.initState();
    _restore();
    _methodController.text = _currentPage.methodText;
  }

  void _restore() {
    final layout = TrainingMethodLayout.decode(widget.initialLayoutJson);
    _pages = layout.pages
        .asMap()
        .entries
        .map((entry) {
          final i = entry.key;
          final page = entry.value;
          return _BoardPageState(
            name: page.name.trim().isEmpty ? 'Step ${i + 1}' : page.name,
            methodText: page.methodText,
            items: page.items
                .map(
                  (e) => _BoardItem(
                    id: _nextId++,
                    type:
                        _boardItemTypeFromString(e.type) ?? _BoardItemType.cone,
                    x: e.x,
                    y: e.y,
                    size: 32,
                    rotationDeg: e.rotationDeg,
                    color: Color(e.colorValue),
                  ),
                )
                .toList(growable: true),
          );
        })
        .toList(growable: true);
    if (_pages.isEmpty) {
      _pages = <_BoardPageState>[
        _BoardPageState(name: 'Step 1', methodText: '', items: <_BoardItem>[]),
      ];
    }
  }

  String _serialize() {
    final layout = TrainingMethodLayout(
      pages: _pages
          .map(
            (p) => TrainingMethodPage(
              name: p.name,
              methodText: p.methodText,
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
      _pages.add(
        _BoardPageState(
          name: 'Step ${_pages.length + 1}',
          methodText: '',
          items: <_BoardItem>[],
        ),
      );
      _pageIndex = _pages.length - 1;
      _selectedItemId = null;
      _methodController.text = _currentPage.methodText;
    });
  }

  void _deleteCurrentPage() {
    if (_pages.length <= 1) return;
    setState(() {
      _pages.removeAt(_pageIndex);
      _pageIndex = _pageIndex.clamp(0, _pages.length - 1);
      _selectedItemId = null;
      _methodController.text = _currentPage.methodText;
    });
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  void _applyPreset(TrainingBoardPreset preset) {
    final layout = TrainingMethodLayout.decode(preset.layoutJson);
    final rebuiltPages = <_BoardPageState>[];
    for (final pageEntry in layout.pages.asMap().entries) {
      final i = pageEntry.key;
      final page = pageEntry.value;
      rebuiltPages.add(
        _BoardPageState(
          name: page.name.trim().isEmpty ? 'Step ${i + 1}' : page.name,
          methodText: page.methodText,
          items: page.items
              .map(
                (e) => _BoardItem(
                  id: _nextId++,
                  type: _boardItemTypeFromString(e.type) ?? _BoardItemType.cone,
                  x: e.x,
                  y: e.y,
                  size: 32,
                  rotationDeg: e.rotationDeg,
                  color: Color(e.colorValue),
                ),
              )
              .toList(growable: true),
        ),
      );
    }
    setState(() {
      _pages = rebuiltPages.isEmpty
          ? <_BoardPageState>[
              _BoardPageState(
                name: 'Step 1',
                methodText: '',
                items: <_BoardItem>[],
              ),
            ]
          : rebuiltPages;
      _pageIndex = 0;
      _selectedItemId = null;
      _methodController.text = _currentPage.methodText;
    });
  }

  Future<void> _showPresetPicker(bool isKo) async {
    final selected = await showModalBottomSheet<TrainingBoardPreset>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView.builder(
            itemCount: widget.presets.length,
            itemBuilder: (context, index) {
              final preset = widget.presets[index];
              return ListTile(
                leading: const Icon(Icons.dashboard_customize_outlined),
                title: Text(preset.label),
                onTap: () => Navigator.of(context).pop(preset),
              );
            },
          ),
        );
      },
    );
    if (!mounted || selected == null) return;
    _applyPreset(selected);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isKo ? '기존 훈련 보드를 불러왔습니다.' : 'Training board loaded.'),
      ),
    );
  }

  @override
  void dispose() {
    _methodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    return Scaffold(
      appBar: AppBar(
        title: Text(isKo ? '훈련보드' : 'Training Board'),
        actions: [
          if (widget.presets.isNotEmpty)
            IconButton(
              tooltip: isKo ? '기존 보드 불러오기' : 'Load existing board',
              icon: const Icon(Icons.library_books_outlined),
              onPressed: () => _showPresetPicker(isKo),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_serialize()),
            child: Text(isKo ? '저장' : 'Save'),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _dismissKeyboard,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            children: [
              _buildPageHeader(isKo),
              const SizedBox(height: 8),
              _buildMethodTextInput(isKo),
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
                            painter: const _PitchPainter(),
                          ),
                          for (final item in _currentPage.items)
                            Positioned(
                              left: (item.x * width) - 26,
                              top: (item.y * height) - 26,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () =>
                                    setState(() => _selectedItemId = item.id),
                                onLongPress: () => setState(() {
                                  _currentPage.items.removeWhere(
                                    (e) => e.id == item.id,
                                  );
                                  if (_selectedItemId == item.id) {
                                    _selectedItemId = null;
                                  }
                                }),
                                onPanUpdate: (details) {
                                  final dx = details.delta.dx / width;
                                  final dy = details.delta.dy / height;
                                  final nextX = (item.x + dx).clamp(0.03, 0.97);
                                  final nextY = (item.y + dy).clamp(0.03, 0.97);
                                  setState(() {
                                    item.x = nextX;
                                    item.y = nextY;
                                  });
                                },
                                child: SizedBox(
                                  width: 52,
                                  height: 52,
                                  child: Center(
                                    child: _BoardToken(
                                      item: item,
                                      selected: item.id == _selectedItemId,
                                    ),
                                  ),
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
              _buildToolButtons(isKo),
              const SizedBox(height: 8),
              _buildSelectedTools(isKo),
            ],
          ),
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
                _methodController.text = _currentPage.methodText;
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
      ],
    );
  }

  Widget _buildMethodTextInput(bool isKo) {
    return TextField(
      controller: _methodController,
      minLines: 2,
      maxLines: 3,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: isKo ? '훈련 보드 메모' : 'Training board note',
        hintText: isKo
            ? '예) 콘 사이 2터치 드리블 후 패스'
            : 'e.g. Two-touch dribble between cones then pass',
        border: const OutlineInputBorder(),
      ),
      onSubmitted: (_) => _dismissKeyboard(),
      onChanged: (value) {
        _currentPage.methodText = value;
      },
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
          onTap: () => _addItem(_BoardItemType.cone),
        ),
        _toolButton(
          isKo: isKo,
          ko: '사람',
          en: 'Player',
          icon: Icons.person,
          onTap: () => _addItem(_BoardItemType.player),
        ),
        _toolButton(
          isKo: isKo,
          ko: '공',
          en: 'Ball',
          icon: Icons.sports_soccer,
          onTap: () => _addItem(_BoardItemType.ball),
        ),
        _toolButton(
          isKo: isKo,
          ko: '사다리',
          en: 'Ladder',
          icon: Icons.view_week,
          onTap: () => _addItem(_BoardItemType.ladder),
        ),
        OutlinedButton.icon(
          onPressed: () => setState(() {
            _currentPage.items.clear();
            _selectedItemId = null;
          }),
          icon: const Icon(Icons.delete_sweep_outlined),
          label: Text(isKo ? '초기화' : 'Clear'),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            minimumSize: const Size(1, 40),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
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
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        minimumSize: const Size(1, 40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }

  Widget _buildSelectedTools(bool isKo) {
    final selected = _selectedItem;
    if (selected == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          isKo
              ? '요소를 탭한 뒤 이동하거나 색상을 선택하세요.'
              : 'Tap an item, then move it or choose color.',
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
                  isKo ? '선택 요소' : 'Selected item',
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
          Text(
            isKo ? '색상 지정' : 'Assign color',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetColors
                .map((c) {
                  final selectedColor =
                      c.toARGB32() == selected.color.toARGB32();
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
                })
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _BoardPageState {
  final String name;
  String methodText;
  final List<_BoardItem> items;

  _BoardPageState({
    required this.name,
    required this.methodText,
    required this.items,
  });
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

const List<Color> _presetColors = <Color>[
  Color(0xFFFFB300),
  Color(0xFF42A5F5),
  Color(0xFF43A047),
  Color(0xFFFB8C00),
  Color(0xFFE53935),
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
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.18),
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.55),
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
        child: Icon(icon, size: 18, color: item.color),
      ),
    );
  }
}

class _PitchPainter extends CustomPainter {
  const _PitchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
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
    canvas.drawRect(Rect.fromLTWH(8, (size.height / 2) - 56, 74, 112), line);
    canvas.drawRect(
      Rect.fromLTWH(size.width - 82, (size.height / 2) - 56, 74, 112),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant _PitchPainter oldDelegate) {
    return false;
  }
}

class TrainingBoardPreset {
  final String label;
  final String layoutJson;

  const TrainingBoardPreset({required this.label, required this.layoutJson});
}
