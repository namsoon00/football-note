import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../application/family_access_service.dart';
import '../../application/local_fortune_service.dart';
import '../../application/meal_coaching_service.dart';
import '../../application/localized_option_defaults.dart';
import '../../application/player_level_service.dart';
import '../../application/parent_shared_feedback_service.dart';
import '../../application/training_plan_reminder_service.dart';
import '../../application/training_service.dart';
import '../../application/training_board_service.dart';
import '../../application/player_profile_service.dart';
import '../../application/weather_location_service.dart';
import '../../application/weather_shared_resource.dart';
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
import '../widgets/info_banner.dart';
import '../widgets/level_up_dialog.dart';
import '../theme/app_motion.dart';
import 'parent_feedback_screen.dart';
import 'training_method_board_screen.dart';

enum EntryFormInitialFocusTarget { lifting, jumpRope }

class EntryFormInitialPlanContext {
  final DateTime scheduledAt;
  final String program;
  final int durationMinutes;
  final String location;
  final String note;

  const EntryFormInitialPlanContext({
    required this.scheduledAt,
    this.program = '',
    this.durationMinutes = 0,
    this.location = '',
    this.note = '',
  });
}

class _DailyGoalVisual {
  final IconData icon;
  final IconData selectedIcon;
  final Color color;

  const _DailyGoalVisual({
    required this.icon,
    required this.selectedIcon,
    required this.color,
  });
}

class EntryFormScreen extends StatefulWidget {
  final TrainingService trainingService;
  final OptionRepository optionRepository;
  final LocaleService localeService;
  final SettingsService settingsService;
  final BackupService? driveBackupService;
  final TrainingEntry? entry;
  final DateTime? initialDate;
  final EntryFormInitialPlanContext? initialPlanContext;
  final EntryFormInitialFocusTarget? initialFocusTarget;
  final bool initialConditioningOnly;
  final bool initialEnableLifting;
  final bool initialEnableJumpRope;
  final bool initialFocusViewOnly;
  final bool initialOpenTrainingBoardEditor;
  final bool closeAfterInitialTrainingBoardEditor;

  const EntryFormScreen({
    super.key,
    required this.trainingService,
    required this.optionRepository,
    required this.localeService,
    required this.settingsService,
    this.driveBackupService,
    this.entry,
    this.initialDate,
    this.initialPlanContext,
    this.initialFocusTarget,
    this.initialConditioningOnly = false,
    this.initialEnableLifting = false,
    this.initialEnableJumpRope = false,
    this.initialFocusViewOnly = false,
    this.initialOpenTrainingBoardEditor = false,
    this.closeAfterInitialTrainingBoardEditor = false,
  });

