import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../application/local_fortune_service.dart';
import '../../application/meal_coaching_service.dart';
import '../../application/localized_option_defaults.dart';
import '../../application/player_level_service.dart';
import '../../application/training_plan_reminder_service.dart';
import '../../application/training_service.dart';
import '../../application/training_board_service.dart';
import '../../application/player_profile_service.dart';
import '../../domain/entities/training_entry.dart';
import '../../domain/repositories/option_repository.dart';
import 'package:football_note/gen/app_localizations.dart';
import '../../application/locale_service.dart';
import '../../application/settings_service.dart';
import '../../application/backup_service.dart';
import '../widgets/watch_cart/watch_cart_card.dart';
import '../widgets/status_style.dart';
import '../models/training_method_layout.dart';
import '../models/training_board_link_codec.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_page_route.dart';
import '../widgets/app_pressable_scale.dart';
import '../widgets/fortune_card.dart';
import '../widgets/level_up_dialog.dart';
import '../theme/app_motion.dart';
import 'training_method_board_screen.dart';

class EntryFormScreen extends StatefulWidget {
  final TrainingService trainingService;
  final OptionRepository optionRepository;
  final LocaleService localeService;
  final SettingsService settingsService;
  final BackupService? driveBackupService;
  final TrainingEntry? entry;
  final DateTime? initialDate;
  final bool initialOpenTrainingBoardEditor;

  const EntryFormScreen({
    super.key,
    required this.trainingService,
    required this.optionRepository,
    required this.localeService,
    required this.settingsService,
    this.driveBackupService,
    this.entry,
    this.initialDate,
    this.initialOpenTrainingBoardEditor = false,
  });

