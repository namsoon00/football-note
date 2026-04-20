import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../../application/backup_service.dart';
import '../../application/locale_service.dart';
import '../../application/meal_coaching_service.dart';
import '../../application/meal_log_service.dart';
import '../../application/news_badge_service.dart';
import '../../application/player_level_service.dart';
import '../../application/settings_service.dart';
import '../../application/training_board_service.dart';
import '../../application/training_plan_reminder_service.dart';
import '../../application/training_service.dart';
import '../../application/weather_location_service.dart';
import '../../domain/entities/training_board.dart';
import '../../domain/entities/meal_entry.dart';
import '../../domain/entities/training_entry.dart';
import '../../domain/repositories/option_repository.dart';
import '../widgets/app_background.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_page_route.dart';
import '../widgets/player_level_visuals.dart';
import '../widgets/rice_bowl_summary.dart';
import '../widgets/shared_tab_header.dart';
import '../widgets/watch_cart/watch_cart_card.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'skill_quiz_screen.dart';
import 'news_screen.dart';
import 'notification_center_screen.dart';
import 'coach_lesson_screen.dart';
import 'entry_form_screen.dart';
import 'football_education_screen.dart';
import 'player_level_guide_screen.dart';
import 'training_method_board_screen.dart';
import 'weather_detail_screen.dart';

class HomeHubScreen extends StatefulWidget {
  final TrainingService trainingService;
  final MealLogService mealLogService;
  final LocaleService localeService;
  final OptionRepository optionRepository;
  final SettingsService settingsService;
  final BackupService? driveBackupService;
  final VoidCallback onCreate;
  final VoidCallback? onQuickPlan;
  final VoidCallback? onQuickMatch;
  final VoidCallback? onQuickQuiz;
  final VoidCallback? onQuickMeal;
  final VoidCallback? onQuickBoard;
  final VoidCallback onOpenPlans;
  final VoidCallback onOpenLogs;
  final VoidCallback onOpenDiary;
  final VoidCallback onOpenWeeklyStats;
  final ValueChanged<TrainingEntry> onEdit;
  final ValueChanged<TrainingEntry> onEditTrainingBoard;
  final Future<void> Function({DateTime? initialDate}) onCreateTrainingBoard;

  const HomeHubScreen({
    super.key,
    required this.trainingService,
    required this.mealLogService,
    required this.localeService,
    required this.optionRepository,
    required this.settingsService,
    this.driveBackupService,
    required this.onCreate,
    this.onQuickPlan,
    this.onQuickMatch,
    this.onQuickQuiz,
    this.onQuickMeal,
    this.onQuickBoard,
    required this.onOpenPlans,
    required this.onOpenLogs,
    required this.onOpenDiary,
    required this.onOpenWeeklyStats,
    required this.onEdit,
    required this.onEditTrainingBoard,
    required this.onCreateTrainingBoard,
  });

  @override
  State<HomeHubScreen> createState() => _HomeHubScreenState();
}

class _HomeHubScreenState extends State<HomeHubScreen> {
  static const String _priorityFocusOverrideKey =
      'home_priority_focus_override_v1';
  final MealCoachingService _mealCoachingService = const MealCoachingService();
  bool _weatherLoading = false;
  bool _weatherNeedsLocation = true;
  String _weatherLocation = '';
  String _weatherSummary = '';
  int? _weatherCode;

