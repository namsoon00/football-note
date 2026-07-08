import 'dart:async';

import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../application/family_access_service.dart';
import '../../application/player_level_service.dart';
import '../../application/settings_service.dart';
import '../../application/sport_service.dart';
import '../../application/training_service.dart';
import '../../application/training_board_service.dart';
import '../../application/training_plan_reminder_service.dart';
import '../../domain/entities/training_board.dart';
import '../../domain/entities/sport_definition.dart';
import '../../domain/repositories/option_repository.dart';
import '../models/training_method_layout.dart';
import '../models/training_board_link_codec.dart';
import '../models/training_board_templates.dart';
import '../widgets/app_bar_action_button.dart';
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

  String get _recentBoardIdStorageKey => SportCatalog.optionKey(
        _recentBoardIdKey,
        sportId: SportService(widget.optionRepository).currentSportId(),
      );

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

  Future<void> _presentBoardXpAward(
    PlayerLevelAward award, {
    required bool isKo,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final reminderService = TrainingPlanReminderService(
      widget.optionRepository,
      SettingsService(widget.optionRepository)..load(),
    );
    await reminderService.showXpGainAlert(
      gainedXp: award.gainedXp,
      totalXp: award.after.totalXp,
      isKo: isKo,
      sourceLabel: l10n.trainingXpSourceTrainingSketch,
    );
    if (award.didLevelUp) {
      await reminderService.showLevelUpAlert(
        level: award.after.level,
        isKo: isKo,
      );
    }
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
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: initialValue);
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.trainingBoardTitleDialogTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: l10n.trainingBoardTitleHint,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(l10n.confirm),
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
      AppPageRoute(
        builder: (_) => TrainingMethodBoardScreen(
          boardTitle: board.title,
          initialLayoutJson: board.layoutJson,
          sportId: SportService(widget.optionRepository).currentSportId(),
          onSaved: (savedLayout) async {
            final resolvedTitle = _resolveBoardTitle(
              layoutJson: savedLayout,
              fallbackTitle: board.title,
            );
            await _boardService.saveBoard(
              board.copyWith(title: resolvedTitle, layoutJson: savedLayout),
            );
          },
          readOnly: _isParentMode,
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
    final l10n = AppLocalizations.of(context)!;
    AppFeedback.showUndo(
      context,
      text: l10n.trainingBoardRenamedSnack,
      undoLabel: l10n.undo,
      onUndo: () {
        unawaited(_boardService.saveBoard(board));
        AppFeedback.showSuccess(
          context,
          text: l10n.trainingBoardRenameUndoneSnack,
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
    final template = await showTrainingBoardTemplatePicker(
      context,
      sportId: SportService(widget.optionRepository).currentSportId(),
    );
    if (!mounted || template == null) return;
    final title = await _promptTitle();
    if (!mounted || title == null) return;
    final layout = template.buildLayout(title);
    final created = await _boardService.createBoard(
      title: title,
      layoutJson: layout.encode(),
    );
    if (!mounted) return;
    await widget.optionRepository
        .setValue(_recentBoardIdStorageKey, created.id);
    if (!mounted) return;
    final award =
        await PlayerLevelService(widget.optionRepository).awardForBoardSaved(
      boardId: created.id,
      boardTitle: created.title,
      savedAt: created.updatedAt,
      created: true,
    );
    await _presentBoardXpAward(award, isKo: isKo);
    if (!mounted) return;
    if (award.gainedXp <= 0) {
      final l10n = AppLocalizations.of(context)!;
      AppFeedback.showSuccess(
        context,
        text: l10n.trainingSketchCreatedSnack,
      );
    }
    await _editBoard(created);
  }

  Future<void> _copyFromPreviousBoard() async {
    if (_isParentMode) {
      _showParentReadOnlyMessage();
      return;
    }
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final l10n = AppLocalizations.of(context)!;
    if (_boards.isEmpty) {
      AppFeedback.showSuccess(
        context,
        text: l10n.trainingBoardNoCopySourceSnack,
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
    final defaultCopyTitle = l10n.trainingBoardDefaultCopyTitle(source.title);
    final copiedTitle = await _promptTitle(initialValue: defaultCopyTitle);
    if (!mounted || copiedTitle == null) return;
    final created = await _boardService.createBoard(
      title: copiedTitle,
      layoutJson: source.layoutJson,
    );
    if (!mounted) return;
    await widget.optionRepository
        .setValue(_recentBoardIdStorageKey, created.id);
    if (!mounted) return;
    final award =
        await PlayerLevelService(widget.optionRepository).awardForBoardSaved(
      boardId: created.id,
      boardTitle: created.title,
      savedAt: created.updatedAt,
      created: true,
    );
    await _presentBoardXpAward(award, isKo: isKo);
    if (!mounted) return;
    if (award.gainedXp <= 0) {
      final l10n = AppLocalizations.of(context)!;
      AppFeedback.showSuccess(
        context,
        text: l10n.trainingSketchPreviousCopiedSnack,
      );
    }
    await _reload();
  }

  Future<void> _deleteBoard(TrainingBoard board) async {
    if (_isParentMode) {
      _showParentReadOnlyMessage();
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.trainingBoardDeleteTitle),
        content: Text(l10n.trainingBoardDeleteConfirm(board.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;
    await PlayerLevelService(widget.optionRepository).revokeBoardAwards(
      boardId: board.id,
      boardTitle: board.title,
    );
    await _boardService.deleteBoard(board.id);
    _selectedIds.remove(board.id);
    if (widget.optionRepository.getValue<String>(_recentBoardIdStorageKey) ==
        board.id) {
      await widget.optionRepository.setValue(_recentBoardIdStorageKey, '');
    }
    if (!mounted) return;
    AppFeedback.showUndo(
      context,
      text: l10n.trainingBoardDeletedSnack,
      undoLabel: l10n.undo,
      onUndo: () {
        unawaited(() async {
          await _boardService.saveBoard(board);
          await PlayerLevelService(widget.optionRepository).awardForBoardSaved(
            boardId: board.id,
            boardTitle: board.title,
            savedAt: board.updatedAt,
            created: true,
          );
        }());
        AppFeedback.showSuccess(
          context,
          text: l10n.trainingBoardDeleteUndoneSnack,
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
    return AppLocalizations.of(context)!.trainingBoardDefaultTitle;
  }

  List<TrainingBoard> _visibleBoards() {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = _boards.where((board) {
      if (query.isEmpty) return true;
      return board.title.toLowerCase().contains(query);
    }).toList(growable: false);
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
        widget.optionRepository.setValue(
          _recentBoardIdStorageKey,
          selected.first,
        ),
      );
    }
    Navigator.of(context).pop(selected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visibleBoards = _visibleBoards();
    final isFiltered = _searchQuery.trim().isNotEmpty;
    final isParentMode = _isParentMode;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.trainingBoardListTitle),
        actions: [
          AppBarActionButton.icon(
            tooltip: _showSearch
                ? l10n.trainingBoardSearchCloseTooltip
                : l10n.trainingBoardSearchTooltip,
            onPressed: _toggleSearch,
            icon: _showSearch ? Icons.close : Icons.search,
            selected: _showSearch,
          ),
          if (!widget.selectionMode)
            AppBarActionMenuButton<_BoardListSort>(
              tooltip: l10n.trainingBoardSortTooltip,
              icon: Icons.sort,
              initialValue: _sort,
              onSelected: (next) => setState(() => _sort = next),
              itemBuilder: (_) => [
                PopupMenuItem<_BoardListSort>(
                  value: _BoardListSort.updatedDesc,
                  child: Text(l10n.trainingBoardSortRecentlyUpdated),
                ),
                PopupMenuItem<_BoardListSort>(
                  value: _BoardListSort.trainingDateDesc,
                  child: Text(l10n.trainingBoardSortTrainingDate),
                ),
                PopupMenuItem<_BoardListSort>(
                  value: _BoardListSort.titleAsc,
                  child: Text(l10n.trainingBoardSortName),
                ),
              ],
            ),
          if (!widget.selectionMode)
            AppBarActionMenuButton<String>(
              tooltip: l10n.trainingBoardAddTooltip,
              enabled: !isParentMode,
              icon: Icons.add,
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
                  child: Text(l10n.trainingBoardCreateNewAction),
                ),
                PopupMenuItem<String>(
                  value: 'copy',
                  child: Text(l10n.trainingBoardCopyPreviousAction),
                ),
              ],
            ),
          if (widget.selectionMode)
            AppBarActionButton.label(
              onPressed: _submitSelection,
              tooltip: l10n.trainingBoardDoneAction,
              icon: const Icon(Icons.check_rounded),
              label: l10n.trainingBoardDoneAction,
              maxLabelWidth: 64,
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
                          l10n.trainingBoardEmptyTitle,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.trainingBoardEmptySubtitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back),
                          label: Text(l10n.trainingBoardBackToNotes),
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
                          hintText: l10n.trainingBoardSearchHint,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: l10n.weatherLabelClear,
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
                              l10n.trainingBoardNoSearchResults,
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
                                      l10n.trainingBoardListItemSubtitle(
                                        itemCount,
                                        dateText,
                                      ),
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
                                      child:
                                          Text(l10n.trainingBoardRenameAction),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'duplicate',
                                      child: Text(
                                          l10n.trainingBoardDuplicateAction),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Text(
                                        l10n.delete,
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
                                            _recentBoardIdStorageKey,
                                            board.id,
                                          ),
                                        );
                                      }
                                    : () {
                                        unawaited(
                                          widget.optionRepository.setValue(
                                            _recentBoardIdStorageKey,
                                            board.id,
                                          ),
                                        );
                                        unawaited(_editBoard(board));
                                      },
                                onLongPress: isParentMode
                                    ? null
                                    : () => unawaited(_editBoard(board)),
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
    final l10n = AppLocalizations.of(context)!;
    final copiedTitle = await _promptTitle(
      initialValue: l10n.trainingBoardDefaultCopyTitle(source.title),
    );
    if (!mounted || copiedTitle == null) return;
    final created = await _boardService.createBoard(
      title: copiedTitle,
      layoutJson: source.layoutJson,
    );
    if (!mounted) return;
    await widget.optionRepository
        .setValue(_recentBoardIdStorageKey, created.id);
    if (!mounted) return;
    final award =
        await PlayerLevelService(widget.optionRepository).awardForBoardSaved(
      boardId: created.id,
      boardTitle: created.title,
      savedAt: created.updatedAt,
      created: true,
    );
    await _presentBoardXpAward(award, isKo: isKo);
    if (!mounted) return;
    if (award.gainedXp <= 0) {
      final l10n = AppLocalizations.of(context)!;
      AppFeedback.showSuccess(
        context,
        text: l10n.trainingSketchDuplicatedSnack,
      );
    }
    await _reload();
  }
}

enum _BoardListSort { updatedDesc, trainingDateDesc, titleAsc }

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
