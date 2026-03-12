import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../application/training_service.dart';
import '../../application/training_board_service.dart';
import '../../domain/entities/training_board.dart';
import '../../domain/repositories/option_repository.dart';
import '../models/training_method_layout.dart';
import '../models/training_board_link_codec.dart';
import 'training_method_board_screen.dart';

class TrainingBoardListScreen extends StatefulWidget {
  final OptionRepository optionRepository;
  final TrainingService trainingService;
  final bool selectionMode;
  final List<String> initialSelectedIds;

  const TrainingBoardListScreen({
    super.key,
    required this.optionRepository,
    required this.trainingService,
    this.selectionMode = false,
    this.initialSelectedIds = const <String>[],
  });

  @override
  State<TrainingBoardListScreen> createState() =>
      _TrainingBoardListScreenState();
}

class _TrainingBoardListScreenState extends State<TrainingBoardListScreen> {
  late final TrainingBoardService _boardService;
  List<TrainingBoard> _boards = const <TrainingBoard>[];
  Map<String, DateTime> _linkedTrainingDateByBoardId =
      const <String, DateTime>{};
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _boardService = TrainingBoardService(widget.optionRepository);
    _selectedIds = widget.initialSelectedIds.toSet();
    unawaited(_reload());
  }

  Future<void> _reload() async {
    final boards = _boardService.allBoards();
    final entries = await widget.trainingService.allEntries();
    final linkedTrainingDateByBoardId = <String, DateTime>{};
    for (final entry in entries) {
      final boardIds = TrainingBoardLinkCodec.decodeBoardIds(entry.drills);
      for (final boardId in boardIds) {
        final existing = linkedTrainingDateByBoardId[boardId];
        if (existing == null || entry.date.isAfter(existing)) {
          linkedTrainingDateByBoardId[boardId] = entry.date;
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _boards = boards;
      _linkedTrainingDateByBoardId = linkedTrainingDateByBoardId;
      _selectedIds = _selectedIds
          .where((id) => _boards.any((board) => board.id == id))
          .toSet();
    });
  }

  Future<String?> _promptTitle({String initialValue = ''}) async {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final controller = TextEditingController(text: initialValue);
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isKo ? '훈련스케치 제목' : 'Training sketch title'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: isKo ? '예) 패스 워밍업' : 'e.g. Pass warm-up',
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
            child: Text(isKo ? '확인' : 'OK'),
          ),
        ],
      ),
    );
    controller.dispose();
    final trimmed = (title ?? '').trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  Future<void> _editBoard(TrainingBoard board) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TrainingMethodBoardScreen(
          boardTitle: board.title,
          initialLayoutJson: board.layoutJson,
          onSaved: (savedLayout) async {
            final resolvedTitle = _resolveBoardTitle(
              layoutJson: savedLayout,
              fallbackTitle: board.title,
            );
            await _boardService.saveBoard(
              board.copyWith(title: resolvedTitle, layoutJson: savedLayout),
            );
          },
        ),
      ),
    );
    if (!mounted) return;
    await _reload();
  }

  Future<void> _renameBoard(TrainingBoard board) async {
    final title = await _promptTitle(initialValue: board.title);
    if (!mounted || title == null || title == board.title) return;
    await _boardService.saveBoard(board.copyWith(title: title));
    if (!mounted) return;
    await _reload();
  }

  Future<void> _deleteBoard(TrainingBoard board) async {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isKo ? '훈련스케치 삭제' : 'Delete training sketch'),
        content: Text(
          isKo ? '"${board.title}"를 정말 삭제할까요?' : 'Delete "${board.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isKo ? '취소' : 'Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(isKo ? '삭제' : 'Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;
    await _boardService.deleteBoard(board.id);
    _selectedIds.remove(board.id);
    if (!mounted) return;
    await _reload();
  }

  String _resolveBoardTitle({
    required String layoutJson,
    required String fallbackTitle,
  }) {
    final pages = TrainingMethodLayout.decode(layoutJson).pages;
    final firstName = pages.isEmpty ? null : pages.first.name.trim();
    if (firstName != null && firstName.isNotEmpty) {
      return firstName;
    }
    final fallback = fallbackTitle.trim();
    if (fallback.isNotEmpty) return fallback;
    return 'Training Board';
  }

  void _submitSelection() {
    final selected = _boards
        .where((board) => _selectedIds.contains(board.id))
        .map((board) => board.id)
        .toList(growable: false);
    Navigator.of(context).pop(selected);
  }

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    return Scaffold(
      appBar: AppBar(
        title: Text(isKo ? '훈련스케치 리스트' : 'Training sketch list'),
        actions: [
          if (widget.selectionMode)
            TextButton(
              onPressed: _submitSelection,
              child: Text(isKo ? '완료' : 'Done'),
            ),
        ],
      ),
      body: _boards.isEmpty
          ? Center(
              child: Text(
                isKo
                    ? '훈련노트 화면에서 먼저 훈련스케치를 생성해주세요.'
                    : 'Create a training sketch from a training note first.',
              ),
            )
          : ListView.separated(
              itemCount: _boards.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final board = _boards[index];
                final layout = TrainingMethodLayout.decode(board.layoutJson);
                final itemCount = layout.pages.fold<int>(
                  0,
                  (sum, page) => sum + page.items.length,
                );
                final linkedTrainingDate =
                    _linkedTrainingDateByBoardId[board.id];
                final dateText = DateFormat(
                  'yyyy.MM.dd',
                ).format(linkedTrainingDate ?? board.updatedAt);
                final selected = _selectedIds.contains(board.id);
                return ListTile(
                  leading: widget.selectionMode
                      ? Checkbox(
                          value: selected,
                          onChanged: (checked) {
                            setState(() {
                              if (checked ?? false) {
                                _selectedIds.add(board.id);
                              } else {
                                _selectedIds.remove(board.id);
                              }
                            });
                          },
                        )
                      : null,
                  title: Text(board.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isKo
                            ? '요소 $itemCount개 · 훈련일 $dateText'
                            : '$itemCount items · Training date $dateText',
                      ),
                      const SizedBox(height: 8),
                      _BoardPreview(layout: layout),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'rename':
                          unawaited(_renameBoard(board));
                          break;
                        case 'delete':
                          unawaited(_deleteBoard(board));
                          break;
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem<String>(
                        value: 'rename',
                        child: Text(isKo ? '이름 변경' : 'Rename'),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Text(
                          isKo ? '삭제' : 'Delete',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    if (widget.selectionMode) {
                      setState(() {
                        if (selected) {
                          _selectedIds.remove(board.id);
                        } else {
                          _selectedIds.add(board.id);
                        }
                      });
                      return;
                    }
                    unawaited(_editBoard(board));
                  },
                  onLongPress: () => unawaited(_editBoard(board)),
                );
              },
            ),
    );
  }
}