  @override
  void initState() {
    super.initState();
    NewsBadgeService.refresh(widget.optionRepository);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadHomeWeather(requestPermission: false));
    });
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
              final allEntries =
                  (snapshot.data ?? const <TrainingEntry>[])
                      .where((entry) => !entry.isMatch)
                      .toList()
                    ..sort(TrainingEntry.compareByRecentCreated);
              return StreamBuilder<List<MealEntry>>(
                stream: widget.mealLogService.watchEntries(),
                builder: (context, mealSnapshot) {
                  final isKo =
                      Localizations.localeOf(context).languageCode == 'ko';
                  final boardsById = TrainingBoardService(
                    widget.optionRepository,
                  ).boardMap();
                  final boards = boardsById.values.toList(growable: false)
                    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
                  final levelState = PlayerLevelService(
                    widget.optionRepository,
                  ).loadState();
                  final mealEntries = widget.mealLogService.mergedEntries(
                    directEntries: mealSnapshot.data ?? const <MealEntry>[],
                    legacyEntries: allEntries,
                  );
                  final data = _HomeHubData.build(
                    entries: allEntries,
                    mealEntries: mealEntries,
                    plans: _loadPlans(widget.optionRepository),
                    boards: boards,
                    quizCompletedAt: _loadQuizCompletedAt(
                      widget.optionRepository,
                    ),
                    viewedDiaryDayToken: widget.optionRepository
                        .getValue<String>(
                          CoachLessonScreen.todayViewedDiaryDayKey,
                        ),
                    quizResumeSummary: SkillQuizScreen.loadResumeSummary(
                      widget.optionRepository,
                    ),
                    openedNewsToday: _openedNewsToday(),
                  );
                  final priorityFocusSignal = _resolvePriorityFocusSignal(data);
                  final reminderUnreadCount = TrainingPlanReminderService(
                    widget.optionRepository,
                    widget.settingsService,
                  ).unreadReminderCountSync();

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ValueListenableBuilder<int>(
                          valueListenable: NewsBadgeService.listenable(
                            widget.optionRepository,
                          ),
                          builder: (context, newsCount, _) {
                            return Builder(
                              builder: (context) => SharedTabHeader(
                                padding: EdgeInsets.zero,
                                onLeadingTap: () =>
                                    Scaffold.of(context).openDrawer(),
                                profilePhotoSource:
                                    widget.optionRepository.getValue<String>(
                                      'profile_photo_url',
                                    ) ??
                                    '',
                                onNewsTap: _openNews,
                                newsBadgeCount: newsCount,
                                onQuizTap: _openQuizShortcut,
                                onCoachTap: _trackedAction(
                                  'header_education',
                                  _openEducation,
                                ),
                                onProfileTap: () => _openProfile(context),
                                onNotificationTap: _openNotifications,
                                notificationBadgeCount: reminderUnreadCount,
                                onSettingsTap: () => _openSettings(context),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _LevelHeroCard(
                          levelState: levelState,
                          isKo: isKo,
                          onTap: _openLevelGuide,
                        ),
                        if (data.showStreakHighlight) ...[
                          const SizedBox(height: 10),
                          _TrainingStreakSpotlightCard(
                            data: data,
                            l10n: AppLocalizations.of(context)!,
                            onTap: data.latestTrainingGapDays == 0
                                ? widget.onOpenWeeklyStats
                                : () => _openTodayEntryOrCreate(data),
                          ),
                        ],
                        const SizedBox(height: 10),
                        RiceBowlSummaryCard(
                          entry: data.todayMealEntry,
                          title: AppLocalizations.of(
                            context,
                          )!.homeRiceBowlTitle,
                          compact: true,
                          onTap: widget.onQuickMeal,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: 0.86),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                isKo ? '오늘의 홈' : 'Today Home',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _TodayWeatherButton(
                              l10n: AppLocalizations.of(context)!,
                              weatherLoading: _weatherLoading,
                              weatherNeedsLocation: _weatherNeedsLocation,
                              weatherSummary: _weatherSummary.trim(),
                              weatherCode: _weatherCode,
                              onTap: _openWeatherDetails,
                            ),
                          ],
                        ),
                        if (data.todayPlanCount > 0) ...[
                          const SizedBox(height: 8),
                          _TodayPlanHighlightCard(
                            isKo: isKo,
                            count: data.todayPlanCount,
                            onTap: widget.onOpenPlans,
                          ),
                        ] else if (data.upcomingPlanDays.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _PlanDaysCard(
                            isKo: isKo,
                            days: data.upcomingPlanDays,
                            onTap: widget.onOpenPlans,
                          ),
                        ],
                        const SizedBox(height: 12),
                        _PriorityActionCard(
                          focusSignal: priorityFocusSignal,
                          isKo: isKo,
                          l10n: AppLocalizations.of(context)!,
                          todayMealEntry: data.todayMealEntry,
                          mealCoachingService: _mealCoachingService,
                          onPrimaryTap: _trackedPriorityAction(
                            priorityFocusSignal,
                            priorityFocusSignal == 'log_today'
                                ? widget.onOpenPlans
                                : priorityFocusSignal == 'add_session'
                                ? widget.onOpenWeeklyStats
                                : priorityFocusSignal == 'add_minutes'
                                ? widget.onQuickBoard
                                : priorityFocusSignal == 'meal_routine'
                                ? widget.onQuickMeal
                                : priorityFocusSignal == 'recovery'
                                ? widget.onOpenWeeklyStats
                                : _openLevelGuide,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _DailyFlowCard(
                          data: data,
                          isKo: isKo,
                          l10n: AppLocalizations.of(context)!,
                          onLog: _trackedAction(
                            'daily_flow_log',
                            () => _openTodayEntryOrCreate(data),
                          ),
                          onLifting: _trackedAction(
                            'daily_flow_lifting',
                            () => _openTodayEntryOrCreate(
                              data,
                              initialFocusTarget:
                                  EntryFormInitialFocusTarget.lifting,
                            ),
                          ),
                          onJumpRope: _trackedAction(
                            'daily_flow_jump_rope',
                            () => _openTodayEntryOrCreate(
                              data,
                              initialFocusTarget:
                                  EntryFormInitialFocusTarget.jumpRope,
                            ),
                          ),
                          onQuiz: _trackedAction(
                            'daily_flow_quiz',
                            widget.onQuickQuiz,
                          ),
                          onReview: _trackedAction(
                            'daily_flow_review',
                            widget.onOpenDiary,
                          ),
                          onNews: _trackedAction('daily_flow_news', _openNews),
                          onBoard: _trackedAction(
                            'daily_flow_board',
                            () => _openTodayBoardSketch(data),
                          ),
                          onMeal: _trackedAction(
                            'daily_flow_meal',
                            widget.onQuickMeal,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _QuickActionGrid(
                          isKo: isKo,
                          weatherOutfitLabel: AppLocalizations.of(
                            context,
                          )!.homeWeatherOutfitButton,
                          onQuickMatch: _trackedAction(
                            'quick_create_match',
                            widget.onQuickMatch,
                          ),
                          onQuickPlan: _trackedAction(
                            'quick_create_plan',
                            widget.onQuickPlan,
                          ),
                          onQuickWeatherOutfit: _trackedAction(
                            'quick_weather_outfit',
                            _openWeatherOutfitGuide,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ContinueCard(
                          data: data,
                          isKo: isKo,
                          onContinueQuiz: widget.onQuickQuiz,
                          onContinueTraining: data.latestTrainingEntry == null
                              ? widget.onCreate
                              : () => widget.onEdit(data.latestTrainingEntry!),
                          onContinueMatch: widget.onQuickMatch,
                          onContinuePlan: widget.onOpenPlans,
                          onContinueBoard: data.latestBoard == null
                              ? widget.onQuickBoard
                              : () => _openBoard(context, data.latestBoard!),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _loadHomeWeather({required bool requestPermission}) async {
    if (_weatherLoading || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    setState(() => _weatherLoading = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _weatherNeedsLocation = true;
          _weatherLocation = '';
          _weatherCode = null;
          _weatherSummary = '';
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _weatherNeedsLocation = true;
            _weatherLocation = '';
            _weatherCode = null;
            _weatherSummary = '';
          });
        }
        if (requestPermission && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.homeWeatherPermissionNeeded)),
          );
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
      if (!mounted) return;
      setState(() {
        _weatherNeedsLocation = place.trim().isEmpty;
        _weatherLocation = place;
      });

      WeatherHomeWarmupResult weather = const WeatherHomeWarmupResult(
        summary: '',
      );
      try {
        weather = await WeatherDetailScreen.fetchForHome(
          latitude: position.latitude,
          longitude: position.longitude,
          location: place,
          l10n: l10n,
          locale: locale,
        );
      } catch (_) {
        weather = const WeatherHomeWarmupResult(summary: '');
      }

      if (!mounted) return;
      if (weather.summary.trim().isNotEmpty || weather.weatherCode != null) {
        setState(() {
          _weatherCode = weather.weatherCode;
          _weatherSummary = weather.summary;
        });
      }
    } catch (_) {
      if (mounted) {
        final shouldNeedLocation = _weatherLocation.trim().isEmpty;
        setState(() {
          _weatherNeedsLocation = shouldNeedLocation;
          if (shouldNeedLocation) {
            _weatherLocation = '';
          }
        });
      }
      if (requestPermission && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.homeWeatherLoadFailed)));
      }
    } finally {
      if (mounted) {
        setState(() => _weatherLoading = false);
      }
    }
  }

  Future<String> _resolvePlaceName({
    required double latitude,
    required double longitude,
    required bool isKo,
    required String koreaLabel,
  }) => WeatherLocationService.resolvePlaceName(
    latitude: latitude,
    longitude: longitude,
    isKo: isKo,
    koreaLabel: koreaLabel,
  );

  Future<void> _openWeatherDetails({
    WeatherDetailInitialAction initialAction = WeatherDetailInitialAction.none,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WeatherDetailScreen(
          initialLocation: _weatherLocation,
          initialSummary: _weatherSummary,
          initialWeatherCode: _weatherCode,
          initialAction: initialAction,
        ),
      ),
    );
  }

  Future<void> _openWeatherOutfitGuide() => _openWeatherDetails(
    initialAction: WeatherDetailInitialAction.outfitGuide,
  );

  static List<_DashboardPlan> _loadPlans(OptionRepository optionRepository) {
    final raw = optionRepository.getValue<String>('training_plans_v1');
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

  static DateTime? _loadQuizCompletedAt(OptionRepository optionRepository) {
    final raw = optionRepository.getValue<String>('skill_quiz_completed_at');
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> _openSettings(BuildContext context) async {
    await Navigator.of(context).push(
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
  }

  Future<void> _openNews() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NewsScreen(
          trainingService: widget.trainingService,
          localeService: widget.localeService,
          optionRepository: widget.optionRepository,
          settingsService: widget.settingsService,
          driveBackupService: widget.driveBackupService,
          isActive: true,
        ),
      ),
    );
    if (!mounted) return;
    await NewsBadgeService.refresh(widget.optionRepository);
  }

  Future<void> _openQuizShortcut() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            SkillQuizScreen(optionRepository: widget.optionRepository),
      ),
    );
  }

  Future<void> _openEducation() async {
    await Navigator.of(
      context,
    ).push(AppPageRoute(builder: (_) => const FootballEducationScreen()));
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationCenterScreen(
          optionRepository: widget.optionRepository,
          settingsService: widget.settingsService,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openBoard(BuildContext context, TrainingBoard board) async {
    await Navigator.of(context).push<void>(
      AppPageRoute(
        builder: (_) => TrainingMethodBoardScreen(
          boardTitle: board.title,
          initialLayoutJson: board.layoutJson,
          optionRepository: widget.optionRepository,
          initialSelectedBoardIds: [board.id],
          initialBoardId: board.id,
        ),
      ),
    );
  }

  VoidCallback? _trackedAction(String key, VoidCallback? action) {
    if (action == null) return null;
    return () {
      unawaited(_trackHomeActionTap(key));
      action();
    };
  }

  Future<void> _trackHomeActionTap(String key) async {
    final metricKey = 'home_action_count_v1_$key';
    final current = widget.optionRepository.getValue(metricKey) as int? ?? 0;
    await widget.optionRepository.setValue(metricKey, current + 1);
    await widget.optionRepository.setValue(
      'home_action_last_tap_at_v1',
      DateTime.now().toIso8601String(),
    );
  }

  String _resolvePriorityFocusSignal(_HomeHubData data) {
    final rawOverride =
        widget.optionRepository.getValue<String>(_priorityFocusOverrideKey) ??
        '';
    final candidates = _priorityFocusCandidates(data);
    if (rawOverride.isNotEmpty && candidates.contains(rawOverride)) {
      return rawOverride;
    }
    return data.focusSignal;
  }

  List<String> _priorityFocusCandidates(_HomeHubData data) {
    final ordered = <String>[
      data.focusSignal,
      if (data.focusSignal != 'log_today') 'log_today',
      if (data.loggedMealsToday == false && data.focusSignal != 'meal_routine')
        'meal_routine',
      if (data.focusSignal != 'add_session') 'add_session',
      if (data.focusSignal != 'add_minutes') 'add_minutes',
      if (data.focusSignal != 'recovery') 'recovery',
      if (data.focusSignal != 'upgrade_quality') 'upgrade_quality',
    ];
    return ordered.toSet().toList(growable: false);
  }

  VoidCallback? _trackedPriorityAction(
    String focusSignal,
    VoidCallback? action,
  ) {
    if (action == null) return null;
    return () {
      unawaited(_trackHomeActionTap('priority_action'));
      unawaited(_advancePriorityFocusSignal(focusSignal));
      action();
    };
  }

  Future<void> _advancePriorityFocusSignal(String currentFocusSignal) async {
    final entries = await widget.trainingService.allEntries();
    final trainingEntries =
        entries.where((entry) => !entry.isMatch).toList(growable: false)
          ..sort(TrainingEntry.compareByRecentCreated);
    final mealEntries = widget.mealLogService.mergedEntries(
      legacyEntries: trainingEntries,
    );
    final boardsById = TrainingBoardService(widget.optionRepository).boardMap();
    final boards = boardsById.values.toList(growable: false)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final data = _HomeHubData.build(
      entries: trainingEntries,
      mealEntries: mealEntries,
      plans: _loadPlans(widget.optionRepository),
      boards: boards,
      quizCompletedAt: _loadQuizCompletedAt(widget.optionRepository),
      viewedDiaryDayToken: widget.optionRepository.getValue<String>(
        CoachLessonScreen.todayViewedDiaryDayKey,
      ),
      quizResumeSummary: SkillQuizScreen.loadResumeSummary(
        widget.optionRepository,
      ),
      openedNewsToday: _openedNewsToday(),
    );
    final candidates = _priorityFocusCandidates(data);
    final currentIndex = candidates.indexOf(currentFocusSignal);
    final nextIndex = currentIndex < 0
        ? 0
        : (currentIndex + 1) % candidates.length;
    await widget.optionRepository.setValue(
      _priorityFocusOverrideKey,
      candidates[nextIndex],
    );
    if (!mounted) return;
    setState(() {});
  }

  void _openTodayEntryOrCreate(
    _HomeHubData data, {
    EntryFormInitialFocusTarget? initialFocusTarget,
  }) {
    final entry = data.latestTrainingEntry;
    if (entry == null) {
      if (initialFocusTarget == null) {
        widget.onCreate();
        return;
      }
      unawaited(
        _openEntryForm(
          initialDate: _today(),
          initialFocusTarget: initialFocusTarget,
        ),
      );
      return;
    }
    final today = _today();
    final entryDay = DateTime(
      entry.date.year,
      entry.date.month,
      entry.date.day,
    );
    if (entryDay == today) {
      if (initialFocusTarget == null) {
        widget.onEdit(entry);
        return;
      }
      unawaited(
        _openEntryForm(entry: entry, initialFocusTarget: initialFocusTarget),
      );
      return;
    }
    if (initialFocusTarget == null) {
      widget.onCreate();
      return;
    }
    unawaited(
      _openEntryForm(
        initialDate: today,
        initialFocusTarget: initialFocusTarget,
      ),
    );
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _openEntryForm({
    TrainingEntry? entry,
    DateTime? initialDate,
    EntryFormInitialFocusTarget? initialFocusTarget,
  }) {
    return Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => EntryFormScreen(
          trainingService: widget.trainingService,
          optionRepository: widget.optionRepository,
          localeService: widget.localeService,
          settingsService: widget.settingsService,
          driveBackupService: widget.driveBackupService,
          entry: entry,
          initialDate: initialDate,
          initialFocusTarget: initialFocusTarget,
        ),
      ),
    );
  }

  void _openTodayBoardSketch(_HomeHubData data) {
    final board = data.latestBoard;
    if (board != null && data.loggedBoardToday) {
      unawaited(_openBoard(context, board));
      return;
    }
    final entry = data.latestCreatedTrainingEntry;
    if (entry != null) {
      final createdDay = DateTime(
        entry.createdAt.year,
        entry.createdAt.month,
        entry.createdAt.day,
      );
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (createdDay == today) {
        widget.onEditTrainingBoard(entry);
        return;
      }
    }
    unawaited(widget.onCreateTrainingBoard(initialDate: DateTime.now()));
  }

  Future<void> _openLevelGuide() async {
    final levelState = PlayerLevelService(widget.optionRepository).loadState();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerLevelGuideScreen(
          currentLevel: levelState.level,
          optionRepository: widget.optionRepository,
          driveBackupService: widget.driveBackupService,
        ),
      ),
    );
  }

  bool _openedNewsToday() {
    final raw = widget.optionRepository.getValue<String>(
      NewsScreen.openedItemsKey,
    );
    if (raw == null || raw.trim().isEmpty) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return false;
      for (final item in decoded) {
        if (item is! Map) continue;
        final openedAt = DateTime.tryParse(item['openedAt']?.toString() ?? '');
        if (openedAt == null) continue;
        final openedDay = DateTime(openedAt.year, openedAt.month, openedAt.day);
        if (openedDay == today) return true;
      }
    } catch (_) {
      return false;
    }
    return false;
  }
}