  @override
  State<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends State<EntryFormScreen> {
  static const String _recentBoardIdKey = 'recent_board_id';
  static const String _weatherAutoEnabledKey = 'entry_weather_auto_enabled';
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
  final _jumpRopeMinutesController = TextEditingController();
  final _jumpRopeNoteController = TextEditingController();
  final _speech = stt.SpeechToText();
  final _fortuneService = LocalFortuneService();
  final _mealCoachingService = const MealCoachingService();
  late final TrainingBoardService _trainingBoardService;
  TextEditingController? _listeningController;
  String _sessionRecognizedWords = '';
  bool _sessionCommitted = false;
  int _listeningSession = 0;
  bool _isListening = false;
  bool _speechInitialized = false;
  bool _speechAvailable = false;
  bool _disposing = false;

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
  TrainingEntry? _persistedEntryForXp;
  final Set<String> _linkedBoardIds = <String>{};
  String _initialSnapshot = '';
  bool _didHandleInitialBoardOpen = false;

  DateTime _date = DateTime.now();
  int _durationMinutes = 60;
  int _intensity = 3;
  int _mood = 3;
  String _type = '';
  String _status = 'normal';
  bool _injury = false;
  bool _rehab = false;
  bool _liftingEnabled = false;
  bool _jumpRopeEnabled = false;
  bool _fortuneEnabled = false;
  bool _breakfastDone = false;
  int _breakfastRiceBowls = 0;
  bool _lunchDone = false;
  int _lunchRiceBowls = 0;
  bool _dinnerDone = false;
  int _dinnerRiceBowls = 0;
  String _location = '';
  final List<String> _imagePaths = [];
  bool _weatherLoading = false;
  String _weatherSummary = '';
  int? _weatherCode;
  bool _weatherAutoEnabled = false;
  String _cachedFortuneComment = '';
  String _cachedFortuneRecommendation = '';
  String _cachedFortuneRecommendedProgram = '';

  @override
  void initState() {
    super.initState();
    _trainingBoardService = TrainingBoardService(widget.optionRepository);
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
    final normalizedDailyGoals = LocalizedOptionDefaults.normalizeOptions(
      key: 'daily_goals',
      stored: _dailyGoalOptions,
      localizedDefaults: _defaultDailyGoals(),
    );
    if (!_sameStringList(_dailyGoalOptions, normalizedDailyGoals)) {
      _dailyGoalOptions = normalizedDailyGoals;
      widget.optionRepository.saveOptions('daily_goals', normalizedDailyGoals);
    }
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
    _weatherAutoEnabled =
        widget.optionRepository.getValue<bool>(_weatherAutoEnabledKey) ?? false;
    final entry = widget.entry;
    if (entry != null) {
      _persistedEntryForXp = entry;
      _editingKey = entry.key is int ? entry.key as int : null;
      _date = entry.date;
      _durationMinutes = _initIntSelection(
        'durations',
        _durationOptions,
        entry.durationMinutes,
      );
      _goodPointsController.text = entry.goodPoints.isNotEmpty
          ? entry.goodPoints
          : entry.feedback;
      _improvementsController.text = entry.improvements.isNotEmpty
          ? entry.improvements
          : _stripWeatherFromNotes(entry.notes);
      _nextGoalController.text = entry.nextGoal.isNotEmpty
          ? entry.nextGoal
          : entry.goal;
      _linkedBoardIds
        ..clear()
        ..addAll(TrainingBoardLinkCodec.decodeBoardIds(entry.drills));
      _syncDrillsPayloadFromBoardLinks();
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
      _jumpRopeController.text = entry.jumpRopeCount > 0
          ? entry.jumpRopeCount.toString()
          : '';
      _jumpRopeMinutesController.text = entry.jumpRopeMinutes > 0
          ? entry.jumpRopeMinutes.toString()
          : '';
      _jumpRopeEnabled = entry.jumpRopeEnabled;
      _jumpRopeNoteController.text = entry.jumpRopeNote;
      _breakfastDone = entry.breakfastDone;
      _breakfastRiceBowls = entry.breakfastRiceBowls.clamp(0, 3);
      _lunchDone = entry.lunchDone;
      _lunchRiceBowls = entry.lunchRiceBowls.clamp(0, 3);
      _dinnerDone = entry.dinnerDone;
      _dinnerRiceBowls = entry.dinnerRiceBowls.clamp(0, 3);
      _fortuneEnabled = entry.fortuneComment.trim().isNotEmpty;
      _cachedFortuneComment = entry.fortuneComment;
      _cachedFortuneRecommendation = entry.fortuneRecommendation;
      _cachedFortuneRecommendedProgram = entry.fortuneRecommendedProgram;
      _weatherSummary = _extractWeatherFromNotes(entry.notes);
      if (_linkedBoardIds.isEmpty && entry.drills.trim().isNotEmpty) {
        unawaited(_migrateLegacyTrainingBoard(entry));
      }
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
      _linkedBoardIds.clear();
      _syncDrillsPayloadFromBoardLinks();
      _jumpRopeEnabled = false;
      _breakfastDone = false;
      _breakfastRiceBowls = 0;
      _lunchDone = false;
      _lunchRiceBowls = 0;
      _dinnerDone = false;
      _dinnerRiceBowls = 0;
      _fortuneEnabled = false;
      _cachedFortuneComment = '';
      _cachedFortuneRecommendation = '';
      _cachedFortuneRecommendedProgram = '';
      _weatherSummary = '';
      unawaited(_applyLatestEntryDefaults());
    }
    _initialSnapshot = _formSnapshot();
    if (widget.initialOpenTrainingBoardEditor && !_didHandleInitialBoardOpen) {
      _didHandleInitialBoardOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_openTrainingBoardEditor());
      });
    }
    if (widget.entry == null &&
        _weatherAutoEnabled &&
        _weatherSummary.trim().isEmpty) {
      unawaited(_useCurrentLocationWeather(fromAuto: true));
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

  void _syncDrillsPayloadFromBoardLinks() {
    if (_linkedBoardIds.isEmpty) {
      _drillsController.text = '';
      return;
    }
    _drillsController.text = TrainingBoardLinkCodec.encodeBoardIds(
      _linkedBoardIds.toList(growable: false),
    );
  }

  Future<void> _migrateLegacyTrainingBoard(TrainingEntry entry) async {
    final raw = entry.drills.trim();
    if (raw.isEmpty || TrainingBoardLinkCodec.isBoardLinkPayload(raw)) return;
    final layout = TrainingMethodLayout.decode(raw);
    final hasContent = layout.pages.any(
      (page) => page.items.isNotEmpty || page.methodText.trim().isNotEmpty,
    );
    if (!hasContent) return;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final created = await _trainingBoardService.createBoard(
      title: entry.program.trim().isNotEmpty
          ? entry.program.trim()
          : (isKo ? '기존 훈련 스케치' : 'Legacy training sketch'),
      layoutJson: layout.encode(),
    );
    if (!mounted) return;
    setState(() {
      _linkedBoardIds
        ..clear()
        ..add(created.id);
      _syncDrillsPayloadFromBoardLinks();
    });
    _scheduleAutoSave();
  }

  String _formSnapshot() {
    final linkedIds = _linkedBoardIds.toList()..sort();
    final selectedGoals = _selectedDailyGoals.toList()..sort();
    final editableDate = DateTime(_date.year, _date.month, _date.day);
    return [
      editableDate.toIso8601String(),
      _durationMinutes.toString(),
      _intensity.toString(),
      _mood.toString(),
      _type.trim(),
      _status.trim(),
      _injury.toString(),
      _rehab.toString(),
      _liftingEnabled.toString(),
      _location.trim(),
      _injuryPartController.text.trim(),
      _painController.text.trim(),
      _goodPointsController.text.trim(),
      _improvementsController.text.trim(),
      _nextGoalController.text.trim(),
      _fortuneEnabled.toString(),
      _weatherSummary.trim(),
      _jumpRopeController.text.trim(),
      _jumpRopeMinutesController.text.trim(),
      _jumpRopeEnabled.toString(),
      _jumpRopeNoteController.text.trim(),
      _breakfastDone.toString(),
      _breakfastRiceBowls.toString(),
      _lunchDone.toString(),
      _lunchRiceBowls.toString(),
      _dinnerDone.toString(),
      _dinnerRiceBowls.toString(),
      linkedIds.join(','),
      selectedGoals.join(','),
      _liftChestController.text.trim(),
      _liftBackController.text.trim(),
      _liftLegsController.text.trim(),
      _liftShouldersController.text.trim(),
      _liftArmsController.text.trim(),
      _liftCoreController.text.trim(),
    ].join('|');
  }

  bool get _hasUnsavedChanges => _formSnapshot() != _initialSnapshot;

  Future<bool> _confirmExitWithoutSave() async {
    if (!_hasUnsavedChanges || _saveInProgress || _deleteInProgress) {
      return true;
    }
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isKo ? '저장되지 않은 변경사항' : 'Unsaved changes'),
        content: Text(
          isKo
              ? '저장하지 않은 수정 내용이 있습니다. 정말 나가시겠어요?'
              : 'You have unsaved edits. Leave without saving?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isKo ? '계속 편집' : 'Keep editing'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(isKo ? '나가기' : 'Leave'),
          ),
        ],
      ),
    );
    return shouldLeave == true;
  }

  Future<void> _attemptExit() async {
    final shouldExit = await _confirmExitWithoutSave();
    if (!mounted || !shouldExit) return;
    Navigator.of(context).pop();
  }

  Future<void> _applyLatestEntryDefaults() async {
    final latest = await widget.trainingService.latestTrainingEntry();
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
      _initialSnapshot = _formSnapshot();
    });
  }

  String _extractWeatherFromNotes(String notes) {
    for (final line in notes.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('[Weather] ')) {
        return trimmed.substring('[Weather] '.length).trim();
      }
      if (trimmed.startsWith('[날씨] ')) {
        return trimmed.substring('[날씨] '.length).trim();
      }
    }
    return '';
  }

  String _stripWeatherFromNotes(String notes) {
    return notes
        .split('\n')
        .map((line) => line.trimRight())
        .where((line) => !line.trim().startsWith('[Weather]'))
        .where((line) => !line.trim().startsWith('[날씨]'))
        .join('\n')
        .trim();
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
                  final iconColor = selected
                      ? statusColor
                      : statusColor.withAlpha(170);
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
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
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
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.3),
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

  // ignore: unused_element
  Widget _buildMealRoutineCard(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final mealStatus = _mealCoachingService.statusForEntry(
      TrainingEntry(
        date: _date,
        durationMinutes: _durationMinutes,
        intensity: _intensity,
        type: _type,
        mood: _mood,
        injury: _injury,
        notes: '',
        location: _location,
        breakfastDone: _breakfastDone,
        breakfastRiceBowls: _breakfastDone ? _breakfastRiceBowls : 0,
        lunchDone: _lunchDone,
        lunchRiceBowls: _lunchDone ? _lunchRiceBowls : 0,
        dinnerDone: _dinnerDone,
        dinnerRiceBowls: _dinnerDone ? _dinnerRiceBowls : 0,
      ),
    );
    return WatchCartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.mealRoutineTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(l10n.mealRoutineSubtitle, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          _buildMealRow(
            l10n: l10n,
            label: l10n.mealBreakfast,
            done: _breakfastDone,
            riceBowls: _breakfastRiceBowls,
            onDoneChanged: (value) {
              setState(() {
                _breakfastDone = value;
                if (!value) _breakfastRiceBowls = 0;
              });
              _scheduleAutoSave();
            },
            onRiceBowlsChanged: (value) {
              setState(() => _breakfastRiceBowls = value);
              _scheduleAutoSave();
            },
          ),
          const SizedBox(height: 10),
          _buildMealRow(
            l10n: l10n,
            label: l10n.mealLunch,
            done: _lunchDone,
            riceBowls: _lunchRiceBowls,
            onDoneChanged: (value) {
              setState(() {
                _lunchDone = value;
                if (!value) _lunchRiceBowls = 0;
              });
              _scheduleAutoSave();
            },
            onRiceBowlsChanged: (value) {
              setState(() => _lunchRiceBowls = value);
              _scheduleAutoSave();
            },
          ),
          const SizedBox(height: 10),
          _buildMealRow(
            l10n: l10n,
            label: l10n.mealDinner,
            done: _dinnerDone,
            riceBowls: _dinnerRiceBowls,
            onDoneChanged: (value) {
              setState(() {
                _dinnerDone = value;
                if (!value) _dinnerRiceBowls = 0;
              });
              _scheduleAutoSave();
            },
            onRiceBowlsChanged: (value) {
              setState(() => _dinnerRiceBowls = value);
              _scheduleAutoSave();
            },
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _mealCoachingHeadline(l10n, mealStatus),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _mealCoachingBody(l10n, mealStatus),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                Text(
                  _mealXpLabel(l10n, mealStatus),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealRow({
    required AppLocalizations l10n,
    required String label,
    required bool done,
    required int riceBowls,
    required ValueChanged<bool> onDoneChanged,
    required ValueChanged<int> onRiceBowlsChanged,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                FilterChip(
                  selected: done,
                  onSelected: onDoneChanged,
                  label: Text(done ? l10n.mealDone : l10n.mealSkipped),
                  avatar: Icon(
                    done
                        ? Icons.check_circle_outline
                        : Icons.radio_button_unchecked,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 130,
            child: DropdownButtonFormField<int>(
              initialValue: done ? riceBowls : 0,
              items: MealCoachingService.riceBowlOptions
                  .where((value) => value == value.truncateToDouble())
                  .map((value) => value.toInt())
                  .map(
                    (value) => DropdownMenuItem<int>(
                      value: value,
                      child: Text(
                        value == 0
                            ? l10n.mealRiceNone
                            : l10n.mealRiceBowls(value),
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: done
                  ? (value) => onRiceBowlsChanged(value ?? 0)
                  : null,
              decoration: InputDecoration(
                labelText: l10n.mealRiceLabel,
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _mealCoachingHeadline(AppLocalizations l10n, MealStatus status) {
    return switch (status.completedMeals) {
      3 => l10n.mealCoachHeadlinePerfect,
      2 => l10n.mealCoachHeadlineAlmost,
      1 => l10n.mealCoachHeadlineNeedsMore,
      _ => l10n.mealCoachHeadlineStart,
    };
  }

  String _mealCoachingBody(AppLocalizations l10n, MealStatus status) {
    if (status.completedMeals >= 3 && status.totalRiceBowls >= 5) {
      return l10n.mealCoachBodySteady;
    }
    if (status.completedMeals >= 3) {
      return l10n.mealCoachBodyThreeMeals;
    }
    if (status.completedMeals == 2 && status.totalRiceBowls >= 3) {
      return l10n.mealCoachBodyTwoMealsSolid;
    }
    if (status.completedMeals == 2) {
      return l10n.mealCoachBodyTwoMealsLight;
    }
    if (status.completedMeals == 1) {
      return l10n.mealCoachBodyOneMeal;
    }
    return l10n.mealCoachBodyZeroMeal;
  }

  String _mealXpLabel(AppLocalizations l10n, MealStatus status) {
    if (status.completedMeals >= 3 && status.totalRiceBowls >= 5) {
      return l10n.mealXpFullBonus;
    }
    if (status.completedMeals >= 3) return l10n.mealXpFull;
    if (status.completedMeals >= 2) return l10n.mealXpPartial;
    return l10n.mealXpNeutral;
  }

  @override
  void dispose() {
    _disposing = true;
    _listeningSession++;
    _isListening = false;
    _listeningController = null;
    _sessionRecognizedWords = '';
    _sessionCommitted = true;
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
    _jumpRopeMinutesController.dispose();
    _jumpRopeNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.entry != null;
    final dateText = DateFormat('yyyy.MM.dd').format(_date);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final weatherStatusText = _weatherLoading
        ? (isKo ? '날씨 불러오는 중...' : 'Loading weather...')
        : _weatherSummary.trim().isNotEmpty
        ? _weatherSummary.trim()
        : _weatherAutoEnabled
        ? (isKo ? '자동으로 날씨 불러오기 대기' : 'Auto weather ready')
        : (isKo ? '위치 버튼으로 날씨 불러오기' : 'Tap location to load weather');
    final weatherHasValue = _weatherSummary.trim().isNotEmpty;
    final isMatchEntry = widget.entry?.isMatch ?? false;
    if (isMatchEntry) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: _attemptExit,
                    icon: const Icon(Icons.arrow_back),
                    tooltip: l10n.cancel,
                  ),
                ),
                const SizedBox(height: 24),
                WatchCartCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isKo
                            ? '시합 기록은 캘린더에서 관리합니다.'
                            : 'Match records are managed in Calendar.',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isKo
                            ? '훈련 노트에서는 시합 정보를 보여주지 않습니다. 시합 확인과 수정은 캘린더에서 진행해주세요.'
                            : 'Training notes no longer show match details. View and edit matches from Calendar.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: _confirmExitWithoutSave,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _weatherBackgroundColors(theme),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                onChanged: _scheduleAutoSave,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              IconButton(
                                onPressed: _attemptExit,
                                icon: const Icon(Icons.arrow_back),
                                tooltip: l10n.cancel,
                              ),
                              TextButton.icon(
                                onPressed:
                                    (_saveInProgress || _deleteInProgress)
                                    ? null
                                    : _save,
                                icon: const Icon(Icons.save_outlined, size: 18),
                                label: Text(l10n.save),
                              ),
                              if (isEdit)
                                TextButton.icon(
                                  onPressed:
                                      (_saveInProgress || _deleteInProgress)
                                      ? null
                                      : _confirmAndDelete,
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  label: Text(
                                    l10n.deleteEntry,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '${l10n.entryHeadline1} ${l10n.entryHeadline2}',
                            textAlign: TextAlign.left,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                            softWrap: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _buildFeatureActionButton(
                              icon: _fortuneEnabled
                                  ? Icons.auto_awesome
                                  : Icons.auto_awesome_outlined,
                              label: isKo ? '오늘의 운세' : 'Today fortune',
                              active: _fortuneEnabled,
                              onPressed: () =>
                                  unawaited(_handleFortuneButtonPressed()),
                            ),
                            _buildFeatureActionButton(
                              icon: _linkedBoardIds.isNotEmpty
                                  ? Icons.developer_board
                                  : Icons.developer_board_outlined,
                              label: isKo ? '훈련 스케치' : 'Training sketch',
                              active: _linkedBoardIds.isNotEmpty,
                              onPressed: _openTrainingBoardEditor,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(height: 4),
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
                                  const SizedBox(width: 8),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        constraints: const BoxConstraints(
                                          maxWidth: 150,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          color: weatherHasValue
                                              ? theme
                                                    .colorScheme
                                                    .primaryContainer
                                                    .withValues(alpha: 0.9)
                                              : theme
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                        ),
                                        child: Text(
                                          weatherStatusText,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: weatherHasValue
                                                    ? theme
                                                          .colorScheme
                                                          .onPrimaryContainer
                                                    : theme
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        constraints: const BoxConstraints(
                                          minWidth: 30,
                                          minHeight: 30,
                                        ),
                                        padding: EdgeInsets.zero,
                                        tooltip: isKo
                                            ? '현재 위치 날씨'
                                            : 'Use location weather',
                                        onPressed: _weatherLoading
                                            ? null
                                            : _useCurrentLocationWeather,
                                        icon: _weatherLoading
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : Icon(
                                                Icons.my_location,
                                                size: 18,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                      ),
                                    ],
                                  ),
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
                            minLines: 2,
                            maxLines: null,
                            decoration: InputDecoration(
                              labelText: isKo ? '다음 목표' : 'Next goal',
                              hintText: isKo
                                  ? '다음 훈련에서 집중할 목표를 적어보세요.'
                                  : 'Write the next goal for your next session.',
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
                          _buildAnimatedSection(
                            visible: _injury,
                            child: Column(
                              children: [
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
                                    onUpdated: (list) => setState(
                                      () => _injuryPartOptions = list,
                                    ),
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
                            ),
                          ),
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
                          _buildAnimatedSection(
                            visible: _liftingEnabled,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                            ),
                          ),
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
                            title: Text(isKo ? '줄넘기 기록' : 'Jump rope record'),
                            value: _jumpRopeEnabled,
                            onChanged: (value) {
                              setState(() => _jumpRopeEnabled = value);
                              _scheduleAutoSave();
                            },
                          ),
                          _buildAnimatedSection(
                            visible: _jumpRopeEnabled,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildEmphasizedField(
                                        controller: _jumpRopeController,
                                        enabled: _jumpRopeEnabled,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: isKo
                                              ? '줄넘기 횟수'
                                              : 'Jump rope count',
                                          hintText: '0',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildEmphasizedField(
                                        controller: _jumpRopeMinutesController,
                                        enabled: _jumpRopeEnabled,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: isKo
                                              ? '줄넘기 시간(분)'
                                              : 'Jump rope time (min)',
                                          hintText: '0',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildEmphasizedField(
                                  controller: _jumpRopeNoteController,
                                  enabled: _jumpRopeEnabled,
                                  minLines: 3,
                                  maxLines: 5,
                                  decoration: InputDecoration(
                                    labelText: isKo ? '메모' : 'Memo',
                                    hintText: isKo
                                        ? '줄넘기를 하면서 느낀 점을 적어보세요.'
                                        : 'Write what you felt during jump rope.',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
        ),
      ),
    );
  }

  Widget _buildAnimatedSection({required bool visible, required Widget child}) {
    return AnimatedSize(
      duration: AppMotion.base(context),
      curve: AppMotion.curveEnter,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: AppMotion.base(context),
        switchInCurve: AppMotion.curveEnter,
        switchOutCurve: AppMotion.curveExit,
        child: visible
            ? Padding(
                key: const ValueKey('section-open'),
                padding: const EdgeInsets.only(top: 4),
                child: child,
              )
            : const SizedBox.shrink(key: ValueKey('section-closed')),
      ),
    );
  }

  Widget _buildFeatureActionButton({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onPressed,
    bool emphasizePrimary = false,
  }) {
    final theme = Theme.of(context);
    final activeFg = emphasizePrimary
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.primary;
    final fg = active ? activeFg : theme.colorScheme.onSurfaceVariant;
    final bg = active
        ? (emphasizePrimary
              ? theme.colorScheme.primary
              : theme.colorScheme.primary.withValues(alpha: 0.12))
        : theme.colorScheme.surfaceContainerHighest;
    final border = active
        ? (emphasizePrimary
              ? theme.colorScheme.primary
              : theme.colorScheme.primary.withValues(alpha: 0.36))
        : theme.colorScheme.outline.withValues(alpha: 0.28);

    return AppPressableScale(
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          minimumSize: const Size(1, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          backgroundColor: bg,
          side: BorderSide(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: fg,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
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
    final showMic =
        controller == _goodPointsController ||
        controller == _improvementsController ||
        controller == _nextGoalController ||
        controller == _jumpRopeNoteController;
    final isListeningFor = _isListening && _listeningController == controller;
    final field = TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      enabled: enabled,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
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
    if (!mounted || _disposing) return;
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
        if (!mounted || _disposing) return;
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
        if (!mounted || _disposing) return;
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
          setState(() {
            _isListening = false;
            _listeningController = null;
            _sessionRecognizedWords = '';
            _sessionCommitted = false;
          });
        }
      },
      onError: (_) {
        if (!mounted || _disposing) return;
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
    if (!mounted || _disposing) return;
    final normalized = recognized.trim();
    if (normalized.isEmpty || _sessionCommitted) return;

    final currentText = controller.text;
    final normalizedCurrent = currentText.trimRight();
    if (normalizedCurrent.isNotEmpty &&
        normalizedCurrent.endsWith(normalized)) {
      _sessionCommitted = true;
      return;
    }

    final needsSpacing =
        !isKoreanLocale &&
        currentText.isNotEmpty &&
        !RegExp(r'\s$').hasMatch(currentText);
    final separator = needsSpacing ? ' ' : '';
    final nextText = '$currentText$separator$normalized';
    try {
      controller.value = controller.value.copyWith(
        text: nextText,
        selection: TextSelection.collapsed(offset: nextText.length),
        composing: TextRange.empty,
      );
    } on FlutterError {
      // Ignore late callbacks from speech recognition after screen teardown.
      return;
    }
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

  Future<void> _useCurrentLocationWeather({bool fromAuto = false}) async {
    if (_weatherLoading || !mounted || _disposing) return;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    setState(() => _weatherLoading = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!fromAuto) {
          await _showLocationServiceDialog(isKo);
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!fromAuto) {
          if (permission == LocationPermission.deniedForever) {
            await _showLocationPermissionDialog(isKo);
          } else {
            _showWeatherSnack(
              isKo ? '위치 권한이 필요합니다.' : 'Location permission is required.',
            );
          }
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      final place = await _resolvePlaceName(
        latitude: position.latitude,
        longitude: position.longitude,
        isKo: isKo,
      );
      final weather = await _fetchCurrentWeather(
        latitude: position.latitude,
        longitude: position.longitude,
        isKo: isKo,
      );
      if (!mounted || _disposing) return;
      setState(() {
        if (place.isNotEmpty) {
          _location = place;
        }
        _weatherCode = weather.$1;
        _weatherSummary = weather.$2;
      });
      _scheduleAutoSave();
      if (!_weatherAutoEnabled) {
        _weatherAutoEnabled = true;
        await widget.optionRepository.setValue(_weatherAutoEnabledKey, true);
      }
    } catch (_) {
      if (!mounted || _disposing) return;
      if (!fromAuto) {
        _showWeatherSnack(isKo ? '날씨를 불러오지 못했어요.' : 'Failed to load weather.');
      }
    } finally {
      if (mounted && !_disposing) {
        setState(() => _weatherLoading = false);
      }
    }
  }

  void _showWeatherSnack(String text) {
    if (!mounted || _disposing) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _showLocationServiceDialog(bool isKo) async {
    if (!mounted || _disposing) return;
    final open = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isKo ? '위치 서비스 필요' : 'Location Service Needed'),
        content: Text(
          isKo
              ? '현재 위치 날씨를 불러오려면 위치 서비스를 켜주세요.'
              : 'Please enable location services to load local weather.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isKo ? '닫기' : 'Close'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(isKo ? '설정 열기' : 'Open settings'),
          ),
        ],
      ),
    );
    if (open == true) {
      await Geolocator.openLocationSettings();
    }
  }

  Future<void> _showLocationPermissionDialog(bool isKo) async {
    if (!mounted || _disposing) return;
    final open = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isKo ? '위치 권한 필요' : 'Location Permission Needed'),
        content: Text(
          isKo
              ? '위치 권한이 꺼져 있어요. 설정에서 권한을 허용해주세요.'
              : 'Location permission is turned off. Allow it in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isKo ? '닫기' : 'Close'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(isKo ? '권한 설정 열기' : 'Open permission settings'),
          ),
        ],
      ),
    );
    if (open == true) {
      await Geolocator.openAppSettings();
    }
  }

  Future<String> _resolvePlaceName({
    required double latitude,
    required double longitude,
    required bool isKo,
  }) async {
    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/reverse', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'count': '1',
      'language': isKo ? 'ko' : 'en',
    });
    final response = await http.get(uri);
    if (response.statusCode != 200) return '';
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return '';
    final results = decoded['results'];
    if (results is! List || results.isEmpty) return '';
    final first = results.first;
    if (first is! Map<String, dynamic>) return '';
    final city = (first['city'] ?? first['name'] ?? '').toString().trim();
    final region = (first['admin1'] ?? '').toString().trim();
    final country = (first['country'] ?? '').toString().trim();
    final parts = <String>[
      if (city.isNotEmpty) city,
      if (region.isNotEmpty && region != city) region,
      if (country.isNotEmpty) country,
    ];
    return parts.take(2).join(', ');
  }

  Future<(int?, String)> _fetchCurrentWeather({
    required double latitude,
    required double longitude,
    required bool isKo,
  }) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'current': 'temperature_2m,weather_code',
      'timezone': 'auto',
    });
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      return (null, '');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return (null, '');
    final current = decoded['current'];
    if (current is! Map<String, dynamic>) return (null, '');
    final temp = (current['temperature_2m'] as num?)?.toDouble();
    final code = (current['weather_code'] as num?)?.toInt();
    final weatherText = _weatherLabelFromCode(code, isKo);
    if (temp == null) return (code, weatherText);
    return (code, '$weatherText ${temp.toStringAsFixed(1)}°C');
  }

  String _weatherLabelFromCode(int? code, bool isKo) {
    switch (code) {
      case 0:
        return isKo ? '맑음' : 'Clear';
      case 1:
      case 2:
      case 3:
        return isKo ? '구름' : 'Cloudy';
      case 45:
      case 48:
        return isKo ? '안개' : 'Fog';
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return isKo ? '이슬비' : 'Drizzle';
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
      case 80:
      case 81:
      case 82:
        return isKo ? '비' : 'Rain';
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return isKo ? '눈' : 'Snow';
      case 95:
      case 96:
      case 99:
        return isKo ? '천둥번개' : 'Thunderstorm';
      default:
        return isKo ? '날씨' : 'Weather';
    }
  }

  List<Color> _weatherBackgroundColors(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    switch (_weatherCode) {
      case 0:
        return isDark
            ? const [Color(0xFF3A2F12), Color(0xFF5A4518)]
            : const [Color(0xFFFFF1B8), Color(0xFFFFD666)];
      case 1:
      case 2:
      case 3:
        return isDark
            ? const [Color(0xFF1F2A3A), Color(0xFF2F3C52)]
            : const [Color(0xFFE6F4FF), Color(0xFFBAC8E0)];
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
      case 80:
      case 81:
      case 82:
        return isDark
            ? const [Color(0xFF1B2636), Color(0xFF2B384A)]
            : const [Color(0xFFD6E4FF), Color(0xFFA5B4D4)];
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return isDark
            ? const [Color(0xFF26313F), Color(0xFF3A475A)]
            : const [Color(0xFFF5F7FA), Color(0xFFDCE3EE)];
      case 95:
      case 96:
      case 99:
        return isDark
            ? const [Color(0xFF1A2030), Color(0xFF121826)]
            : const [Color(0xFF3C4A68), Color(0xFF232D42)];
      default:
        return [theme.scaffoldBackgroundColor, theme.scaffoldBackgroundColor];
    }
  }

  String _withWeatherInNotes(String notes, bool isKo) {
    final weather = _weatherSummary.trim();
    if (weather.isEmpty) return notes;
    final lines = notes
        .split('\n')
        .map((line) => line.trimRight())
        .where((line) => line.isNotEmpty)
        .where(
          (line) => !line.startsWith('[Weather]') && !line.startsWith('[날씨]'),
        )
        .toList(growable: true);
    lines.add(isKo ? '[날씨] $weather' : '[Weather] $weather');
    return lines.join('\n');
  }

  Future<void> _handleFortuneButtonPressed() async {
    if (!mounted || _disposing) return;
    FocusScope.of(context).unfocus();
    if (!_fortuneEnabled) {
      setState(() => _fortuneEnabled = true);
      _scheduleAutoSave();
    }
    try {
      await _showTodayFortuneInNote(forceShow: true);
    } catch (_) {
      if (!mounted || _disposing) return;
      final isKo = Localizations.localeOf(context).languageCode == 'ko';
      _showWeatherSnack(
        isKo ? '운세 화면을 여는 중 문제가 생겼어요.' : 'Failed to open fortune.',
      );
    }
  }

  Future<void> _showTodayFortuneInNote({bool forceShow = false}) async {
    if (!_fortuneEnabled && !forceShow) return;
    if (!mounted || _disposing) return;
    if (_cachedFortuneComment.trim().isNotEmpty) {
      await _showFortuneRevealDialog(_cachedFortuneComment);
      return;
    }
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final profile = PlayerProfileService(widget.optionRepository).load();
    final allEntries = await widget.trainingService.allEntries();
    if (!mounted || _disposing) return;
    final goodPoints = _goodPointsController.text.trim();
    final improvements = _improvementsController.text.trim();
    final notes = _withWeatherInNotes(improvements, isKo);
    final draft = TrainingEntry(
      date: DateTime(_date.year, _date.month, _date.day),
      durationMinutes: _durationMinutes,
      intensity: _intensity,
      type: _type,
      mood: _mood,
      injury: _injury,
      notes: notes,
      location: _location,
      program: _type,
      drills: _drillsController.text.trim(),
      club: '',
      injuryPart: _injury ? _injuryPartController.text.trim() : '',
      painLevel: _injury ? _parseInt(_painController.text) : null,
      rehab: _injury ? _rehab : false,
      goal: '',
      feedback: goodPoints,
      heightCm: profile.heightCm,
      weightKg: profile.weightKg,
      imagePath: _imagePaths.isNotEmpty ? _imagePaths.first : '',
      imagePaths: _imagePaths,
      status: _status,
      liftingByPart: const <String, int>{},
      goalFocuses: _selectedDailyGoals.toList()..sort(),
      goodPoints: goodPoints,
      improvements: improvements,
      nextGoal: '',
      createdAt: DateTime.now(),
      jumpRopeCount: _jumpRopeEnabled
          ? (_parseInt(_jumpRopeController.text.trim()) ?? 0)
          : 0,
      jumpRopeMinutes: _jumpRopeEnabled
          ? (_parseInt(_jumpRopeMinutesController.text.trim()) ?? 0)
          : 0,
      jumpRopeEnabled: _jumpRopeEnabled,
      jumpRopeNote: _jumpRopeEnabled ? _jumpRopeNoteController.text.trim() : '',
      breakfastDone: _breakfastDone,
      breakfastRiceBowls: _breakfastDone ? _breakfastRiceBowls : 0,
      lunchDone: _lunchDone,
      lunchRiceBowls: _lunchDone ? _lunchRiceBowls : 0,
      dinnerDone: _dinnerDone,
      dinnerRiceBowls: _dinnerDone ? _dinnerRiceBowls : 0,
    );
    final fortune = _fortuneService.generateResult(
      entry: draft,
      profile: profile,
      history: allEntries,
      isKo: isKo,
    );
    _cachedFortuneComment = fortune.fortuneText;
    _cachedFortuneRecommendation = fortune.recommendationText;
    _cachedFortuneRecommendedProgram = fortune.recommendedProgram;
    if (!mounted) return;
    await Future<void>.delayed(Duration.zero);
    if (!mounted || _disposing) return;
    await _showFortuneRevealDialog(_cachedFortuneComment);
  }

  Future<void> _openTrainingBoardEditor() async {
    final allBoards = _trainingBoardService.allBoards();
    final recentBoardId =
        widget.optionRepository.getValue<String>(_recentBoardIdKey) ?? '';
    final hasRecentBoard = allBoards.any((board) => board.id == recentBoardId);
    final selectedIds = await Navigator.of(context).push<List<String>>(
      AppPageRoute(
        builder: (_) => TrainingMethodBoardScreen(
          boardTitle: '',
          initialLayoutJson: '',
          optionRepository: widget.optionRepository,
          initialSelectedBoardIds: _linkedBoardIds.toList(growable: false),
          initialBoardId: _linkedBoardIds.isNotEmpty
              ? _linkedBoardIds.first
              : (hasRecentBoard
                    ? recentBoardId
                    : (allBoards.isNotEmpty ? allBoards.first.id : null)),
        ),
      ),
    );
    if (!mounted || selectedIds == null) return;
    if (!mounted) return;
    setState(() {
      _linkedBoardIds
        ..clear()
        ..addAll(selectedIds);
      _syncDrillsPayloadFromBoardLinks();
    });
    if (selectedIds.isNotEmpty) {
      await widget.optionRepository.setValue(
        _recentBoardIdKey,
        selectedIds.first,
      );
    }
    _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    if (widget.entry == null) return;
    if (_saveInProgress) return;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted || _disposing) return;
      _save(popAfterSave: false, silent: true);
    });
  }

  Future<void> _save({bool popAfterSave = true, bool silent = false}) async {
    if (!mounted || _disposing) return;
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
      _syncDrillsPayloadFromBoardLinks();
      final injuryPart = _injury ? _injuryPartController.text.trim() : '';
      final painLevel = _injury ? _parseInt(_painController.text) : null;
      final durationMinutes = _durationMinutes;
      final profile = PlayerProfileService(widget.optionRepository).load();
      final allEntries = await widget.trainingService.allEntries();
      if (!mounted || _disposing) return;
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
      final notesWithWeather = _withWeatherInNotes(improvements, isKo);
      final createdAt = widget.entry?.createdAt ?? DateTime.now();
      final jumpRopeCount = _jumpRopeEnabled
          ? (_parseInt(_jumpRopeController.text.trim())?.clamp(0, 1000000) ?? 0)
          : 0;
      final jumpRopeMinutes = _jumpRopeEnabled
          ? (_parseInt(
                  _jumpRopeMinutesController.text.trim(),
                )?.clamp(0, 1000000) ??
                0)
          : 0;
      final jumpRopeNote = _jumpRopeEnabled
          ? _jumpRopeNoteController.text.trim()
          : '';

      final draftEntry = TrainingEntry(
        date: DateTime(_date.year, _date.month, _date.day),
        durationMinutes: durationMinutes,
        intensity: _intensity,
        type: _type,
        mood: _mood,
        injury: _injury,
        notes: notesWithWeather,
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
        jumpRopeMinutes: jumpRopeMinutes,
        jumpRopeEnabled: _jumpRopeEnabled,
        jumpRopeNote: jumpRopeNote,
        breakfastDone: _breakfastDone,
        breakfastRiceBowls: _breakfastDone ? _breakfastRiceBowls : 0,
        lunchDone: _lunchDone,
        lunchRiceBowls: _lunchDone ? _lunchRiceBowls : 0,
        dinnerDone: _dinnerDone,
        dinnerRiceBowls: _dinnerDone ? _dinnerRiceBowls : 0,
      );
      final shouldShowFortuneOnSave = popAfterSave && widget.entry == null;
      final shouldPersistFortune = _fortuneEnabled || shouldShowFortuneOnSave;
      if (shouldPersistFortune && _cachedFortuneComment.trim().isEmpty) {
        final generatedFortune = _fortuneService.generateResult(
          entry: draftEntry,
          profile: profile,
          history: allEntries,
          isKo: isKo,
        );
        _cachedFortuneComment = generatedFortune.fortuneText;
        _cachedFortuneRecommendation = generatedFortune.recommendationText;
        _cachedFortuneRecommendedProgram = generatedFortune.recommendedProgram;
      }
      final fortuneComment = shouldPersistFortune ? _cachedFortuneComment : '';
      final fortuneRecommendation = shouldPersistFortune
          ? _cachedFortuneRecommendation
          : '';
      final fortuneRecommendedProgram = shouldPersistFortune
          ? _cachedFortuneRecommendedProgram
          : '';

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
        fortuneRecommendation: fortuneRecommendation,
        fortuneRecommendedProgram: fortuneRecommendedProgram,
        goalFocuses: draftEntry.goalFocuses,
        goodPoints: draftEntry.goodPoints,
        improvements: draftEntry.improvements,
        nextGoal: draftEntry.nextGoal,
        createdAt: draftEntry.createdAt,
        jumpRopeCount: draftEntry.jumpRopeCount,
        jumpRopeMinutes: draftEntry.jumpRopeMinutes,
        jumpRopeEnabled: draftEntry.jumpRopeEnabled,
        jumpRopeNote: draftEntry.jumpRopeNote,
        opponentTeam: draftEntry.opponentTeam,
        scoredGoals: draftEntry.scoredGoals,
        concededGoals: draftEntry.concededGoals,
        playerGoals: draftEntry.playerGoals,
        playerAssists: draftEntry.playerAssists,
        minutesPlayed: draftEntry.minutesPlayed,
        breakfastDone: draftEntry.breakfastDone,
        breakfastRiceBowls: draftEntry.breakfastRiceBowls,
        lunchDone: draftEntry.lunchDone,
        lunchRiceBowls: draftEntry.lunchRiceBowls,
        dinnerDone: draftEntry.dinnerDone,
        dinnerRiceBowls: draftEntry.dinnerRiceBowls,
      );

      final playerLevelService = PlayerLevelService(widget.optionRepository);
      PlayerLevelAward? levelAward;
      if (widget.entry == null) {
        await widget.trainingService.add(entry);
        _persistedEntryForXp = entry;
        levelAward = await playerLevelService.awardForTrainingLog(
          entry: entry,
          existingEntries: allEntries,
        );
        final reminderService = TrainingPlanReminderService(
          widget.optionRepository,
          widget.settingsService,
        );
        await reminderService.recordTrainingLog(entry.createdAt);
        await reminderService.showXpGainAlert(
          gainedXp: levelAward.gainedXp,
          totalXp: levelAward.after.totalXp,
          isKo: isKo,
          sourceLabel: isKo ? '훈련 기록' : 'Training log',
        );
        if (levelAward.didLevelUp) {
          await reminderService.showLevelUpAlert(
            level: levelAward.after.level,
            isKo: isKo,
          );
        }
        if (!mounted) return;
        if (popAfterSave) {
          AppFeedback.showSuccess(
            context,
            text: _buildSaveFeedback(isKo: isKo, levelAward: levelAward),
          );
        }
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
        final previousEntryForXp = _persistedEntryForXp ?? widget.entry!;
        levelAward = await playerLevelService.awardForTrainingLogUpdate(
          previousEntry: previousEntryForXp,
          updatedEntry: entry,
        );
        _persistedEntryForXp = entry;
        if (levelAward.gainedXp > 0) {
          final reminderService = TrainingPlanReminderService(
            widget.optionRepository,
            widget.settingsService,
          );
          await reminderService.showXpGainAlert(
            gainedXp: levelAward.gainedXp,
            totalXp: levelAward.after.totalXp,
            isKo: isKo,
            sourceLabel: isKo ? '훈련 기록 수정' : 'Training update',
          );
          if (levelAward.didLevelUp) {
            await reminderService.showLevelUpAlert(
              level: levelAward.after.level,
              isKo: isKo,
            );
          }
        }
      }
      _initialSnapshot = _formSnapshot();
      if (!mounted) return;
      final fortuneToShow = shouldShowFortuneOnSave
          ? _cachedFortuneComment
          : '';
      if (fortuneToShow.trim().isNotEmpty && popAfterSave) {
        await _showFortuneRevealDialog(fortuneToShow);
        if (!mounted) return;
      }
      if (popAfterSave && widget.entry == null && levelAward.didLevelUp) {
        final leveledUpAward = levelAward;
        final customRewardName = PlayerLevelService(
          widget.optionRepository,
        ).customRewardNameForLevel(leveledUpAward.after.level);
        await showLevelUpCelebrationDialog(
          context,
          award: leveledUpAward,
          isKo: isKo,
          customRewardName: customRewardName,
          onClaimReward: () async {
            final claim = await PlayerLevelService(
              widget.optionRepository,
            ).claimRewardForLevel(leveledUpAward.after.level);
            if (!mounted || claim == null) return;
            final rewardName = claim.customRewardName.trim().isNotEmpty
                ? claim.customRewardName
                : (isKo ? claim.reward.nameKo : claim.reward.nameEn);
            AppFeedback.showSuccess(
              context,
              text: isKo ? '$rewardName 선물을 받았어요.' : 'Claimed $rewardName.',
            );
          },
        );
        if (!mounted) return;
      }
      if (popAfterSave) {
        if (widget.entry != null) {
          AppFeedback.showSuccess(
            context,
            text: levelAward.gainedXp > 0
                ? _buildSaveFeedback(isKo: isKo, levelAward: levelAward)
                : (isKo ? '훈련노트를 저장했어요.' : 'Training note saved.'),
          );
        }
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

  String _buildSaveFeedback({
    required bool isKo,
    required PlayerLevelAward levelAward,
  }) {
    final base = isKo ? '훈련노트를 저장했어요.' : 'Training note saved.';
    if (levelAward.gainedXp == 0) return base;
    final xpText = levelAward.gainedXp > 0
        ? (isKo
              ? '+${levelAward.gainedXp} XP 획득'
              : '+${levelAward.gainedXp} XP earned')
        : (isKo
              ? '${levelAward.gainedXp} XP 차감'
              : '${levelAward.gainedXp} XP deducted');
    if (!levelAward.didLevelUp) {
      return '$base $xpText';
    }
    final levelName = PlayerLevelService.levelName(
      levelAward.after.level,
      isKo,
    );
    return isKo
        ? '$base $xpText · Lv.${levelAward.after.level} $levelName 달성'
        : '$base $xpText · Reached Lv.${levelAward.after.level} $levelName';
  }

  Future<void> _showFortuneRevealDialog(String fortuneComment) async {
    if (fortuneComment.trim().isEmpty) return;
    if (!mounted || _disposing) return;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final l10n = AppLocalizations.of(context)!;
    final sections = FortuneSections.fromComment(fortuneComment);
    final formattedPoolSize = LocalFortuneService.formatFortunePoolCount(
      Localizations.localeOf(context).toLanguageTag(),
    );
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _fortuneDialogBody(
        contextForClose: dialogContext,
        isKo: isKo,
        sections: sections,
        l10n: l10n,
        formattedPoolSize: formattedPoolSize,
      ),
    );
  }

  Widget _fortuneDialogBody({
    required BuildContext contextForClose,
    required bool isKo,
    required FortuneSections sections,
    required AppLocalizations l10n,
    required String formattedPoolSize,
  }) {
    final dialogMaxHeight = MediaQuery.sizeOf(context).height * 0.82;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560, maxHeight: dialogMaxHeight),
        child: SingleChildScrollView(
          child: FortuneCard(
            sections: sections,
            title: l10n.fortuneDialogTitle,
            subtitle: l10n.fortuneDialogSubtitle,
            luckyInfoTitle: l10n.fortuneDialogLuckyInfoTitle,
            overviewTitle: l10n.fortuneDialogOverviewTitle,
            overallFortuneLabel: l10n.fortuneDialogOverallFortuneLabel,
            overallFortuneCount: l10n.fortuneDialogOverallFortuneCount(
              sections.bodyLines.length,
            ),
            luckyInfoLabel: l10n.fortuneDialogLuckyInfoLabel,
            luckyInfoCount: l10n.fortuneDialogLuckyInfoCount(
              sections.luckyInfoLines.length,
            ),
            poolSizeLabel: l10n.fortuneDialogPoolSizeLabel,
            poolSizeValue: l10n.fortuneDialogPoolSizeCount(formattedPoolSize),
            actionLabel: l10n.fortuneDialogAction,
            isKo: isKo,
            showOverview: false,
            onActionPressed: () => Navigator.of(contextForClose).pop(),
          ),
        ),
      ),
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
      final isKo = Localizations.localeOf(context).languageCode == 'ko';
      AppFeedback.showUndo(
        context,
        text: isKo ? '기록을 삭제했어요.' : 'Entry deleted.',
        undoLabel: isKo ? '되돌리기' : 'Undo',
        onUndo: () {
          unawaited(widget.trainingService.add(target));
        },
      );
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
