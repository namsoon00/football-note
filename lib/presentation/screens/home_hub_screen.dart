import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../../application/backup_service.dart';
import '../../application/challenge_service.dart';
import '../../application/family_access_service.dart';
import '../../application/locale_service.dart';
import '../../application/meal_log_service.dart';
import '../../application/news_badge_service.dart';
import '../../application/player_level_service.dart';
import '../../application/settings_service.dart';
import '../../application/training_board_service.dart';
import '../../application/training_plan_reminder_service.dart';
import '../../application/training_service.dart';
import '../../application/weather_location_service.dart';
import '../../application/weather_shared_resource.dart';
import '../../domain/entities/training_board.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/meal_entry.dart';
import '../../domain/entities/training_entry.dart';
import '../../domain/repositories/option_repository.dart';
import '../localization/player_progression_localizations.dart';
import '../widgets/app_background.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_page_route.dart';
import '../widgets/player_level_visuals.dart';
import '../widgets/progress_star_gauge.dart';
import '../widgets/rinzy_mascot.dart';
import '../widgets/rice_bowl_summary.dart';
import '../widgets/shared_tab_header.dart';
import '../widgets/watch_cart/watch_cart_card.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'skill_quiz_screen.dart';
import 'news_screen.dart';
import 'notification_center_screen.dart';
import 'coach_lesson_screen.dart';
import 'challenge_screen.dart';
import 'entry_form_screen.dart';
import 'player_level_guide_screen.dart';
import 'running_coach_screen.dart';
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
  final ValueChanged<DateTime>? onOpenPlansForDay;
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
    this.onOpenPlansForDay,
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
  static const String _homeWeatherSnapshotKey = 'home_weather_snapshot_v1';
  static const int _homeTrainingLookbackDays = 400;

  bool _weatherLoading = false;
  bool _weatherNeedsLocation = true;
  bool _weatherLoadFailed = false;
  bool _weatherFetchInFlight = false;
  String _weatherLocation = '';
  String _weatherSummary = '';
  int? _weatherCode;
  Timer? _initialWeatherTimer;
  late Stream<List<TrainingEntry>> _trainingEntriesStream;
  bool _dailyTaskAwardInFlight = false;
  String? _lastDailyTaskAwardToken;
  bool _challengeFinalizeInFlight = false;
  String? _lastChallengeFinalizeSignature;

  bool get _isParentMode =>
      FamilyAccessService(widget.optionRepository).loadState().isParentMode;

  Stream<List<TrainingEntry>> _watchHomeTrainingEntries() {
    final today = _normalizeDay(DateTime.now());
    return widget.trainingService.watchEntriesInRange(
      today.subtract(const Duration(days: _homeTrainingLookbackDays)),
      today.add(const Duration(days: 1)),
    );
  }

  DateTime _normalizeDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  @override
  void initState() {
    super.initState();
    _trainingEntriesStream = _watchHomeTrainingEntries();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final hasFreshWeather = _applyCachedHomeWeather();
      if (!hasFreshWeather) {
        _scheduleInitialWeatherLoad();
      }
      _queueHomeActionSideEffect(
        () => NewsBadgeService.refresh(widget.optionRepository),
      );
    });
  }

  @override
  void didUpdateWidget(covariant HomeHubScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trainingService == oldWidget.trainingService) return;
    _trainingEntriesStream = _watchHomeTrainingEntries();
  }

  @override
  void dispose() {
    _initialWeatherTimer?.cancel();
    super.dispose();
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
            stream: _trainingEntriesStream,
            builder: (context, snapshot) {
              final allEntries = (snapshot.data ?? const <TrainingEntry>[])
                  .where((entry) => !entry.isMatch)
                  .toList()
                ..sort(TrainingEntry.compareByRecentCreated);
              return StreamBuilder<List<MealEntry>>(
                stream: widget.mealLogService.watchEntries(),
                builder: (context, mealSnapshot) {
                  final l10n = AppLocalizations.of(context)!;
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
                  final challengeService = ChallengeService(
                    widget.optionRepository,
                  );
                  final challengeProgress = challengeService.activeProgress(
                    trainingEntries: allEntries,
                    mealEntries: mealEntries,
                  );
                  final data = _HomeHubData.build(
                    entries: allEntries,
                    mealEntries: mealEntries,
                    plans: _loadPlans(widget.optionRepository),
                    boards: boards,
                    quizCompletedAt: _loadQuizCompletedAt(
                      widget.optionRepository,
                    ),
                    viewedDiaryDayToken:
                        widget.optionRepository.getValue<String>(
                      CoachLessonScreen.todayViewedDiaryDayKey,
                    ),
                    quizResumeSummary: SkillQuizScreen.loadResumeSummary(
                      widget.optionRepository,
                    ),
                    openedNewsToday: _openedNewsToday(),
                  );
                  _scheduleDailyTaskCompletionAwardIfNeeded(data);
                  if (challengeProgress != null) {
                    _scheduleChallengeFinalizeIfNeeded(challengeProgress);
                  }
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
                          onTap: _openLevelGuide,
                        ),
                        const SizedBox(height: 10),
                        _ChallengeHomeCard(
                          progress: challengeProgress,
                          title: challengeProgress == null
                              ? l10n.challengeTitle
                              : _challengeTemplateTitle(
                                  l10n,
                                  challengeProgress.template,
                                ),
                          onTap: _openChallenge,
                        ),
                        if (data.showStreakHighlight) ...[
                          const SizedBox(height: 10),
                          _TrainingStreakSpotlightCard(
                            data: data,
                            l10n: l10n,
                            onTap: data.latestTrainingGapDays == 0
                                ? widget.onOpenWeeklyStats
                                : () => _openTodayEntryOrCreate(data),
                          ),
                        ],
                        const SizedBox(height: 10),
                        RiceBowlSummaryCard(
                          entry: data.todayMealEntry,
                          title: l10n.homeRiceBowlTitle,
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
                                l10n.homeHubTitleShort,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _TodayWeatherButton(
                              l10n: l10n,
                              weatherLoading: _weatherLoading,
                              weatherNeedsLocation: _weatherNeedsLocation,
                              weatherLoadFailed: _weatherLoadFailed,
                              weatherSummary: _weatherSummary.trim(),
                              weatherCode: _weatherCode,
                              onTap: _weatherBadgeTapAction(),
                            ),
                          ],
                        ),
                        if (data.todayPlanCount > 0) ...[
                          const SizedBox(height: 8),
                          Builder(
                            builder: (context) {
                              final firstPlan = data.todayPlans.first;
                              final showLogAction = DateTime.now().isAfter(
                                firstPlan.endsAt,
                              );
                              return _TodayPlanHighlightCard(
                                l10n: l10n,
                                plans: data.todayPlans,
                                count: data.todayPlanCount,
                                onOpenPlans: widget.onOpenPlans,
                                onPrimaryAction: _isParentMode
                                    ? widget.onOpenPlans
                                    : showLogAction
                                        ? _trackedAction(
                                            'today_plan_log',
                                            () => unawaited(
                                                _openTodayPlanLog(data)),
                                          )
                                        : widget.onOpenPlans,
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 12),
                        _DailyFlowCard(
                          data: data,
                          l10n: l10n,
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
                          weatherOutfitLabel: l10n.homeWeatherOutfitButton,
                          runningCoachLabel: l10n.drawerRunningCoach,
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
                          onQuickRunningCoach: _trackedAction(
                            'quick_running_coach',
                            _openRunningCoach,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ContinueCard(
                          data: data,
                          onContinueQuiz: widget.onQuickQuiz,
                          onContinueTraining: () =>
                              _openTodayEntryOrCreate(data),
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

  bool _applyCachedHomeWeather() {
    final cachedSnapshot = WeatherSharedResource.cachedSnapshot(
      locale: Localizations.localeOf(context),
    );
    if (cachedSnapshot != null &&
        (cachedSnapshot.summary.trim().isNotEmpty ||
            cachedSnapshot.weatherCode != null)) {
      _applyHomeWeatherSnapshot(cachedSnapshot);
      return true;
    }
    final persistedSnapshot = _loadPersistedHomeWeather(
      Localizations.localeOf(context),
    );
    if (persistedSnapshot == null) return false;
    _applyHomeWeatherSnapshot(persistedSnapshot);
    return DateTime.now().difference(persistedSnapshot.fetchedAt) <
        WeatherSharedResource.cacheTtl;
  }

  void _applyHomeWeatherSnapshot(WeatherSharedSnapshot snapshot) {
    setState(() {
      _weatherNeedsLocation = false;
      _weatherLoadFailed = false;
      _weatherLocation = snapshot.location;
      _weatherCode = snapshot.weatherCode;
      _weatherSummary = snapshot.summary;
    });
  }

  WeatherSharedSnapshot? _loadPersistedHomeWeather(Locale locale) {
    final raw = widget.optionRepository.getValue<String>(
      _homeWeatherSnapshotKey,
    );
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final map = decoded.cast<String, dynamic>();
      if (map['localeTag']?.toString() != locale.toLanguageTag()) return null;
      final summary = map['summary']?.toString().trim() ?? '';
      final weatherCode = (map['weatherCode'] as num?)?.toInt();
      if (summary.isEmpty && weatherCode == null) return null;
      return WeatherSharedSnapshot(
        location: map['location']?.toString() ?? '',
        localeTag: locale.toLanguageTag(),
        fetchedAt: DateTime.tryParse(map['fetchedAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        summary: summary,
        weatherCode: weatherCode,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistHomeWeatherSnapshot(
    WeatherSharedSnapshot snapshot,
  ) async {
    if (snapshot.summary.trim().isEmpty && snapshot.weatherCode == null) {
      return;
    }
    await widget.optionRepository.setValue(
      _homeWeatherSnapshotKey,
      jsonEncode(<String, dynamic>{
        'location': snapshot.location,
        'localeTag': snapshot.localeTag,
        'fetchedAt': snapshot.fetchedAt.toIso8601String(),
        'summary': snapshot.summary,
        'weatherCode': snapshot.weatherCode,
      }),
    );
  }

  VoidCallback _weatherBadgeTapAction() {
    final needsUserLoad = _weatherLoadFailed ||
        (_weatherNeedsLocation && _weatherSummary.trim().isEmpty);
    if (!needsUserLoad) {
      return _openWeatherDetails;
    }
    return () => unawaited(_loadHomeWeather(requestPermission: true));
  }

  void _scheduleInitialWeatherLoad() {
    _initialWeatherTimer?.cancel();
    _initialWeatherTimer = Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      unawaited(_loadHomeWeather(requestPermission: false, showLoading: false));
    });
  }

  Future<void> _loadHomeWeather({
    required bool requestPermission,
    bool showLoading = true,
  }) async {
    if (_weatherFetchInFlight || !mounted) return;
    _weatherFetchInFlight = true;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    if (showLoading) {
      setState(() {
        _weatherLoading = true;
        if (requestPermission) {
          _weatherLoadFailed = false;
        }
      });
    } else if (requestPermission) {
      setState(() => _weatherLoadFailed = false);
    }
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          final hasWeather = _weatherSummary.trim().isNotEmpty;
          _weatherNeedsLocation = !hasWeather;
          _weatherLoadFailed = false;
          if (!hasWeather) {
            _weatherLocation = '';
            _weatherCode = null;
            _weatherSummary = '';
          }
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
            final hasWeather = _weatherSummary.trim().isNotEmpty;
            _weatherNeedsLocation = !hasWeather;
            _weatherLoadFailed = false;
            if (!hasWeather) {
              _weatherLocation = '';
              _weatherCode = null;
              _weatherSummary = '';
            }
          });
        }
        if (requestPermission && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.homeWeatherPermissionNeeded)),
          );
        }
        return;
      }

      Position? position;
      if (!requestPermission) {
        position = await Geolocator.getLastKnownPosition();
      }
      position ??= await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy:
              requestPermission ? LocationAccuracy.high : LocationAccuracy.low,
          timeLimit: Duration(seconds: requestPermission ? 8 : 5),
        ),
      );
      final placeFuture = _resolvePlaceName(
        latitude: position.latitude,
        longitude: position.longitude,
        isKo: isKo,
        koreaLabel: l10n.homeWeatherCountryKorea,
      ).timeout(const Duration(seconds: 5)).catchError((_) => '');
      final weatherFuture = WeatherSharedResource.fetchForCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
        l10n: l10n,
        locale: locale,
        allowRetry: false,
      )
          .then<WeatherSharedSnapshot?>((snapshot) => snapshot)
          .catchError((_) => null);
      final results = await Future.wait<Object?>([placeFuture, weatherFuture]);
      final place = results[0] as String;
      if (!mounted) return;
      final resolvedWeather = (results[1] as WeatherSharedSnapshot?)?.copyWith(
        location: place,
      );
      if (resolvedWeather != null && resolvedWeather.hasData) {
        WeatherSharedResource.primeSnapshot(resolvedWeather);
        unawaited(_persistHomeWeatherSnapshot(resolvedWeather));
      }
      if (resolvedWeather != null &&
          (resolvedWeather.summary.trim().isNotEmpty ||
              resolvedWeather.weatherCode != null)) {
        setState(() {
          _weatherNeedsLocation = false;
          _weatherLoadFailed = false;
          _weatherLocation = place;
          _weatherCode = resolvedWeather.weatherCode;
          _weatherSummary = resolvedWeather.summary;
        });
      } else {
        setState(() {
          final hasWeather = _weatherSummary.trim().isNotEmpty;
          _weatherNeedsLocation = !hasWeather && place.trim().isEmpty;
          _weatherLoadFailed = !hasWeather;
          if (!hasWeather) {
            _weatherLocation = place;
            _weatherCode = null;
            _weatherSummary = '';
          }
        });
        if (requestPermission && mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.homeWeatherLoadFailed)));
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          final hasWeather = _weatherSummary.trim().isNotEmpty;
          _weatherNeedsLocation = false;
          _weatherLoadFailed = !hasWeather;
          if (!hasWeather) {
            _weatherCode = null;
            _weatherSummary = '';
          }
        });
      }
      if (requestPermission && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.homeWeatherLoadFailed)));
      }
    } finally {
      _weatherFetchInFlight = false;
      if (mounted && showLoading) {
        setState(() => _weatherLoading = false);
      }
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

  Future<void> _openWeatherDetails({
    WeatherDetailInitialAction initialAction = WeatherDetailInitialAction.none,
  }) async {
    await Navigator.of(context).push(
      AppPageRoute(
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

  void _scheduleDailyTaskCompletionAwardIfNeeded(_HomeHubData data) {
    if (_isParentMode || !data.completedDailyTasks) return;
    final token = CoachLessonScreen.todayViewedDayToken(DateTime.now());
    if (_lastDailyTaskAwardToken == token || _dailyTaskAwardInFlight) return;
    _lastDailyTaskAwardToken = token;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_awardDailyTaskCompletion());
    });
  }

  Future<void> _awardDailyTaskCompletion() async {
    if (_dailyTaskAwardInFlight || !mounted) return;
    _dailyTaskAwardInFlight = true;
    try {
      final l10n = AppLocalizations.of(context)!;
      final isKo = Localizations.localeOf(context).languageCode == 'ko';
      final levelService = PlayerLevelService(widget.optionRepository);
      final award = await levelService.awardForDailyTasksCompleted();
      if (!mounted || award.gainedXp <= 0) return;
      final reminderService = TrainingPlanReminderService(
        widget.optionRepository,
        widget.settingsService,
      );
      await reminderService.showXpGainAlert(
        gainedXp: award.gainedXp,
        totalXp: award.after.totalXp,
        isKo: isKo,
        sourceLabel: l10n.homeDailyCheckTitle,
      );
      if (award.didLevelUp) {
        await reminderService.showLevelUpAlert(
          level: award.after.level,
          isKo: isKo,
        );
      }
    } finally {
      _dailyTaskAwardInFlight = false;
    }
  }

  void _scheduleChallengeFinalizeIfNeeded(ChallengeProgress progress) {
    if (_isParentMode) return;
    if (!progress.readyToFinalize()) return;
    final completedRounds = progress.rounds
        .where((round) => round.completed)
        .map((round) => round.round.number)
        .join(',');
    final signature =
        '${progress.run.id}:finalize:$completedRounds:${progress.rounds.length}';
    if (_challengeFinalizeInFlight ||
        _lastChallengeFinalizeSignature == signature) {
      return;
    }
    _lastChallengeFinalizeSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_finalizeChallenge(progress, signature));
    });
  }

  Future<void> _finalizeChallenge(
    ChallengeProgress progress,
    String signature,
  ) async {
    if (_challengeFinalizeInFlight || !mounted) return;
    _challengeFinalizeInFlight = true;
    try {
      await ChallengeService(widget.optionRepository).finalizeRun(
        progress: progress,
        playerLevelService: PlayerLevelService(widget.optionRepository),
      );
      if (mounted) setState(() {});
    } finally {
      _challengeFinalizeInFlight = false;
      _lastChallengeFinalizeSignature = signature;
    }
  }

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
    final raw = optionRepository.getValue<String>(
      SkillQuizScreen.completionKey,
    );
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> _openSettings(BuildContext context) async {
    await Navigator.of(context).push(
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
  }

  Future<void> _openNews() async {
    await Navigator.of(context).push(
      AppPageRoute(
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

  Future<void> _openRunningCoach() async {
    await Navigator.of(context).push(
      AppPageRoute(
        builder: (_) =>
            RunningCoachScreen(optionRepository: widget.optionRepository),
      ),
    );
  }

  Future<void> _openChallenge() async {
    await Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => ChallengeScreen(
          trainingService: widget.trainingService,
          mealLogService: widget.mealLogService,
          optionRepository: widget.optionRepository,
          localeService: widget.localeService,
          settingsService: widget.settingsService,
          driveBackupService: widget.driveBackupService,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openQuizShortcut() async {
    await Navigator.of(context).push(
      AppPageRoute(
        builder: (_) =>
            SkillQuizScreen(optionRepository: widget.optionRepository),
      ),
    );
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      AppPageRoute(
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
          readOnly: _isParentMode,
        ),
      ),
    );
  }

  VoidCallback? _trackedAction(String key, VoidCallback? action) {
    if (action == null) return null;
    return () {
      action();
      _queueHomeActionSideEffect(() => _trackHomeActionTap(key));
    };
  }

  void _queueHomeActionSideEffect(Future<void> Function() task) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(task());
    });
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

  void _openTodayEntryOrCreate(
    _HomeHubData data, {
    EntryFormInitialFocusTarget? initialFocusTarget,
  }) {
    final entry = data.latestTrainingEntry;
    if (_isParentMode) {
      if (entry == null) {
        _showParentFeedbackEntryGuide();
        widget.onOpenLogs();
        return;
      }
      if (initialFocusTarget == null) {
        unawaited(_openEntryForm(entry: entry, initialFocusViewOnly: true));
        return;
      }
      unawaited(
        _openEntryForm(
          entry: entry,
          initialFocusTarget: initialFocusTarget,
          initialFocusViewOnly: true,
        ),
      );
      return;
    }
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

  void _showParentFeedbackEntryGuide() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    AppFeedback.showMessage(
      context,
      text: l10n.parentFeedbackOpenExistingEntryBody,
    );
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _openEntryForm({
    TrainingEntry? entry,
    DateTime? initialDate,
    EntryFormInitialPlanContext? initialPlanContext,
    EntryFormInitialFocusTarget? initialFocusTarget,
    bool initialFocusViewOnly = false,
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
          initialPlanContext: initialPlanContext,
          initialFocusTarget: initialFocusTarget,
          initialFocusViewOnly: initialFocusViewOnly,
        ),
      ),
    );
  }

  Future<void> _openTodayPlanLog(_HomeHubData data) async {
    final selectedPlan = await _pickTodayPlanForLog(data.todayPlans);
    if (!mounted || selectedPlan == null) {
      return;
    }
    final scheduledDay = DateTime(
      selectedPlan.scheduledAt.year,
      selectedPlan.scheduledAt.month,
      selectedPlan.scheduledAt.day,
    );
    await _openEntryForm(
      initialDate: scheduledDay,
      initialPlanContext: EntryFormInitialPlanContext(
        scheduledAt: selectedPlan.scheduledAt,
        program: selectedPlan.category,
        durationMinutes: selectedPlan.durationMinutes,
        location: selectedPlan.location,
        note: selectedPlan.note,
      ),
    );
  }

  Future<_DashboardPlan?> _pickTodayPlanForLog(
    List<_DashboardPlan> plans,
  ) async {
    if (plans.isEmpty) {
      return null;
    }
    if (plans.length == 1) {
      return plans.first;
    }
    final l10n = AppLocalizations.of(context)!;
    return showModalBottomSheet<_DashboardPlan>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: plans.length + 1,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  title: Text(
                    l10n.homeTodayPlanSelectForLogTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                );
              }
              final plan = plans[index - 1];
              final title = plan.category.trim().isEmpty
                  ? l10n.drawerTrainingPlan
                  : plan.category.trim();
              return ListTile(
                title: Text(title),
                subtitle: Text(_planLogSubtitle(plan, l10n)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pop(plan),
              );
            },
          ),
        );
      },
    );
  }

  String _planLogSubtitle(_DashboardPlan plan, AppLocalizations l10n) {
    final timeLabel = _formatPlanTime(plan.scheduledAt, l10n: l10n);
    final durationLabel = l10n.minutes(plan.durationMinutes);
    final location = plan.location.trim();
    final note = plan.note.trim();
    if (note.isEmpty && location.isEmpty) {
      return '$timeLabel · $durationLabel';
    }
    final extras = <String>[
      if (location.isNotEmpty) location,
      if (note.isNotEmpty) note,
    ];
    return '$timeLabel · $durationLabel · ${extras.join(' · ')}';
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
      AppPageRoute(
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
  final List<_DashboardPlan> todayPlans;
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
    required this.todayPlans,
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

  int get dailyTaskTotalCount => 8;

  int get dailyTaskCompletedCount => <bool>[
        loggedTrainingToday,
        loggedLiftingToday,
        loggedJumpRopeToday,
        loggedMealsToday,
        openedNewsToday,
        quizCompletedToday,
        reviewedTodayDiary,
        loggedBoardToday,
      ].where((done) => done).length;

  bool get completedDailyTasks =>
      dailyTaskCompletedCount >= dailyTaskTotalCount;

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
    final latestCreatedTrainingEntry = entries.where((entry) {
      final createdDay = DateTime(
        entry.createdAt.year,
        entry.createdAt.month,
        entry.createdAt.day,
      );
      return createdDay == today;
    }).fold<TrainingEntry?>(
      null,
      (latest, entry) =>
          latest == null || entry.createdAt.isAfter(latest.createdAt)
              ? entry
              : latest,
    );
    final todayEntries = entries.where((entry) {
      final day = DateTime(
        entry.date.year,
        entry.date.month,
        entry.date.day,
      );
      return day == today;
    }).toList(growable: false);
    final loggedTrainingToday = todayEntries.isNotEmpty;
    final loggedLiftingToday = todayEntries.any(
      (entry) =>
          entry.liftingMinutes > 0 ||
          entry.liftingByPart.values.any((value) => value > 0),
    );
    final loggedJumpRopeToday = todayEntries.any(_hasCompletedJumpRope);
    final todayMealEntry = mealEntries.where((entry) {
      final day = DateTime(
        entry.date.year,
        entry.date.month,
        entry.date.day,
      );
      return day == today;
    }).fold<MealEntry?>(
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

    final todayPlans = plans.where((plan) {
      final day = DateTime(
        plan.scheduledAt.year,
        plan.scheduledAt.month,
        plan.scheduledAt.day,
      );
      return day == today;
    }).toList(growable: false)
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final remainingTodayPlans = todayPlans
        .where((plan) => !_isPlanCoveredByTrainingEntry(plan, entries))
        .toList(growable: false);
    final todayPlanCount = remainingTodayPlans.length;
    final quizCompletedToday = quizCompletedAt != null &&
        quizCompletedAt.year == now.year &&
        quizCompletedAt.month == now.month &&
        quizCompletedAt.day == now.day;
    final reviewedTodayDiary =
        viewedDiaryDayToken == CoachLessonScreen.todayViewedDayToken(now);
    final loggedBoardToday = boards.isNotEmpty &&
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
      todayPlans: remainingTodayPlans,
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

  static bool _isPlanCoveredByTrainingEntry(
    _DashboardPlan plan,
    Iterable<TrainingEntry> entries,
  ) {
    final planDay = DateTime(
      plan.scheduledAt.year,
      plan.scheduledAt.month,
      plan.scheduledAt.day,
    );
    final normalizedCategory = plan.category.trim().toLowerCase();
    final normalizedLocation = plan.location.trim().toLowerCase();
    var hasTrainingEntryOnPlanDay = false;
    for (final entry in entries) {
      if (entry.isMatch) continue;
      final entryDay = DateTime(
        entry.date.year,
        entry.date.month,
        entry.date.day,
      );
      if (entryDay != planDay) continue;
      hasTrainingEntryOnPlanDay = true;
      if (normalizedCategory.isEmpty && normalizedLocation.isEmpty) {
        return true;
      }
      final entryType = entry.type.trim().toLowerCase();
      final entryProgram = entry.program.trim().toLowerCase();
      final entryPrograms = entry.effectiveTrainingProgramMinutes.keys
          .map((program) => program.trim().toLowerCase())
          .where((program) => program.isNotEmpty)
          .toSet();
      final entryLocation = entry.location.trim().toLowerCase();
      final categoryMatches = normalizedCategory.isEmpty ||
          entryType == normalizedCategory ||
          entryProgram == normalizedCategory ||
          entryPrograms.contains(normalizedCategory);
      final locationMatches =
          normalizedLocation.isEmpty || entryLocation == normalizedLocation;
      if (categoryMatches && locationMatches) {
        return true;
      }
    }
    return hasTrainingEntryOnPlanDay && DateTime.now().isAfter(plan.endsAt);
  }
}

class _DashboardPlan {
  final String id;
  final DateTime scheduledAt;
  final String category;
  final int durationMinutes;
  final String location;
  final String note;

  const _DashboardPlan({
    required this.id,
    required this.scheduledAt,
    required this.category,
    required this.durationMinutes,
    required this.location,
    required this.note,
  });

  DateTime get endsAt => scheduledAt.add(Duration(minutes: durationMinutes));

  factory _DashboardPlan.fromMap(Map<String, dynamic> map) {
    return _DashboardPlan(
      id: map['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      scheduledAt: DateTime.tryParse(map['scheduledAt']?.toString() ?? '') ??
          DateTime.now(),
      category: map['category']?.toString() ?? '',
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 60,
      location: map['location']?.toString() ?? '',
      note: map['note']?.toString() ?? '',
    );
  }
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

String _challengeTemplateTitle(
  AppLocalizations l10n,
  ChallengeTemplate template,
) {
  return switch (template.id) {
    'starter_3' => l10n.challengeTemplateStarterTitle,
    'weekly_7' => l10n.challengeTemplateWeeklyTitle,
    'focus_14' => l10n.challengeTemplateFocusTitle,
    _ => l10n.challengeTitle,
  };
}

class _TodayPlanHighlightCard extends StatelessWidget {
  final AppLocalizations l10n;
  final List<_DashboardPlan> plans;
  final int count;
  final VoidCallback onOpenPlans;
  final VoidCallback? onPrimaryAction;

  const _TodayPlanHighlightCard({
    required this.l10n,
    required this.plans,
    required this.count,
    required this.onOpenPlans,
    required this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final firstPlan = plans.isEmpty ? null : plans.first;
    final showLogAction =
        firstPlan != null && DateTime.now().isAfter(firstPlan.endsAt);
    final location = firstPlan?.location.trim() ?? '';
    final category = firstPlan?.category.trim() ?? '';
    final detailText = [
      if (firstPlan != null) _formatPlanTime(firstPlan.scheduledAt, l10n: l10n),
      if (category.isNotEmpty) category,
      if (location.isNotEmpty) location,
    ].join(' · ');
    final summary = [
      l10n.homeTodayPlanCardSummary(count),
      if (detailText.isNotEmpty) detailText,
    ].join(' · ');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpenPlans,
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
            crossAxisAlignment: CrossAxisAlignment.center,
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
                child: Text(
                  summary,
                  key: const ValueKey('today-plan-summary-text'),
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              if (onPrimaryAction != null)
                Align(
                  alignment: Alignment.center,
                  child: FilledButton.tonal(
                    key: showLogAction
                        ? const ValueKey('today-plan-log-action')
                        : const ValueKey('today-plan-open-action'),
                    onPressed: onPrimaryAction,
                    child: Text(
                      showLogAction
                          ? l10n.tabLogs
                          : l10n.homeTodayPlanOpenAction,
                      maxLines: 2,
                      textAlign: TextAlign.center,
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

class _ChallengeHomeCard extends StatelessWidget {
  final ChallengeProgress? progress;
  final String title;
  final VoidCallback onTap;

  const _ChallengeHomeCard({
    required this.progress,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final activeRound = progress?.activeRound;
    final completed = progress?.completedRoundCount ?? 0;
    final total = progress?.totalRoundCount ?? 0;
    final challengeTintAlpha =
        theme.brightness == Brightness.dark ? 0.24 : 0.34;
    final challengeGoldAlpha =
        theme.brightness == Brightness.dark ? 0.18 : 0.28;
    final subtitle = progress == null
        ? l10n.homeChallengeEmptyBody
        : activeRound == null
            ? l10n.challengeCompletedSummary(title)
            : l10n.homeChallengeActiveBody(
                completed,
                total,
                activeRound.round.number,
              );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('home-challenge-card'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.alphaBlend(
                  const Color(0xFF40D697).withValues(alpha: challengeTintAlpha),
                  theme.colorScheme.surface,
                ),
                Color.alphaBlend(
                  const Color(0xFFFFC95A).withValues(alpha: challengeGoldAlpha),
                  theme.colorScheme.surface,
                ),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFF26A66D).withValues(
                alpha: theme.brightness == Brightness.dark ? 0.44 : 0.34,
              ),
            ),
          ),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.48),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: RinzyMascot(
                    size: 68,
                    progress: progress?.completionRate ?? 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    if (progress != null) ...[
                      const SizedBox(height: 10),
                      ProgressStarGauge(
                        progress: progress!.completionRate,
                        height: 28,
                        trackHeight: 7,
                        iconSize: 24,
                      ),
                    ],
                  ],
                ),
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
  final VoidCallback onTap;

  const _LevelHeroCard({required this.levelState, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final spec = PlayerLevelVisualSpec.fromLevel(levelState.level);
    final progressLabel = levelState.isMaxLevel
        ? l10n.homeLevelProgressMax(
            levelState.masteryStars,
            levelState.xpToNextMasteryStar,
          )
        : l10n.homeLevelProgressNext(levelState.xpToNextLevel);
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
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.playerLevelName(levelState.level),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
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
                          progressLabel,
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _HomeLevelIllustration(level: levelState.level),
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
    final completedCount = data.dailyTaskCompletedCount;
    final totalCount = data.dailyTaskTotalCount;
    final progress = completedCount / totalCount;
    return WatchCartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.homeDailyCheckTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              Text(
                l10n.homeDailyCheckCompletedCount(completedCount, totalCount),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ProgressStarGauge(
            progress: progress,
            height: 28,
            trackHeight: 7,
            iconSize: 24,
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
                label: l10n.homeTodoTrainingLogShort,
                onTap: onLog,
              ),
              _TodoChip(
                done: data.loggedLiftingToday,
                icon: Icons.fitness_center_rounded,
                label: l10n.homeTodoLiftingShort,
                onTap: onLifting,
              ),
              _TodoChip(
                done: data.loggedJumpRopeToday,
                icon: Icons.sports_gymnastics_rounded,
                label: l10n.homeTodoJumpRopeShort,
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
                label: l10n.homeTodoQuizShort,
                onTap: onQuiz,
              ),
              _TodoChip(
                done: data.openedNewsToday,
                icon: Icons.article_outlined,
                label: l10n.homeTodoNewsShort,
                onTap: onNews,
              ),
              _TodoChip(
                done: data.reviewedTodayDiary,
                icon: Icons.auto_stories_rounded,
                label: l10n.homeTodoDiaryShort,
                onTap: onReview,
              ),
              _TodoChip(
                done: data.loggedBoardToday,
                icon: Icons.developer_board_outlined,
                label: l10n.homeTodoBoardSketchShort,
                onTap: onBoard,
              ),
            ],
          ),
        ],
      ),
    );
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
    final badgeLabel =
        isActive ? l10n.homeStreakBadgeActive : l10n.homeStreakBadgeResume;
    final title = gapDays == 0
        ? l10n.homeStreakActiveTodayTitle(data.streakDays)
        : gapDays == 1
            ? l10n.homeStreakActiveYesterdayTitle(data.streakDays)
            : l10n.homeStreakPausedTitle(data.streakDays);
    final actionLabel = gapDays == 0
        ? l10n.homeStreakActionReview
        : l10n.homeStreakActionContinue;
    final gradientColors = isActive
        ? const <Color>[Color(0xFFFFCB8E), Color(0xFFF56E56)]
        : const <Color>[Color(0xFFF0E7CE), Color(0xFFD6DDE8)];
    final foreground =
        isActive ? const Color(0xFF4A1C07) : const Color(0xFF1F3344);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x17111827),
            blurRadius: 10,
            offset: Offset(0, 6),
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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isActive
                      ? Icons.local_fire_department_rounded
                      : Icons.route_rounded,
                  color: foreground,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
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
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 2,
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
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
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
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
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
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: foreground,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  actionLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    var weekdayLabel = DateFormat.E(
      Localizations.localeOf(context).toString(),
    ).format(marker.day);
    if (isKo && weekdayLabel.endsWith('요일')) {
      weekdayLabel = weekdayLabel.replaceAll('요일', '');
    }
    return Container(
      constraints: BoxConstraints(minWidth: isKo ? 28 : 38),
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: marker.recorded
            ? Colors.white.withValues(alpha: 0.34)
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: marker.recorded
              ? Colors.white.withValues(alpha: 0.44)
              : Colors.white.withValues(alpha: 0.16),
        ),
      ),
      child: Center(
        child: Text(
          weekdayLabel,
          key: ValueKey('streak-weekday-${marker.day.weekday}'),
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: marker.recorded ? FontWeight.w900 : FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _TodayWeatherButton extends StatelessWidget {
  final AppLocalizations l10n;
  final bool weatherLoading;
  final bool weatherNeedsLocation;
  final bool weatherLoadFailed;
  final String weatherSummary;
  final int? weatherCode;
  final VoidCallback onTap;

  const _TodayWeatherButton({
    required this.l10n,
    required this.weatherLoading,
    required this.weatherNeedsLocation,
    required this.weatherLoadFailed,
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
    if ((weatherNeedsLocation || weatherLoadFailed) && weatherSummary.isEmpty) {
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
            primary: weatherLoadFailed
                ? l10n.homeWeatherRetryTitle
                : weatherNeedsLocation
                    ? l10n.homeWeatherNeedsLocationTitle
                    : l10n.homeWeatherTitle,
            secondary: weatherLoadFailed
                ? l10n.homeWeatherRetrySubtitle
                : weatherNeedsLocation
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
                              : weatherLoadFailed
                                  ? Icons.refresh_rounded
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

String _formatPlanTime(DateTime value, {required AppLocalizations l10n}) {
  final languageCode = l10n.localeName.split('_').first;
  final pattern = switch (languageCode) {
    'ko' => 'a h:mm',
    'ja' => 'H:mm',
    _ => 'h:mm a',
  };
  return DateFormat(pattern, l10n.localeName).format(value);
}

class _QuickActionGrid extends StatelessWidget {
  final String weatherOutfitLabel;
  final String runningCoachLabel;
  final VoidCallback? onQuickMatch;
  final VoidCallback? onQuickPlan;
  final VoidCallback? onQuickWeatherOutfit;
  final VoidCallback? onQuickRunningCoach;

  const _QuickActionGrid({
    required this.weatherOutfitLabel,
    required this.runningCoachLabel,
    required this.onQuickMatch,
    required this.onQuickPlan,
    required this.onQuickWeatherOutfit,
    required this.onQuickRunningCoach,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primaryItems = <_QuickActionItem>[
      _QuickActionItem(
        icon: Icons.sports_soccer_outlined,
        title: l10n.homeQuickActionMatch,
        onTap: onQuickMatch,
      ),
      _QuickActionItem(
        icon: Icons.event_note_outlined,
        title: l10n.homeQuickActionPlan,
        onTap: onQuickPlan,
      ),
      _QuickActionItem(
        icon: Icons.checkroom_outlined,
        title: weatherOutfitLabel,
        onTap: onQuickWeatherOutfit,
      ),
      _QuickActionItem(
        icon: Icons.directions_run_outlined,
        title: runningCoachLabel,
        onTap: onQuickRunningCoach,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.homeQuickActionsTitle,
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
  final VoidCallback? onContinueQuiz;
  final VoidCallback? onContinueTraining;
  final VoidCallback? onContinueMatch;
  final VoidCallback? onContinuePlan;
  final VoidCallback? onContinueBoard;

  const _ContinueCard({
    required this.data,
    required this.onContinueQuiz,
    required this.onContinueTraining,
    required this.onContinueMatch,
    required this.onContinuePlan,
    required this.onContinueBoard,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final shortDateFormat = DateFormat('M/d', l10n.localeName);
    final quizSummary = data.quizResumeSummary;
    final hasQuizSession = quizSummary.hasActiveSession;
    final latestTrainingEntry = data.latestTrainingEntry;
    final latestTrainingIsToday = latestTrainingEntry != null &&
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
            ? l10n.homeContinueWrongAnswerReview
            : l10n.homeContinueQuiz)
        : l10n.homeContinueStartQuiz;
    final quizSubtitle = hasQuizSession
        ? l10n.homeContinueQuizProgress(
            quizSummary.currentIndex + 1,
            quizSummary.totalQuestions,
          )
        : l10n.homeContinueQuizStartSubtitle;
    final items = <_ContinueItemData>[
      if (latestTrainingIsToday)
        _ContinueItemData(
          icon: Icons.edit_note_outlined,
          title: l10n.homeContinueTodayTrainingLog,
          subtitle: _homeTrainingProgramLabel(latestTrainingEntry).isEmpty
              ? l10n.homeContinueTrainingDuration(
                  shortDateFormat.format(latestTrainingEntry.date),
                  latestTrainingEntry.durationMinutes,
                )
              : '${_homeTrainingProgramLabel(latestTrainingEntry)} · ${shortDateFormat.format(latestTrainingEntry.date)}',
          buttonLabel: l10n.homeContinueTrainingButton,
          onPressed: onContinueTraining,
        ),
      if (data.todayPlanCount > 0)
        _ContinueItemData(
          icon: Icons.event_note_outlined,
          title: l10n.homeContinueTodayPlanTitle,
          subtitle: l10n.homeContinueTodayPlanSubtitle(data.todayPlanCount),
          buttonLabel: l10n.homeContinuePlanButton,
          onPressed: onContinuePlan,
        ),
      if (hasQuizSession)
        _ContinueItemData(
          icon: Icons.quiz_outlined,
          title: quizTitle,
          subtitle: quizSubtitle,
          buttonLabel: l10n.homeContinueQuizButton,
          onPressed: onContinueQuiz,
        ),
      if (data.boardCount > 0)
        _ContinueItemData(
          icon: Icons.developer_board_outlined,
          title: l10n.homeContinueRecentBoardTitle,
          subtitle: data.latestBoard == null
              ? l10n.homeContinueBoardCount(data.boardCount)
              : data.latestBoardUpdatedAt == null
                  ? l10n.homeContinueBoardCount(data.boardCount)
                  : l10n.homeContinueBoardSaved(
                      data.latestBoard!.title,
                      shortDateFormat.format(data.latestBoardUpdatedAt!),
                    ),
          buttonLabel: l10n.homeContinueBoardButton,
          onPressed: onContinueBoard,
        ),
    ];
    return WatchCartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.homeContinueTitle,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Text(
              l10n.homeContinueEmpty,
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
  final int level;

  const _HomeLevelIllustration({required this.level});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                l10n.playerLevelIllustrationLabel(level),
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

String _homeTrainingProgramLabel(TrainingEntry entry) {
  final programs = entry.effectiveTrainingProgramMinutes.keys
      .map((program) => program.trim())
      .where((program) => program.isNotEmpty)
      .join(', ');
  if (programs.isNotEmpty) return programs;
  return entry.program.trim();
}
