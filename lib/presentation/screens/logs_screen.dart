import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:football_note/gen/app_localizations.dart';
import '../../application/locale_service.dart';
import '../../domain/repositories/option_repository.dart';
import '../widgets/watch_cart/main_app_bar.dart';
import '../widgets/watch_cart/home_options.dart';
import '../widgets/watch_cart/watch_cart_card.dart';
import '../widgets/status_style.dart';
import '../widgets/tab_screen_title.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../application/training_service.dart';
import '../../application/settings_service.dart';
import '../../application/backup_service.dart';
import '../../application/localized_option_defaults.dart';
import '../../application/training_board_service.dart';
import '../../domain/entities/training_entry.dart';
import '../../domain/entities/training_board.dart';
import '../models/training_method_layout.dart';
import '../models/training_board_link_codec.dart';
import '../widgets/app_background.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_page_route.dart';
import '../theme/app_motion.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';
import 'coach_lesson_screen.dart';
import 'training_board_list_screen.dart';

class LogsScreen extends StatefulWidget {
  final TrainingService trainingService;
  final LocaleService localeService;
  final OptionRepository optionRepository;
  final SettingsService settingsService;
  final BackupService? driveBackupService;
  final ValueChanged<TrainingEntry> onEdit;
  final VoidCallback onCreate;
  final VoidCallback? onQuickPlan;
  final VoidCallback? onQuickMatch;
  final VoidCallback? onQuickQuiz;

