import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/training_method_layout.dart';

class TrainingMethodBoardScreen extends StatefulWidget {
  final String initialLayoutJson;
  final List<TrainingBoardPreset> presets;
  final ValueChanged<String>? onSaved;

  const TrainingMethodBoardScreen({
    super.key,
    required this.initialLayoutJson,
    this.presets = const <TrainingBoardPreset>[],
    this.onSaved,
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
  bool _penMode = false;
  Color _penColor = const Color(0xFF000000);
  List<Offset>? _activeStroke;
  String _lastSavedLayout = '';

  _BoardPageState get _currentPage => _pages[_pageIndex];

  bool get _hasUnsavedChanges => _serialize() != _lastSavedLayout;

  @override
  void initState() {
    super.initState();
    _restore();
    _methodController.text = _currentPage.methodText;
    _lastSavedLayout = _serialize();
  }

  void _restore() {
    final layout = TrainingMethodLayout.decode(widget.initialLayoutJson);
    _pages = layout.pages.asMap().entries.map((entry) {
      final i = entry.key;
      final page = entry.value;
      return _BoardPageState(
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
        strokes: page.strokes
            .map(
              (stroke) => _BoardStroke(
                points: stroke.points
                    .map((point) => Offset(point.x, point.y))
                    .toList(growable: false),
                color: Color(stroke.colorValue),
                width: stroke.width,
              ),
            )
            .toList(growable: true),
      );
    }).toList(growable: true);
    if (_pages.isEmpty) {
      _pages = <_BoardPageState>[
        _BoardPageState(
          name: 'Step 1',
          methodText: '',
          items: <_BoardItem>[],
          strokes: <_BoardStroke>[],
        ),
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
              strokes: p.strokes
                  .map(
                    (stroke) => TrainingMethodStroke(
                      points: stroke.points
                          .map(
                            (point) =>
                                TrainingMethodPoint(x: point.dx, y: point.dy),
                          )
                          .toList(growable: false),
                      colorValue: stroke.color.toARGB32(),
                      width: stroke.width,
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
      _penMode = false;
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
          strokes: <_BoardStroke>[],
        ),
      );
      _pageIndex = _pages.length - 1;
      _selectedItemId = null;
      _methodController.text = _currentPage.methodText;
    });
  }

  Future<void> _renameCurrentPage(bool isKo) async {
    final controller = TextEditingController(text: _currentPage.name);
    final renamed = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isKo ? '스텝명 변경' : 'Rename step'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: isKo ? '스텝명' : 'Step name',
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(isKo ? '취소' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(isKo ? '적용' : 'Apply'),
          ),
        ],
      ),
    );
    controller.dispose();
    final next = (renamed ?? '').trim();
    if (next.isEmpty) return;
    setState(() {
      _currentPage.name = next;
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

  Future<void> _saveBoard(bool isKo) async {
    final serialized = _serialize();
    widget.onSaved?.call(serialized);
    setState(() {
      _lastSavedLayout = serialized;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isKo ? '훈련보드를 저장했습니다.' : 'Training board saved.',
        ),
      ),
    );
  }

  void _copyPresetStep({
    required TrainingBoardPreset preset,
    required TrainingMethodPage page,
    required bool isKo,
  }) {
    final copiedPage = _BoardPageState(
      name: page.name.trim().isEmpty ? 'Step ${_pages.length + 1}' : page.name,
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
      strokes: page.strokes
          .map(
            (stroke) => _BoardStroke(
              points: stroke.points
                  .map((point) => Offset(point.x, point.y))
                  .toList(growable: false),
              color: Color(stroke.colorValue),
              width: stroke.width,
            ),
          )
          .toList(growable: true),
    );

    setState(() {
      _pages.add(copiedPage);
      _pageIndex = _pages.length - 1;
      _selectedItemId = null;
      _penMode = false;
      _methodController.text = _currentPage.methodText;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isKo
              ? '${preset.title} 스텝을 복사했습니다.'
              : 'Step copied from ${preset.title}.',
        ),
      ),
    );
  }