class _HomeHubData {
  final int weeklyTrainingCount;
  final int weeklyMinutes;
  final int streakDays;
  final DateTime? latestTrainingDay;
  final int? latestTrainingGapDays;
  final List<_RecentTrainingMarker> recentTrainingMarkers;
  final int boardCount;
  final DateTime? latestBoardUpdatedAt;
  final TrainingBoard? latestBoard;
  final int todayPlanCount;
  final List<_PlanDaySummary> upcomingPlanDays;
  final String strongestSignal;
  final String focusSignal;
  final TrainingEntry? latestTrainingEntry;
  final TrainingEntry? latestCreatedTrainingEntry;
  final bool loggedTrainingToday;
  final bool loggedLiftingToday;
  final bool loggedJumpRopeToday;
  final bool loggedMealsToday;
  final bool openedNewsToday;
  final bool reviewedTodayDiary;
  final bool quizCompletedToday;
  final bool loggedBoardToday;
  final MealEntry? todayMealEntry;
  final SkillQuizResumeSummary quizResumeSummary;

  const _HomeHubData({
    required this.weeklyTrainingCount,
    required this.weeklyMinutes,
    required this.streakDays,
    required this.latestTrainingDay,
    required this.latestTrainingGapDays,
    required this.recentTrainingMarkers,
    required this.boardCount,
    required this.latestBoardUpdatedAt,
    required this.latestBoard,
    required this.todayPlanCount,
    required this.upcomingPlanDays,
    required this.strongestSignal,
    required this.focusSignal,
    required this.latestTrainingEntry,
    required this.latestCreatedTrainingEntry,
    required this.loggedTrainingToday,
    required this.loggedLiftingToday,
    required this.loggedJumpRopeToday,
    required this.loggedMealsToday,
    required this.openedNewsToday,
    required this.reviewedTodayDiary,
    required this.quizCompletedToday,
    required this.loggedBoardToday,
    required this.todayMealEntry,
    required this.quizResumeSummary,
  });