  @override
  State<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends State<EntryFormScreen> {
  static const String _recentBoardIdKey = 'recent_board_id';
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
  final _liftingMinutesController = TextEditingController();
  final _jumpRopeController = TextEditingController();
  final _jumpRopeMinutesController = TextEditingController();
  final _jumpRopeNoteController = TextEditingController();
  final _liftingFieldFocusNode = FocusNode();
  final _jumpRopeFieldFocusNode = FocusNode();
  final _liftingFieldKey = GlobalKey();
  final _jumpRopeFieldKey = GlobalKey();
  final _speech = stt.SpeechToText();
  final _fortuneService = LocalFortuneService();
  final _mealCoachingService = const MealCoachingService();
  late final TrainingBoardService _trainingBoardService;
  late final ParentSharedFeedbackService _parentSharedFeedbackService;
  TextEditingController? _listeningController;
  String _sessionRecognizedWords = '';
  bool _sessionCommitted = false;
  int _listeningSession = 0;
  bool _isListening = false;
  bool _speechInitialized = false;
  bool _speechAvailable = false;
  bool _disposing = false;

  List<String> _programOptions = [];
  List<String> _dailyGoalOptions = [];
  List<int> _durationOptions = [];
  List<String> _injuryPartOptions = [];
  final Set<String> _selectedDailyGoals = <String>{};
  bool _optionsLoaded = false;
  Timer? _autoSaveTimer;
  bool _autoSaving = false;
  bool _saveInProgress = false;
  bool _deleteInProgress = false;
  bool _manualSaveQueuedAfterAutoSave = false;
  int? _editingKey;
  TrainingEntry? _persistedEntryForXp;
  final Set<String> _linkedBoardIds = <String>{};
  String _initialSnapshot = '';
  bool _didHandleInitialBoardOpen = false;
  bool _didRequestInitialFocus = false;

  DateTime _date = DateTime.now();
  int _durationMinutes = 60;
  int _intensity = 3;
  int _mood = 3;
  String _type = '';
  final Map<String, int> _trainingProgramMinutes = <String, int>{};
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
  final List<String> _imagePaths = [];
  bool _weatherLoading = false;
  String _weatherSummary = '';
  String _weatherLocation = '';
  int? _weatherCode;
  String _cachedFortuneComment = '';
  String _cachedFortuneRecommendation = '';
  String _cachedFortuneRecommendedProgram = '';
  String _savedParentFeedback = '';
  String _savedParentFeedbackReaction = '';
  DateTime? _savedParentFeedbackUpdatedAt;

  @override
  void initState() {
    super.initState();
    _trainingBoardService = TrainingBoardService(widget.optionRepository);
    _parentSharedFeedbackService = ParentSharedFeedbackService(
      widget.optionRepository,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_optionsLoaded) return;
    _optionsLoaded = true;
    final l10n = AppLocalizations.of(context)!;

    _programOptions = _loadOptions(
      key: 'programs',
      defaults: [
        l10n.defaultProgram1,
        l10n.defaultProgram2,
        l10n.defaultProgram3,
        l10n.defaultProgram4,
        l10n.challengeLiftingLabel,
        l10n.challengeJumpRopeLabel,
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
      _goodPointsController.text =
          entry.goodPoints.isNotEmpty ? entry.goodPoints : entry.feedback;
      _improvementsController.text = entry.improvements.isNotEmpty
          ? entry.improvements
          : _stripWeatherFromNotes(entry.notes);
      _nextGoalController.text =
          entry.nextGoal.isNotEmpty ? entry.nextGoal : entry.goal;
      _linkedBoardIds
        ..clear()
        ..addAll(TrainingBoardLinkCodec.decodeBoardIds(entry.drills));
      _syncDrillsPayloadFromBoardLinks();
      _intensity = entry.intensity;
      _mood = entry.mood;
      _type = _initSelection('programs', _programOptions, entry.program);
      _trainingProgramMinutes
        ..clear()
        ..addAll(
          _initialTrainingProgramMinutes(
            entry,
            fallbackProgram: _type,
            fallbackMinutes: _durationMinutes,
          ),
        );
      _status = entry.status.isEmpty ? 'normal' : entry.status;
      _injury = entry.injury;
      _injuryPartController.text = entry.injuryPart;
      _painController.text = entry.painLevel?.toString() ?? '';
      _rehab = entry.rehab;
      _liftingEnabled = entry.liftingMinutes > 0 ||
          entry.liftingByPart.values.any((value) => value > 0);
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
      _liftingMinutesController.text =
          entry.liftingMinutes > 0 ? entry.liftingMinutes.toString() : '';
      _jumpRopeController.text =
          entry.jumpRopeCount > 0 ? entry.jumpRopeCount.toString() : '';
      _jumpRopeMinutesController.text =
          entry.jumpRopeMinutes > 0 ? entry.jumpRopeMinutes.toString() : '';
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
      _weatherLocation = entry.location.trim();
      final parentFeedback = _parentSharedFeedbackService.feedbackForEntry(
        entry,
      );
      _savedParentFeedback = parentFeedback?.message ?? '';
      _savedParentFeedbackReaction = parentFeedback?.reaction ?? '';
      _savedParentFeedbackUpdatedAt = parentFeedback?.updatedAt;
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
      if (widget.initialConditioningOnly) {
        _durationMinutes = _initIntSelection('durations', _durationOptions, 0);
      }
      _intensity = 3;
      _mood = 3;
      _type = _defaultString('default_program', _programOptions, 'programs');
      _trainingProgramMinutes
        ..clear()
        ..addAll(
          _durationMinutes > 0
              ? <String, int>{_type.trim(): _durationMinutes}
              : const <String, int>{},
        );
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
      _weatherLocation = '';
      _savedParentFeedback = '';
      _savedParentFeedbackReaction = '';
      _savedParentFeedbackUpdatedAt = null;
      final planContext = widget.initialPlanContext;
      if (planContext != null) {
        _date = DateTime(
          planContext.scheduledAt.year,
          planContext.scheduledAt.month,
          planContext.scheduledAt.day,
        );
        if (planContext.program.trim().isNotEmpty) {
          _type = _initSelection(
            'programs',
            _programOptions,
            planContext.program.trim(),
          );
          _trainingProgramMinutes
            ..clear()
            ..addAll(
              _durationMinutes > 0
                  ? <String, int>{_type.trim(): _durationMinutes}
                  : const <String, int>{},
            );
        }
        if (planContext.durationMinutes > 0) {
          _durationMinutes = _initIntSelection(
            'durations',
            _durationOptions,
            planContext.durationMinutes,
          );
          _trainingProgramMinutes
            ..clear()
            ..addAll(
              _type.trim().isNotEmpty
                  ? <String, int>{_type.trim(): _durationMinutes}
                  : const <String, int>{},
            );
        }
      }
      unawaited(_applyLatestEntryDefaults());
    }
    _applyInitialFocusTarget();
    var mergedInitialPlanIntoExistingEntry = false;
    if (widget.entry != null && widget.initialPlanContext != null) {
      _initialSnapshot = _formSnapshot();
      mergedInitialPlanIntoExistingEntry =
          _mergeInitialPlanContextIntoExistingEntry(widget.initialPlanContext!);
    } else {
      _initialSnapshot = _formSnapshot();
    }
    if (mergedInitialPlanIntoExistingEntry) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scheduleAutoSave();
      });
    }
    if (widget.initialOpenTrainingBoardEditor && !_didHandleInitialBoardOpen) {
      _didHandleInitialBoardOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(
          _openTrainingBoardEditor(
            closeHostAfterReturn: widget.closeAfterInitialTrainingBoardEditor,
          ),
        );
      });
    }
    if (widget.entry == null && _weatherSummary.trim().isEmpty) {
      final appliedCachedWeather = _applyCachedHomeWeather(
        WeatherSharedResource.cachedSnapshot(
          locale: Localizations.localeOf(context),
        ),
      );
      if (appliedCachedWeather) {
        _initialSnapshot = _formSnapshot();
      }
    }
  }

  bool _mergeInitialPlanContextIntoExistingEntry(
    EntryFormInitialPlanContext planContext,
  ) {
    if (planContext.durationMinutes <= 0) return false;
    final program = planContext.program.trim().isNotEmpty
        ? planContext.program.trim()
        : _type.trim();
    if (program.isEmpty) return false;
    _ensureProgramOptions(<String>[program]);
    _trainingProgramMinutes[program] =
        (_trainingProgramMinutes[program] ?? 0) + planContext.durationMinutes;
    if (_type.trim().isEmpty) {
      _type = program;
    }
    _syncTotalDurationFromPrograms();
    return true;
  }

  void _applyInitialFocusTarget() {
    if (widget.initialEnableLifting ||
        widget.initialFocusTarget == EntryFormInitialFocusTarget.lifting) {
      _liftingEnabled = true;
    }
    if (widget.initialEnableJumpRope ||
        widget.initialFocusTarget == EntryFormInitialFocusTarget.jumpRope) {
      _jumpRopeEnabled = true;
    }
    if (widget.initialFocusTarget == null || _didRequestInitialFocus) {
      return;
    }
    _didRequestInitialFocus = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_focusInitialTarget());
    });
  }

  Future<void> _focusInitialTarget() async {
    final targetFocusNode = switch (widget.initialFocusTarget) {
      EntryFormInitialFocusTarget.lifting => _liftingFieldFocusNode,
      EntryFormInitialFocusTarget.jumpRope => _jumpRopeFieldFocusNode,
      null => null,
    };
    final targetContext = switch (widget.initialFocusTarget) {
      EntryFormInitialFocusTarget.lifting => _liftingFieldKey.currentContext,
      EntryFormInitialFocusTarget.jumpRope => _jumpRopeFieldKey.currentContext,
      null => null,
    };
    if (targetFocusNode == null) {
      return;
    }
    if (targetContext == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_focusInitialTarget());
      });
      return;
    }
    if (widget.initialFocusViewOnly) {
      FocusManager.instance.primaryFocus?.unfocus();
    } else {
      targetFocusNode.requestFocus();
    }
    await Scrollable.ensureVisible(
      targetContext,
      alignment: 0.24,
      duration: AppMotion.base(context),
      curve: AppMotion.curveEnter,
    );
  }

  bool _applyCachedHomeWeather(WeatherSharedSnapshot? cachedSnapshot) {
    if (cachedSnapshot == null) return false;
    if (cachedSnapshot.summary.trim().isEmpty &&
        cachedSnapshot.weatherCode == null) {
      return false;
    }
    _weatherSummary = cachedSnapshot.summary.trim();
    _weatherLocation = cachedSnapshot.location.trim();
    _weatherCode = cachedSnapshot.weatherCode;
    return true;
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

  String _trainingEntryProgramLabel(TrainingEntry entry) {
    final programs = entry.effectiveTrainingProgramMinutes.keys
        .map((program) => program.trim())
        .where((program) => program.isNotEmpty)
        .join(', ');
    if (programs.isNotEmpty) return programs;
    return entry.program.trim();
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
      title: _trainingEntryProgramLabel(entry).isNotEmpty
          ? _trainingEntryProgramLabel(entry)
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
      _injuryPartController.text.trim(),
      _painController.text.trim(),
      _goodPointsController.text.trim(),
      _improvementsController.text.trim(),
      _nextGoalController.text.trim(),
      _fortuneEnabled.toString(),
      _weatherSummary.trim(),
      _weatherLocation.trim(),
      _jumpRopeController.text.trim(),
      _jumpRopeMinutesController.text.trim(),
      _jumpRopeEnabled.toString(),
      _jumpRopeNoteController.text.trim(),
      _liftingMinutesController.text.trim(),
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
      _trainingProgramMinutesSnapshot(),
    ].join('|');
  }

  Map<String, int> _initialTrainingProgramMinutes(
    TrainingEntry entry, {
    required String fallbackProgram,
    required int fallbackMinutes,
  }) {
    final stored = _normalizeProgramMinutes(entry.trainingProgramMinutes);
    if (stored.isNotEmpty) {
      _ensureProgramOptions(stored.keys);
      return stored;
    }
    final program = fallbackProgram.trim();
    if (program.isEmpty || fallbackMinutes <= 0) {
      return const <String, int>{};
    }
    return <String, int>{program: fallbackMinutes};
  }

  void _ensureProgramOptions(Iterable<String> programs) {
    var updated = false;
    for (final rawProgram in programs) {
      final program = rawProgram.trim();
      if (program.isEmpty || _programOptions.contains(program)) continue;
      _programOptions.add(program);
      updated = true;
    }
    if (updated) {
      widget.optionRepository.saveOptions('programs', _programOptions);
    }
  }

  Map<String, int> _persistedTrainingProgramMinutes() {
    final normalized = _normalizeProgramMinutes(_trainingProgramMinutes);
    if (normalized.isNotEmpty) return normalized;
    final program = _type.trim();
    if (program.isEmpty || _durationMinutes <= 0) {
      return const <String, int>{};
    }
    return <String, int>{program: _durationMinutes};
  }

  Map<String, int> _normalizeProgramMinutes(Map<String, int> source) {
    final normalized = <String, int>{};
    for (final entry in source.entries) {
      final program = entry.key.trim();
      final minutes = entry.value;
      if (program.isEmpty || minutes <= 0) continue;
      normalized[program] = (normalized[program] ?? 0) + minutes;
    }
    return normalized;
  }

  int _trainingProgramMinutesTotal(Map<String, int> source) {
    return source.values
        .where((minutes) => minutes > 0)
        .fold<int>(0, (sum, minutes) => sum + minutes);
  }

  String _trainingProgramMinutesSnapshot() {
    final keys = _trainingProgramMinutes.keys
        .map((program) => program.trim())
        .where((program) => program.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return keys
        .map((program) => '$program:${_trainingProgramMinutes[program] ?? 0}')
        .join(',');
  }

  void _addTrainingProgramDuration() {
    final nextProgram = _programOptions.firstWhere(
      (program) => !_trainingProgramMinutes.containsKey(program),
      orElse: () => _type.trim().isNotEmpty
          ? _type.trim()
          : (_programOptions.isEmpty ? '' : _programOptions.first),
    );
    if (nextProgram.trim().isEmpty) return;
    _trainingProgramMinutes.putIfAbsent(nextProgram, () => 0);
  }

  void _changeTrainingProgramDurationProgram(
    String currentProgram,
    String nextProgram,
  ) {
    final current = currentProgram.trim();
    final next = nextProgram.trim();
    if (current.isEmpty || next.isEmpty || current == next) return;
    final minutes = _trainingProgramMinutes.remove(current) ?? 0;
    _trainingProgramMinutes[next] =
        (_trainingProgramMinutes[next] ?? 0) + minutes;
    if (_type.trim() == current) {
      _type = next;
    }
  }

  void _changeTrainingProgramDurationMinutes(String program, int minutes) {
    final key = program.trim();
    if (key.isEmpty) return;
    _trainingProgramMinutes[key] = minutes;
    _syncTotalDurationFromPrograms();
  }

  void _removeTrainingProgramDuration(String program) {
    final key = program.trim();
    if (key.isEmpty) return;
    _trainingProgramMinutes.remove(key);
    if (_type.trim() == key && _trainingProgramMinutes.isNotEmpty) {
      _type = _trainingProgramMinutes.keys.first;
    }
    _syncTotalDurationFromPrograms();
  }

  void _syncTotalDurationFromPrograms() {
    final total = _trainingProgramMinutesTotal(_trainingProgramMinutes);
    _durationMinutes = total > 0
        ? _initIntSelection('durations', _durationOptions, total)
        : _initIntSelection('durations', _durationOptions, 0);
  }

  bool get _hasUnsavedChanges {
    return _formSnapshot() != _initialSnapshot;
  }

  int? _resolveEditingKey(List<TrainingEntry> allEntries) {
    final currentKey = widget.entry?.key;
    if (currentKey is int) return currentKey;
    final source = widget.entry;
    if (source == null) return null;

    final candidates = allEntries.where((entry) {
      final key = entry.key;
      return key is int &&
          entry.createdAt == source.createdAt &&
          entry.date == source.date &&
          entry.isMatch == source.isMatch;
    }).toList(growable: false);
    if (candidates.length == 1) {
      return candidates.single.key as int;
    }

    final strictCandidates = candidates.where((entry) {
      return entry.durationMinutes == source.durationMinutes &&
          entry.type == source.type &&
          entry.program == source.program &&
          entry.location == source.location;
    }).toList(growable: false);
    if (strictCandidates.length == 1) {
      return strictCandidates.single.key as int;
    }
    return null;
  }

  bool get _isReadOnlyMode {
    return FamilyAccessService(
      widget.optionRepository,
    ).loadState().isParentMode;
  }

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
      if (!widget.initialConditioningOnly &&
          (widget.initialPlanContext == null ||
              widget.initialPlanContext!.durationMinutes <= 0)) {
        _durationMinutes = _initIntSelection(
          'durations',
          _durationOptions,
          latest.durationMinutes,
        );
        if (_trainingProgramMinutes.length <= 1 && _type.trim().isNotEmpty) {
          _trainingProgramMinutes
            ..clear()
            ..addAll(<String, int>{_type.trim(): _durationMinutes});
        }
      }
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

  String get _locationForSave {
    final weatherLocation = _weatherLocation.trim();
    if (weatherLocation.isNotEmpty) return weatherLocation;
    return widget.entry?.location ?? '';
  }

  int _defaultInt(String key, int fallback) {
    final value = widget.optionRepository.getValue<int>(key);
    if (value == null) return fallback;
    return value;
  }

  String _defaultString(String key, List<String> options, String optionsKey) {
    if (options.isEmpty) return '';
    final value = widget.optionRepository.getValue<String>(key);
    final normalized = LocalizedOptionDefaults.normalizeDefaultValue(
      key: key,
      storedValue: value,
      localizedDefaults: _localizedDefaultsForDefaultKey(key),
      options: options,
      preserveCustomValue: true,
    );
    if (normalized.isEmpty) return options.first;
    if (value != normalized) {
      unawaited(widget.optionRepository.setValue(key, normalized));
    }
    if (!options.contains(normalized)) {
      options.add(normalized);
      widget.optionRepository.saveOptions(optionsKey, options);
    }
    return normalized;
  }

  List<String> _localizedDefaultsForDefaultKey(String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'default_program':
        return [
          l10n.defaultProgram1,
          l10n.defaultProgram2,
          l10n.defaultProgram3,
          l10n.defaultProgram4,
          l10n.challengeLiftingLabel,
          l10n.challengeJumpRopeLabel,
        ];
      default:
        return const <String>[];
    }
  }

  bool get _canEditParentFeedback {
    return widget.entry != null &&
        FamilyAccessService(widget.optionRepository).loadState().isParentMode;
  }

  Future<void> _openParentFeedbackScreen() async {
    final entry = widget.entry;
    if (entry == null) {
      return;
    }
    final result = await Navigator.of(context).push<ParentFeedbackScreenResult>(
      AppPageRoute(
        builder: (_) => ParentFeedbackScreen(
          entry: entry,
          optionRepository: widget.optionRepository,
          driveBackupService: widget.driveBackupService,
          initialFocusReactions: true,
        ),
      ),
    );
    if (!mounted || result == null || !result.changed) {
      return;
    }
    setState(() {
      _savedParentFeedback = result.feedback?.message ?? '';
      _savedParentFeedbackReaction = result.feedback?.reaction ?? '';
      _savedParentFeedbackUpdatedAt = result.feedback?.updatedAt;
    });
    final l10n = AppLocalizations.of(context)!;
    final baseMessage = result.feedback == null
        ? l10n.parentFeedbackCleared
        : l10n.parentFeedbackSaved;
    final syncMessage = result.didSync
        ? l10n.parentSharedSyncDone
        : l10n.parentSharedSyncPending;
    AppFeedback.showSuccess(context, text: '$baseMessage $syncMessage');
  }

  String _parentFeedbackActionLabel(AppLocalizations l10n) {
    final feedbackExists = _savedParentFeedback.trim().isNotEmpty;
    if (_canEditParentFeedback) {
      return feedbackExists
          ? l10n.parentFeedbackEditAction
          : l10n.parentFeedbackWriteAction;
    }
    return l10n.parentFeedbackViewAction;
  }

  Widget _buildParentFeedbackCard({required AppLocalizations l10n}) {
    final entry = widget.entry;
    if (entry == null) {
      return const SizedBox.shrink();
    }
    final canEdit = _canEditParentFeedback;
    final feedbackText = _savedParentFeedback.trim();
    final reaction = _savedParentFeedbackReaction.trim();
    final reactionIcon = _parentFeedbackReactionIcon(
      _savedParentFeedbackReaction,
    );
    if (!canEdit && feedbackText.isEmpty && reaction.isEmpty) {
      return const SizedBox.shrink();
    }
    final updatedAt = _savedParentFeedbackUpdatedAt;
    final updatedLabel = updatedAt == null
        ? ''
        : DateFormat(
            Localizations.localeOf(context).languageCode == 'ko'
                ? 'M/d HH:mm'
                : 'MMM d HH:mm',
            Localizations.localeOf(context).toString(),
          ).format(updatedAt);
    return WatchCartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.parentFeedbackSectionTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton.filledTonal(
                visualDensity: VisualDensity.compact,
                tooltip: _parentFeedbackActionLabel(l10n),
                onPressed: _openParentFeedbackScreen,
                icon: Icon(
                  reactionIcon ??
                      (canEdit
                          ? Icons.edit_note_outlined
                          : Icons.visibility_outlined),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (updatedLabel.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(updatedLabel, style: Theme.of(context).textTheme.labelSmall),
          ],
          const SizedBox(height: 12),
          Text(
            feedbackText.isEmpty
                ? (reaction.isEmpty
                    ? l10n.parentFeedbackEmpty
                    : l10n.parentFeedbackReactionOnly)
                : feedbackText,
            maxLines: canEdit ? 3 : 5,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (reaction.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _parentFeedbackReactionIds(reaction)
                  .map(
                    (id) => Chip(
                      avatar: Icon(
                        _parentFeedbackReactionIcon(id) ??
                            Icons.rate_review_rounded,
                        size: 16,
                      ),
                      label: Text(_parentFeedbackReactionLabel(id, l10n)),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }

  IconData? _parentFeedbackReactionIcon(String reaction) {
    final reactions = _parentFeedbackReactionIds(reaction);
    final primaryReaction = reactions.firstWhere(
      (item) => item != 'review',
      orElse: () => reactions.isEmpty ? '' : reactions.first,
    );
    return switch (primaryReaction) {
      'thanks' => Icons.favorite_rounded,
      'proud' => Icons.emoji_events_rounded,
      'review' => Icons.rate_review_rounded,
      'try' => Icons.directions_run_rounded,
      _ => null,
    };
  }

  List<String> _parentFeedbackReactionIds(String reaction) {
    return reaction
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  String _parentFeedbackReactionLabel(String reaction, AppLocalizations l10n) {
    return switch (reaction) {
      'thanks' => l10n.parentFeedbackReactionThanks,
      'proud' => l10n.parentFeedbackReactionProud,
      'review' => l10n.parentFeedbackReactionReview,
      'try' => l10n.parentFeedbackReactionTry,
      _ => reaction,
    };
  }

  Widget _buildStatusRow(AppLocalizations l10n) {
    const values = ['great', 'good', 'normal', 'tough', 'recovery'];
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values.map((value) {
            final visual = trainingStatusVisual(value);
            final selected = _status == value;
            final foreground = selected
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurface;
            return ChoiceChip(
              selected: selected,
              showCheckmark: false,
              avatar: Icon(
                visual.icon,
                size: 18,
                color: selected ? visual.gradientEnd : visual.color,
              ),
              label: Text(_trainingStatusLabel(l10n, value)),
              labelStyle: theme.textTheme.labelLarge?.copyWith(
                color: foreground,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              ),
              selectedColor: visual.gradientStart.withValues(alpha: 0.28),
              backgroundColor: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.62),
              side: BorderSide(
                color: selected
                    ? visual.gradientEnd.withValues(alpha: 0.72)
                    : theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.62,
                      ),
              ),
              onSelected: (_) {
                setState(() => _status = value);
                _scheduleAutoSave();
              },
            );
          }).toList(growable: false),
        ),
      ],
    );
  }

  String _trainingStatusLabel(AppLocalizations l10n, String status) {
    return switch (status) {
      'great' => l10n.statusGreat,
      'good' => l10n.statusGood,
      'tough' => l10n.statusTough,
      'recovery' => l10n.statusRecovery,
      _ => l10n.statusNormal,
    };
  }

  _DailyGoalVisual _dailyGoalVisualFor(String option) {
    final normalized = option.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    if (_goalTextContains(normalized, const ['드리블', 'dribbl', 'ドリブル'])) {
      return const _DailyGoalVisual(
        icon: Icons.sports_soccer_outlined,
        selectedIcon: Icons.sports_soccer_rounded,
        color: Color(0xFF0F9F76),
      );
    }
    if (_goalTextContains(normalized, const ['패스', 'pass', 'パス'])) {
      return const _DailyGoalVisual(
        icon: Icons.compare_arrows_rounded,
        selectedIcon: Icons.swap_calls_rounded,
        color: Color(0xFF2563EB),
      );
    }
    if (_goalTextContains(normalized, const ['슈팅', 'shoot', 'シュート'])) {
      return const _DailyGoalVisual(
        icon: Icons.gps_fixed_rounded,
        selectedIcon: Icons.ads_click_rounded,
        color: Color(0xFFDC2626),
      );
    }
    if (_goalTextContains(normalized, const ['체력', 'fitness', '体力'])) {
      return const _DailyGoalVisual(
        icon: Icons.bolt_outlined,
        selectedIcon: Icons.bolt_rounded,
        color: Color(0xFFF59E0B),
      );
    }
    if (_goalTextContains(normalized, const ['수비', 'defens', '守備'])) {
      return const _DailyGoalVisual(
        icon: Icons.shield_outlined,
        selectedIcon: Icons.shield_rounded,
        color: Color(0xFF4F46E5),
      );
    }
    if (_goalTextContains(normalized, const ['터치', 'touch', 'タッチ'])) {
      return const _DailyGoalVisual(
        icon: Icons.touch_app_outlined,
        selectedIcon: Icons.touch_app_rounded,
        color: Color(0xFF9333EA),
      );
    }
    return _DailyGoalVisual(
      icon: Icons.flag_outlined,
      selectedIcon: Icons.flag_rounded,
      color: Theme.of(context).colorScheme.primary,
    );
  }

  bool _goalTextContains(String normalized, List<String> needles) {
    return needles.any((needle) => normalized.contains(needle.toLowerCase()));
  }

  Widget _buildDailyGoalSelector(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTrainingSectionHeader(
          icon: Icons.flag_outlined,
          title: l10n.entryTodayGoalsTitle,
          actions: [
            IconButton.filledTonal(
              onPressed: () => _addOption(
                key: 'daily_goals',
                title: l10n.entryTodayGoalAddTitle,
                options: _dailyGoalOptions,
                onUpdated: (list) => setState(() => _dailyGoalOptions = list),
                onSelected: (value) {
                  setState(() {
                    _selectedDailyGoals.add(value);
                  });
                  _scheduleAutoSave();
                },
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              tooltip: l10n.entryTodayGoalAddTooltip,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_dailyGoalOptions.isEmpty)
          Text(
            l10n.entryTodayGoalsNone,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in _dailyGoalOptions)
                Builder(
                  builder: (context) {
                    final selected = _selectedDailyGoals.contains(option);
                    final visual = _dailyGoalVisualFor(option);
                    final foreground = selected
                        ? visual.color
                        : theme.colorScheme.onSurfaceVariant;
                    return FilterChip(
                      selected: selected,
                      showCheckmark: false,
                      avatar: Icon(
                        selected ? visual.selectedIcon : visual.icon,
                        size: 18,
                        color: foreground,
                      ),
                      label: Text(option),
                      labelStyle: theme.textTheme.labelLarge?.copyWith(
                        color: foreground,
                        fontWeight:
                            selected ? FontWeight.w900 : FontWeight.w700,
                      ),
                      selectedColor: visual.color.withValues(
                        alpha:
                            theme.brightness == Brightness.dark ? 0.28 : 0.16,
                      ),
                      backgroundColor: Color.alphaBlend(
                        visual.color.withValues(alpha: 0.07),
                        theme.colorScheme.surfaceContainerHighest,
                      ),
                      side: BorderSide(
                        color: selected
                            ? visual.color.withValues(alpha: 0.58)
                            : theme.colorScheme.outlineVariant.withValues(
                                alpha: 0.62,
                              ),
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedDailyGoals.add(option);
                          } else {
                            _selectedDailyGoals.remove(option);
                          }
                        });
                        _scheduleAutoSave();
                      },
                    );
                  },
                ),
            ],
          ),
      ],
    );
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
        location: '',
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
              onChanged:
                  done ? (value) => onRiceBowlsChanged(value ?? 0) : null,
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
    _liftingMinutesController.dispose();
    _jumpRopeController.dispose();
    _jumpRopeMinutesController.dispose();
    _jumpRopeNoteController.dispose();
    _liftingFieldFocusNode.dispose();
    _jumpRopeFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.entry != null;
    final dateText = DateFormat('yyyy.MM.dd').format(_date);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final isParentMode = FamilyAccessService(
      widget.optionRepository,
    ).loadState().isParentMode;
    final isReadOnly = isParentMode;
    final weatherSummary = _weatherSummary.trim();
    final weatherLocation = _weatherLocation.trim();
    final weatherStatusText = _weatherLoading
        ? l10n.entryWeatherLoading
        : weatherSummary.isNotEmpty
            ? [
                weatherLocation,
                weatherSummary,
              ].where((part) => part.isNotEmpty).join(' · ')
            : l10n.entryWeatherHomeMissing;
    final weatherHasValue = weatherSummary.isNotEmpty;
    final isMatchEntry = widget.entry?.isMatch ?? false;
    if (isReadOnly && widget.entry == null) {
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
                  child: InfoBanner(
                    summary: l10n.parentFeedbackOpenExistingEntryTitle,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
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
    final canPopWithoutPrompt =
        !_hasUnsavedChanges || _saveInProgress || _deleteInProgress;
    return PopScope(
      canPop: canPopWithoutPrompt,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || canPopWithoutPrompt) return;
        final navigator = Navigator.of(context);
        final shouldExit = await _confirmExitWithoutSave();
        if (!mounted || !shouldExit) return;
        navigator.pop();
      },
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
                onChanged: isReadOnly ? null : _scheduleAutoSave,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _attemptExit,
                          icon: const Icon(Icons.arrow_back),
                          tooltip: l10n.cancel,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${l10n.entryHeadline1} ${l10n.entryHeadline2}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (!isReadOnly) ...[
                          const SizedBox(width: 8),
                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 6,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              FilledButton.icon(
                                onPressed: (_deleteInProgress ||
                                        (_saveInProgress && !_autoSaving))
                                    ? null
                                    : _handleSavePressed,
                                icon: const Icon(Icons.save_outlined, size: 18),
                                label: Text(l10n.save),
                                style: FilledButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  minimumSize: const Size(0, 40),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                              if (isEdit)
                                OutlinedButton.icon(
                                  onPressed:
                                      (_saveInProgress || _deleteInProgress)
                                          ? null
                                          : _confirmAndDelete,
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                  ),
                                  label: Text(l10n.delete),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: theme.colorScheme.error,
                                    visualDensity: VisualDensity.compact,
                                    minimumSize: const Size(0, 40),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    side: BorderSide(
                                      color: theme.colorScheme.error.withValues(
                                        alpha: 0.48,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (widget.entry != null) ...[
                      _buildParentFeedbackCard(l10n: l10n),
                      if (_canEditParentFeedback ||
                          _savedParentFeedback.trim().isNotEmpty)
                        const SizedBox(height: 12),
                    ],
                    if (widget.entry == null &&
                        widget.initialPlanContext != null) ...[
                      InfoBanner(
                        key: const ValueKey('entry-plan-banner'),
                        icon: Icons.event_note_outlined,
                        centerContent: true,
                        summary: l10n.entryStartedFromPlanSummary(
                          _initialPlanSummary(isKo),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildFeatureActionButton(
                            icon: _fortuneEnabled
                                ? Icons.auto_awesome
                                : Icons.auto_awesome_outlined,
                            label: l10n.fortuneDialogTitle,
                            active: _fortuneEnabled,
                            onPressed: () =>
                                unawaited(_handleFortuneButtonPressed()),
                          ),
                          _buildFeatureActionButton(
                            icon: _linkedBoardIds.isNotEmpty
                                ? Icons.developer_board
                                : Icons.developer_board_outlined,
                            label: l10n.drawerAddTrainingSketch,
                            active: _linkedBoardIds.isNotEmpty,
                            onPressed: _openTrainingBoardEditor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AbsorbPointer(
                      absorbing: isReadOnly,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 4),
                          _buildTrainingOverviewCard(
                            l10n: l10n,
                            dateText: dateText,
                            weatherStatusText: weatherStatusText,
                            weatherHasValue: weatherHasValue,
                          ),
                          const SizedBox(height: 16),
                          WatchCartCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDailyGoalSelector(l10n),
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
                                    labelText:
                                        isKo ? '아쉬운 점' : 'What to improve',
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
                                        value:
                                            _injuryPartController.text.isEmpty
                                                ? l10n.notSet
                                                : _injuryPartController.text,
                                        options: [
                                          l10n.notSet,
                                          ..._injuryPartOptions,
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            _injuryPartController.text =
                                                value == l10n.notSet
                                                    ? ''
                                                    : value;
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
                                            () => _injuryPartController.text =
                                                value,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.liftingByPart,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildEmphasizedField(
                                        fieldKey: _liftingFieldKey,
                                        controller: _liftingMinutesController,
                                        focusNode: _liftingFieldFocusNode,
                                        enabled: _liftingEnabled,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: l10n.liftingMinutesLabel,
                                          hintText: '0',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildEmphasizedField(
                                              controller: _liftChestController,
                                              enabled: _liftingEnabled,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: InputDecoration(
                                                labelText:
                                                    l10n.liftingPartInfront,
                                                hintText: '0',
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildEmphasizedField(
                                              controller: _liftBackController,
                                              enabled: _liftingEnabled,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: InputDecoration(
                                                labelText:
                                                    l10n.liftingPartInside,
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
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: InputDecoration(
                                                labelText:
                                                    l10n.liftingPartOutside,
                                                hintText: '0',
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildEmphasizedField(
                                              controller:
                                                  _liftShouldersController,
                                              enabled: _liftingEnabled,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: InputDecoration(
                                                labelText:
                                                    l10n.liftingPartMuple,
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
                                              keyboardType:
                                                  TextInputType.number,
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
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: InputDecoration(
                                                labelText:
                                                    l10n.liftingPartChest,
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
                                  title: Text(l10n.jumpRopeRecordTitle),
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
                                              fieldKey: _jumpRopeFieldKey,
                                              controller:
                                                  _jumpRopeMinutesController,
                                              focusNode:
                                                  _jumpRopeFieldFocusNode,
                                              enabled: _jumpRopeEnabled,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: InputDecoration(
                                                labelText:
                                                    l10n.jumpRopeMinutesLabel,
                                                hintText: '0',
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildEmphasizedField(
                                              controller: _jumpRopeController,
                                              enabled: _jumpRopeEnabled,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: InputDecoration(
                                                labelText:
                                                    l10n.jumpRopeCountLabel,
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
                                          labelText: l10n.jumpRopeMemoLabel,
                                          hintText: l10n.jumpRopeMemoHint,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (isEdit && !isReadOnly)
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

  String _initialPlanSummary(bool isKo) {
    final plan = widget.initialPlanContext;
    if (plan == null) return '';
    final parts = <String>[];
    final program = plan.program.trim();
    if (program.isNotEmpty) {
      parts.add(program);
    }
    if (plan.durationMinutes > 0) {
      parts.add(
        isKo ? '${plan.durationMinutes}분' : '${plan.durationMinutes} min',
      );
    }
    final note = plan.note.trim();
    if (note.isNotEmpty) {
      parts.add(note);
    }
    return parts.join(' · ');
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

  Widget _buildTrainingSectionHeader({
    required IconData icon,
    required String title,
    Color? color,
    List<Widget> actions = const <Widget>[],
  }) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.primary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (actions.isNotEmpty) ...[
          const SizedBox(width: 6),
          Wrap(spacing: 4, runSpacing: 4, children: actions),
        ],
      ],
    );
  }

  Widget _buildTrainingOverviewCard({
    required AppLocalizations l10n,
    required String dateText,
    required String weatherStatusText,
    required bool weatherHasValue,
  }) {
    return WatchCartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTrainingDateWeatherRow(
            l10n: l10n,
            dateText: dateText,
            weatherStatusText: weatherStatusText,
            weatherHasValue: weatherHasValue,
          ),
          const SizedBox(height: 16),
          _buildStatusRow(l10n),
          const Divider(height: 28),
          _buildProgramDurationSection(l10n),
        ],
      ),
    );
  }

  Widget _buildTrainingDateWeatherRow({
    required AppLocalizations l10n,
    required String dateText,
    required String weatherStatusText,
    required bool weatherHasValue,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(
              child: _buildTrainingDateButton(l10n: l10n, dateText: dateText),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 52,
              child: _buildTrainingWeatherChip(
                l10n: l10n,
                weatherStatusText: weatherStatusText,
                weatherHasValue: weatherHasValue,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTrainingDateButton({
    required AppLocalizations l10n,
    required String dateText,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.46 : 0.70,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.58),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.calendar_today_rounded,
                  size: 17,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  dateText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrainingWeatherChip({
    required AppLocalizations l10n,
    required String weatherStatusText,
    required bool weatherHasValue,
  }) {
    final theme = Theme.of(context);
    final color = _trainingWeatherAccentColor(
      theme,
      weatherHasValue: weatherHasValue,
    );
    final tooltip = weatherHasValue
        ? weatherStatusText
        : l10n.entryWeatherUseLocationTooltip;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _weatherLoading ? null : _useCurrentLocationWeather,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                color.withValues(
                  alpha: weatherHasValue
                      ? (theme.brightness == Brightness.dark ? 0.18 : 0.10)
                      : 0.04,
                ),
                theme.colorScheme.surfaceContainerHighest,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: weatherHasValue
                    ? color.withValues(alpha: 0.28)
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.72),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _weatherLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      )
                    : Icon(
                        _trainingWeatherIcon(weatherHasValue: weatherHasValue),
                        size: 18,
                        color: color,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _trainingWeatherIcon({required bool weatherHasValue}) {
    if (!weatherHasValue) return Icons.add_location_alt_outlined;
    switch (_weatherCode) {
      case 0:
        return Icons.wb_sunny_outlined;
      case 1:
      case 2:
      case 3:
        return Icons.cloud_outlined;
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
      case 80:
      case 81:
      case 82:
        return Icons.grain_rounded;
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return Icons.ac_unit_rounded;
      case 95:
      case 96:
      case 99:
        return Icons.flash_on_rounded;
      default:
        return Icons.wb_cloudy_outlined;
    }
  }

  Color _trainingWeatherAccentColor(
    ThemeData theme, {
    required bool weatherHasValue,
  }) {
    if (!weatherHasValue) return theme.colorScheme.onSurfaceVariant;
    switch (_weatherCode) {
      case 0:
        return const Color(0xFFE6A100);
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
      case 80:
      case 81:
      case 82:
        return const Color(0xFF2B6FF3);
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return const Color(0xFF4E7FA8);
      case 95:
      case 96:
      case 99:
        return const Color(0xFF5B6DB8);
      default:
        return theme.colorScheme.primary;
    }
  }

  Widget _buildFeatureActionButton({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onPressed,
    bool emphasizePrimary = false,
  }) {
    final theme = Theme.of(context);
    final fg = active
        ? (emphasizePrimary
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onPrimaryContainer)
        : theme.colorScheme.onSurfaceVariant;
    final bg = active
        ? (emphasizePrimary
            ? theme.colorScheme.primary
            : theme.colorScheme.primaryContainer.withValues(alpha: 0.92))
        : theme.colorScheme.surfaceContainerHighest;
    final border = active
        ? (emphasizePrimary
            ? theme.colorScheme.primary
            : theme.colorScheme.primary.withValues(alpha: 0.62))
        : theme.colorScheme.outline.withValues(alpha: 0.28);

    return AppPressableScale(
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 126),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (active) ...[
                const SizedBox(width: 5),
                Icon(Icons.check_circle_rounded, size: 15, color: fg),
              ],
            ],
          ),
        ),
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          backgroundColor: bg,
          foregroundColor: fg,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          visualDensity: VisualDensity.compact,
          textStyle: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildEmphasizedField({
    Key? fieldKey,
    required TextEditingController controller,
    FocusNode? focusNode,
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
        controller == _nextGoalController ||
        controller == _jumpRopeNoteController;
    final isListeningFor = _isListening && _listeningController == controller;
    final isMultiline = maxLines == null || maxLines > 1 || minLines > 1;
    final resolvedTextInputAction =
        isMultiline ? TextInputAction.newline : TextInputAction.done;
    final micButton = showMic && enabled
        ? IconButton(
            onPressed: () => _toggleListening(controller, l10n),
            icon: Icon(
              isListeningFor ? Icons.mic : Icons.mic_none,
              color: isListeningFor
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          )
        : null;
    final suffixIcon = enabled && micButton != null
        ? Row(mainAxisSize: MainAxisSize.min, children: [micButton])
        : decoration.suffixIcon;
    final field = TextFormField(
      key: fieldKey,
      controller: controller,
      focusNode: focusNode,
      minLines: minLines,
      maxLines: maxLines,
      enabled: enabled,
      textInputAction: resolvedTextInputAction,
      onFieldSubmitted: resolvedTextInputAction == TextInputAction.newline
          ? null
          : (_) => FocusScope.of(context).unfocus(),
      keyboardType:
          keyboardType ?? (isMultiline ? TextInputType.multiline : null),
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
        suffixIcon: suffixIcon,
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

    final needsSpacing = !isKoreanLocale &&
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
    final locale = Localizations.localeOf(context);
    final l10n = AppLocalizations.of(context)!;
    setState(() => _weatherLoading = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!fromAuto) {
          await _showLocationServiceDialog();
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
            await _showLocationPermissionDialog();
          } else {
            _showWeatherSnack(l10n.entryWeatherPermissionRequired);
          }
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final place = await _resolvePlaceName(
        latitude: position.latitude,
        longitude: position.longitude,
        isKo: isKo,
        koreaLabel: l10n.homeWeatherCountryKorea,
      );
      final weather = await WeatherSharedResource.fetchForLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        location: place,
        l10n: l10n,
        locale: locale,
      );
      if (!mounted || _disposing) return;
      setState(() {
        _weatherCode = weather.weatherCode;
        _weatherSummary = weather.summary.trim();
        _weatherLocation = place.trim();
      });
      _scheduleAutoSave();
    } catch (_) {
      if (!mounted || _disposing) return;
      if (!fromAuto) {
        _showWeatherSnack(l10n.entryWeatherLoadFailed);
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

  Future<void> _showLocationServiceDialog() async {
    if (!mounted || _disposing) return;
    final l10n = AppLocalizations.of(context)!;
    final open = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.entryWeatherLocationServiceTitle),
        content: Text(l10n.entryWeatherLocationServiceBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).closeButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.entryWeatherOpenSettings),
          ),
        ],
      ),
    );
    if (open == true) {
      await Geolocator.openLocationSettings();
    }
  }

  Future<void> _showLocationPermissionDialog() async {
    if (!mounted || _disposing) return;
    final l10n = AppLocalizations.of(context)!;
    final open = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.entryWeatherPermissionTitle),
        content: Text(l10n.entryWeatherPermissionBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).closeButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.entryWeatherOpenSettings),
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
    required String koreaLabel,
  }) =>
      WeatherLocationService.resolvePlaceName(
        latitude: latitude,
        longitude: longitude,
        isKo: isKo,
        koreaLabel: koreaLabel,
      );

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
    if (!_fortuneEnabled && !_isReadOnlyMode) {
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
    if (!_fortuneEnabled && !forceShow && !_isReadOnlyMode) return;
    if (!mounted || _disposing) return;
    if (_cachedFortuneComment.trim().isNotEmpty) {
      await _showFortuneRevealDialog(_cachedFortuneComment);
      return;
    }
    if (_isReadOnlyMode && widget.entry != null) {
      _showWeatherSnack(
        AppLocalizations.of(context)!.parentReadOnlyFortuneEmpty,
      );
      return;
    }
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final profile = PlayerProfileService(widget.optionRepository).load();
    final allEntries = await widget.trainingService.allEntries();
    if (!mounted || _disposing) return;
    final trainingProgramMinutes = _persistedTrainingProgramMinutes();
    final durationMinutes =
        _trainingProgramMinutesTotal(trainingProgramMinutes) > 0
            ? _trainingProgramMinutesTotal(trainingProgramMinutes)
            : _durationMinutes;
    final goodPoints = _goodPointsController.text.trim();
    final improvements = _improvementsController.text.trim();
    final notes = _withWeatherInNotes(improvements, isKo);
    final draft = TrainingEntry(
      date: DateTime(_date.year, _date.month, _date.day),
      durationMinutes: durationMinutes,
      intensity: _intensity,
      type: _type,
      mood: _mood,
      injury: _injury,
      notes: notes,
      location: _locationForSave,
      program: _type,
      trainingProgramMinutes: trainingProgramMinutes,
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
      liftingMinutes: _liftingEnabled
          ? (_parseInt(_liftingMinutesController.text.trim()) ?? 0)
          : 0,
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

  Future<void> _openTrainingBoardEditor({
    bool closeHostAfterReturn = false,
  }) async {
    final allBoards = _trainingBoardService.allBoards();
    final recentBoardId =
        widget.optionRepository.getValue<String>(_recentBoardIdKey) ?? '';
    final hasRecentBoard = allBoards.any((board) => board.id == recentBoardId);
    final isReadOnly = _isReadOnlyMode;
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
          readOnly: isReadOnly,
        ),
      ),
    );
    if (!mounted) return;
    if (!isReadOnly && selectedIds != null) {
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
    if (!closeHostAfterReturn || !mounted) {
      return;
    }
    if (widget.entry != null && !_isReadOnlyMode && _hasUnsavedChanges) {
      await _save(popAfterSave: true, silent: true);
      return;
    }
    Navigator.of(context).pop();
  }

  void _scheduleAutoSave() {
    if (widget.entry == null) return;
    if (_isReadOnlyMode) return;
    if (_saveInProgress) return;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted || _disposing) return;
      _save(popAfterSave: false, silent: true);
    });
  }

  void _handleSavePressed() {
    if (_deleteInProgress) return;
    if (_autoSaving) {
      _manualSaveQueuedAfterAutoSave = true;
      return;
    }
    if (_saveInProgress) return;
    unawaited(_save());
  }

  Future<void> _save({bool popAfterSave = true, bool silent = false}) async {
    if (!mounted || _disposing) return;
    if (_isReadOnlyMode) return;
    if (_saveInProgress) return;
    if (_autoSaving) return;
    if (!silent) {
      _autoSaveTimer?.cancel();
      _manualSaveQueuedAfterAutoSave = false;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    _saveInProgress = true;
    _autoSaving = silent;
    if (silent && mounted) setState(() {});

    try {
      final isKo = Localizations.localeOf(context).languageCode == 'ko';
      final l10n = AppLocalizations.of(context)!;
      _syncDrillsPayloadFromBoardLinks();
      final injuryPart = _injury ? _injuryPartController.text.trim() : '';
      final painLevel = _injury ? _parseInt(_painController.text) : null;
      final trainingProgramMinutes = _persistedTrainingProgramMinutes();
      final durationMinutes =
          _trainingProgramMinutesTotal(trainingProgramMinutes) > 0
              ? _trainingProgramMinutesTotal(trainingProgramMinutes)
              : _durationMinutes;
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
      final liftingMinutes = _liftingEnabled
          ? (_parseInt(
                _liftingMinutesController.text.trim(),
              )?.clamp(0, 1000000) ??
              0)
          : 0;
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
      final jumpRopeNote =
          _jumpRopeEnabled ? _jumpRopeNoteController.text.trim() : '';

      final draftEntry = TrainingEntry(
        date: DateTime(_date.year, _date.month, _date.day),
        durationMinutes: durationMinutes,
        intensity: _intensity,
        type: _type,
        mood: _mood,
        injury: _injury,
        notes: notesWithWeather,
        location: _locationForSave,
        program: _type,
        trainingProgramMinutes: trainingProgramMinutes,
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
        liftingMinutes: liftingMinutes,
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
      final fortuneRecommendation =
          shouldPersistFortune ? _cachedFortuneRecommendation : '';
      final fortuneRecommendedProgram =
          shouldPersistFortune ? _cachedFortuneRecommendedProgram : '';

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
        trainingProgramMinutes: draftEntry.trainingProgramMinutes,
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
        liftingMinutes: draftEntry.liftingMinutes,
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
        if (levelAward.didLevelUp) {
          await reminderService.showLevelUpAlert(
            level: levelAward.after.level,
            isKo: isKo,
          );
        }
        if (!mounted) return;
      } else {
        final editingKey = _editingKey ?? _resolveEditingKey(allEntries);
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
        _editingKey = editingKey;
        await widget.trainingService.update(editingKey, entry);
        final previousEntryForXp = _persistedEntryForXp ?? widget.entry!;
        levelAward = await playerLevelService.awardForTrainingLogUpdate(
          previousEntry: previousEntryForXp,
          updatedEntry: entry,
        );
        _persistedEntryForXp = entry;
        if (levelAward.didLevelUp) {
          final reminderService = TrainingPlanReminderService(
            widget.optionRepository,
            widget.settingsService,
          );
          await reminderService.showLevelUpAlert(
            level: levelAward.after.level,
            isKo: isKo,
          );
        }
      }
      _initialSnapshot = _formSnapshot();
      if (!mounted) return;
      final fortuneToShow =
          shouldShowFortuneOnSave ? _cachedFortuneComment : '';
      if (fortuneToShow.trim().isNotEmpty && popAfterSave) {
        await _showFortuneRevealDialog(fortuneToShow);
        if (!mounted) return;
      }
      if (popAfterSave && widget.entry == null) {
        await showTrainingRecordSavedDialog(context, award: levelAward);
        if (!mounted) return;
      } else if (popAfterSave && levelAward.gainedXp > 0) {
        await showTrainingXpRewardDialog(context, award: levelAward);
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
              text: l10n.levelUpRewardClaimed(rewardName),
            );
          },
        );
        if (!mounted) return;
      }
      if (popAfterSave) {
        await showTrainingStreakCheerDialog(context, award: levelAward);
        if (!mounted) return;
      }
      if (popAfterSave) {
        AppFeedback.showSuccess(context, text: l10n.trainingSaveToastPlain);
        Navigator.of(context).pop();
      }
    } finally {
      final shouldRunQueuedManualSave = silent &&
          _manualSaveQueuedAfterAutoSave &&
          mounted &&
          !_disposing &&
          !_deleteInProgress;
      if (shouldRunQueuedManualSave) {
        _manualSaveQueuedAfterAutoSave = false;
      }
      _saveInProgress = false;
      _autoSaving = false;
      if (silent && mounted) setState(() {});
      if (shouldRunQueuedManualSave) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _disposing) return;
          unawaited(_save(popAfterSave: true));
        });
      }
    }
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
      await PlayerLevelService(
        widget.optionRepository,
      ).revokeTrainingEntryAward(target);
      await widget.trainingService.delete(target);
      if (!mounted) return;
      final isKo = Localizations.localeOf(context).languageCode == 'ko';
      AppFeedback.showUndo(
        context,
        text: isKo ? '기록을 삭제했어요.' : 'Entry deleted.',
        undoLabel: isKo ? '되돌리기' : 'Undo',
        onUndo: () {
          unawaited(() async {
            await widget.trainingService.add(target);
            final restoredEntries = await widget.trainingService.allEntries();
            final restoredExistingEntries = restoredEntries
                .where((item) => item.key != target.key)
                .toList(growable: false);
            final levelService = PlayerLevelService(widget.optionRepository);
            if (target.isMatch) {
              await levelService.awardForMatchLog(updatedEntry: target);
            } else {
              await levelService.awardForTrainingLog(
                entry: target,
                existingEntries: restoredExistingEntries,
              );
            }
          }());
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

  Widget _buildProgramDurationSection(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final entries = _trainingProgramMinutes.entries.toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTrainingSectionHeader(
          icon: Icons.sports_soccer_outlined,
          title: l10n.entryProgramDurationsTitle,
          actions: [
            IconButton.filledTonal(
              onPressed: () {
                setState(_addTrainingProgramDuration);
                _scheduleAutoSave();
              },
              icon: const Icon(Icons.add_rounded, size: 20),
              tooltip: l10n.entryProgramDurationAddAction,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            ),
            IconButton.filledTonal(
              onPressed: () => _addProgramOptionFromDurationSection(l10n),
              icon: const Icon(Icons.playlist_add_rounded, size: 20),
              tooltip: l10n.entryProgramOptionAddTooltip,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            ),
            IconButton.filledTonal(
              onPressed: () => _addDurationOptionFromDurationSection(l10n),
              icon: const Icon(Icons.more_time_rounded, size: 20),
              tooltip: l10n.entryDurationOptionAddTooltip,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          InkWell(
            onTap: () {
              setState(_addTrainingProgramDuration);
              _scheduleAutoSave();
            },
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.38 : 0.58,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.64,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.entryProgramDurationEmpty,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 320;
              return Column(
                children: [
                  for (var index = 0; index < entries.length; index++) ...[
                    _buildProgramDurationRow(
                      l10n: l10n,
                      program: entries[index].key,
                      minutes: entries[index].value,
                      compact: compact,
                    ),
                    if (index < entries.length - 1) const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildProgramDurationRow({
    required AppLocalizations l10n,
    required String program,
    required int minutes,
    required bool compact,
  }) {
    final theme = Theme.of(context);
    final programField = _buildProgramDurationDropdown<String>(
      label: l10n.program,
      value: program,
      options: _programOptions,
      icon: _trainingProgramIconFor(program),
      iconForValue: _trainingProgramIconFor,
      optionLabel: (value) => value,
      onChanged: (value) {
        setState(() => _changeTrainingProgramDurationProgram(program, value));
        _scheduleAutoSave();
      },
    );
    final durationField = _buildProgramDurationDropdown<int>(
      label: l10n.trainingDuration,
      value: minutes,
      options: _durationOptions,
      icon: Icons.timer_outlined,
      optionLabel: (value) => value == 0 ? l10n.notSet : l10n.minutes(value),
      onChanged: (value) {
        setState(() => _changeTrainingProgramDurationMinutes(program, value));
        _scheduleAutoSave();
      },
    );
    final removeButton = IconButton(
      onPressed: () {
        setState(() => _removeTrainingProgramDuration(program));
        _scheduleAutoSave();
      },
      icon: const Icon(Icons.close_rounded, size: 18),
      tooltip: l10n.entryProgramDurationRemoveTooltip,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 34, height: 34),
      style: IconButton.styleFrom(
        foregroundColor: theme.colorScheme.onSurfaceVariant,
      ),
    );
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.34 : 0.50,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.58),
        ),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                programField,
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: durationField),
                    const SizedBox(width: 6),
                    removeButton,
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 7, child: programField),
                const SizedBox(width: 8),
                Expanded(flex: 4, child: durationField),
                const SizedBox(width: 4),
                removeButton,
              ],
            ),
    );
  }

  IconData _trainingProgramIconFor(String label) {
    final normalized = label.trim().toLowerCase();
    if (normalized.isEmpty) return Icons.sports_soccer;

    bool hasAny(List<String> keywords) {
      return keywords.any((keyword) => normalized.contains(keyword));
    }

    if (hasAny(const ['shoot', '슈팅', 'finishing', '마무리'])) {
      return Icons.flag;
    }
    if (hasAny(const ['pass', '패스', 'cross', '크로스'])) {
      return Icons.compare_arrows;
    }
    if (hasAny(const ['def', '수비', 'press', '압박'])) {
      return Icons.security;
    }
    if (hasAny(const ['tactic', '전술', 'analysis', '분석'])) {
      return Icons.account_tree;
    }
    if (hasAny(const [
      '피지컬',
      'fitness',
      'strength',
      '체력',
      'conditioning',
      'lifting',
      '웨이트',
      '근력',
    ])) {
      return Icons.fitness_center;
    }
    if (hasAny(const ['speed', 'agility', '민첩', 'sprint', '스프린트'])) {
      return Icons.directions_run;
    }
    if (hasAny(const ['recovery', '회복', 'stretch', '스트레칭', 'yoga'])) {
      return Icons.self_improvement;
    }
    if (hasAny(const ['keeper', 'gk', '골키퍼'])) {
      return Icons.sports_handball;
    }
    if (hasAny(const ['match', 'game', '시합', '경기'])) {
      return Icons.emoji_events;
    }
    if (hasAny(const ['jump', 'rope', '줄넘기'])) {
      return Icons.loop;
    }
    if (hasAny(const ['rondo', '론도'])) {
      return Icons.device_hub;
    }
    if (hasAny(const [
      'dribble',
      '드리블',
      'touch',
      '트래핑',
      'trap',
      '기본',
      'fundamental',
      'first touch',
    ])) {
      return Icons.sports_soccer;
    }
    return Icons.sports_soccer;
  }

  Widget _buildProgramDurationDropdown<T>({
    required String label,
    required T value,
    required List<T> options,
    required IconData icon,
    IconData Function(T value)? iconForValue,
    required String Function(T value) optionLabel,
    required ValueChanged<T> onChanged,
  }) {
    final theme = Theme.of(context);
    final menuOptions = List<T>.from(options);
    if (!menuOptions.contains(value)) {
      menuOptions.add(value);
    }
    if (menuOptions.isEmpty) {
      return Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.38),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return Tooltip(
      message: label,
      child: Container(
        height: 44,
        padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.38),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            borderRadius: BorderRadius.circular(12),
            icon: const Icon(Icons.expand_more_rounded, size: 18),
            selectedItemBuilder: (context) => menuOptions
                .map(
                  (option) => _ProgramDurationSelectedValue(
                    icon: iconForValue?.call(option) ?? icon,
                    label: optionLabel(option),
                  ),
                )
                .toList(growable: false),
            items: menuOptions
                .map(
                  (option) => DropdownMenuItem<T>(
                    value: option,
                    child: _ProgramDurationSelectedValue(
                      icon: iconForValue?.call(option) ?? icon,
                      label: optionLabel(option),
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
        ),
      ),
    );
  }

  void _addProgramOptionFromDurationSection(AppLocalizations l10n) {
    _addOption(
      key: 'programs',
      title: l10n.program,
      options: _programOptions,
      onUpdated: (list) => setState(() => _programOptions = list),
      onSelected: (value) {
        setState(() {
          _type = value;
          _trainingProgramMinutes.putIfAbsent(value, () => 0);
        });
        _scheduleAutoSave();
      },
    );
  }

  void _addDurationOptionFromDurationSection(AppLocalizations l10n) {
    _addIntOption(
      key: 'durations',
      title: l10n.trainingDuration,
      options: _durationOptions,
      onUpdated: (list) => setState(() => _durationOptions = list),
      onSelected: (value) {
        setState(() {
          final program = _trainingProgramMinutes.keys.isNotEmpty
              ? _trainingProgramMinutes.keys.last
              : _type.trim();
          if (program.isNotEmpty) {
            _changeTrainingProgramDurationMinutes(program, value);
          } else {
            _durationMinutes = _initIntSelection(
              'durations',
              _durationOptions,
              value,
            );
          }
        });
        _scheduleAutoSave();
      },
      hint: '90',
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
          decoration: InputDecoration(hintText: hint.isEmpty ? null : hint),
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

class _ProgramDurationSelectedValue extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ProgramDurationSelectedValue({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 17, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
