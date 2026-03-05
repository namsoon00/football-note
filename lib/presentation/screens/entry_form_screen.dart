import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../application/local_fortune_service.dart';
import '../../application/localized_option_defaults.dart';
import '../../application/training_service.dart';
import '../../application/player_profile_service.dart';
import '../../domain/entities/training_entry.dart';
import '../../domain/repositories/option_repository.dart';
import 'package:football_note/gen/app_localizations.dart';
import '../../application/locale_service.dart';
import '../../application/settings_service.dart';
import '../../application/backup_service.dart';
import '../widgets/watch_cart/constants.dart';
import '../widgets/watch_cart/watch_cart_card.dart';
import '../widgets/status_style.dart';
import 'settings_screen.dart';
import 'training_method_board_screen.dart';

class EntryFormScreen extends StatefulWidget {
  final TrainingService trainingService;
  final OptionRepository optionRepository;
  final LocaleService localeService;
  final SettingsService settingsService;
  final BackupService? driveBackupService;
  final TrainingEntry? entry;
  final DateTime? initialDate;

  const EntryFormScreen({
    super.key,
    required this.trainingService,
    required this.optionRepository,
    required this.localeService,
    required this.settingsService,
    this.driveBackupService,
    this.entry,
    this.initialDate,
  });

  @override
  State<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends State<EntryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _goodPointsController = TextEditingController();
  final _improvementsController = TextEditingController();
  final _nextGoalController = TextEditingController();
  final _drillsController = TextEditingController();
  final _injuryPartController = TextEditingController();
  final _painController = TextEditingController();
  final _liftChestController = TextEditingController();
  final _liftBackController = TextEditingController();
  final _liftLegsController = TextEditingController();
  final _liftShouldersController = TextEditingController();
  final _liftArmsController = TextEditingController();
  final _liftCoreController = TextEditingController();
  final _jumpRopeController = TextEditingController();
  final _speech = stt.SpeechToText();
  final _fortuneService = LocalFortuneService();
  TextEditingController? _listeningController;
  String _sessionRecognizedWords = '';
  bool _sessionCommitted = false;
  int _listeningSession = 0;
  bool _isListening = false;
  bool _speechInitialized = false;
  bool _speechAvailable = false;

  List<String> _locationOptions = [];
  List<String> _programOptions = [];
  List<String> _dailyGoalOptions = [];
  List<int> _durationOptions = [];
  List<String> _injuryPartOptions = [];
  final Set<String> _selectedDailyGoals = <String>{};
  final List<int> _ratingOptions = [1, 2, 3, 4, 5];
  bool _optionsLoaded = false;
  Timer? _autoSaveTimer;
  bool _autoSaving = false;
  bool _saveInProgress = false;
  bool _deleteInProgress = false;
  int? _editingKey;