  bool get showStreakHighlight =>
      streakDays >= 2 &&
      latestTrainingGapDays != null &&
      latestTrainingGapDays! <= 5;

  bool get streakIsActive =>
      latestTrainingGapDays != null && latestTrainingGapDays! <= 1;

  factory _HomeHubData.build({
    required List<TrainingEntry> entries,
    required List<MealEntry> mealEntries,
    required List<_DashboardPlan> plans,
    required List<TrainingBoard> boards,
    required DateTime? quizCompletedAt,
    required String? viewedDiaryDayToken,
    required SkillQuizResumeSummary quizResumeSummary,
    required bool openedNewsToday,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEndExclusive = weekStart.add(const Duration(days: 7));
    final weeklyEntries = entries
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
    final latestTrainingEntry = entries.isEmpty ? null : entries.first;
    final latestCreatedTrainingEntry = entries
        .where((entry) {
          final createdDay = DateTime(
            entry.createdAt.year,
            entry.createdAt.month,
            entry.createdAt.day,
          );
          return createdDay == today;
        })
        .fold<TrainingEntry?>(
          null,
          (latest, entry) =>
              latest == null || entry.createdAt.isAfter(latest.createdAt)
              ? entry
              : latest,
        );
    final todayEntries = entries
        .where((entry) {
          final day = DateTime(
            entry.date.year,
            entry.date.month,
            entry.date.day,
          );
          return day == today;
        })
        .toList(growable: false);
    final loggedTrainingToday = todayEntries.isNotEmpty;
    final loggedLiftingToday = todayEntries.any(
      (entry) => entry.liftingByPart.values.any((value) => value > 0),
    );
    final loggedJumpRopeToday = todayEntries.any(_hasCompletedJumpRope);
    final todayMealEntry = mealEntries
        .where((entry) {
          final day = DateTime(
            entry.date.year,
            entry.date.month,
            entry.date.day,
          );
          return day == today;
        })
        .fold<MealEntry?>(
          null,
          (latest, entry) =>
              latest == null || entry.createdAt.isAfter(latest.createdAt)
              ? entry
              : latest,
        );
    final loggedMealsToday =
        todayMealEntry != null && todayMealEntry.hasRecords;

    final entryDays = entries
        .map(
          (entry) =>
              DateTime(entry.date.year, entry.date.month, entry.date.day),
        )
        .toSet();
    final latestTrainingDay = entryDays.isEmpty
        ? null
        : entryDays.reduce((latest, day) => day.isAfter(latest) ? day : latest);
    var streakDays = 0;
    DateTime? cursor = latestTrainingDay;
    while (cursor != null && entryDays.contains(cursor)) {
      streakDays++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    final latestTrainingGapDays = latestTrainingDay == null
        ? null
        : today.difference(latestTrainingDay).inDays;
    final recentTrainingMarkers = List<_RecentTrainingMarker>.generate(5, (
      index,
    ) {
      final day = today.subtract(Duration(days: 4 - index));
      return _RecentTrainingMarker(day: day, recorded: entryDays.contains(day));
    });

    final todayPlanCount = plans.where((plan) {
      final day = DateTime(
        plan.scheduledAt.year,
        plan.scheduledAt.month,
        plan.scheduledAt.day,
      );
      return day == today;
    }).length;
    final planDayCount = <DateTime, int>{};
    for (final plan in plans) {
      final day = DateTime(
        plan.scheduledAt.year,
        plan.scheduledAt.month,
        plan.scheduledAt.day,
      );
      if (day.isBefore(today)) continue;
      planDayCount[day] = (planDayCount[day] ?? 0) + 1;
    }
    final upcomingPlanDays = planDayCount.entries.toList(growable: false)
      ..sort((a, b) => a.key.compareTo(b.key));
    final upcomingPlanDaySummaries = upcomingPlanDays
        .take(7)
        .map((entry) => _PlanDaySummary(day: entry.key, count: entry.value))
        .toList(growable: false);
    final totalMood = weeklyEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.mood,
    );
    final averageMood = weeklyEntries.isEmpty
        ? 0
        : totalMood / weeklyEntries.length;

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
    } else if (!loggedMealsToday) {
      focus = 'meal_routine';
    } else if (weeklyEntries.length < 3) {
      focus = 'add_session';
    } else if (weeklyMinutes < 150) {
      focus = 'add_minutes';
    } else if (averageMood < 3) {
      focus = 'recovery';
    } else {
      focus = 'upgrade_quality';
    }

    final quizCompletedToday =
        quizCompletedAt != null &&
        quizCompletedAt.year == now.year &&
        quizCompletedAt.month == now.month &&
        quizCompletedAt.day == now.day;
    final reviewedTodayDiary =
        viewedDiaryDayToken == CoachLessonScreen.todayViewedDayToken(now);
    final loggedBoardToday =
        boards.isNotEmpty &&
        boards.first.updatedAt.year == now.year &&
        boards.first.updatedAt.month == now.month &&
        boards.first.updatedAt.day == now.day;

    return _HomeHubData(
      weeklyTrainingCount: weeklyEntries.length,
      weeklyMinutes: weeklyMinutes,
      streakDays: streakDays,
      latestTrainingDay: latestTrainingDay,
      latestTrainingGapDays: latestTrainingGapDays,
      recentTrainingMarkers: recentTrainingMarkers,
      boardCount: boards.length,
      latestBoardUpdatedAt: boards.isEmpty ? null : boards.first.updatedAt,
      latestBoard: boards.isEmpty ? null : boards.first,
      todayPlanCount: todayPlanCount,
      upcomingPlanDays: upcomingPlanDaySummaries,
      strongestSignal: strongest,
      focusSignal: focus,
      latestTrainingEntry: latestTrainingEntry,
      latestCreatedTrainingEntry: latestCreatedTrainingEntry,
      loggedTrainingToday: loggedTrainingToday,
      loggedLiftingToday: loggedLiftingToday,
      loggedJumpRopeToday: loggedJumpRopeToday,
      loggedMealsToday: loggedMealsToday,
      openedNewsToday: openedNewsToday,
      reviewedTodayDiary: reviewedTodayDiary,
      quizCompletedToday: quizCompletedToday,
      loggedBoardToday: loggedBoardToday,
      todayMealEntry: todayMealEntry,
      quizResumeSummary: quizResumeSummary,
    );
  }
}

