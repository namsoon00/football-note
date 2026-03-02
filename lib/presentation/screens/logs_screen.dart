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
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../application/training_service.dart';
import '../../application/settings_service.dart';
import '../../application/backup_service.dart';
import '../../domain/entities/training_entry.dart';
import '../widgets/app_background.dart';
import '../widgets/app_drawer.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';

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
    _programOptions = widget.optionRepository.getOptions('programs', [
      l10n.defaultProgram1,
      l10n.defaultProgram2,
      l10n.defaultProgram3,
      l10n.defaultProgram4,
    ]);
    final savedLayout =
        widget.optionRepository.getValue<String>(_layoutKey) ?? 'card';
    _layout = savedLayout == 'list' ? _LogsLayout.list : _LogsLayout.card;
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
              final allEntries = (snapshot.data ?? [])
                ..sort((a, b) => b.date.compareTo(a.date));
              final entries = _applyFilters(allEntries);
              final l10n = AppLocalizations.of(context)!;

              return SingleChildScrollView(
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${l10n.logsHeadline1} ${l10n.logsHeadline2}',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        _buildLayoutToggle(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    WatchCartHomeOptions(
                      onAdd: widget.onCreate,
                      onSearch: _toggleSearch,
                      onFilter: () => _openFilterSheet(context),
                      actionLabel: l10n.addEntry,
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
                        child: Center(child: Text(l10n.noEntries)),
                      )
                    else if (entries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text(l10n.noResults)),
                      )
                    else if (_layout == _LogsLayout.card)
                      MasonryGridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return ZoomIn(
                            child: _EntryCard(
                              entry: entry,
                              onEdit: () => _onEntryTap(entry),
                              onDelete: () => _confirmDelete(context, entry),
                            ),
                          );
                        },
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: entries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return _EntryListItem(
                            entry: entry,
                            onEdit: () => _onEntryTap(entry),
                            onDelete: () => _confirmDelete(context, entry),
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          ),
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
          setState(() => _layout = type);
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
      onChanged: (value) => setState(() => _searchQuery = value.trim()),
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
        entry.location,
        entry.notes,
        entry.goal,
        entry.feedback,
        entry.injuryPart,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
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
                  const SizedBox(height: 12),
                  _buildFilterDropdown(
                    label: l10n.location,
                    value: localLocation,
                    entries: _optionEntries(_locationOptions, l10n.filterAll),
                    onChanged: (value) =>
                        setModalState(() => localLocation = value),
                  ),
                  const SizedBox(height: 12),
                  _buildFilterDropdown(
                    label: l10n.program,
                    value: localProgram,
                    entries: _optionEntries(_programOptions, l10n.filterAll),
                    onChanged: (value) =>
                        setModalState(() => localProgram = value),
                  ),
                  const SizedBox(height: 12),
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
    });
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
      height: 50,
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
            vertical: 8,
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

  Future<void> _confirmDelete(BuildContext context, TrainingEntry entry) async {
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
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (result == true) {
      await widget.trainingService.delete(entry);
    }
  }

  void _onEntryTap(TrainingEntry entry) {
    HapticFeedback.selectionClick();
    widget.onEdit(entry);
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
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EntryCard({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final dateText = DateFormat.yMMMd(locale).add_E().format(entry.date);
    final l10n = AppLocalizations.of(context)!;
    final titleProgram = entry.type.isEmpty ? l10n.program : entry.type;
    final titleLocation = entry.location.trim();
    final titleText = titleLocation.isEmpty
        ? titleProgram
        : '$titleProgram · $titleLocation';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onEdit,
        child: WatchCartCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateText,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 6),
              Center(child: _EntryImage(entry: entry)),
              const SizedBox(height: 6),
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
              if (_buildListFocusText(entry).isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  _buildListFocusText(entry),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: Text(
                      l10n.edit,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: Text(
                      l10n.delete,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
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
  final VoidCallback onDelete;

  const _EntryListItem({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

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

    return WatchCartCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        leading: _StatusIcon(status: entry.status),
        title: Text(
          '${entry.type.isEmpty ? l10n.program : entry.type} · $durationText · $locationText',
        ),
        subtitle: Text(
          [
            '${l10n.intensity} ${entry.intensity} · ${l10n.condition} ${entry.mood} · $dateText',
            if (_buildListFocusText(entry).isNotEmpty)
              _buildListFocusText(entry),
          ].join('\n'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<String>(
          tooltip: l10n.edit,
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
              return;
            }
            if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(l10n.edit),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete_outline, size: 18),
                  const SizedBox(width: 8),
                  Text(l10n.delete),
                ],
              ),
            ),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }
}

String _buildSummaryLine(AppLocalizations l10n, TrainingEntry entry) {
  final parts = <String>[];
  if (entry.durationMinutes > 0) {
    parts.add(l10n.minutes(entry.durationMinutes));
  }
  parts.add('${l10n.intensity} ${entry.intensity}');
  parts.add('${l10n.condition} ${entry.mood}');
  if (entry.location.isNotEmpty) {
    parts.add(entry.location);
  }
  return parts.join('  •  ');
}

String _buildListFocusText(TrainingEntry entry) {
  if (entry.goal.trim().isNotEmpty) return entry.goal.trim();
  if (entry.feedback.trim().isNotEmpty) return entry.feedback.trim();
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
        width: 64,
        height: 64,
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
            height: 92,
            width: 92,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              final status = _statusMeta(entry.status);
              return Container(
                width: 92,
                height: 92,
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
