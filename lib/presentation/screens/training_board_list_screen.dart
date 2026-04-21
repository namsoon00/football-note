import 'dart:async';

import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../application/family_access_service.dart';
import '../../application/player_level_service.dart';
import '../../application/settings_service.dart';
import '../../application/training_service.dart';
import '../../application/training_board_service.dart';
import '../../application/training_plan_reminder_service.dart';
import '../../domain/entities/training_board.dart';
import '../../domain/repositories/option_repository.dart';
import '../models/training_method_layout.dart';
import '../models/training_board_link_codec.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_page_route.dart';
import '../theme/app_motion.dart';
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
  static const String _recentBoardIdKey = 'recent_board_id';
  late final TrainingBoardService _boardService;
  final TextEditingController _searchController = TextEditingController();
  List<TrainingBoard> _boards = const <TrainingBoard>[];
  Map<String, DateTime> _linkedTrainingDateByBoardId =
      const <String, DateTime>{};
  late Set<String> _selectedIds;
  String _searchQuery = '';
  _BoardListSort _sort = _BoardListSort.updatedDesc;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _boardService = TrainingBoardService(widget.optionRepository);
    _selectedIds = widget.initialSelectedIds.toSet();
    unawaited(_reload());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
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
        title: Text(isKo ? '훈련 스케치 제목' : 'Training sketch title'),
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
    if (_isParentMode) {
      _showParentReadOnlyMessage();
      return;
    }
    await Navigator.of(context).push<void>(
      AppPageRoute(
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
    if (_isParentMode) {
      _showParentReadOnlyMessage();
      return;
    }
    final title = await _promptTitle(initialValue: board.title);
    if (!mounted || title == null || title == board.title) return;
    await _boardService.saveBoard(board.copyWith(title: title));
    if (!mounted) return;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    AppFeedback.showUndo(
      context,
      text: isKo ? '보드 이름을 변경했어요.' : 'Board renamed.',
      undoLabel: isKo ? '되돌리기' : 'Undo',
      onUndo: () {
        unawaited(_boardService.saveBoard(board));
        AppFeedback.showSuccess(
          context,
          text: isKo ? '이름 변경을 되돌렸어요.' : 'Rename undone.',
        );
        unawaited(_reload());
      },
    );
    if (!mounted) return;
    await _reload();
  }

  Future<void> _createBoard() async {
    if (_isParentMode) {
      _showParentReadOnlyMessage();
      return;
    }
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final template = await _pickTemplate(isKo);
    if (!mounted || template == null) return;
    final title = await _promptTitle();
    if (!mounted || title == null) return;
    final layout = template.buildLayout(title);
    final created = await _boardService.createBoard(
      title: title,
      layoutJson: layout.encode(),
    );
    if (!mounted) return;
    await widget.optionRepository.setValue(_recentBoardIdKey, created.id);
    if (!mounted) return;
    final award = await PlayerLevelService(widget.optionRepository)
        .awardForBoardSaved(
          boardId: created.id,
          boardTitle: created.title,
          savedAt: created.updatedAt,
          created: true,
        );
    await TrainingPlanReminderService(
      widget.optionRepository,
      SettingsService(widget.optionRepository)..load(),
    ).showXpGainAlert(
      gainedXp: award.gainedXp,
      totalXp: award.after.totalXp,
      isKo: isKo,
      sourceLabel: isKo ? '훈련 스케치' : 'Training sketch',
    );
    if (!mounted) return;
    AppFeedback.showSuccess(
      context,
      text: isKo
          ? '훈련 스케치를 만들었어요.${award.gainedXp > 0 ? ' +${award.gainedXp} XP' : ''}'
          : 'Training sketch created.${award.gainedXp > 0 ? ' +${award.gainedXp} XP' : ''}',
    );
    await _reload();
  }

  Future<_BoardTemplate?> _pickTemplate(bool isKo) {
    final templates = _defaultTemplates(isKo);
    return showModalBottomSheet<_BoardTemplate>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                isKo ? '템플릿 선택' : 'Choose template',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...templates.map(
              (template) => ListTile(
                leading: Icon(template.icon),
                title: Text(isKo ? template.labelKo : template.labelEn),
                subtitle: Text(
                  isKo ? template.descriptionKo : template.descriptionEn,
                ),
                onTap: () => Navigator.of(context).pop(template),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_BoardTemplate> _defaultTemplates(bool isKo) {
    TrainingMethodLayout blank(String title) => TrainingMethodLayout(
      pages: <TrainingMethodPage>[
        TrainingMethodPage(name: title, items: const <TrainingMethodItem>[]),
      ],
    );
    TrainingMethodLayout passWarmup(String title) => TrainingMethodLayout(
      pages: <TrainingMethodPage>[
        TrainingMethodPage(
          name: title,
          methodText: isKo ? '2터치 패스 + 움직임 교대' : 'Two-touch pass + rotate',
          items: <TrainingMethodItem>[
            const TrainingMethodItem(
              type: 'player',
              x: 0.2,
              y: 0.5,
              size: 32,
              rotationDeg: 0,
              colorValue: 0xFF1E88E5,
            ),
            const TrainingMethodItem(
              type: 'player',
              x: 0.5,
              y: 0.25,
              size: 32,
              rotationDeg: 0,
              colorValue: 0xFF1E88E5,
            ),
            const TrainingMethodItem(
              type: 'player',
              x: 0.8,
              y: 0.5,
              size: 32,
              rotationDeg: 0,
              colorValue: 0xFF1E88E5,
            ),
            const TrainingMethodItem(
              type: 'cone',
              x: 0.5,
              y: 0.75,
              size: 30,
              rotationDeg: 0,
              colorValue: 0xFFFFA000,
            ),
            const TrainingMethodItem(
              type: 'ball',
              x: 0.2,
              y: 0.5,
              size: 30,
              rotationDeg: 0,
              colorValue: 0xFFFFFFFF,
            ),
          ],
        ),
      ],
    );
    TrainingMethodLayout buildUp(String title) => TrainingMethodLayout(
      pages: <TrainingMethodPage>[
        TrainingMethodPage(
          name: title,
          methodText: isKo ? '후방 빌드업 3-2 전개' : 'Back build-up 3-2 shape',
          items: <TrainingMethodItem>[
            const TrainingMethodItem(
              type: 'player',
              x: 0.2,
              y: 0.8,
              size: 32,
              rotationDeg: 0,
              colorValue: 0xFF1E88E5,
            ),
            const TrainingMethodItem(
              type: 'player',
              x: 0.5,
              y: 0.82,
              size: 32,
              rotationDeg: 0,
              colorValue: 0xFF1E88E5,
            ),
            const TrainingMethodItem(
              type: 'player',
              x: 0.8,
              y: 0.8,
              size: 32,
              rotationDeg: 0,
              colorValue: 0xFF1E88E5,
            ),
            const TrainingMethodItem(
              type: 'player',
              x: 0.38,
              y: 0.58,
              size: 32,
              rotationDeg: 0,
              colorValue: 0xFF1E88E5,
            ),
            const TrainingMethodItem(
              type: 'player',
              x: 0.62,
              y: 0.58,
              size: 32,
              rotationDeg: 0,
              colorValue: 0xFF1E88E5,
            ),
            const TrainingMethodItem(
              type: 'ball',
              x: 0.5,
              y: 0.82,
              size: 30,
              rotationDeg: 0,
              colorValue: 0xFFFFFFFF,
            ),
          ],
        ),
      ],
    );
    TrainingMethodLayout pressing(String title) => TrainingMethodLayout(
      pages: <TrainingMethodPage>[
        TrainingMethodPage(
          name: title,
          methodText: isKo ? '전방 압박 트리거 확인' : 'Front pressing trigger',
          items: <TrainingMethodItem>[
            const TrainingMethodItem(
              type: 'player',
              x: 0.3,
              y: 0.35,
              size: 32,
              rotationDeg: 0,
              colorValue: 0xFFE53935,
            ),
            const TrainingMethodItem(
              type: 'player',
              x: 0.5,
              y: 0.42,
              size: 32,
              rotationDeg: 0,
              colorValue: 0xFFE53935,
            ),
            const TrainingMethodItem(
              type: 'player',
              x: 0.7,
              y: 0.35,
              size: 32,
              rotationDeg: 0,
              colorValue: 0xFFE53935,
            ),
            const TrainingMethodItem(
              type: 'ball',
              x: 0.5,
              y: 0.18,
              size: 30,
              rotationDeg: 0,
              colorValue: 0xFFFFFFFF,
            ),
          ],
        ),
      ],
    );
    TrainingMethodLayout setPiece(String title) => TrainingMethodLayout(
      pages: <TrainingMethodPage>[
        TrainingMethodPage(
          name: title,
          methodText: isKo ? '코너킥 공격 패턴' : 'Corner kick attacking setup',
          items: <TrainingMethodItem>[
            const TrainingMethodItem(
              type: 'ball',
              x: 0.06,
              y: 0.08,
              size: 30,
              rotationDeg: 0,
              colorValue: 0xFFFFFFFF,
            ),
            const TrainingMethodItem(
              type: 'player',
              x: 0.2,
              y: 0.2,
              size: 32,
              rotationDeg: 0,
              colorValue: 0xFF1E88E5,
            ),
            const TrainingMethodItem(
              type: 'player',
              x: 0.3,
              y: 0.28,
              size: 32,
              rotationDeg: 0,
              colorValue: 0xFF1E88E5,
            ),
            const TrainingMethodItem(
              type: 'player',
              x: 0.38,
              y: 0.36,
              size: 32,
              rotationDeg: 0,
              colorValue: 0xFF1E88E5,
            ),
            const TrainingMethodItem(
              type: 'player',
              x: 0.45,
              y: 0.24,
              size: 32,
              rotationDeg: 0,
              colorValue: 0xFFE53935,
            ),
          ],
        ),
      ],
    );

    return <_BoardTemplate>[
      _BoardTemplate(
        id: 'blank',
        icon: Icons.dashboard_outlined,
        labelKo: '빈 스케치',
        labelEn: 'Blank sketch',
        descriptionKo: '아무 요소 없이 바로 시작',
        descriptionEn: 'Start from an empty board',
        buildLayout: blank,
      ),
      _BoardTemplate(
        id: 'pass_warmup',
        icon: Icons.sports_soccer_outlined,
        labelKo: '패스 워밍업',
        labelEn: 'Pass warm-up',
        descriptionKo: '기본 3인 패스 구조',
        descriptionEn: 'Basic 3-player passing setup',
        buildLayout: passWarmup,
      ),
      _BoardTemplate(
        id: 'build_up',
        icon: Icons.account_tree_outlined,
        labelKo: '빌드업 패턴',
        labelEn: 'Build-up pattern',
        descriptionKo: '후방 전개 기본 구조',
        descriptionEn: 'Back build-up structure',
        buildLayout: buildUp,
      ),
      _BoardTemplate(
        id: 'pressing',
        icon: Icons.bolt_outlined,
        labelKo: '압박 전환',
        labelEn: 'Pressing transition',
        descriptionKo: '전방 압박 시작 위치',
        descriptionEn: 'Pressing trigger shape',
        buildLayout: pressing,
      ),
      _BoardTemplate(
        id: 'set_piece',
        icon: Icons.flag_outlined,
        labelKo: '세트피스',
        labelEn: 'Set piece',
        descriptionKo: '코너킥 기본 배치',
        descriptionEn: 'Corner-kick layout',
        buildLayout: setPiece,
      ),
    ];
  }

  Future<void> _copyFromPreviousBoard() async {
    if (_isParentMode) {
      _showParentReadOnlyMessage();
      return;
    }
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    if (_boards.isEmpty) {
      AppFeedback.showSuccess(
        context,
        text: isKo ? '복사할 훈련 스케치가 없어요.' : 'No training sketch to copy.',
      );
      return;
    }
    final source = await showModalBottomSheet<TrainingBoard>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _boards.length,
          itemBuilder: (context, index) {
            final board = _boards[index];
            return ListTile(
              leading: const Icon(Icons.copy_all_outlined),
              title: Text(
                board.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                DateFormat('yyyy.MM.dd HH:mm').format(board.updatedAt),
              ),
              onTap: () => Navigator.of(context).pop(board),
            );
          },
        ),
      ),
    );
    if (!mounted || source == null) return;
    final defaultCopyTitle = isKo
        ? '${source.title} 복사본'
        : '${source.title} Copy';
    final copiedTitle = await _promptTitle(initialValue: defaultCopyTitle);
    if (!mounted || copiedTitle == null) return;
    final created = await _boardService.createBoard(
      title: copiedTitle,
      layoutJson: source.layoutJson,
    );
    if (!mounted) return;
    await widget.optionRepository.setValue(_recentBoardIdKey, created.id);
    if (!mounted) return;
    final award = await PlayerLevelService(widget.optionRepository)
        .awardForBoardSaved(
          boardId: created.id,
          boardTitle: created.title,
          savedAt: created.updatedAt,
          created: true,
        );
    await TrainingPlanReminderService(
      widget.optionRepository,
      SettingsService(widget.optionRepository)..load(),
    ).showXpGainAlert(
      gainedXp: award.gainedXp,
      totalXp: award.after.totalXp,
      isKo: isKo,
      sourceLabel: isKo ? '훈련 스케치' : 'Training sketch',
    );
    if (!mounted) return;
    AppFeedback.showSuccess(
      context,
      text: isKo
          ? '이전 스케치를 복사했어요.${award.gainedXp > 0 ? ' +${award.gainedXp} XP' : ''}'
          : 'Previous sketch copied.${award.gainedXp > 0 ? ' +${award.gainedXp} XP' : ''}',
    );
    await _reload();
  }

  Future<void> _deleteBoard(TrainingBoard board) async {
    if (_isParentMode) {
      _showParentReadOnlyMessage();
      return;
    }
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isKo ? '훈련 스케치 삭제' : 'Delete training sketch'),
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
    if (widget.optionRepository.getValue<String>(_recentBoardIdKey) ==
        board.id) {
      await widget.optionRepository.setValue(_recentBoardIdKey, '');
    }
    if (!mounted) return;
    AppFeedback.showUndo(
      context,
      text: isKo ? '보드를 삭제했어요.' : 'Board deleted.',
      undoLabel: isKo ? '되돌리기' : 'Undo',
      onUndo: () {
        unawaited(_boardService.saveBoard(board));
        AppFeedback.showSuccess(
          context,
          text: isKo ? '삭제를 되돌렸어요.' : 'Delete undone.',
        );
        unawaited(_reload());
      },
    );
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

  List<TrainingBoard> _visibleBoards() {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = _boards
        .where((board) {
          if (query.isEmpty) return true;
          return board.title.toLowerCase().contains(query);
        })
        .toList(growable: false);
    final sorted = [...filtered];
    switch (_sort) {
      case _BoardListSort.updatedDesc:
        sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case _BoardListSort.titleAsc:
        sorted.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case _BoardListSort.trainingDateDesc:
        DateTime mappedDate(TrainingBoard board) =>
            _linkedTrainingDateByBoardId[board.id] ?? board.updatedAt;
        sorted.sort((a, b) => mappedDate(b).compareTo(mappedDate(a)));
        break;
    }
    return sorted;
  }

  void _submitSelection() {
    final selected = _boards
        .where((board) => _selectedIds.contains(board.id))
        .map((board) => board.id)
        .toList(growable: false);
    if (selected.isNotEmpty) {
      unawaited(
        widget.optionRepository.setValue(_recentBoardIdKey, selected.first),
      );
    }
    Navigator.of(context).pop(selected);
  }

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final listTitle = isKo ? '훈련 스케치 리스트' : 'Training sketch list';
    final visibleBoards = _visibleBoards();
    final isFiltered = _searchQuery.trim().isNotEmpty;
    final isParentMode = _isParentMode;
    return Scaffold(
      appBar: AppBar(
        title: Text(listTitle),
        actions: [
          IconButton(
            tooltip: _showSearch
                ? (isKo ? '검색 닫기' : 'Close search')
                : (isKo ? '보드 검색' : 'Search boards'),
            onPressed: _toggleSearch,
            icon: Icon(_showSearch ? Icons.close : Icons.search),
          ),
          if (!widget.selectionMode)
            PopupMenuButton<_BoardListSort>(
              tooltip: isKo ? '정렬' : 'Sort',
              icon: const Icon(Icons.sort),
              initialValue: _sort,
              onSelected: (next) => setState(() => _sort = next),
              itemBuilder: (_) => [
                PopupMenuItem<_BoardListSort>(
                  value: _BoardListSort.updatedDesc,
                  child: Text(isKo ? '최근 수정순' : 'Recently updated'),
                ),
                PopupMenuItem<_BoardListSort>(
                  value: _BoardListSort.trainingDateDesc,
                  child: Text(isKo ? '훈련일 최신순' : 'Training date'),
                ),
                PopupMenuItem<_BoardListSort>(
                  value: _BoardListSort.titleAsc,
                  child: Text(isKo ? '이름순' : 'Name A-Z'),
                ),
              ],
            ),
          if (!widget.selectionMode)
            PopupMenuButton<String>(
              tooltip: isKo ? '훈련 스케치 추가' : 'Add training sketch',
              enabled: !isParentMode,
              icon: const Icon(Icons.add),
              onSelected: (value) {
                switch (value) {
                  case 'new':
                    unawaited(_createBoard());
                    break;
                  case 'copy':
                    unawaited(_copyFromPreviousBoard());
                    break;
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem<String>(
                  value: 'new',
                  child: Text(isKo ? '새 스케치 만들기' : 'Create new sketch'),
                ),
                PopupMenuItem<String>(
                  value: 'copy',
                  child: Text(isKo ? '이전 스케치 복사' : 'Copy previous sketch'),
                ),
              ],
            ),
          if (widget.selectionMode)
            TextButton(
              onPressed: _submitSelection,
              child: Text(isKo ? '완료' : 'Done'),
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: AppMotion.base(context),
        switchInCurve: AppMotion.curveEnter,
        switchOutCurve: AppMotion.curveExit,
        child: _boards.isEmpty
            ? Center(
                key: const ValueKey('board-list-empty'),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isKo ? '훈련보드가 아직 없습니다.' : 'No boards yet.',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isKo
                              ? '훈련노트에서 보드 버튼을 눌러 바로 생성해보세요.'
                              : 'Create one directly from a training note.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back),
                          label: Text(isKo ? '훈련노트로 돌아가기' : 'Back to notes'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : Column(
                key: const ValueKey('board-list-items'),
                children: [
                  if (_showSearch)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: isKo ? '보드명 검색' : 'Search board',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: isKo ? '지우기' : 'Clear',
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) =>
                            setState(() => _searchQuery = value.trim()),
                      ),
                    ),
                  Expanded(
                    child: visibleBoards.isEmpty && isFiltered
                        ? Center(
                            child: Text(
                              isKo ? '검색 결과가 없습니다.' : 'No search results.',
                            ),
                          )
                        : ListView.separated(
                            itemCount: visibleBoards.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final board = visibleBoards[index];
                              final layout = TrainingMethodLayout.decode(
                                board.layoutJson,
                              );
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
                                  enabled: !isParentMode,
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'rename':
                                        unawaited(_renameBoard(board));
                                        break;
                                      case 'duplicate':
                                        unawaited(
                                          _duplicateBoardDirectly(board),
                                        );
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
                                      value: 'duplicate',
                                      child: Text(isKo ? '복제' : 'Duplicate'),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Text(
                                        isKo ? '삭제' : 'Delete',
                                        style: const TextStyle(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: widget.selectionMode
                                    ? () {
                                        setState(() {
                                          if (selected) {
                                            _selectedIds.remove(board.id);
                                          } else {
                                            _selectedIds.add(board.id);
                                          }
                                        });
                                        unawaited(
                                          widget.optionRepository.setValue(
                                            _recentBoardIdKey,
                                            board.id,
                                          ),
                                        );
                                      }
                                    : isParentMode
                                    ? null
                                    : () {
                                        unawaited(
                                          widget.optionRepository.setValue(
                                            _recentBoardIdKey,
                                            board.id,
                                          ),
                                        );
                                        unawaited(_editBoard(board));
                                      },
                                onLongPress: isParentMode
                                    ? null
                                    : () {
                                        unawaited(_editBoard(board));
                                      },
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  bool get _isParentMode {
    return FamilyAccessService(
      widget.optionRepository,
    ).loadState().isParentMode;
  }

  void _showParentReadOnlyMessage() {
    AppFeedback.showMessage(
      context,
      text: AppLocalizations.of(context)!.parentReadOnlySketchMessage,
    );
  }

  Future<void> _duplicateBoardDirectly(TrainingBoard source) async {
    if (_isParentMode) {
      _showParentReadOnlyMessage();
      return;
    }
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final copiedTitle = await _promptTitle(
      initialValue: isKo ? '${source.title} 복사본' : '${source.title} Copy',
    );
    if (!mounted || copiedTitle == null) return;
    final created = await _boardService.createBoard(
      title: copiedTitle,
      layoutJson: source.layoutJson,
    );
    if (!mounted) return;
    await widget.optionRepository.setValue(_recentBoardIdKey, created.id);
    if (!mounted) return;
    final award = await PlayerLevelService(widget.optionRepository)
        .awardForBoardSaved(
          boardId: created.id,
          boardTitle: created.title,
          savedAt: created.updatedAt,
          created: true,
        );
    await TrainingPlanReminderService(
      widget.optionRepository,
      SettingsService(widget.optionRepository)..load(),
    ).showXpGainAlert(
      gainedXp: award.gainedXp,
      totalXp: award.after.totalXp,
      isKo: isKo,
      sourceLabel: isKo ? '훈련 스케치' : 'Training sketch',
    );
    if (!mounted) return;
    AppFeedback.showSuccess(
      context,
      text: isKo
          ? '스케치를 복제했어요.${award.gainedXp > 0 ? ' +${award.gainedXp} XP' : ''}'
          : 'Sketch duplicated.${award.gainedXp > 0 ? ' +${award.gainedXp} XP' : ''}',
    );
    await _reload();
  }
}

enum _BoardListSort { updatedDesc, trainingDateDesc, titleAsc }

class _BoardTemplate {
  final String id;
  final IconData icon;
  final String labelKo;
  final String labelEn;
  final String descriptionKo;
  final String descriptionEn;
  final TrainingMethodLayout Function(String title) buildLayout;

  const _BoardTemplate({
    required this.id,
    required this.icon,
    required this.labelKo,
    required this.labelEn,
    required this.descriptionKo,
    required this.descriptionEn,
    required this.buildLayout,
  });
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

    for (final route in page.routes) {
      if (route.points.length < 2) continue;
      final routePaint = Paint()
        ..color = Color(route.colorValue).withValues(alpha: 0.84)
        ..style = PaintingStyle.stroke
        ..strokeWidth = route.width.clamp(1.2, 2.2)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final path = Path()
        ..moveTo(
          route.points.first.x * size.width,
          route.points.first.y * size.height,
        );
      for (final point in route.points.skip(1)) {
        path.lineTo(point.x * size.width, point.y * size.height);
      }
      canvas.drawPath(path, routePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPreviewPainter oldDelegate) {
    return oldDelegate.page != page;
  }
}