class _BoardPreview extends StatelessWidget {
  final TrainingMethodLayout layout;

  const _BoardPreview({required this.layout});

  @override
  Widget build(BuildContext context) {
    final previewPage = layout.pages.isNotEmpty
        ? layout.pages.first
        : TrainingMethodLayout.empty().pages.first;
    final itemCount = layout.pages.fold<int>(
      0,
      (sum, page) => sum + page.items.length,
    );
    return Container(
      height: 84,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          return Stack(
            children: [
              CustomPaint(
                size: Size(width, height),
                painter: _BoardPreviewPainter(page: previewPage),
              ),
              ...previewPage.items.take(12).map((item) {
                final icon = switch (item.type) {
                  'cone' => Icons.change_history,
                  'player' => Icons.person,
                  'ball' => Icons.sports_soccer,
                  'ladder' => Icons.view_week,
                  _ => Icons.circle,
                };
                return Positioned(
                  left: (item.x * width).clamp(6.0, width - 18.0),
                  top: (item.y * height).clamp(4.0, height - 18.0),
                  child: Transform.rotate(
                    angle: item.rotationDeg * 3.1415926535897932 / 180,
                    child: Icon(
                      icon,
                      size: (item.size * 0.38).clamp(10.0, 18.0),
                      color: Color(item.colorValue).withValues(alpha: 0.96),
                    ),
                  ),
                );
              }),
              Positioned(
                right: 8,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$itemCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BoardPreviewPainter extends CustomPainter {
  final TrainingMethodPage page;

  const _BoardPreviewPainter({required this.page});

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final pathPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 2, size.width - 4, size.height - 4),
        const Radius.circular(10),
      ),
      line,
    );
    canvas.drawLine(Offset(centerX, 2), Offset(centerX, size.height - 2), line);
    canvas.drawCircle(Offset(centerX, centerY), 10, line);

    for (final stroke in page.strokes) {
      if (stroke.points.length < 2) continue;
      final strokePaint = Paint()
        ..color = Color(stroke.colorValue).withValues(alpha: 0.92)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke.width.clamp(1.0, 4.0)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final path = Path()
        ..moveTo(
          stroke.points.first.x * size.width,
          stroke.points.first.y * size.height,
        );
      for (final point in stroke.points.skip(1)) {
        path.lineTo(point.x * size.width, point.y * size.height);
      }
      canvas.drawPath(path, strokePaint);
    }

    if (page.playerPath.length >= 2) {
      final path = Path()
        ..moveTo(
          page.playerPath.first.x * size.width,
          page.playerPath.first.y * size.height,
        );
      for (final point in page.playerPath.skip(1)) {
        path.lineTo(point.x * size.width, point.y * size.height);
      }
      canvas.drawPath(path, pathPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPreviewPainter oldDelegate) {
    return oldDelegate.page != page;
  }
}
