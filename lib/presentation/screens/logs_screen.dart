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
import '../widgets/app_drawer.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';
import 'training_board_list_screen.dart';

class LogsScreen extends StatefulWidget {
  final TrainingService trainingService;
  final LocaleService localeService;
  final OptionRepository optionRepository;
  final SettingsService settingsService;
  final BackupService? driveBackupService;
  final ValueChanged<TrainingEntry> onEdit;
  final VoidCallback onCreate;

  const LogsScreen({
    super.key,
    required this.trainingService,
    required this.localeService,
    required this.optionRepository,
    required this.settingsService,
    this.driveBackupService,
    required this.onEdit,
    required this.onCreate,
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
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;
  String _searchQuery = '';
  String _statusFilter = _allFilterValue;
  String _locationFilter = _allFilterValue;
  String _programFilter = _allFilterValue;
  bool _injuryOnly = false;
  _LogsLayout _layout = _LogsLayout.card;
  bool _optionsLoaded = false;
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
              final allEntries =
                  sourceEntries.where((entry) => !entry.isMatch).toList()
                    ..sort(TrainingEntry.compareByRecentCreated);
              final entries = _applyFilters(allEntries);
              final visibleEntries = entries
                  .take(_visibleCount.clamp(0, entries.length))
                  .toList(growable: false);
              final l10n = AppLocalizations.of(context)!;
              final boardService = TrainingBoardService(
                widget.optionRepository,
              );
              final boardsById = boardService.boardMap();

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
                        ),
                      ),
                      const SizedBox(height: 12),
                      TabScreenTitle(
                        title: '${l10n.logsHeadline1} ${l10n.logsHeadline2}',
                        trailing: _buildLayoutToggle(),
                      ),
                      const SizedBox(height: 12),
                      WatchCartHomeOptions(
                        onBoardList: _openBoardList,
                        boardListLabel:
                            Localizations.localeOf(context).languageCode == 'ko'
                            ? '훈련스케치 리스트'
                            : 'Training sketch list',
                        boardListTitle:
                            Localizations.localeOf(context).languageCode == 'ko'
                            ? '훈련스케치'
                            : 'Sketches',
                        boardBadgeCount: boardsById.length,
                        onSearch: _toggleSearch,
                        onFilter: () => _openFilterSheet(context),
                        actionLabel:
                            Localizations.localeOf(context).languageCode == 'ko'
                            ? '기록 개수'
                            : 'Entries',
                        badgeCount: allEntries.length,
                      ),
                      if (_showSearch) ...[
                        const SizedBox(height: 10),
                        _buildSearchBar(l10n),
                      ],
                      const SizedBox(height: 12),
                      if (allEntries.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(l10n.noEntries),
                          ),
                        )
                      else if (visibleEntries.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: Text(l10n.noResults)),
                        )
                      else if (_layout == _LogsLayout.card)
                        MasonryGridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          itemCount: visibleEntries.length,
                          itemBuilder: (context, index) {
                            final entry = visibleEntries[index];
                            return ZoomIn(
                              child: Dismissible(
                                key: ValueKey(
                                  'logs-card-${entry.key ?? '${entry.date.millisecondsSinceEpoch}-${entry.type}-${entry.notes.hashCode}'}',
                                ),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (_) =>
                                    _confirmDelete(context, entry),
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(16),
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
                              ),
                            );
                          },
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: visibleEntries.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final entry = visibleEntries[index];
                            return Dismissible(
                              key: ValueKey(
                                'logs-list-${entry.key ?? '${entry.date.millisecondsSinceEpoch}-${entry.type}-${entry.notes.hashCode}'}',
                              ),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) =>
                                  _confirmDelete(context, entry),
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(16),
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
                          },
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
        onPressed: widget.onCreate,
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.addEntry),
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
    final fillColor = isDark
        ? const Color(0xFF242D3D)
        : const Color(0xFFF7F8FC);
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
      MaterialPageRoute(
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
      MaterialPageRoute(
        builder: (_) =>
            ProfileScreen(optionRepository: widget.optionRepository),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openBoardList() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
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
    final titleLocation = entry.location.trim().isEmpty
        ? '-'
        : entry.location.trim();
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
    final legacyLayout = linkedBoards.isEmpty
        ? TrainingMethodLayout.decode(entry.drills)
        : null;
    final hasTrainingBoard =
        linkedBoards.isNotEmpty ||
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
    final locationText = entry.location.trim().isEmpty
        ? '-'
        : entry.location.trim();
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