  Future<void> _showPresetPicker(bool isKo) async {
    final selected = await showModalBottomSheet<_PresetStepSelection>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: widget.presets.length,
                  itemBuilder: (context, index) {
                    final preset = widget.presets[index];
                    final layout =
                        TrainingMethodLayout.decode(preset.layoutJson);
                    if (layout.pages.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return ExpansionTile(
                      leading: const Icon(Icons.copy_all_outlined),
                      title: Text(preset.title),
                      subtitle: preset.subtitle.trim().isEmpty
                          ? null
                          : Text(
                              preset.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                      children: layout.pages.asMap().entries.map((entry) {
                        final pageIndex = entry.key;
                        final page = entry.value;
                        final stepName = page.name.trim().isEmpty
                            ? 'Step ${pageIndex + 1}'
                            : page.name.trim();
                        final memo = page.methodText.trim();
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.content_paste_outlined),
                          title: Text(stepName),
                          subtitle: memo.isEmpty
                              ? null
                              : Text(
                                  memo,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).pop(
                              _PresetStepSelection(preset: preset, page: page),
                            );
                          },
                        );
                      }).toList(growable: false),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(isKo ? '취소' : 'Cancel'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || selected == null) return;
    _copyPresetStep(preset: selected.preset, page: selected.page, isKo: isKo);
  }

  Future<bool> _handleWillPop(bool isKo) async {
    if (!_hasUnsavedChanges) {
      return true;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isKo ? '저장되지 않은 변경사항' : 'Unsaved changes'),
        content: Text(
          isKo
              ? '저장하지 않은 편집 내용이 있습니다. 페이지를 나가시겠어요?'
              : 'You have unsaved edits. Leave this page?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isKo ? '계속 편집' : 'Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(isKo ? '나가기' : 'Leave'),
          ),
        ],
      ),
    );
    return discard == true;
  }

  void _startStroke(Offset localPosition, double width, double height) {
    final x = (localPosition.dx / width).clamp(0.0, 1.0);
    final y = (localPosition.dy / height).clamp(0.0, 1.0);
    setState(() {
      _activeStroke = <Offset>[Offset(x, y)];
      _selectedItemId = null;
    });
  }

  void _appendStrokePoint(Offset localPosition, double width, double height) {
    final points = _activeStroke;
    if (points == null) return;
    final x = (localPosition.dx / width).clamp(0.0, 1.0);
    final y = (localPosition.dy / height).clamp(0.0, 1.0);
    setState(() {
      points.add(Offset(x, y));
    });
  }

  void _endStroke() {
    final points = _activeStroke;
    if (points == null || points.length < 2) {
      setState(() {
        _activeStroke = null;
      });
      return;
    }
    setState(() {
      _currentPage.strokes.add(
        _BoardStroke(
          points: List<Offset>.from(points),
          color: _penColor,
          width: 3.0,
        ),
      );
      _activeStroke = null;
    });
  }

  @override
  void dispose() {
    _methodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _handleWillPop(isKo);
        if (!shouldPop || !mounted) return;
        Navigator.of(this.context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isKo ? '훈련보드' : 'Training Board'),
          actions: [
            if (widget.presets.isNotEmpty)
              IconButton(
                tooltip: isKo ? '훈련보드 복사' : 'Copy board step',
                icon: const Icon(Icons.copy_all_outlined),
                onPressed: () => _showPresetPicker(isKo),
              ),
            TextButton.icon(
              onPressed: () => _saveBoard(isKo),
              icon: const Icon(Icons.save_outlined),
              label: Text(isKo ? '저장' : 'Save'),
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
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanStart: _penMode
                              ? (details) => _startStroke(
                                    details.localPosition,
                                    width,
                                    height,
                                  )
                              : null,
                          onPanUpdate: _penMode
                              ? (details) => _appendStrokePoint(
                                    details.localPosition,
                                    width,
                                    height,
                                  )
                              : null,
                          onPanEnd: _penMode ? (_) => _endStroke() : null,
                          child: Stack(
                            children: [
                              CustomPaint(
                                size: Size(width, height),
                                painter: const _PitchPainter(),
                              ),
                              CustomPaint(
                                size: Size(width, height),
                                painter: _InkPainter(
                                  strokes: _currentPage.strokes,
                                  activeStrokePoints: _activeStroke,
                                  activeStrokeColor: _penColor,
                                ),
                              ),
                              IgnorePointer(
                                ignoring: _penMode,
                                child: Stack(
                                  children: [
                                    for (final item in _currentPage.items)
                                      Positioned(
                                        left: (item.x * width) - 26,
                                        top: (item.y * height) - 26,
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () => setState(
                                            () => _selectedItemId = item.id,
                                          ),
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
                                            final dy =
                                                details.delta.dy / height;
                                            final nextX =
                                                (item.x + dx).clamp(0.03, 0.97);
                                            final nextY =
                                                (item.y + dy).clamp(0.03, 0.97);
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
                                                selected:
                                                    item.id == _selectedItemId,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
                _activeStroke = null;
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
          onPressed: () => _renameCurrentPage(isKo),
          icon: const Icon(Icons.drive_file_rename_outline),
          tooltip: isKo ? '스텝명 변경' : 'Rename step',
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
          onPressed: () => setState(() => _penMode = !_penMode),
          icon: Icon(_penMode ? Icons.draw : Icons.edit_note_outlined),
          label: Text(isKo ? '펜' : 'Pen'),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            minimumSize: const Size(1, 40),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            foregroundColor: _penMode ? const Color(0xFFFFEB3B) : null,
          ),
        ),
        OutlinedButton.icon(
          onPressed: _currentPage.strokes.isEmpty
              ? null
              : () => setState(() {
                    _currentPage.strokes.clear();
                    _activeStroke = null;
                  }),
          icon: const Icon(Icons.layers_clear_outlined),
          label: Text(isKo ? '펜 지우기' : 'Clear ink'),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            minimumSize: const Size(1, 40),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => setState(() {
            _currentPage.items.clear();
            _currentPage.strokes.clear();
            _activeStroke = null;
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
    if (_penMode) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isKo
                  ? '펜 모드: 보드 영역을 드래그해 그릴 수 있습니다.'
                  : 'Pen mode: drag on the board to draw.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              isKo ? '펜 색상' : 'Pen color',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _penColors.map((c) {
                final selectedColor = c.toARGB32() == _penColor.toARGB32();
                return InkWell(
                  onTap: () => setState(() => _penColor = c),
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
                    child: selectedColor
                        ? Icon(
                            Icons.check,
                            size: 14,
                            color: c.computeLuminance() < 0.45
                                ? Colors.white
                                : Colors.black87,
                          )
                        : null,
                  ),
                );
              }).toList(growable: false),
            ),
          ],
        ),
      );
    }
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
            children: _presetColors.map((c) {
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
}

class _BoardPageState {
  String name;
  String methodText;
  final List<_BoardItem> items;
  final List<_BoardStroke> strokes;

  _BoardPageState({
    required this.name,
    required this.methodText,
    required this.items,
    required this.strokes,
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

class _BoardStroke {
  final List<Offset> points;
  final Color color;
  final double width;

  const _BoardStroke({
    required this.points,
    required this.color,
    required this.width,
  });
}

class _PresetStepSelection {
  final TrainingBoardPreset preset;
  final TrainingMethodPage page;

  const _PresetStepSelection({required this.preset, required this.page});
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

const List<Color> _penColors = <Color>[
  Color(0xFF000000),
  Color(0xFFFFFFFF),
  Color(0xFFFFEB3B),
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
        child: Icon(icon, size: 18, color: item.color),
      ),
    );
  }
}

class _InkPainter extends CustomPainter {
  final List<_BoardStroke> strokes;
  final List<Offset>? activeStrokePoints;
  final Color activeStrokeColor;

  const _InkPainter({
    required this.strokes,
    required this.activeStrokePoints,
    required this.activeStrokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _drawStroke(canvas, size, stroke.points, stroke.color, stroke.width);
    }
    final active = activeStrokePoints;
    if (active != null && active.length > 1) {
      _drawStroke(canvas, size, active, activeStrokeColor, 3.0);
    }
  }

  void _drawStroke(
    Canvas canvas,
    Size size,
    List<Offset> points,
    Color color,
    double width,
  ) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(points.first.dx * size.width, points.first.dy * size.height);
    for (var i = 1; i < points.length; i++) {
      final p = points[i];
      path.lineTo(p.dx * size.width, p.dy * size.height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _InkPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.activeStrokePoints != activeStrokePoints ||
        oldDelegate.activeStrokeColor != activeStrokeColor;
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
  final String title;
  final String subtitle;
  final String layoutJson;

  const TrainingBoardPreset({
    required this.title,
    required this.subtitle,
    required this.layoutJson,
  });
}