class _DashboardPlan {
  final DateTime scheduledAt;

  const _DashboardPlan({required this.scheduledAt});

  factory _DashboardPlan.fromMap(Map<String, dynamic> map) {
    return _DashboardPlan(
      scheduledAt:
          DateTime.tryParse(map['scheduledAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class _PlanDaySummary {
  final DateTime day;
  final int count;

  const _PlanDaySummary({required this.day, required this.count});
}

class _RecentTrainingMarker {
  final DateTime day;
  final bool recorded;

  const _RecentTrainingMarker({required this.day, required this.recorded});
}

bool _hasCompletedJumpRope(TrainingEntry entry) {
  if (!entry.jumpRopeEnabled) return false;
  return entry.jumpRopeCount > 0 || entry.jumpRopeMinutes > 0;
}

class _TodayPlanHighlightCard extends StatelessWidget {
  final bool isKo;
  final int count;
  final VoidCallback onTap;

  const _TodayPlanHighlightCard({
    required this.isKo,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.event_note_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isKo ? '오늘의 훈련 계획' : 'Today training plan',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isKo
                          ? '등록된 계획 $count개를 바로 확인하세요.'
                          : 'Open your $count saved plans for today.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isKo ? '계획 보기' : 'Open plans',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.primary,
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

class _LevelHeroCard extends StatelessWidget {
  final PlayerLevelState levelState;
  final bool isKo;
  final VoidCallback onTap;

  const _LevelHeroCard({
    required this.levelState,
    required this.isKo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final spec = PlayerLevelVisualSpec.fromLevel(levelState.level);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('level-hero-card'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                spec.colors.first.withValues(alpha: 0.92),
                spec.colors.last.withValues(alpha: 0.92),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.20),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Lv.${levelState.level}',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                PlayerLevelService.levelName(
                                  levelState.level,
                                  isKo,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isKo
                              ? '다음까지 ${levelState.xpToNextLevel}XP'
                              : '${levelState.xpToNextLevel} XP left',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _HomeLevelIllustration(isKo: isKo, level: levelState.level),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: levelState.progress,
                minHeight: 5,
                borderRadius: BorderRadius.circular(999),
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyFlowCard extends StatelessWidget {
  final _HomeHubData data;
  final bool isKo;
  final AppLocalizations l10n;
  final VoidCallback? onLog;
  final VoidCallback? onLifting;
  final VoidCallback? onJumpRope;
  final VoidCallback? onMeal;
  final VoidCallback? onQuiz;
  final VoidCallback? onReview;
  final VoidCallback? onNews;
  final VoidCallback? onBoard;

  const _DailyFlowCard({
    required this.data,
    required this.isKo,
    required this.l10n,
    required this.onLog,
    required this.onLifting,
    required this.onJumpRope,
    required this.onMeal,
    required this.onQuiz,
    required this.onReview,
    required this.onNews,
    required this.onBoard,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount = <bool>[
      data.loggedTrainingToday,
      data.loggedLiftingToday,
      data.loggedJumpRopeToday,
      data.loggedMealsToday,
      data.openedNewsToday,
      data.quizCompletedToday,
      data.reviewedTodayDiary,
      data.loggedBoardToday,
    ].where((done) => done).length;
    final progress = completedCount / 8;
    return WatchCartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isKo ? '오늘 할 일' : 'Today tasks',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                isKo ? '$completedCount/8 완료' : '$completedCount/8 done',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 8),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.0,
            children: [
              _TodoChip(
                done: data.loggedTrainingToday,
                icon: Icons.menu_book_rounded,
                label: isKo ? '훈련기록' : 'Training',
                onTap: onLog,
              ),
              _TodoChip(
                done: data.loggedLiftingToday,
                icon: Icons.fitness_center_rounded,
                label: isKo ? '리프팅' : 'Lifting',
                onTap: onLifting,
              ),
              _TodoChip(
                done: data.loggedJumpRopeToday,
                icon: Icons.sports_gymnastics_rounded,
                label: isKo ? '줄넘기' : 'Jump',
                onTap: onJumpRope,
              ),
              _TodoChip(
                done: data.loggedMealsToday,
                icon: Icons.rice_bowl_outlined,
                label: l10n.mealShortLabel,
                onTap: onMeal,
              ),
              _TodoChip(
                done: data.quizCompletedToday,
                icon: Icons.quiz_rounded,
                label: isKo ? '퀴즈' : 'Quiz',
                onTap: onQuiz,
              ),
              _TodoChip(
                done: data.openedNewsToday,
                icon: Icons.article_outlined,
                label: l10n.tabNews,
                onTap: onNews,
              ),
              _TodoChip(
                done: data.reviewedTodayDiary,
                icon: Icons.auto_stories_rounded,
                label: isKo ? '다이어리' : 'Diary',
                onTap: onReview,
              ),
              _TodoChip(
                done: data.loggedBoardToday,
                icon: Icons.developer_board_outlined,
                label: isKo ? '훈련스케치' : 'Sketch',
                onTap: onBoard,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriorityActionCard extends StatelessWidget {
  final String focusSignal;
  final bool isKo;
  final AppLocalizations l10n;
  final MealEntry? todayMealEntry;
  final MealCoachingService mealCoachingService;
  final VoidCallback? onPrimaryTap;

  const _PriorityActionCard({
    required this.focusSignal,
    required this.isKo,
    required this.l10n,
    required this.todayMealEntry,
    required this.mealCoachingService,
    required this.onPrimaryTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (message, buttonLabel, icon, supportingText) = _copy();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.95),
            theme.colorScheme.primaryContainer.withValues(alpha: 0.70),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      maxLines: 2,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    if (supportingText != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        supportingText,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onPrimaryTap,
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: const Size(1, 44),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: Text(
                  buttonLabel,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  (String, String, IconData, String?) _copy() {
    final mealStatus = todayMealEntry == null
        ? null
        : mealCoachingService.statusForMealEntry(todayMealEntry!);
    switch (focusSignal) {
      case 'log_today':
        return (
          isKo
              ? '오늘 기록 전, 남은 계획을 먼저 확인하세요.'
              : 'Check the remaining plans before logging today.',
          isKo ? '계획 보기' : 'Open plans',
          Icons.event_note_outlined,
          null,
        );
      case 'add_session':
        return (
          isKo
              ? '주간 흐름을 보고 다음 세션을 추가하세요.'
              : 'Review the weekly flow before adding another session.',
          isKo ? '주간 통계 보기' : 'Open weekly stats',
          Icons.bar_chart_outlined,
          null,
        );
      case 'add_minutes':
        return (
          isKo
              ? '다음 훈련 길이는 보드에서 먼저 잡아두세요.'
              : 'Shape the next longer session on the board first.',
          isKo ? '훈련판 열기' : 'Open board',
          Icons.developer_board_outlined,
          null,
        );
      case 'meal_routine':
        return (
          _mealSuggestionHeadline(mealStatus),
          l10n.homeMealCoachRecordAction,
          Icons.rice_bowl_outlined,
          _mealSuggestionBody(mealStatus),
        );
      case 'recovery':
        return (
          isKo
              ? '최근 컨디션 흐름을 보고 강도를 조절하세요.'
              : 'Review the recent condition trend before adjusting load.',
          isKo ? '주간 통계 보기' : 'Open weekly stats',
          Icons.monitor_heart_outlined,
          null,
        );
      default:
        return (
          isKo
              ? '보상 확인 후 다음 훈련 흐름을 바로 잡아보세요.'
              : 'Review rewards, then shape the next training flow.',
          isKo ? '레벨 가이드' : 'Level guide',
          Icons.military_tech_outlined,
          null,
        );
    }
  }

  String _mealSuggestionHeadline(MealStatus? status) {
    final completed = status?.completedMeals ?? 0;
    return switch (completed) {
      3 => l10n.homeMealCoachHeadlinePerfect,
      2 => l10n.homeMealCoachHeadlineAlmost,
      1 => l10n.homeMealCoachHeadlineNeedsMore,
      _ => l10n.homeMealCoachHeadlineStart,
    };
  }

  String _mealSuggestionBody(MealStatus? status) {
    if (status == null) {
      return l10n.homeMealCoachNoEntry;
    }
    final breakfast = status.breakfastDone
        ? l10n.mealRiceBowlsValue(_formatMealBowls(status.breakfastRiceBowls))
        : l10n.mealSkipped;
    final lunch = status.lunchDone
        ? l10n.mealRiceBowlsValue(_formatMealBowls(status.lunchRiceBowls))
        : l10n.mealSkipped;
    final dinner = status.dinnerDone
        ? l10n.mealRiceBowlsValue(_formatMealBowls(status.dinnerRiceBowls))
        : l10n.mealSkipped;
    return l10n.homeMealCoachSummary(
      l10n.mealBreakfast,
      breakfast,
      l10n.mealLunch,
      lunch,
      l10n.mealDinner,
      dinner,
    );
  }

  String _formatMealBowls(double bowls) {
    return bowls == bowls.truncateToDouble()
        ? bowls.toStringAsFixed(0)
        : bowls.toStringAsFixed(1);
  }
}

class _TrainingStreakSpotlightCard extends StatelessWidget {
  final _HomeHubData data;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const _TrainingStreakSpotlightCard({
    required this.data,
    required this.l10n,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gapDays = data.latestTrainingGapDays ?? 0;
    final isActive = data.streakIsActive;
    final badgeLabel = isActive
        ? l10n.homeStreakBadgeActive
        : l10n.homeStreakBadgeResume;
    final title = gapDays == 0
        ? l10n.homeStreakActiveTodayTitle(data.streakDays)
        : gapDays == 1
        ? l10n.homeStreakActiveYesterdayTitle(data.streakDays)
        : l10n.homeStreakPausedTitle(data.streakDays);
    final body = gapDays == 0
        ? l10n.homeStreakActiveTodayBody
        : gapDays == 1
        ? l10n.homeStreakActiveYesterdayBody
        : l10n.homeStreakPausedBody(gapDays);
    final actionLabel = gapDays == 0
        ? l10n.homeStreakActionReview
        : l10n.homeStreakActionContinue;
    final gradientColors = isActive
        ? const <Color>[Color(0xFFFFCB8E), Color(0xFFF56E56)]
        : const <Color>[Color(0xFFF0E7CE), Color(0xFFD6DDE8)];
    final foreground = isActive
        ? const Color(0xFF4A1C07)
        : const Color(0xFF1F3344);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x17111827),
            blurRadius: 12,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isActive
                      ? Icons.local_fire_department_rounded
                      : Icons.route_rounded,
                  color: foreground,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badgeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  l10n.homeStreakDaysValue(data.streakDays),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: foreground.withValues(alpha: 0.84),
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: data.recentTrainingMarkers
                      .map(
                        (marker) => Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _RecentTrainingMarkerChip(
                              marker: marker,
                              foreground: foreground,
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: foreground,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(actionLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentTrainingMarkerChip extends StatelessWidget {
  final _RecentTrainingMarker marker;
  final Color foreground;

  const _RecentTrainingMarkerChip({
    required this.marker,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: marker.recorded
            ? Colors.white.withValues(alpha: 0.24)
            : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: marker.recorded
              ? Colors.white.withValues(alpha: 0.34)
              : Colors.white.withValues(alpha: 0.18),
        ),
      ),
      child: Icon(
        marker.recorded ? Icons.check_rounded : Icons.remove_rounded,
        size: 11,
        color: foreground,
      ),
    );
  }
}

class _TodayWeatherButton extends StatelessWidget {
  final AppLocalizations l10n;
  final bool weatherLoading;
  final bool weatherNeedsLocation;
  final String weatherSummary;
  final int? weatherCode;
  final VoidCallback onTap;

  const _TodayWeatherButton({
    required this.l10n,
    required this.weatherLoading,
    required this.weatherNeedsLocation,
    required this.weatherSummary,
    required this.weatherCode,
    required this.onTap,
  });

  IconData _weatherIcon(int? code) {
    switch (code) {
      case 0:
        return Icons.wb_sunny_outlined;
      case 1:
      case 2:
      case 3:
        return Icons.wb_cloudy_outlined;
      case 45:
      case 48:
        return Icons.foggy;
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
      case 80:
      case 81:
      case 82:
        return Icons.umbrella_outlined;
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return Icons.ac_unit;
      case 95:
      case 96:
      case 99:
        return Icons.thunderstorm_outlined;
      default:
        return Icons.cloud_outlined;
    }
  }

  _WeatherHeroPalette _palette(ThemeData theme) {
    if (weatherNeedsLocation && weatherSummary.isEmpty) {
      return _WeatherHeroPalette(
        gradientColors: [
          Color.lerp(
            theme.colorScheme.surfaceContainerHighest,
            theme.colorScheme.primaryContainer,
            0.36,
          )!,
          Color.lerp(
            theme.colorScheme.secondaryContainer,
            theme.colorScheme.surfaceContainerHighest,
            0.42,
          )!,
        ],
        foreground: theme.colorScheme.onPrimaryContainer,
        surface: Colors.white.withValues(alpha: 0.24),
        outline: theme.colorScheme.outline.withValues(alpha: 0.22),
      );
    }
    switch (weatherCode) {
      case 0:
        return _WeatherHeroPalette(
          gradientColors: [
            Color.lerp(
              theme.colorScheme.primaryContainer,
              Colors.amber.shade100,
              0.5,
            )!,
            Color.lerp(
              theme.colorScheme.secondaryContainer,
              Colors.lightBlue.shade100,
              0.48,
            )!,
          ],
          foreground: theme.colorScheme.onPrimaryContainer,
          surface: Colors.white.withValues(alpha: 0.24),
          outline: theme.colorScheme.primary.withValues(alpha: 0.12),
        );
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
      case 80:
      case 81:
      case 82:
      case 95:
      case 96:
      case 99:
        return _WeatherHeroPalette(
          gradientColors: [
            Color.lerp(
              theme.colorScheme.primaryContainer,
              Colors.blueGrey.shade200,
              0.58,
            )!,
            Color.lerp(
              theme.colorScheme.secondaryContainer,
              Colors.blue.shade100,
              0.45,
            )!,
          ],
          foreground: theme.colorScheme.onPrimaryContainer,
          surface: Colors.white.withValues(alpha: 0.22),
          outline: theme.colorScheme.primary.withValues(alpha: 0.12),
        );
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return _WeatherHeroPalette(
          gradientColors: [
            Color.lerp(
              theme.colorScheme.primaryContainer,
              Colors.cyan.shade50,
              0.56,
            )!,
            Color.lerp(
              theme.colorScheme.secondaryContainer,
              Colors.blue.shade50,
              0.54,
            )!,
          ],
          foreground: theme.colorScheme.onPrimaryContainer,
          surface: Colors.white.withValues(alpha: 0.26),
          outline: theme.colorScheme.primary.withValues(alpha: 0.12),
        );
      default:
        return _WeatherHeroPalette(
          gradientColors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.96),
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.88),
          ],
          foreground: theme.colorScheme.onPrimaryContainer,
          surface: Colors.white.withValues(alpha: 0.22),
          outline: theme.colorScheme.primary.withValues(alpha: 0.12),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasWeather = weatherSummary.isNotEmpty;
    final palette = _palette(theme);
    final parts = hasWeather
        ? _HomeWeatherBadgeParts.parse(weatherSummary)
        : _HomeWeatherBadgeParts(
            primary: weatherNeedsLocation
                ? l10n.homeWeatherNeedsLocationTitle
                : l10n.homeWeatherTitle,
            secondary: weatherNeedsLocation
                ? l10n.homeWeatherNeedsLocationSubtitle
                : null,
          );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: palette.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: weatherLoading
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.1,
                            color: palette.foreground,
                          ),
                        )
                      : Icon(
                          hasWeather
                              ? _weatherIcon(weatherCode)
                              : weatherNeedsLocation
                              ? Icons.location_searching_rounded
                              : Icons.cloud_off_outlined,
                          size: 17,
                          color: palette.foreground,
                        ),
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      parts.primary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: palette.foreground,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                    if (parts.secondary != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        parts.secondary!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: palette.foreground.withValues(alpha: 0.78),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: palette.foreground.withValues(alpha: 0.72),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeWeatherBadgeParts {
  final String primary;
  final String? secondary;

  const _HomeWeatherBadgeParts({
    required this.primary,
    required this.secondary,
  });

  factory _HomeWeatherBadgeParts.parse(String text) {
    final trimmed = text.trim();
    final match = RegExp(r'^(.+?)\s+(-?\d+(?:\.\d+)?°C)$').firstMatch(trimmed);
    if (match == null) {
      return _HomeWeatherBadgeParts(primary: trimmed, secondary: null);
    }
    return _HomeWeatherBadgeParts(primary: match.group(2)!, secondary: null);
  }
}

class _WeatherHeroPalette {
  final List<Color> gradientColors;
  final Color foreground;
  final Color surface;
  final Color outline;

  const _WeatherHeroPalette({
    required this.gradientColors,
    required this.foreground,
    required this.surface,
    required this.outline,
  });
}

class _PlanDaysCard extends StatelessWidget {
  final bool isKo;
  final List<_PlanDaySummary> days;
  final VoidCallback? onTap;

  const _PlanDaysCard({
    required this.isKo,
    required this.days,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final totalPlans = days.fold<int>(0, (sum, item) => sum + item.count);
    final next = days.first;
    final nextLabel = isKo
        ? '${next.day.month}월 ${next.day.day}일'
        : DateFormat('EEE M/d').format(next.day);
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final remainingDays = next.day.difference(today).inDays;
    final whenText = remainingDays <= 0
        ? (isKo ? '오늘' : 'Today')
        : remainingDays == 1
        ? (isKo ? '내일' : 'Tomorrow')
        : (isKo ? '$remainingDays일 뒤' : 'In $remainingDays days');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.event_note_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isKo ? '다음 훈련' : 'Next training',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isKo
                          ? '$nextLabel · ${next.count}개 예정'
                          : '$nextLabel · ${next.count} planned',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isKo
                          ? '$whenText · 앞으로 총 $totalPlans개'
                          : '$whenText · $totalPlans upcoming',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  final bool isKo;
  final String weatherOutfitLabel;
  final VoidCallback? onQuickMatch;
  final VoidCallback? onQuickPlan;
  final VoidCallback? onQuickWeatherOutfit;

  const _QuickActionGrid({
    required this.isKo,
    required this.weatherOutfitLabel,
    required this.onQuickMatch,
    required this.onQuickPlan,
    required this.onQuickWeatherOutfit,
  });

  @override
  Widget build(BuildContext context) {
    final primaryItems = <_QuickActionItem>[
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
        icon: Icons.checkroom_outlined,
        title: weatherOutfitLabel,
        onTap: onQuickWeatherOutfit,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isKo ? '빠른 실행' : 'Quick actions',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 3.1,
          ),
          itemCount: primaryItems.length,
          itemBuilder: (context, index) =>
              _QuickActionButton(item: primaryItems[index]),
        ),
      ],
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final _HomeHubData data;
  final bool isKo;
  final VoidCallback? onContinueQuiz;
  final VoidCallback? onContinueTraining;
  final VoidCallback? onContinueMatch;
  final VoidCallback? onContinuePlan;
  final VoidCallback? onContinueBoard;

  const _ContinueCard({
    required this.data,
    required this.isKo,
    required this.onContinueQuiz,
    required this.onContinueTraining,
    required this.onContinueMatch,
    required this.onContinuePlan,
    required this.onContinueBoard,
  });

  @override
  Widget build(BuildContext context) {
    final quizSummary = data.quizResumeSummary;
    final hasQuizSession = quizSummary.hasActiveSession;
    final latestTrainingEntry = data.latestTrainingEntry;
    final latestTrainingIsToday =
        latestTrainingEntry != null &&
        DateTime(
              latestTrainingEntry.date.year,
              latestTrainingEntry.date.month,
              latestTrainingEntry.date.day,
            ) ==
            DateTime.now().copyWith(
              hour: 0,
              minute: 0,
              second: 0,
              millisecond: 0,
              microsecond: 0,
            );
    final quizTitle = hasQuizSession
        ? (quizSummary.reviewMode
              ? (isKo ? '오답 복습 이어하기' : 'Continue wrong-answer review')
              : (isKo ? '퀴즈 이어하기' : 'Continue quiz'))
        : (isKo ? '새 퀴즈 시작' : 'Start quiz');
    final quizSubtitle = hasQuizSession
        ? (isKo
              ? '${quizSummary.currentIndex + 1} / ${quizSummary.totalQuestions} 진행 중'
              : 'In progress ${quizSummary.currentIndex + 1} / ${quizSummary.totalQuestions}')
        : (isKo ? '오늘 퀴즈를 다시 시작해요.' : 'Jump back into today’s quiz.');
    final items = <_ContinueItemData>[
      if (latestTrainingIsToday)
        _ContinueItemData(
          icon: Icons.edit_note_outlined,
          title: isKo ? '오늘 훈련 기록' : 'Today training log',
          subtitle: latestTrainingEntry.program.trim().isEmpty
              ? '${DateFormat('M/d').format(latestTrainingEntry.date)} · ${latestTrainingEntry.durationMinutes}${isKo ? '분' : ' min'}'
              : '${latestTrainingEntry.program.trim()} · ${DateFormat('M/d').format(latestTrainingEntry.date)}',
          buttonLabel: isKo ? '이어서 쓰기' : 'Continue',
          onPressed: onContinueTraining,
        ),
      if (data.todayPlanCount > 0)
        _ContinueItemData(
          icon: Icons.event_note_outlined,
          title: isKo ? '오늘 훈련 계획' : 'Today training plan',
          subtitle: isKo
              ? '오늘 계획 ${data.todayPlanCount}개가 있어요.'
              : '${data.todayPlanCount} plans are waiting today.',
          buttonLabel: isKo ? '계획 보기' : 'Open plans',
          onPressed: onContinuePlan,
        ),
      if (hasQuizSession)
        _ContinueItemData(
          icon: Icons.quiz_outlined,
          title: quizTitle,
          subtitle: quizSubtitle,
          buttonLabel: isKo ? '퀴즈 열기' : 'Open quiz',
          onPressed: onContinueQuiz,
        ),
      if (data.boardCount > 0)
        _ContinueItemData(
          icon: Icons.developer_board_outlined,
          title: isKo ? '최근 훈련보드' : 'Recent training board',
          subtitle: data.latestBoard == null
              ? (isKo
                    ? '스케치 ${data.boardCount}개'
                    : '${data.boardCount} sketches')
              : data.latestBoardUpdatedAt == null
              ? (isKo
                    ? '스케치 ${data.boardCount}개'
                    : '${data.boardCount} sketches')
              : (isKo
                    ? '${data.latestBoard!.title} · 최근 저장 ${DateFormat('M/d').format(data.latestBoardUpdatedAt!)}'
                    : '${data.latestBoard!.title} · saved ${DateFormat('M/d').format(data.latestBoardUpdatedAt!)}'),
          buttonLabel: isKo ? '바로 수정' : 'Edit now',
          onPressed: onContinueBoard,
        ),
    ];
    return WatchCartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isKo ? '이어하기' : 'Continue',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Text(
              isKo
                  ? '오늘은 이어서 할 액션이 없어요. 아래에서 새 도전을 골라보세요.'
                  : 'Nothing to continue today. Pick a fresh challenge below.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ContinueItem(item: item),
              ),
            ),
        ],
      ),
    );
  }
}

class _ContinueItemData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback? onPressed;

  const _ContinueItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
  });
}

class _ContinueItem extends StatelessWidget {
  final _ContinueItemData item;

  const _ContinueItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: item.onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.icon,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.buttonLabel,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: item.onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.18),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    strutStyle: const StrutStyle(
                      fontSize: 14,
                      height: 1.05,
                      forceStrutHeight: true,
                    ),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: 14,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
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

class _HomeLevelIllustration extends StatelessWidget {
  final bool isKo;
  final int level;

  const _HomeLevelIllustration({required this.isKo, required this.level});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.topRight,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned(
            right: 2,
            top: 0,
            child: PlayerLevelIllustration(level: level, size: 46),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
              ),
              child: Text(
                PlayerLevelService.illustrationLabel(level, isKo),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodoChip extends StatelessWidget {
  final bool done;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _TodoChip({
    required this.done,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: done
                  ? const Color(0xFF0FA968).withValues(alpha: 0.40)
                  : scheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                done ? Icons.check_circle : icon,
                size: 18,
                color: done ? const Color(0xFF0FA968) : scheme.primary,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  strutStyle: const StrutStyle(
                    fontSize: 14,
                    height: 1.05,
                    forceStrutHeight: true,
                  ),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 14,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