  const LogsScreen({
    super.key,
    required this.trainingService,
    required this.localeService,
    required this.optionRepository,
    required this.settingsService,
    this.driveBackupService,
    required this.onEdit,
    required this.onCreate,
    this.onQuickPlan,
    this.onQuickMatch,
    this.onQuickQuiz,
  });

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  static const String _allFilterValue = '__all__';
  static const String _layoutKey = 'logs_layout';
  static const String _statusFilterKey = 'logs_filter_status';
  static const String _locationFilterKey = 'logs_filter_location';
  static const String _programFilterKey = 'logs_filter_program';
  static const String _injuryOnlyFilterKey = 'logs_filter_injury_only';
  static const String _quickGuideSeenKey = 'logs_quick_guide_seen_v1';
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;
  String _searchQuery = '';
  String _statusFilter = _allFilterValue;
  String _locationFilter = _allFilterValue;
  String _programFilter = _allFilterValue;
  bool _injuryOnly = false;
  _LogsLayout _layout = _LogsLayout.card;
  bool _optionsLoaded = false;
  bool _quickGuideOpened = false;
  List<String> _locationOptions = [];
  List<String> _programOptions = [];
  static const int _pageSize = 20;
  int _visibleCount = _pageSize;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_optionsLoaded) return;
    _optionsLoaded = true;
    final l10n = AppLocalizations.of(context)!;
    _locationOptions = widget.optionRepository.getOptions('locations', [
      l10n.defaultLocation1,
      l10n.defaultLocation2,
      l10n.defaultLocation3,
    ]);
    final normalizedLocations = LocalizedOptionDefaults.normalizeOptions(
      key: 'locations',
      stored: _locationOptions,
      localizedDefaults: [
        l10n.defaultLocation1,
        l10n.defaultLocation2,
        l10n.defaultLocation3,
      ],
    );
    if (!_sameStringList(_locationOptions, normalizedLocations)) {
      _locationOptions = normalizedLocations;
      widget.optionRepository.saveOptions('locations', normalizedLocations);
    }
    _programOptions = widget.optionRepository.getOptions('programs', [
      l10n.defaultProgram1,
      l10n.defaultProgram2,
      l10n.defaultProgram3,
      l10n.defaultProgram4,
    ]);
    final normalizedPrograms = LocalizedOptionDefaults.normalizeOptions(
      key: 'programs',
      stored: _programOptions,
      localizedDefaults: [
        l10n.defaultProgram1,
        l10n.defaultProgram2,
        l10n.defaultProgram3,
        l10n.defaultProgram4,
      ],
    );
    if (!_sameStringList(_programOptions, normalizedPrograms)) {
      _programOptions = normalizedPrograms;
      widget.optionRepository.saveOptions('programs', normalizedPrograms);
    }
    final savedLayout =
        widget.optionRepository.getValue<String>(_layoutKey) ?? 'card';
    _layout = savedLayout == 'list' ? _LogsLayout.list : _LogsLayout.card;
    _statusFilter =
        widget.optionRepository.getValue<String>(_statusFilterKey) ??
            _allFilterValue;
    _locationFilter =
        widget.optionRepository.getValue<String>(_locationFilterKey) ??
            _allFilterValue;
    _programFilter =
        widget.optionRepository.getValue<String>(_programFilterKey) ??
            _allFilterValue;
    _injuryOnly =
        widget.optionRepository.getValue<bool>(_injuryOnlyFilterKey) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        trainingService: widget.trainingService,
        optionRepository: widget.optionRepository,
        localeService: widget.localeService,
        settingsService: widget.settingsService,
        driveBackupService: widget.driveBackupService,
        currentIndex: 0,
      ),
      body: AppBackground(
        child: SafeArea(
          child: StreamBuilder<List<TrainingEntry>>(
            stream: widget.trainingService.watchEntries(),
            builder: (context, snapshot) {
              final sourceEntries = snapshot.data ?? const <TrainingEntry>[];
              final allEntries = sourceEntries
                  .where((entry) => !entry.isMatch)
                  .toList()
                ..sort(TrainingEntry.compareByRecentCreated);
              if (allEntries.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  unawaited(_maybeShowQuickGuide(hasEntries: false));
                });
              }
              final entries = _applyFilters(allEntries);
              final visibleEntries = entries
                  .take(_visibleCount.clamp(0, entries.length))
                  .toList(growable: false);
              final l10n = AppLocalizations.of(context)!;
              final isKo = Localizations.localeOf(context).languageCode == 'ko';
              final boardService = TrainingBoardService(
                widget.optionRepository,
              );
              final boardsById = boardService.boardMap();
              final dashboardData = _buildDashboardData(
                allEntries: allEntries,
                boardsById: boardsById,
              );

              return NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification.metrics.pixels >=
                      notification.metrics.maxScrollExtent - 240) {
                    _loadMore(entries.length);
                  }
                  return false;
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Builder(
                        builder: (context) => WatchCartAppBar(
                          onMenuTap: () => Scaffold.of(context).openDrawer(),
                          profilePhotoSource:
                              widget.optionRepository.getValue<String>(
                                    'profile_photo_url',
                                  ) ??
                                  '',
                          onProfileTap: () => _openProfile(context),
                          onSettingsTap: () => _openSettings(context),
                          onCoachTap: () => _openCoach(context),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TabScreenTitle(
                        title: isKo ? '오늘의 훈련 허브' : 'Training Hub',
                        trailing: _buildWeeklyBadge(
                          count: dashboardData.weeklyTrainingCount,
                          isKo: isKo,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _TodayOverviewCard(
                        data: dashboardData,
                        isKo: isKo,
                      ),
                      const SizedBox(height: 12),
                      _QuickActionGrid(
                        isKo: isKo,
                        onCreate: widget.onCreate,
                        onQuickMatch: widget.onQuickMatch,
                        onQuickPlan: widget.onQuickPlan,
                        onBoardList: _openBoardList,
                        onQuickQuiz: widget.onQuickQuiz,
                      ),
                      const SizedBox(height: 12),
                      _WeeklySummaryCard(
                        data: dashboardData,
                        isKo: isKo,
                      ),
                      const SizedBox(height: 12),
                      _ContinueSection(
                        data: dashboardData,
                        isKo: isKo,
                        onOpenRecentEntry: dashboardData.latestEntry == null
                            ? null
                            : () => _onEntryTap(dashboardData.latestEntry!),
                        onOpenRecentBoard: dashboardData.recentBoard == null
                            ? null
                            : _openBoardList,
                        onOpenNextPlan: widget.onQuickPlan,
                        onOpenQuiz: widget.onQuickQuiz,
                      ),
                      const SizedBox(height: 18),
                      TabScreenTitle(
                        title: isKo ? '최근 훈련 기록' : 'Recent Training Logs',
                        trailing: _buildLayoutToggle(),
                      ),
                      const SizedBox(height: 12),
                      WatchCartHomeOptions(
                        onBoardList: _openBoardList,
                        boardListIcon: Icons.edit_note_outlined,
                        boardListLabel:
                            Localizations.localeOf(context).languageCode == 'ko'
                                ? '훈련 스케치 리스트'
                                : 'Training sketch list',
                        boardListTitle: isKo ? '훈련 스케치' : 'Sketches',
                        boardBadgeCount: boardsById.length,
                        onSearch: _toggleSearch,
                        onFilter: () => _openFilterSheet(context),
                      ),
                      if (_showSearch) ...[
                        const SizedBox(height: 10),
                        _buildSearchBar(l10n),
                      ],
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: AppMotion.base(context),
                        switchInCurve: AppMotion.curveEnter,
                        switchOutCurve: AppMotion.curveExit,
                        child: allEntries.isEmpty
                            ? Padding(
                                key: const ValueKey('logs-empty-all'),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                ),
                                child: _buildEmptyState(
                                  title: l10n.noEntries,
                                  subtitle: Localizations.localeOf(
                                            context,
                                          ).languageCode ==
                                          'ko'
                                      ? '첫 훈련기록을 남기고 흐름을 시작해보세요.'
                                      : 'Create your first training note to start the flow.',
                                  actionLabel: Localizations.localeOf(
                                            context,
                                          ).languageCode ==
                                          'ko'
                                      ? '기록 추가'
                                      : 'Add entry',
                                  onPressed: widget.onCreate,
                                ),
                              )
                            : visibleEntries.isEmpty
                                ? Padding(
                                    key: const ValueKey('logs-empty-filtered'),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 24,
                                    ),
                                    child: _buildEmptyState(
                                      title: l10n.noResults,
                                      subtitle: Localizations.localeOf(
                                                context,
                                              ).languageCode ==
                                              'ko'
                                          ? '필터를 초기화하면 더 많은 기록을 볼 수 있어요.'
                                          : 'Reset filters to see more entries.',
                                      actionLabel: l10n.filterReset,
                                      onPressed: () async {
                                        const reset = _LogFilters(
                                          status: _allFilterValue,
                                          location: _allFilterValue,
                                          program: _allFilterValue,
                                          injuryOnly: false,
                                        );
                                        setState(() {
                                          _statusFilter = reset.status;
                                          _locationFilter = reset.location;
                                          _programFilter = reset.program;
                                          _injuryOnly = reset.injuryOnly;
                                          _resetPagination();
                                        });
                                        await _persistFilters(reset);
                                      },
                                    ),
                                  )
                                : _layout == _LogsLayout.card
                                    ? MasonryGridView.count(
                                        key: const ValueKey('logs-card-view'),
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 8,
                                        crossAxisSpacing: 8,
                                        itemCount: visibleEntries.length,
                                        itemBuilder: (context, index) {
                                          final entry = visibleEntries[index];
                                          final row = Dismissible(
                                            key: ValueKey(
                                              'logs-card-${entry.key ?? '${entry.date.millisecondsSinceEpoch}-${entry.type}-${entry.notes.hashCode}'}',
                                            ),
                                            direction:
                                                DismissDirection.endToStart,
                                            confirmDismiss: (_) =>
                                                _confirmDelete(context, entry),
                                            background: Container(
                                              alignment: Alignment.centerRight,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 14,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.errorContainer,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Icon(
                                                Icons.delete_outline,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onErrorContainer,
                                              ),
                                            ),
                                            child: _EntryCard(
                                              entry: entry,
                                              boardsById: boardsById,
                                              onEdit: () => _onEntryTap(entry),
                                            ),
                                          );
                                          if (AppMotion.reduceMotion(context)) {
                                            return row;
                                          }
                                          return FadeInUp(
                                            delay: Duration(
                                              milliseconds:
                                                  (index * 24).clamp(0, 240),
                                            ),
                                            duration: AppMotion.base(context),
                                            child: row,
                                          );
                                        },
                                      )
                                    : ListView.separated(
                                        key: const ValueKey('logs-list-view'),
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: visibleEntries.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 8),
                                        itemBuilder: (context, index) {
                                          final entry = visibleEntries[index];
                                          final row = Dismissible(
                                            key: ValueKey(
                                              'logs-list-${entry.key ?? '${entry.date.millisecondsSinceEpoch}-${entry.type}-${entry.notes.hashCode}'}',
                                            ),
                                            direction:
                                                DismissDirection.endToStart,
                                            confirmDismiss: (_) =>
                                                _confirmDelete(context, entry),
                                            background: Container(
                                              alignment: Alignment.centerRight,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 14,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.errorContainer,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Icon(
                                                Icons.delete_outline,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onErrorContainer,
                                              ),
                                            ),
                                            child: _EntryListItem(
                                              entry: entry,
                                              onEdit: () => _onEntryTap(entry),
                                            ),
                                          );
                                          if (AppMotion.reduceMotion(context)) {
                                            return row;
                                          }
                                          return FadeInUp(
                                            delay: Duration(
                                              milliseconds:
                                                  (index * 20).clamp(0, 220),
                                            ),
                                            duration: AppMotion.base(context),
                                            child: row,
                                          );
                                        },
                                      ),
                      ),
                      if (visibleEntries.length < entries.length)
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 4),
                          child: Center(
                            child: Text(
                              Localizations.localeOf(context).languageCode ==
                                      'ko'
                                  ? '${visibleEntries.length}/${entries.length}개 표시 중'
                                  : 'Showing ${visibleEntries.length}/${entries.length}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'logs_fab',
        onPressed: widget.onCreate,
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.addEntry),
      ),
    );
  }

  _LogsDashboardData _buildDashboardData({
    required List<TrainingEntry> allEntries,
    required Map<String, TrainingBoard> boardsById,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEndExclusive = weekStart.add(const Duration(days: 7));
    final weeklyEntries = allEntries
        .where(
          (entry) =>
              !entry.date.isBefore(weekStart) &&
              entry.date.isBefore(weekEndExclusive),
        )
        .toList(growable: false);
    final weeklyMinutes = weeklyEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.durationMinutes,
    );
    final latestEntry = allEntries.isEmpty ? null : allEntries.first;
    final latestEntryDay = latestEntry == null
        ? null
        : DateTime(
            latestEntry.date.year,
            latestEntry.date.month,
            latestEntry.date.day,
          );

    var streakDays = 0;
    DateTime? cursor = latestEntryDay;
    final entryDays = allEntries
        .map((entry) =>
            DateTime(entry.date.year, entry.date.month, entry.date.day))
        .toSet();
    while (cursor != null && entryDays.contains(cursor)) {
      streakDays++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    final todayPlans = _loadPlans().where((plan) {
      final day = DateTime(
        plan.scheduledAt.year,
        plan.scheduledAt.month,
        plan.scheduledAt.day,
      );
      return day == today;
    }).toList(growable: false);
    final nextPlan = _loadPlans()
        .where((plan) => plan.scheduledAt.isAfter(now))
        .toList(growable: false)
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final boards = boardsById.values.toList(growable: false)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final recentBoard = boards.isEmpty ? null : boards.first;

    final totalMood =
        weeklyEntries.fold<int>(0, (sum, entry) => sum + entry.mood);
    final averageMood =
        weeklyEntries.isEmpty ? 0 : totalMood / weeklyEntries.length;

    String strongest;
    String focus;
    if (weeklyEntries.length >= 4) {
      strongest = 'consistency';
    } else if (averageMood >= 4) {
      strongest = 'condition';
    } else if (weeklyMinutes >= 180) {
      strongest = 'volume';
    } else {
      strongest = 'restart';
    }

    if (weeklyEntries.isEmpty) {
      focus = 'log_today';
    } else if (weeklyEntries.length < 3) {
      focus = 'add_session';
    } else if (weeklyMinutes < 150) {
      focus = 'add_minutes';
    } else if (averageMood < 3) {
      focus = 'recovery';
    } else {
      focus = 'upgrade_quality';
    }

    final quizCompletedAtRaw = widget.optionRepository.getValue<String>(
      'skill_quiz_completed_at',
    );
    final quizCompletedAt = quizCompletedAtRaw == null
        ? null
        : DateTime.tryParse(quizCompletedAtRaw);
    final quizCompletedToday =
        quizCompletedAt != null && _isSameDay(quizCompletedAt, now);

    return _LogsDashboardData(
      todayPlans: todayPlans,
      nextPlan: nextPlan.isEmpty ? null : nextPlan.first,
      latestEntry: latestEntry,
      recentBoard: recentBoard,
      weeklyTrainingCount: weeklyEntries.length,
      weeklyMinutes: weeklyMinutes,
      streakDays: streakDays,
      strongestSignal: strongest,
      focusSignal: focus,
      quizCompletedToday: quizCompletedToday,
    );
  }

  List<_DashboardPlan> _loadPlans() {
    final raw = widget.optionRepository.getValue<String>(
      'training_plans_v1',
    );
    if (raw == null || raw.trim().isEmpty) return const <_DashboardPlan>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <_DashboardPlan>[];
      return decoded
          .whereType<Map>()
          .map((item) => _DashboardPlan.fromMap(item.cast<String, dynamic>()))
          .toList(growable: false);
    } catch (_) {
      return const <_DashboardPlan>[];
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildWeeklyBadge({required int count, required bool isKo}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isKo ? '이번 주 $count회' : '$count this week',
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildLayoutToggle() {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surface = Theme.of(context).colorScheme.surfaceContainerHighest;
    final outline = Theme.of(context).colorScheme.outline.withAlpha(120);
    final primary = Theme.of(context).colorScheme.primary;

    Widget layoutToggle({
      required _LogsLayout type,
      required IconData icon,
      required String label,
    }) {
      final selected = _layout == type;
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          setState(() {
            _layout = type;
            _resetPagination();
          });
          await widget.optionRepository.setValue(
            _layoutKey,
            type == _LogsLayout.list ? 'list' : 'card',
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? primary.withAlpha(24) : surface.withAlpha(120),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? primary.withAlpha(110) : outline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? primary : onSurface.withAlpha(170),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? primary : onSurface.withAlpha(170),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        layoutToggle(
          type: _LogsLayout.card,
          icon: Icons.grid_view_rounded,
          label: isKo ? '카드' : 'Card',
        ),
        const SizedBox(width: 6),
        layoutToggle(
          type: _LogsLayout.list,
          icon: Icons.view_list_rounded,
          label: isKo ? '리스트' : 'List',
        ),
      ],
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n) {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() {
        _searchQuery = value.trim();
        _resetPagination();
      }),
      decoration: InputDecoration(
        hintText: l10n.searchHint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchQuery.isEmpty
            ? IconButton(
                onPressed: _toggleSearch,
                icon: const Icon(Icons.close),
              )
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                icon: const Icon(Icons.clear),
              ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        _searchQuery = '';
      }
      _resetPagination();
    });
  }

  List<TrainingEntry> _applyFilters(List<TrainingEntry> entries) {
    if (entries.isEmpty) return entries;
    final query = _searchQuery.toLowerCase();
    return entries.where((entry) {
      if (_statusFilter != _allFilterValue && entry.status != _statusFilter) {
        return false;
      }
      if (_locationFilter != _allFilterValue &&
          entry.location != _locationFilter) {
        return false;
      }
      if (_programFilter != _allFilterValue &&
          entry.program != _programFilter) {
        return false;
      }
      if (_injuryOnly && !entry.injury) {
        return false;
      }
      if (query.isEmpty) return true;
      final haystack = [
        entry.program,
        entry.type,
        entry.opponentTeam,
        entry.location,
        entry.goalFocuses.join(' '),
        entry.goodPoints,
        entry.improvements,
        entry.nextGoal,
        entry.jumpRopeNote,
        entry.notes,
        entry.goal,
        entry.feedback,
        entry.injuryPart,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  bool _sameStringList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _openFilterSheet(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final statusValue = _statusFilter;
    final locationValue = _locationFilter;
    final programValue = _programFilter;
    final injuryOnlyValue = _injuryOnly;

    final result = await showModalBottomSheet<_LogFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        var localStatus = statusValue;
        var localLocation = locationValue;
        var localProgram = programValue;
        var localInjuryOnly = injuryOnlyValue;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.filterTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildFilterDropdown(
                    label: l10n.status,
                    value: localStatus,
                    entries: _statusEntries(l10n),
                    onChanged: (value) =>
                        setModalState(() => localStatus = value),
                  ),
                  const SizedBox(height: 16),
                  _buildFilterDropdown(
                    label: l10n.location,
                    value: localLocation,
                    entries: _optionEntries(_locationOptions, l10n.filterAll),
                    onChanged: (value) =>
                        setModalState(() => localLocation = value),
                  ),
                  const SizedBox(height: 16),
                  _buildFilterDropdown(
                    label: l10n.program,
                    value: localProgram,
                    entries: _optionEntries(_programOptions, l10n.filterAll),
                    onChanged: (value) =>
                        setModalState(() => localProgram = value),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    value: localInjuryOnly,
                    onChanged: (value) =>
                        setModalState(() => localInjuryOnly = value),
                    title: Text(l10n.filterInjuryOnly),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop(
                              const _LogFilters(
                                status: _allFilterValue,
                                location: _allFilterValue,
                                program: _allFilterValue,
                                injuryOnly: false,
                              ),
                            );
                          },
                          child: Text(l10n.filterReset),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(
                              _LogFilters(
                                status: localStatus,
                                location: localLocation,
                                program: localProgram,
                                injuryOnly: localInjuryOnly,
                              ),
                            );
                          },
                          child: Text(l10n.filterApply),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result == null) return;
    setState(() {
      _statusFilter = result.status;
      _locationFilter = result.location;
      _programFilter = result.program;
      _injuryOnly = result.injuryOnly;
      _resetPagination();
    });
    await _persistFilters(result);
  }

  List<DropdownMenuEntry<String>> _statusEntries(AppLocalizations l10n) {
    return [
      DropdownMenuEntry(value: _allFilterValue, label: l10n.filterAll),
      DropdownMenuEntry(value: 'great', label: l10n.statusGreat),
      DropdownMenuEntry(value: 'good', label: l10n.statusGood),
      DropdownMenuEntry(value: 'normal', label: l10n.statusNormal),
      DropdownMenuEntry(value: 'tough', label: l10n.statusTough),
      DropdownMenuEntry(value: 'recovery', label: l10n.statusRecovery),
    ];
  }

  List<DropdownMenuEntry<String>> _optionEntries(
    List<String> options,
    String allLabel,
  ) {
    return [
      DropdownMenuEntry(value: _allFilterValue, label: allLabel),
      ...options.map(
        (option) => DropdownMenuEntry(value: option, label: option),
      ),
    ];
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<DropdownMenuEntry<String>> entries,
    required ValueChanged<String> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final fillColor =
        isDark ? const Color(0xFF242D3D) : const Color(0xFFF7F8FC);
    final borderColor = isDark
        ? const Color(0xFF4A556D)
        : const Color.fromRGBO(210, 220, 245, 1);
    return SizedBox(
      height: 54,
      child: DropdownMenu<String>(
        initialSelection: value,
        label: Text(label),
        textStyle: TextStyle(fontSize: 14, color: onSurface),
        inputDecorationTheme: InputDecorationTheme(
          isDense: true,
          filled: true,
          fillColor: fillColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: borderColor, width: 1.2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: borderColor, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 1.4,
            ),
          ),
        ),
        dropdownMenuEntries: entries,
        onSelected: (value) {
          if (value != null) {
            onChanged(value);
          }
        },
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, TrainingEntry entry) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteEntry),
        content: Text(AppLocalizations.of(context)!.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (result == true) {
      await widget.trainingService.delete(entry);
      if (!context.mounted) return true;
      final isKo = Localizations.localeOf(context).languageCode == 'ko';
      AppFeedback.showUndo(
        context,
        text: isKo ? '기록을 삭제했어요.' : 'Entry deleted.',
        undoLabel: isKo ? '되돌리기' : 'Undo',
        onUndo: () {
          unawaited(widget.trainingService.add(entry));
          AppFeedback.showSuccess(
            context,
            text: isKo ? '삭제를 되돌렸어요.' : 'Delete undone.',
          );
        },
      );
      return true;
    }
    return false;
  }

  void _onEntryTap(TrainingEntry entry) {
    HapticFeedback.selectionClick();
    widget.onEdit(entry);
  }

  Future<void> _persistFilters(_LogFilters filters) async {
    await Future.wait([
      widget.optionRepository.setValue(_statusFilterKey, filters.status),
      widget.optionRepository.setValue(_locationFilterKey, filters.location),
      widget.optionRepository.setValue(_programFilterKey, filters.program),
      widget.optionRepository.setValue(
        _injuryOnlyFilterKey,
        filters.injuryOnly,
      ),
    ]);
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => SettingsScreen(
          localeService: widget.localeService,
          settingsService: widget.settingsService,
          optionRepository: widget.optionRepository,
          driveBackupService: widget.driveBackupService,
        ),
      ),
    );
  }

  Future<void> _openProfile(BuildContext context) async {
    await Navigator.of(context).push(
      AppPageRoute(
        builder: (_) =>
            ProfileScreen(optionRepository: widget.optionRepository),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openCoach(BuildContext context) async {
    await Navigator.of(context).push(
      AppPageRoute(
        builder: (_) =>
            CoachLessonScreen(optionRepository: widget.optionRepository),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openBoardList() async {
    await Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => TrainingBoardListScreen(
          optionRepository: widget.optionRepository,
          trainingService: widget.trainingService,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  void _resetPagination() {
    _visibleCount = _pageSize;
  }

  void _loadMore(int totalCount) {
    if (!mounted) return;
    if (_visibleCount >= totalCount) return;
    setState(() {
      _visibleCount = (_visibleCount + _pageSize).clamp(0, totalCount);
    });
  }

  Future<void> _maybeShowQuickGuide({required bool hasEntries}) async {
    if (_quickGuideOpened) return;
    if (hasEntries) return;
    _quickGuideOpened = true;
    final seen = widget.optionRepository.getValue<bool>(_quickGuideSeenKey);
    if (seen == true) return;
    await _showQuickGuideDialog();
    await widget.optionRepository.setValue(_quickGuideSeenKey, true);
  }

  Future<void> _showQuickGuideDialog() async {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final steps = isKo
        ? const <String>[
            '1) 기록 추가에서 훈련노트를 작성해요.',
            '2) 노트에서 훈련보드를 열고 연결해요.',
            '3) 훈련기록에서 전체 흐름을 확인해요.',
          ]
        : const <String>[
            '1) Create a training note from Add entry.',
            '2) Open and link a training board from the note.',
            '3) Review the whole flow in Training logs.',
          ];
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isKo ? '빠른 시작 가이드' : 'Quick start guide'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: steps
              .map(
                (step) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(step),
                ),
              )
              .toList(growable: false),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(isKo ? '닫기' : 'Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onCreate();
            },
            child: Text(isKo ? '기록 추가' : 'Add entry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.arrow_forward),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogFilters {
  final String status;
  final String location;
  final String program;
  final bool injuryOnly;

  const _LogFilters({
    required this.status,
    required this.location,
    required this.program,
    required this.injuryOnly,
  });
}

class _LogsDashboardData {
  final List<_DashboardPlan> todayPlans;
  final _DashboardPlan? nextPlan;
  final TrainingEntry? latestEntry;
  final TrainingBoard? recentBoard;
  final int weeklyTrainingCount;
  final int weeklyMinutes;
  final int streakDays;
  final String strongestSignal;
  final String focusSignal;
  final bool quizCompletedToday;

  const _LogsDashboardData({
    required this.todayPlans,
    required this.nextPlan,
    required this.latestEntry,
    required this.recentBoard,
    required this.weeklyTrainingCount,
    required this.weeklyMinutes,
    required this.streakDays,
    required this.strongestSignal,
    required this.focusSignal,
    required this.quizCompletedToday,
  });
}

class _DashboardPlan {
  final String id;
  final DateTime scheduledAt;
  final String category;
  final int durationMinutes;
  final String note;

  const _DashboardPlan({
    required this.id,
    required this.scheduledAt,
    required this.category,
    required this.durationMinutes,
    required this.note,
  });

  factory _DashboardPlan.fromMap(Map<String, dynamic> map) {
    return _DashboardPlan(
      id: map['id']?.toString() ?? '',
      scheduledAt: DateTime.tryParse(map['scheduledAt']?.toString() ?? '') ??
          DateTime.now(),
      category: map['category']?.toString().trim() ?? '',
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 60,
      note: map['note']?.toString().trim() ?? '',
    );
  }
}

class _TodayOverviewCard extends StatelessWidget {
  final _LogsDashboardData data;
  final bool isKo;

  const _TodayOverviewCard({required this.data, required this.isKo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latestEntry = data.latestEntry;
    final todayPlanLabel = data.todayPlans.isEmpty
        ? (isKo ? '오늘 계획 없음' : 'No plan today')
        : (isKo
            ? '오늘 계획 ${data.todayPlans.length}개'
            : '${data.todayPlans.length} plans today');
    final latestLabel = latestEntry == null
        ? (isKo ? '최근 기록 없음' : 'No recent log')
        : (isKo
            ? '최근 기록 ${DateFormat('M/d').format(latestEntry.date)}'
            : 'Last log ${DateFormat('M/d').format(latestEntry.date)}');

    return WatchCartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isKo
                ? '오늘 무엇을 할지 한 번에 확인하세요.'
                : 'See your next training move at a glance.',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatPill(
                icon: Icons.today_outlined,
                label: todayPlanLabel,
              ),
              _StatPill(
                icon: Icons.local_fire_department_outlined,
                label: isKo
                    ? '${data.streakDays}일 연속'
                    : '${data.streakDays}-day streak',
              ),
              _StatPill(
                icon: Icons.history,
                label: latestLabel,
              ),
              _StatPill(
                icon: Icons.timelapse_outlined,
                label: isKo
                    ? '주간 ${data.weeklyMinutes}분'
                    : '${data.weeklyMinutes} min this week',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  final bool isKo;
  final VoidCallback onCreate;
  final VoidCallback? onQuickMatch;
  final VoidCallback? onQuickPlan;
  final VoidCallback onBoardList;
  final VoidCallback? onQuickQuiz;

  const _QuickActionGrid({
    required this.isKo,
    required this.onCreate,
    required this.onQuickMatch,
    required this.onQuickPlan,
    required this.onBoardList,
    required this.onQuickQuiz,
  });

  @override
  Widget build(BuildContext context) {
    final actions = <_QuickActionItem>[
      _QuickActionItem(
        icon: Icons.add_circle_outline,
        title: isKo ? '훈련 기록' : 'Add log',
        onTap: onCreate,
      ),
      _QuickActionItem(
        icon: Icons.sports_soccer_outlined,
        title: isKo ? '시합 기록' : 'Add match',
        onTap: onQuickMatch,
      ),
      _QuickActionItem(
        icon: Icons.event_note_outlined,
        title: isKo ? '훈련 계획' : 'Add plan',
        onTap: onQuickPlan,
      ),
      _QuickActionItem(
        icon: Icons.developer_board_outlined,
        title: isKo ? '훈련 스케치' : 'Sketches',
        onTap: onBoardList,
      ),
      _QuickActionItem(
        icon: Icons.quiz_outlined,
        title: isKo ? '퀴즈 시작' : 'Start quiz',
        onTap: onQuickQuiz,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isKo ? '빠른 실행' : 'Quick actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.05,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) => _QuickActionButton(
            item: actions[index],
          ),
        ),
      ],
    );
  }
}

class _WeeklySummaryCard extends StatelessWidget {
  final _LogsDashboardData data;
  final bool isKo;

  const _WeeklySummaryCard({required this.data, required this.isKo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WatchCartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isKo ? '이번 주 성장 요약' : 'Weekly growth summary',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: isKo ? '훈련 횟수' : 'Sessions',
                  value: '${data.weeklyTrainingCount}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryMetric(
                  label: isKo ? '총 시간' : 'Minutes',
                  value: '${data.weeklyMinutes}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isKo
                ? '강점: ${_strongestLabel(data.strongestSignal, true)}'
                : 'Strongest signal: ${_strongestLabel(data.strongestSignal, false)}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            isKo
                ? '다음 포커스: ${_focusLabel(data.focusSignal, true)}'
                : 'Next focus: ${_focusLabel(data.focusSignal, false)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _strongestLabel(String key, bool isKo) {
    switch (key) {
      case 'consistency':
        return isKo ? '훈련 꾸준함' : 'consistency';
      case 'condition':
        return isKo ? '좋은 컨디션' : 'condition';
      case 'volume':
        return isKo ? '충분한 훈련량' : 'training volume';
      case 'restart':
      default:
        return isKo ? '다시 시작할 준비' : 'restart momentum';
    }
  }

  String _focusLabel(String key, bool isKo) {
    switch (key) {
      case 'add_session':
        return isKo ? '이번 주 1회 더 기록하기' : 'add one more session';
      case 'add_minutes':
        return isKo ? '훈련 시간을 조금 더 늘리기' : 'increase minutes';
      case 'recovery':
        return isKo ? '회복 중심으로 강도 조절하기' : 'balance recovery';
      case 'upgrade_quality':
        return isKo ? '훈련 보드와 함께 질 높이기' : 'upgrade quality with sketches';
      case 'log_today':
      default:
        return isKo ? '오늘 첫 기록 남기기' : 'log today';
    }
  }
}

class _ContinueSection extends StatelessWidget {
  final _LogsDashboardData data;
  final bool isKo;
  final VoidCallback? onOpenRecentEntry;
  final VoidCallback? onOpenRecentBoard;
  final VoidCallback? onOpenNextPlan;
  final VoidCallback? onOpenQuiz;

  const _ContinueSection({
    required this.data,
    required this.isKo,
    required this.onOpenRecentEntry,
    required this.onOpenRecentBoard,
    required this.onOpenNextPlan,
    required this.onOpenQuiz,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_ContinueItem>[
      _ContinueItem(
        title: isKo ? '최근 기록' : 'Latest log',
        subtitle: data.latestEntry == null
            ? (isKo ? '기록을 시작해보세요.' : 'Start your first log.')
            : _entrySubtitle(data.latestEntry!, isKo),
        icon: Icons.history_toggle_off,
        onTap: onOpenRecentEntry,
      ),
      _ContinueItem(
        title: isKo ? '다음 계획' : 'Next plan',
        subtitle: data.nextPlan == null
            ? (isKo ? '계획을 추가해보세요.' : 'Add a plan.')
            : _planSubtitle(data.nextPlan!, isKo),
        icon: Icons.schedule_outlined,
        onTap: onOpenNextPlan,
      ),
      _ContinueItem(
        title: isKo ? '최근 스케치' : 'Recent sketch',
        subtitle: data.recentBoard == null
            ? (isKo ? '첫 스케치를 만들어보세요.' : 'Create your first sketch.')
            : data.recentBoard!.title,
        icon: Icons.developer_board_outlined,
        onTap: onOpenRecentBoard,
      ),
      _ContinueItem(
        title: isKo ? '오늘의 퀴즈' : 'Daily quiz',
        subtitle: data.quizCompletedToday
            ? (isKo ? '오늘 퀴즈를 완료했어요.' : 'Quiz completed today.')
            : (isKo ? '짧게 풀고 판단력 점검' : 'Quick decision-making check.'),
        icon: Icons.quiz_outlined,
        onTap: onOpenQuiz,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isKo ? '이어 하기' : 'Continue',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ContinueCard(item: item),
          ),
        ),
      ],
    );
  }

  String _entrySubtitle(TrainingEntry entry, bool isKo) {
    final date = DateFormat('M/d').format(entry.date);
    final program = entry.program.trim().isEmpty
        ? (isKo ? '훈련 기록' : 'Training log')
        : entry.program.trim();
    return '$date · $program';
  }

  String _planSubtitle(_DashboardPlan plan, bool isKo) {
    final date = DateFormat('M/d HH:mm').format(plan.scheduledAt);
    final category = plan.category.isEmpty
        ? (isKo ? '훈련 계획' : 'Training plan')
        : plan.category;
    return '$date · $category';
  }
}

class _QuickActionItem {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _QuickActionItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}

class _QuickActionButton extends StatelessWidget {
  final _QuickActionItem item;

  const _QuickActionButton({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: item.onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.18),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.icon, color: theme.colorScheme.primary),
                const Spacer(),
                Text(
                  item.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const _ContinueItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}

class _ContinueCard extends StatelessWidget {
  final _ContinueItem item;

  const _ContinueCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: Icon(item.icon, color: theme.colorScheme.primary),
            title: Text(
              item.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(item.subtitle),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final TrainingEntry entry;
  final Map<String, TrainingBoard> boardsById;
  final VoidCallback onEdit;

  const _EntryCard({
    required this.entry,
    required this.boardsById,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final dateText = DateFormat.yMMMd(locale).add_E().format(entry.date);
    final l10n = AppLocalizations.of(context)!;
    final titleProgram = _entryTitleLabel(entry, l10n);
    final durationText = entry.durationMinutes > 0
        ? l10n.minutes(entry.durationMinutes)
        : l10n.durationNotSet;
    final titleLocation =
        entry.location.trim().isEmpty ? '-' : entry.location.trim();
    final secondaryText = _entrySecondaryText(entry, isKo: isKo);
    final titleText = [
      titleProgram,
      durationText,
      titleLocation,
      secondaryText,
    ].where((part) => part.trim().isNotEmpty).join(' · ');
    final focusText = _buildListFocusText(entry, includeFortune: false);
    final focusTextColor = Theme.of(context).colorScheme.primary;
    final boardIds = TrainingBoardLinkCodec.decodeBoardIds(entry.drills);
    final linkedBoards = boardIds
        .map((id) => boardsById[id])
        .whereType<TrainingBoard>()
        .toList(growable: false);
    final legacyLayout =
        linkedBoards.isEmpty ? TrainingMethodLayout.decode(entry.drills) : null;
    final hasTrainingBoard = linkedBoards.isNotEmpty ||
        (legacyLayout != null &&
            legacyLayout.pages.any((page) => page.items.isNotEmpty));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onEdit,
        child: WatchCartCard(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateText,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 4),
              Center(child: _EntryImage(entry: entry)),
              const SizedBox(height: 4),
              Text(
                titleText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _buildSummaryLine(l10n, entry),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
              if (hasTrainingBoard) ...[
                const SizedBox(height: 6),
                _TrainingBoardThumb(layout: legacyLayout, boards: linkedBoards),
              ],
              if (focusText.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  focusText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: focusTextColor),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryListItem extends StatelessWidget {
  final TrainingEntry entry;
  final VoidCallback onEdit;

  const _EntryListItem({required this.entry, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final dateText = DateFormat.yMMMd(locale).add_E().format(entry.date);
    final l10n = AppLocalizations.of(context)!;
    final durationText = entry.durationMinutes > 0
        ? l10n.minutes(entry.durationMinutes)
        : l10n.durationNotSet;
    final locationText =
        entry.location.trim().isEmpty ? '-' : entry.location.trim();
    final focusText = _buildListFocusText(entry, includeFortune: false);
    final focusTextColor = Theme.of(context).colorScheme.primary;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final titleText = [
      _entryTitleLabel(entry, l10n),
      durationText,
      locationText,
      _entrySecondaryText(entry, isKo: isKo),
    ].where((part) => part.trim().isNotEmpty).join(' · ');

    return WatchCartCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        leading: _StatusIcon(status: entry.status),
        title: Text(titleText),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${l10n.intensity} ${entry.intensity} · ${l10n.condition} ${entry.mood} · $dateText',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (focusText.isNotEmpty)
              Text(
                focusText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: focusTextColor),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onEdit,
      ),
    );
  }
}

class _TrainingBoardThumb extends StatelessWidget {
  final TrainingMethodLayout? layout;
  final List<TrainingBoard> boards;

  const _TrainingBoardThumb({
    this.layout,
    this.boards = const <TrainingBoard>[],
  });

  @override
  Widget build(BuildContext context) {
    final linkedBoards = boards;
    final previewLayout = linkedBoards.isNotEmpty
        ? TrainingMethodLayout.decode(linkedBoards.first.layoutJson)
        : (layout ?? TrainingMethodLayout.empty());
    final previewItems = previewLayout.pages.isNotEmpty
        ? previewLayout.pages.first.items
        : const <TrainingMethodItem>[];
    final itemCount = previewLayout.pages.fold<int>(
      0,
      (sum, p) => sum + p.items.length,
    );
    return Container(
      height: 42,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return Stack(
            children: [
              CustomPaint(painter: _ThumbPitchPainter()),
              ...previewItems.take(10).map((item) {
                final icon = switch (item.type) {
                  'cone' => Icons.change_history,
                  'player' => Icons.person,
                  'ball' => Icons.sports_soccer,
                  'ladder' => Icons.view_week,
                  _ => Icons.circle,
                };
                return Positioned(
                  left: (item.x * w).clamp(4, w - 12),
                  top: (item.y * h).clamp(2, h - 12),
                  child: Icon(
                    icon,
                    size: 11,
                    color: Color(item.colorValue).withValues(alpha: 0.95),
                  ),
                );
              }),
              Positioned(
                right: 6,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
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
              if (linkedBoards.isNotEmpty)
                Positioned(
                  left: 6,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      linkedBoards.first.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
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

class _ThumbPitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    canvas.drawRect(Rect.fromLTWH(2, 2, size.width - 4, size.height - 4), line);
    canvas.drawLine(Offset(centerX, 2), Offset(centerX, size.height - 2), line);
    canvas.drawCircle(Offset(centerX, centerY), 7, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String _buildSummaryLine(AppLocalizations l10n, TrainingEntry entry) {
  final parts = <String>[];
  parts.add('${l10n.intensity} ${entry.intensity}');
  parts.add('${l10n.condition} ${entry.mood}');
  return parts.join('  •  ');
}

String _entryTitleLabel(TrainingEntry entry, AppLocalizations l10n) {
  final label = entry.type.trim();
  if (label.isNotEmpty) return label;
  return entry.program.trim().isNotEmpty ? entry.program.trim() : l10n.program;
}

String _entrySecondaryText(TrainingEntry entry, {required bool isKo}) {
  final parts = <String>[];
  final location = entry.location.trim();
  if (location.isNotEmpty) {
    parts.add(location);
  }
  return parts.join(' · ');
}

String _buildListFocusText(TrainingEntry entry, {bool includeFortune = true}) {
  if (entry.opponentTeam.trim().isNotEmpty) {
    return entry.opponentTeam.trim();
  }
  if (entry.goalFocuses.isNotEmpty) {
    return entry.goalFocuses.join(', ');
  }
  if (entry.nextGoal.trim().isNotEmpty) return entry.nextGoal.trim();
  if (entry.goodPoints.trim().isNotEmpty) return entry.goodPoints.trim();
  if (entry.improvements.trim().isNotEmpty) return entry.improvements.trim();
  if (entry.jumpRopeNote.trim().isNotEmpty) return entry.jumpRopeNote.trim();
  if (entry.goal.trim().isNotEmpty) return entry.goal.trim();
  if (entry.feedback.trim().isNotEmpty) return entry.feedback.trim();
  if (includeFortune && entry.fortuneComment.trim().isNotEmpty) {
    return entry.fortuneComment.trim();
  }
  if (entry.notes.trim().isNotEmpty) return entry.notes.trim();
  return '';
}

class _EntryImage extends StatelessWidget {
  final TrainingEntry entry;

  const _EntryImage({required this.entry});

  @override
  Widget build(BuildContext context) {
    final images = entry.imagePaths.isNotEmpty
        ? entry.imagePaths
        : (entry.imagePath.isNotEmpty ? [entry.imagePath] : const <String>[]);
    if (images.isEmpty) {
      final status = _statusMeta(entry.status);
      return Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: status.color.withAlpha(30),
          shape: BoxShape.circle,
        ),
        child: Icon(status.icon, size: 28, color: status.color),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(images.first),
            height: 80,
            width: 80,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              final status = _statusMeta(entry.status);
              return Container(
                width: 80,
                height: 80,
                color: status.color.withAlpha(20),
                child: Icon(status.icon, size: 28, color: status.color),
              );
            },
          ),
        ),
        Positioned(
          left: 4,
          bottom: 4,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(230),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _statusMeta(entry.status).icon,
              size: 12,
              color: _statusMeta(entry.status).color,
            ),
          ),
        ),
        if (images.length > 1)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(153),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+${images.length - 1}',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
      ],
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final String status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    final meta = trainingStatusVisual(status);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [meta.gradientStart, meta.gradientEnd],
        ),
        border: Border.all(color: Colors.white.withAlpha(170), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: meta.gradientEnd.withAlpha(80),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(meta.icon, size: 19, color: Colors.white),
          Positioned(
            right: 5,
            top: 5,
            child: Icon(
              meta.sparkleIcon,
              size: 10,
              color: Colors.white.withAlpha(230),
            ),
          ),
        ],
      ),
    );
  }
}

_StatusMeta _statusMeta(String status) {
  final v = trainingStatusVisual(status);
  return _StatusMeta(
    icon: v.icon,
    color: v.color,
    gradientStart: v.gradientStart,
    gradientEnd: v.gradientEnd,
    sparkleIcon: v.sparkleIcon,
  );
}

class _StatusMeta {
  final Color gradientStart;
  final Color gradientEnd;
  final IconData sparkleIcon;
  final IconData icon;
  final Color color;

  const _StatusMeta({
    required this.icon,
    required this.color,
    required this.gradientStart,
    required this.gradientEnd,
    required this.sparkleIcon,
  });
}

enum _LogsLayout { card, list }