  DateTime _date = DateTime.now();
  int _durationMinutes = 60;
  int _intensity = 3;
  int _mood = 3;
  String _type = '';
  String _status = 'normal';
  bool _injury = false;
  bool _rehab = false;
  bool _liftingEnabled = false;
  String _fortuneComment = '';
  String _location = '';
  final List<String> _imagePaths = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_optionsLoaded) return;
    _optionsLoaded = true;
    final l10n = AppLocalizations.of(context)!;

    _locationOptions = _loadOptions(
      key: 'locations',
      defaults: [
        l10n.defaultLocation1,
        l10n.defaultLocation2,
        l10n.defaultLocation3,
      ],
    );
    _programOptions = _loadOptions(
      key: 'programs',
      defaults: [
        l10n.defaultProgram1,
        l10n.defaultProgram2,
        l10n.defaultProgram3,
        l10n.defaultProgram4,
      ],
    );
    _dailyGoalOptions = _loadOptions(
      key: 'daily_goals',
      defaults: _defaultDailyGoals(),
    );
    _durationOptions = _loadIntOptions(
      key: 'durations',
      defaults: const [0, 30, 45, 60, 75, 90, 120],
    );
    _injuryPartOptions = _loadOptions(
      key: 'injury_parts',
      defaults: [
        l10n.defaultInjury1,
        l10n.defaultInjury2,
        l10n.defaultInjury3,
        l10n.defaultInjury4,
        l10n.defaultInjury5,
      ],
    );
    final entry = widget.entry;
    if (entry != null) {
      _editingKey = entry.key is int ? entry.key as int : null;
      _date = entry.date;
      _durationMinutes = _initIntSelection(
        'durations',
        _durationOptions,
        entry.durationMinutes,
      );
      _goodPointsController.text =
          entry.goodPoints.isNotEmpty ? entry.goodPoints : entry.feedback;
      _improvementsController.text =
          entry.improvements.isNotEmpty ? entry.improvements : entry.notes;
      _nextGoalController.text =
          entry.nextGoal.isNotEmpty ? entry.nextGoal : entry.goal;
      _drillsController.text = entry.drills;
      _intensity = entry.intensity;
      _mood = entry.mood;
      _type = _initSelection('programs', _programOptions, entry.program);
      _status = entry.status.isEmpty ? 'normal' : entry.status;
      _injury = entry.injury;
      _location = _initSelection('locations', _locationOptions, entry.location);
      _injuryPartController.text = entry.injuryPart;
      _painController.text = entry.painLevel?.toString() ?? '';
      _rehab = entry.rehab;
      _liftingEnabled = entry.liftingByPart.values.any((value) => value > 0);
      _selectedDailyGoals
        ..clear()
        ..addAll(entry.goalFocuses);
      var hasNewDailyGoalOption = false;
      for (final goal in _selectedDailyGoals) {
        if (!_dailyGoalOptions.contains(goal)) {
          _dailyGoalOptions.add(goal);
          hasNewDailyGoalOption = true;
        }
      }
      if (hasNewDailyGoalOption) {
        widget.optionRepository.saveOptions('daily_goals', _dailyGoalOptions);
      }
      if (entry.goalFocuses.isEmpty && entry.goal.trim().isNotEmpty) {
        final legacyGoal = entry.goal.trim();
        if (_dailyGoalOptions.contains(legacyGoal)) {
          _selectedDailyGoals.add(legacyGoal);
        }
      }
      _fortuneComment = entry.fortuneComment;
      _imagePaths
        ..clear()
        ..addAll(
          entry.imagePaths.isNotEmpty
              ? entry.imagePaths
              : (entry.imagePath.isNotEmpty ? [entry.imagePath] : const []),
        );
      _liftChestController.text = _liftingText(entry.liftingByPart, 'infront');
      _liftBackController.text = _liftingText(entry.liftingByPart, 'inside');
      _liftLegsController.text = _liftingText(entry.liftingByPart, 'outside');
      _liftShouldersController.text = _liftingText(
        entry.liftingByPart,
        'muple',
      );
      _liftArmsController.text = _liftingText(entry.liftingByPart, 'head');
      _liftCoreController.text = _liftingText(entry.liftingByPart, 'chest');
      _jumpRopeController.text =
          entry.jumpRopeCount > 0 ? entry.jumpRopeCount.toString() : '';
    } else {
      if (widget.initialDate != null) {
        final d = widget.initialDate!;
        _date = DateTime(d.year, d.month, d.day);
      }
      _durationMinutes = _defaultInt(
        'default_duration',
        _durationOptions.first,
      );
      _intensity = _defaultInt('default_intensity', 3);
      _mood = _defaultInt('default_condition', 3);
      _location = _defaultString(
        'default_location',
        _locationOptions,
        'locations',
      );
      _type = _defaultString('default_program', _programOptions, 'programs');
      _status = 'normal';
      _fortuneComment = '';
      unawaited(_applyLatestEntryDefaults());
    }
  }

  List<String> _defaultDailyGoals() {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    if (isKo) {
      return const ['드리블', '패스 정확도', '슈팅', '체력', '수비 위치 선정', '퍼스트 터치'];
    }
    return const [
      'Dribbling',
      'Passing Accuracy',
      'Shooting',
      'Fitness',
      'Defensive Positioning',
      'First Touch',
    ];
  }

  Future<void> _applyLatestEntryDefaults() async {
    final latest = await widget.trainingService.latestEntry();
    if (!mounted || latest == null || widget.entry != null) return;
    setState(() {
      _durationMinutes = _initIntSelection(
        'durations',
        _durationOptions,
        latest.durationMinutes,
      );
      _location = _initSelection(
        'locations',
        _locationOptions,
        latest.location,
      );
    });
  }

  int _defaultInt(String key, int fallback) {
    final value = widget.optionRepository.getValue<int>(key);
    if (value == null) return fallback;
    return value;
  }

  String _defaultString(String key, List<String> options, String optionsKey) {
    final value = widget.optionRepository.getValue<String>(key);
    if (value == null || value.isEmpty) return options.first;
    if (!options.contains(value)) {
      options.add(value);
      widget.optionRepository.saveOptions(optionsKey, options);
    }
    return value;
  }

  Widget _buildStatusRow(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseChipBg = theme.colorScheme.surfaceContainerHighest;
    final baseChipBorder = theme.colorScheme.outline.withValues(alpha: 0.45);
    final disabledColor = theme.colorScheme.onSurface.withValues(alpha: 0.35);

    final options = [
      _StatusOption(
        'great',
        trainingStatusVisual('great').icon,
        l10n.statusGreat,
      ),
      _StatusOption('good', trainingStatusVisual('good').icon, l10n.statusGood),
      _StatusOption(
        'normal',
        trainingStatusVisual('normal').icon,
        l10n.statusNormal,
      ),
      _StatusOption(
        'tough',
        trainingStatusVisual('tough').icon,
        l10n.statusTough,
      ),
      _StatusOption(
        'recovery',
        trainingStatusVisual('recovery').icon,
        l10n.statusRecovery,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.status, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              Builder(
                builder: (context) {
                  final selected = _status == option.value;
                  final statusColor = trainingStatusColor(option.value);
                  final iconColor =
                      selected ? statusColor : statusColor.withAlpha(170);
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(option.icon, size: 16, color: iconColor),
                        const SizedBox(width: 6),
                        Text(
                          option.label,
                          style: TextStyle(
                            color: iconColor,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _status = option.value);
                      _scheduleAutoSave();
                    },
                    showCheckmark: false,
                    backgroundColor: baseChipBg,
                    selectedColor: statusColor.withValues(
                      alpha: isDark ? 0.22 : 0.14,
                    ),
                    disabledColor: disabledColor,
                    side: BorderSide(
                      color: selected ? statusColor : baseChipBorder,
                      width: selected ? 1.6 : 1.2,
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDailyGoalSelector() {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final title = isKo ? '오늘의 목표' : 'Today goals';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleSmall),
            ),
            IconButton(
              onPressed: () => _addOption(
                key: 'daily_goals',
                title: isKo ? '오늘의 목표 추가' : 'Add Today Goal',
                options: _dailyGoalOptions,
                onUpdated: (list) => setState(() => _dailyGoalOptions = list),
                onSelected: (value) {
                  setState(() {
                    _selectedDailyGoals.add(value);
                  });
                  _scheduleAutoSave();
                },
              ),
              icon: const Icon(Icons.add),
              tooltip: isKo ? '목표 추가' : 'Add goal',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _selectedDailyGoalsSummary(isKo),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              TextButton.icon(
                onPressed: _dailyGoalOptions.isEmpty
                    ? null
                    : () => _openDailyGoalPicker(isKo),
                icon: const Icon(Icons.checklist, size: 18),
                label: Text(isKo ? '선택' : 'Select'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _selectedDailyGoalsSummary(bool isKo) {
    if (_selectedDailyGoals.isEmpty) {
      return isKo ? '선택된 목표 없음' : 'No goals selected';
    }
    final selected = _dailyGoalOptions
        .where(_selectedDailyGoals.contains)
        .toList(growable: false);
    if (selected.isEmpty) {
      return isKo
          ? '${_selectedDailyGoals.length}개 선택됨'
          : '${_selectedDailyGoals.length} selected';
    }
    return selected.join(', ');
  }

  Future<void> _openDailyGoalPicker(bool isKo) async {
    final working = Set<String>.from(_selectedDailyGoals);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, sheetSetState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            isKo ? '오늘의 목표 선택' : 'Select today goals',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(isKo ? '완료' : 'Done'),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final option in _dailyGoalOptions)
                          CheckboxListTile(
                            value: working.contains(option),
                            title: Text(option),
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (checked) {
                              sheetSetState(() {
                                if (checked ?? false) {
                                  working.add(option);
                                } else {
                                  working.remove(option);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (saved != true || !mounted) return;
    setState(() {
      _selectedDailyGoals
        ..clear()
        ..addAll(working);
    });
    _scheduleAutoSave();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    unawaited(_speech.cancel());
    _goodPointsController.dispose();
    _improvementsController.dispose();
    _nextGoalController.dispose();
    _drillsController.dispose();
    _injuryPartController.dispose();
    _painController.dispose();
    _liftChestController.dispose();
    _liftBackController.dispose();
    _liftLegsController.dispose();
    _liftShouldersController.dispose();
    _liftArmsController.dispose();
    _liftCoreController.dispose();
    _jumpRopeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.entry != null;
    final dateText = DateFormat('yyyy.MM.dd').format(_date);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final isDark = theme.brightness == Brightness.dark;
    final heroAccent = isDark
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.65)
        : WatchCartConstants.primaryColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.3,
            child: Row(
              children: [
                Expanded(
                  child: Container(color: theme.scaffoldBackgroundColor),
                ),
                Expanded(child: Container(color: heroAccent)),
              ],
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                onChanged: _scheduleAutoSave,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: const Icon(Icons.arrow_back),
                              tooltip: l10n.cancel,
                            ),
                            TextButton.icon(
                              onPressed: (_saveInProgress || _deleteInProgress)
                                  ? null
                                  : (isEdit ? _confirmAndDelete : _save),
                              icon: Icon(
                                isEdit
                                    ? Icons.delete_outline
                                    : Icons.save_outlined,
                                size: 18,
                              ),
                              label:
                                  Text(isEdit ? l10n.deleteEntry : l10n.save),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.stadium_outlined,
                                color: _drillsController.text.trim().isNotEmpty
                                    ? theme.colorScheme.primary
                                    : null,
                              ),
                              tooltip:
                                  isKo ? '훈련 방법 보드' : 'Training Method Board',
                              onPressed: _openTrainingMethodBoard,
                            ),
                            IconButton(
                              icon: const Icon(Icons.settings),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => SettingsScreen(
                                      localeService: widget.localeService,
                                      settingsService: widget.settingsService,
                                      optionRepository: widget.optionRepository,
                                      driveBackupService:
                                          widget.driveBackupService,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${l10n.entryHeadline1} ${l10n.entryHeadline2}',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            if (_fortuneComment.trim().isNotEmpty) {
                              _showFortuneRevealDialog(_fortuneComment.trim());
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isKo
                                      ? '먼저 저장하면 오늘의 재미 운세를 확인할 수 있어요.'
                                      : 'Save first to view your fun fortune for today.',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.auto_awesome, size: 16),
                          label: Text(isKo ? '재미운세' : 'Fortune'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    WatchCartCard(
                      child: Column(
                        children: [
                          _buildStatusRow(l10n),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withAlpha(140),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 18,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.trainingDate,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          dateText,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildIntSelectRow(
                            label: l10n.trainingDuration,
                            value: _durationMinutes,
                            options: _durationOptions,
                            optionLabel: (value) =>
                                value == 0 ? l10n.notSet : l10n.minutes(value),
                            onChanged: (value) {
                              setState(() => _durationMinutes = value);
                              _scheduleAutoSave();
                            },
                            onAdd: () => _addIntOption(
                              key: 'durations',
                              title: l10n.trainingDuration,
                              options: _durationOptions,
                              onUpdated: (list) =>
                                  setState(() => _durationOptions = list),
                              onSelected: (value) =>
                                  setState(() => _durationMinutes = value),
                              hint: '90',
                            ),
                          ),
                          const SizedBox(height: 18),
                          _buildSelectRow(
                            label: l10n.location,
                            value: _location,
                            options: _locationOptions,
                            onChanged: (value) {
                              setState(() => _location = value);
                              _scheduleAutoSave();
                            },
                            onAdd: () => _addOption(
                              key: 'locations',
                              title: l10n.location,
                              options: _locationOptions,
                              onUpdated: (list) =>
                                  setState(() => _locationOptions = list),
                              onSelected: (value) =>
                                  setState(() => _location = value),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildSelectRow(
                            label: l10n.program,
                            value: _type,
                            options: _programOptions,
                            onChanged: (value) {
                              setState(() => _type = value);
                              _scheduleAutoSave();
                            },
                            onAdd: () => _addOption(
                              key: 'programs',
                              title: l10n.program,
                              options: _programOptions,
                              onUpdated: (list) =>
                                  setState(() => _programOptions = list),
                              onSelected: (value) =>
                                  setState(() => _type = value),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildIntSelectRow(
                                  label: l10n.intensity,
                                  value: _intensity,
                                  options: _ratingOptions,
                                  optionLabel: (value) => '$value / 5',
                                  onChanged: (value) {
                                    setState(() => _intensity = value);
                                    _scheduleAutoSave();
                                  },
                                  onAdd: null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildIntSelectRow(
                                  label: l10n.condition,
                                  value: _mood,
                                  options: _ratingOptions,
                                  optionLabel: (value) => '$value / 5',
                                  onChanged: (value) {
                                    setState(() => _mood = value);
                                    _scheduleAutoSave();
                                  },
                                  onAdd: null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    WatchCartCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDailyGoalSelector(),
                          const SizedBox(height: 12),
                          _buildEmphasizedField(
                            controller: _goodPointsController,
                            minLines: 2,
                            maxLines: null,
                            decoration: InputDecoration(
                              labelText: isKo ? '잘한 점' : 'What went well',
                              hintText: isKo
                                  ? '오늘 잘된 플레이를 적어보세요.'
                                  : 'Write what you did well today.',
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildEmphasizedField(
                            controller: _improvementsController,
                            minLines: 3,
                            maxLines: null,
                            decoration: InputDecoration(
                              labelText: isKo ? '아쉬운 점' : 'What to improve',
                              hintText: isKo
                                  ? '다음에 보완할 부분을 적어보세요.'
                                  : 'Write what needs improvement.',
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildEmphasizedField(
                            controller: _nextGoalController,
                            minLines: 4,
                            maxLines: null,
                            decoration: InputDecoration(
                              labelText: isKo ? '다음 목표' : 'Next goal',
                              hintText: isKo
                                  ? '다음 훈련 목표를 적어보세요.'
                                  : 'Write your next training goal.',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    WatchCartCard(
                      child: Column(
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(l10n.injury),
                            value: _injury,
                            onChanged: (value) {
                              setState(() => _injury = value);
                              _scheduleAutoSave();
                            },
                          ),
                          if (_injury) ...[
                            _buildSelectRow(
                              label: l10n.injuryPart,
                              value: _injuryPartController.text.isEmpty
                                  ? l10n.notSet
                                  : _injuryPartController.text,
                              options: [l10n.notSet, ..._injuryPartOptions],
                              onChanged: (value) {
                                setState(() {
                                  _injuryPartController.text =
                                      value == l10n.notSet ? '' : value;
                                });
                                _scheduleAutoSave();
                              },
                              onAdd: () => _addOption(
                                key: 'injury_parts',
                                title: l10n.injuryPart,
                                options: _injuryPartOptions,
                                onUpdated: (list) =>
                                    setState(() => _injuryPartOptions = list),
                                onSelected: (value) => setState(
                                  () => _injuryPartController.text = value,
                                ),
                              ),
                              enabled: _injury,
                            ),
                            const SizedBox(height: 12),
                            _buildEmphasizedField(
                              controller: _painController,
                              enabled: _injury,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: l10n.painLevel,
                                hintText: '4',
                              ),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(l10n.rehab),
                              value: _rehab,
                              onChanged: (value) {
                                setState(() => _rehab = value);
                                _scheduleAutoSave();
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    WatchCartCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(l10n.liftingRecord),
                            value: _liftingEnabled,
                            onChanged: (value) {
                              setState(() => _liftingEnabled = value);
                              _scheduleAutoSave();
                            },
                          ),
                          if (_liftingEnabled) ...[
                            Text(
                              l10n.liftingByPart,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildEmphasizedField(
                                    controller: _liftChestController,
                                    enabled: _liftingEnabled,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: l10n.liftingPartInfront,
                                      hintText: '0',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildEmphasizedField(
                                    controller: _liftBackController,
                                    enabled: _liftingEnabled,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: l10n.liftingPartInside,
                                      hintText: '0',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildEmphasizedField(
                                    controller: _liftLegsController,
                                    enabled: _liftingEnabled,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: l10n.liftingPartOutside,
                                      hintText: '0',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildEmphasizedField(
                                    controller: _liftShouldersController,
                                    enabled: _liftingEnabled,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: l10n.liftingPartMuple,
                                      hintText: '0',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildEmphasizedField(
                                    controller: _liftArmsController,
                                    enabled: _liftingEnabled,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: l10n.liftingPartHead,
                                      hintText: '0',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildEmphasizedField(
                                    controller: _liftCoreController,
                                    enabled: _liftingEnabled,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: l10n.liftingPartChest,
                                      hintText: '0',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    WatchCartCard(
                      child: _buildEmphasizedField(
                        controller: _jumpRopeController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isKo ? '줄넘기 횟수' : 'Jump rope count',
                          hintText: '0',
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (isEdit)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 4),
                            child: Text(
                              _autoSaving
                                  ? (Localizations.localeOf(
                                            context,
                                          ).languageCode ==
                                          'ko'
                                      ? '자동 저장 중...'
                                      : 'Autosaving...')
                                  : (Localizations.localeOf(
                                            context,
                                          ).languageCode ==
                                          'ko'
                                      ? '수정 내용이 자동 저장됩니다.'
                                      : 'Changes are saved automatically.'),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmphasizedField({
    required TextEditingController controller,
    required InputDecoration decoration,
    int minLines = 1,
    int? maxLines = 1,
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final outline = theme.colorScheme.outline.withValues(alpha: 0.42);
    final disabledOutline = theme.colorScheme.outline.withValues(alpha: 0.26);
    final disabledText = theme.colorScheme.onSurface.withValues(alpha: 0.45);
    final fillColor = enabled
        ? theme.colorScheme.surfaceContainerHighest
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.56);
    final showMic = controller == _goodPointsController ||
        controller == _improvementsController ||
        controller == _nextGoalController;
    final isListeningFor = _isListening && _listeningController == controller;
    final field = TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      enabled: enabled,
      keyboardType:
          keyboardType ?? (maxLines == null ? TextInputType.multiline : null),
      style: TextStyle(
        color: enabled ? theme.colorScheme.onSurface : disabledText,
      ),
      decoration: decoration.copyWith(
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: outline, width: 1.3),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: outline, width: 1.3),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: disabledOutline, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.8),
        ),
        labelStyle: TextStyle(
          color: enabled
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.46),
        ),
        hintStyle: TextStyle(
          color: enabled
              ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8)
              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.44),
        ),
        helperText: decoration.helperText,
        helperMaxLines: decoration.helperMaxLines,
        suffixIcon: showMic && enabled
            ? IconButton(
                onPressed: () => _toggleListening(controller, l10n),
                icon: Icon(
                  isListeningFor ? Icons.mic : Icons.mic_none,
                  color: isListeningFor
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              )
            : decoration.suffixIcon,
      ),
    );
    return field;
  }

  Future<void> _toggleListening(
    TextEditingController controller,
    AppLocalizations l10n,
  ) async {
    if (_isListening) {
      _listeningSession++;
      final wasListeningForSameController = _listeningController == controller;
      final controllerToCommit = _listeningController;
      final recognizedToCommit = _sessionRecognizedWords;
      final shouldCommit = !_sessionCommitted;
      final locale = Localizations.localeOf(context).toString();
      if (mounted) {
        setState(() {
          _isListening = false;
          _listeningController = null;
          _sessionRecognizedWords = '';
          _sessionCommitted = false;
        });
      }
      await _speech.cancel();
      if (!mounted) return;
      if (wasListeningForSameController) {
        if (shouldCommit &&
            controllerToCommit != null &&
            recognizedToCommit.trim().isNotEmpty) {
          _commitRecognizedText(
            controller: controllerToCommit,
            recognized: recognizedToCommit,
            isKoreanLocale: locale.startsWith('ko'),
          );
        }
        return;
      }
    }

    final available = await _ensureSpeechInitialized();
    if (!available) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.voiceNotAvailable)));
      return;
    }
    final listeningSession = ++_listeningSession;
    setState(() {
      _isListening = true;
      _listeningController = controller;
      _sessionRecognizedWords = '';
      _sessionCommitted = false;
    });
    if (!mounted) return;
    final locale = Localizations.localeOf(context).toString();
    final localeId = locale.startsWith('ko') ? 'ko_KR' : null;
    await _speech.listen(
      localeId: localeId,
      onResult: (result) {
        if (listeningSession != _listeningSession) return;
        final recognized = result.recognizedWords.trim();
        if (recognized.isEmpty) return;
        _sessionRecognizedWords = recognized;
      },
    );
  }

  Future<bool> _ensureSpeechInitialized() async {
    if (_speechInitialized) return _speechAvailable;
    _speechInitialized = true;
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (!_isListening) return;
        if (status == 'done' || status == 'notListening') {
          if (_listeningController != null &&
              !_sessionCommitted &&
              _sessionRecognizedWords.trim().isNotEmpty) {
            final locale = Localizations.localeOf(context).toString();
            _commitRecognizedText(
              controller: _listeningController!,
              recognized: _sessionRecognizedWords,
              isKoreanLocale: locale.startsWith('ko'),
            );
          }
          if (!mounted) return;
          setState(() {
            _isListening = false;
            _listeningController = null;
            _sessionRecognizedWords = '';
            _sessionCommitted = false;
          });
        }
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _isListening = false;
          _listeningController = null;
          _sessionRecognizedWords = '';
          _sessionCommitted = false;
        });
      },
    );
    return _speechAvailable;
  }

  void _commitRecognizedText({
    required TextEditingController controller,
    required String recognized,
    required bool isKoreanLocale,
  }) {
    final normalized = recognized.trim();
    if (normalized.isEmpty || _sessionCommitted) return;

    final currentText = controller.text;
    final normalizedCurrent = currentText.trimRight();
    if (normalizedCurrent.isNotEmpty &&
        normalizedCurrent.endsWith(normalized)) {
      _sessionCommitted = true;
      return;
    }

    final needsSpacing = !isKoreanLocale &&
        currentText.isNotEmpty &&
        !RegExp(r'\s$').hasMatch(currentText);
    final separator = needsSpacing ? ' ' : '';
    final nextText = '$currentText$separator$normalized';
    controller.value = controller.value.copyWith(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextText.length),
      composing: TextRange.empty,
    );
    _sessionCommitted = true;
    _scheduleAutoSave();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() => _date = picked);
      _scheduleAutoSave();
    }
  }

  Future<void> _openTrainingMethodBoard() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => TrainingMethodBoardScreen(
          initialLayoutJson: _drillsController.text,
        ),
      ),
    );
    if (result == null || !mounted) return;
    if (_drillsController.text == result) return;
    setState(() {
      _drillsController.text = result;
    });
    _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    if (widget.entry == null) return;
    if (_saveInProgress) return;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 700), () {
      _save(popAfterSave: false, silent: true);
    });
  }

  Future<void> _save({bool popAfterSave = true, bool silent = false}) async {
    if (_saveInProgress) return;
    if (_autoSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    _saveInProgress = true;
    if (silent) {
      _autoSaving = true;
      if (mounted) setState(() {});
    }

    try {
      final isKo = Localizations.localeOf(context).languageCode == 'ko';
      final injuryPart = _injury ? _injuryPartController.text.trim() : '';
      final painLevel = _injury ? _parseInt(_painController.text) : null;
      final durationMinutes = _durationMinutes;
      final profile = PlayerProfileService(widget.optionRepository).load();
      final allEntries = await widget.trainingService.allEntries();
      final liftingByPart = _liftingEnabled
          ? (<String, int>{
              'infront': _parseLiftCount(_liftChestController.text),
              'inside': _parseLiftCount(_liftBackController.text),
              'outside': _parseLiftCount(_liftLegsController.text),
              'muple': _parseLiftCount(_liftShouldersController.text),
              'head': _parseLiftCount(_liftArmsController.text),
              'chest': _parseLiftCount(_liftCoreController.text),
            }..removeWhere((_, value) => value <= 0))
          : <String, int>{};
      final selectedGoals = _selectedDailyGoals.toList()..sort();
      final goodPoints = _goodPointsController.text.trim();
      final improvements = _improvementsController.text.trim();
      final nextGoal = _nextGoalController.text.trim();
      final createdAt = widget.entry?.createdAt ?? DateTime.now();
      final jumpRopeCount =
          _parseInt(_jumpRopeController.text.trim())?.clamp(0, 1000000) ?? 0;

      final draftEntry = TrainingEntry(
        date: DateTime(_date.year, _date.month, _date.day),
        durationMinutes: durationMinutes,
        intensity: _intensity,
        type: _type,
        mood: _mood,
        injury: _injury,
        notes: improvements,
        location: _location,
        program: _type,
        drills: _drillsController.text.trim(),
        club: '',
        injuryPart: injuryPart,
        painLevel: painLevel,
        rehab: _injury ? _rehab : false,
        goal: nextGoal,
        feedback: goodPoints,
        heightCm: profile.heightCm,
        weightKg: profile.weightKg,
        imagePath: _imagePaths.isNotEmpty ? _imagePaths.first : '',
        imagePaths: _imagePaths,
        status: _status,
        liftingByPart: liftingByPart,
        goalFocuses: selectedGoals,
        goodPoints: goodPoints,
        improvements: improvements,
        nextGoal: nextGoal,
        createdAt: createdAt,
        jumpRopeCount: jumpRopeCount,
      );
      final fortune = _fortuneService.generateResult(
        entry: draftEntry,
        profile: profile,
        history: allEntries,
        isKo: isKo,
      );
      final fortuneComment = fortune.fortuneText;
      _fortuneComment = fortuneComment;

      final entry = TrainingEntry(
        date: draftEntry.date,
        durationMinutes: draftEntry.durationMinutes,
        intensity: draftEntry.intensity,
        type: draftEntry.type,
        mood: draftEntry.mood,
        injury: draftEntry.injury,
        notes: draftEntry.notes,
        location: draftEntry.location,
        program: draftEntry.program,
        drills: draftEntry.drills,
        club: draftEntry.club,
        injuryPart: draftEntry.injuryPart,
        painLevel: draftEntry.painLevel,
        rehab: draftEntry.rehab,
        goal: draftEntry.goal,
        feedback: draftEntry.feedback,
        heightCm: draftEntry.heightCm,
        weightKg: draftEntry.weightKg,
        imagePath: draftEntry.imagePath,
        imagePaths: draftEntry.imagePaths,
        status: draftEntry.status,
        liftingByPart: draftEntry.liftingByPart,
        coachComment: '',
        fortuneComment: fortuneComment,
        fortuneRecommendation: '',
        fortuneRecommendedProgram: '',
        goalFocuses: draftEntry.goalFocuses,
        goodPoints: draftEntry.goodPoints,
        improvements: draftEntry.improvements,
        nextGoal: draftEntry.nextGoal,
        createdAt: draftEntry.createdAt,
        jumpRopeCount: draftEntry.jumpRopeCount,
      );

      if (widget.entry == null) {
        await widget.trainingService.add(entry);
      } else {
        final editingKey = _editingKey;
        if (editingKey == null) {
          if (!silent && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  Localizations.localeOf(context).languageCode == 'ko'
                      ? '수정 대상 키를 찾지 못해 중복 저장을 막았습니다. 목록에서 다시 열어주세요.'
                      : 'Missing edit key. Prevented duplicate save. Reopen from list.',
                ),
              ),
            );
          }
          return;
        }
        await widget.trainingService.update(editingKey, entry);
      }
      if (!mounted) return;
      if (widget.entry == null && popAfterSave) {
        await _showFortuneRevealDialog(fortuneComment);
        if (!mounted) return;
      }
      if (popAfterSave) {
        Navigator.of(context).pop();
      }
    } finally {
      _saveInProgress = false;
      if (silent) {
        _autoSaving = false;
        if (mounted) setState(() {});
      }
    }
  }

  Future<void> _showFortuneRevealDialog(String fortuneComment) async {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'fortune',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, _, __) {
        final eased = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.82, end: 1).animate(eased),
            child: AlertDialog(
              icon: Icon(
                Icons.auto_awesome,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(isKo ? '짠! 오늘의 운세' : 'Ta-da! Your Fortune'),
              content: Text(fortuneComment),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(isKo ? '확인' : 'OK'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmAndDelete() async {
    if (widget.entry == null || _deleteInProgress) return;
    final l10n = AppLocalizations.of(context)!;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteEntry),
        content: Text(l10n.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    _deleteInProgress = true;
    if (mounted) setState(() {});
    _autoSaveTimer?.cancel();
    try {
      final entries = await widget.trainingService.allEntries();
      final key = _editingKey;
      TrainingEntry target = widget.entry!;
      if (key != null) {
        for (final item in entries) {
          if (item.key == key) {
            target = item;
            break;
          }
        }
      }
      await widget.trainingService.delete(target);
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      _deleteInProgress = false;
      if (mounted) setState(() {});
    }
  }

  List<String> _loadOptions({
    required String key,
    required List<String> defaults,
  }) {
    final stored = widget.optionRepository.getOptions(key, defaults);
    final normalized = LocalizedOptionDefaults.normalizeOptions(
      key: key,
      stored: stored,
      localizedDefaults: defaults,
    );
    if (!_sameStringList(stored, normalized)) {
      widget.optionRepository.saveOptions(key, normalized);
    }
    return normalized;
  }

  bool _sameStringList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  String _initSelection(String key, List<String> options, String value) {
    if (value.isEmpty) {
      return options.first;
    }
    if (!options.contains(value)) {
      options.add(value);
      widget.optionRepository.saveOptions(key, options);
    }
    return value;
  }

  Widget _buildSelectRow({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
    required VoidCallback? onAdd,
    bool enabled = true,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: DropdownMenu<String>(
              initialSelection: value,
              label: Text(label),
              trailingIcon: Icon(
                Icons.expand_more,
                color: enabled
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.42),
              ),
              selectedTrailingIcon: Icon(
                Icons.expand_less,
                color: enabled
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.42),
              ),
              textStyle: TextStyle(
                fontSize: 14,
                color: enabled
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.42),
              ),
              inputDecorationTheme: _dropdownDecoration(enabled: enabled),
              dropdownMenuEntries: options
                  .map(
                    (option) => DropdownMenuEntry(value: option, label: option),
                  )
                  .toList(),
              onSelected: (value) {
                if (value != null && enabled) {
                  onChanged(value);
                }
              },
              enabled: enabled,
            ),
          ),
        ),
        if (onAdd != null) ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: enabled ? onAdd : null,
            icon: const Icon(Icons.add),
            tooltip: '${l10n.add} $label',
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minHeight: 36, minWidth: 36),
          ),
        ],
      ],
    );
  }

  Widget _buildIntSelectRow({
    required String label,
    required int value,
    required List<int> options,
    required String Function(int value) optionLabel,
    required ValueChanged<int> onChanged,
    required VoidCallback? onAdd,
    bool enabled = true,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: DropdownMenu<int>(
              initialSelection: value,
              label: Text(label),
              trailingIcon: Icon(
                Icons.expand_more,
                color: enabled
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.42),
              ),
              selectedTrailingIcon: Icon(
                Icons.expand_less,
                color: enabled
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.42),
              ),
              textStyle: TextStyle(
                fontSize: 14,
                color: enabled
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.42),
              ),
              inputDecorationTheme: _dropdownDecoration(enabled: enabled),
              dropdownMenuEntries: options
                  .map(
                    (option) => DropdownMenuEntry(
                      value: option,
                      label: optionLabel(option),
                    ),
                  )
                  .toList(),
              onSelected: (value) {
                if (value != null && enabled) {
                  onChanged(value);
                }
              },
              enabled: enabled,
            ),
          ),
        ),
        if (onAdd != null) ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: enabled ? onAdd : null,
            icon: const Icon(Icons.add),
            tooltip: '${l10n.add} $label',
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minHeight: 36, minWidth: 36),
          ),
        ],
      ],
    );
  }

  InputDecorationTheme _dropdownDecoration({bool enabled = true}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disabledBorderColor = Theme.of(
      context,
    ).colorScheme.outline.withValues(alpha: 0.32);
    final normalBorderColor = Theme.of(
      context,
    ).colorScheme.outline.withValues(alpha: 0.45);
    final fillColor = isDark
        ? const Color(0xFF242D3D)
        : (enabled ? const Color(0xFFF7F8FC) : const Color(0xFFE8EDF6));
    final disabledTextColor = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.42);
    return InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: fillColor,
      labelStyle: TextStyle(
        color: enabled
            ? Theme.of(context).colorScheme.onSurface
            : disabledTextColor,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: enabled ? normalBorderColor : disabledBorderColor,
          width: 1.2,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: enabled ? normalBorderColor : disabledBorderColor,
          width: 1.2,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: disabledBorderColor, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.8,
        ),
      ),
    );
  }

  Future<void> _addOption({
    required String key,
    required String title,
    required List<String> options,
    required ValueChanged<List<String>> onUpdated,
    required ValueChanged<String> onSelected,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.newItem,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(AppLocalizations.of(context)!.add),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;
    if (options.contains(result)) {
      onSelected(result);
      return;
    }
    final updated = [...options, result];
    await widget.optionRepository.saveOptions(key, updated);
    onUpdated(updated);
    onSelected(result);
  }

  List<int> _loadIntOptions({
    required String key,
    required List<int> defaults,
  }) {
    return widget.optionRepository.getIntOptions(key, defaults);
  }

  int _initIntSelection(String key, List<int> options, int value) {
    if (value <= 0) {
      return options.first;
    }
    if (!options.contains(value)) {
      options.add(value);
      options.sort();
      widget.optionRepository.saveOptions(key, options);
    }
    return value;
  }

  Future<void> _addIntOption({
    required String key,
    required String title,
    required List<int> options,
    required ValueChanged<List<int>> onUpdated,
    required ValueChanged<int> onSelected,
    String hint = '',
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(AppLocalizations.of(context)!.add),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;
    final parsed = int.tryParse(result);
    if (parsed == null || parsed <= 0) return;
    if (options.contains(parsed)) {
      onSelected(parsed);
      return;
    }
    final updated = [...options, parsed]..sort();
    await widget.optionRepository.saveOptions(key, updated);
    onUpdated(updated);
    onSelected(parsed);
  }

  int? _parseInt(String text) {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned);
  }

  int _parseLiftCount(String text) {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return 0;
    final parsed = int.tryParse(cleaned) ?? 0;
    return parsed < 0 ? 0 : parsed;
  }

  String _liftingText(Map<String, int> liftingByPart, String key) {
    final value = liftingByPart[key] ?? 0;
    return value <= 0 ? '' : value.toString();
  }
}

class _StatusOption {
  final String value;
  final IconData icon;
  final String label;

  const _StatusOption(this.value, this.icon, this.label);
}
