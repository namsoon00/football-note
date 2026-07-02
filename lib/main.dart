import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'domain/entities/training_entry.dart';
import 'domain/repositories/option_repository.dart';
import 'infrastructure/auto_backup_option_repository.dart';
import 'infrastructure/hive_option_repository.dart';
import 'infrastructure/hive_training_repository.dart';
import 'application/training_service.dart';
import 'application/locale_service.dart';
import 'application/settings_service.dart';
import 'application/backup_service.dart';
import 'application/club_training_reminder_service.dart';
import 'application/drive_backup_service.dart';
import 'application/family_access_service.dart';
import 'application/meal_log_service.dart';
import 'application/league_fixture_reminder_service.dart';
import 'application/notification_app_link.dart';
import 'application/sport_service.dart';
import 'application/sport_state_controller.dart';
import 'application/training_plan_badge_service.dart';
import 'application/training_plan_reminder_service.dart';
import 'application/weather_reminder_service.dart';
import 'domain/entities/sport_definition.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/sport_start_selection_screen.dart';
import 'presentation/screens/welcome_screen.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/navigation/notification_tap_router.dart';
import 'presentation/widgets/keyboard_dismiss_overlay.dart';
import 'presentation/widgets/sport_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {
      // Firebase web config may be intentionally omitted for local/dev web runs.
    }
  }
  await Hive.initFlutter();
  Hive.registerAdapter(TrainingEntryAdapter());
  final trainingBox = await Hive.openBox<TrainingEntry>('training_entries');
  final optionBox = await Hive.openBox('options');
  await initializeDateFormatting('ko_KR');
  final trainingRepository = HiveTrainingRepository(trainingBox);
  final baseOptionRepository = HiveOptionRepository(optionBox);
  const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  final driveBackupRepository = DriveBackupService(
    trainingBox,
    optionBox,
    webClientId: webClientId,
  );
  final backupService = BackupService(driveBackupRepository);
  final optionRepository = AutoBackupOptionRepository(
    baseOptionRepository,
    backupService,
  );
  final localeService = LocaleService(optionRepository);
  localeService.load();
  final settingsService = SettingsService(optionRepository);
  settingsService.load();
  final sportController = SportStateController(optionRepository);
  final mealLogService = MealLogService(optionRepository);
  final trainingService = TrainingService(
    trainingRepository,
    backupService: backupService,
  );
  final reminderService = TrainingPlanReminderService(
    optionRepository,
    settingsService,
  );
  final leagueFixtureReminderService = LeagueFixtureReminderService(
    optionRepository,
    settingsService,
  );
  final weatherReminderService = WeatherReminderService(
    optionRepository,
    settingsService,
  );
  final clubTrainingReminderService = ClubTrainingReminderService(
    optionRepository,
    settingsService,
  );
  final badgeService = TrainingPlanBadgeService(optionRepository);
  NotificationTapRouter.configure(
    NotificationTapDependencies(
      trainingService: trainingService,
      mealLogService: mealLogService,
      optionRepository: optionRepository,
      localeService: localeService,
      settingsService: settingsService,
      driveBackupService: backupService,
    ),
  );
  TrainingPlanReminderService.onNotificationPayloadTap =
      NotificationTapRouter.handlePayload;
  LeagueFixtureReminderService.onNotificationPayloadTap =
      NotificationTapRouter.handlePayload;
  WeatherReminderService.onNotificationPayloadTap =
      NotificationTapRouter.handlePayload;
  ClubTrainingReminderService.onNotificationPayloadTap =
      NotificationTapRouter.handlePayload;
  settingsService.addListener(() {
    unawaited(reminderService.syncSettingsDrivenReminders());
    unawaited(weatherReminderService.syncSettingsDrivenReminders());
    unawaited(clubTrainingReminderService.syncSettingsDrivenReminders());
    if (!settingsService.reminderEnabled ||
        !settingsService.leagueFixtureAlertEnabled) {
      unawaited(leagueFixtureReminderService.clearAllReminders());
      unawaited(leagueFixtureReminderService.clearWorldCupReminders());
    }
    if (!settingsService.reminderEnabled ||
        !settingsService.weatherAlertEnabled) {
      unawaited(weatherReminderService.clearAllReminders());
    }
    if (!settingsService.reminderEnabled ||
        !settingsService.clubTrainingAlertEnabled) {
      unawaited(clubTrainingReminderService.clearAllReminders());
    }
  });

  runApp(
    FootballNoteApp(
      trainingService: trainingService,
      mealLogService: mealLogService,
      optionRepository: optionRepository,
      localeService: localeService,
      settingsService: settingsService,
      sportController: sportController,
      driveBackupService: backupService,
    ),
  );

  unawaited(
    _warmStartupServices(
      backupService: backupService,
      reminderService: reminderService,
      leagueFixtureReminderService: leagueFixtureReminderService,
      weatherReminderService: weatherReminderService,
      clubTrainingReminderService: clubTrainingReminderService,
      badgeService: badgeService,
      trainingService: trainingService,
    ),
  );
}

Future<void> _warmStartupServices({
  required BackupService backupService,
  required TrainingPlanReminderService reminderService,
  required LeagueFixtureReminderService leagueFixtureReminderService,
  required WeatherReminderService weatherReminderService,
  required ClubTrainingReminderService clubTrainingReminderService,
  required TrainingPlanBadgeService badgeService,
  required TrainingService trainingService,
}) async {
  var handledLaunchPayload = false;
  void handleLaunchPayload(String? payload) {
    if (handledLaunchPayload) return;
    final normalized = payload?.trim();
    if (normalized == null || normalized.isEmpty) return;
    handledLaunchPayload = true;
    NotificationTapRouter.handlePayload(normalized);
  }

  try {
    await backupService.autoBackupDaily();
  } catch (_) {
    // Ignore startup backup failures and keep app entry responsive.
  }
  try {
    if (backupService.hasPendingParentSharedChanges()) {
      await backupService.backupIfSignedIn();
    }
    await backupService.refreshFamilySharedDataIfNeeded();
  } catch (_) {
    // Family shared refresh can recover on later app resumes.
  }
  try {
    await reminderService.initialize();
    handleLaunchPayload(await reminderService.launchPayload());
    await reminderService.syncAll(entries: await trainingService.allEntries());
  } catch (_) {
    // Reminder sync can recover on later app interactions.
  }
  try {
    await leagueFixtureReminderService.initialize();
    handleLaunchPayload(await leagueFixtureReminderService.launchPayload());
  } catch (_) {
    // Fixture notification launch handling can recover on later interactions.
  }
  try {
    await weatherReminderService.initialize();
    handleLaunchPayload(await weatherReminderService.launchPayload());
    await weatherReminderService.syncSettingsDrivenReminders();
  } catch (_) {
    // Weather reminder sync can recover on later settings or app interactions.
  }
  try {
    await clubTrainingReminderService.initialize();
    handleLaunchPayload(await clubTrainingReminderService.launchPayload());
    await clubTrainingReminderService.syncSettingsDrivenReminders();
  } catch (_) {
    // Club training reminder sync can recover on later schedule changes.
  }
  try {
    await badgeService.syncFromStorage();
  } catch (_) {
    // Badge sync is non-critical for first frame.
  }
}

class FootballNoteApp extends StatelessWidget {
  final TrainingService trainingService;
  final MealLogService mealLogService;
  final OptionRepository optionRepository;
  final LocaleService localeService;
  final SettingsService settingsService;
  final SportStateController sportController;
  final BackupService? driveBackupService;

  const FootballNoteApp({
    super.key,
    required this.trainingService,
    required this.mealLogService,
    required this.optionRepository,
    required this.localeService,
    required this.settingsService,
    required this.sportController,
    this.driveBackupService,
  });

  @override
  Widget build(BuildContext context) {
    Widget entryGate(String sportId) => _EntryGate(
          key: ValueKey<String>('entry-gate-$sportId'),
          sportId: sportId,
          trainingService: trainingService,
          mealLogService: mealLogService,
          optionRepository: optionRepository,
          localeService: localeService,
          settingsService: settingsService,
          driveBackupService: driveBackupService,
        );

    return SportScope(
      controller: sportController,
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) => AnimatedBuilder(
          animation: Listenable.merge([
            localeService,
            settingsService,
            sportController,
          ]),
          builder: (context, _) {
            final sportId = sportController.currentSportId;
            return MaterialApp(
              onGenerateTitle: (context) =>
                  AppLocalizations.of(context)!.appTitle,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: settingsService.themeMode,
              navigatorKey: NotificationTapRouter.navigatorKey,
              locale: localeService.locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              onGenerateRoute: (settings) {
                final routeName = settings.name?.trim();
                if (routeName == null ||
                    NotificationAppLink.tryParse(routeName) == null) {
                  return null;
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  NotificationTapRouter.handlePayload(routeName);
                });
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (_) => entryGate(sportId),
                );
              },
              builder: (context, child) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final overlayStyle = (isDark
                        ? SystemUiOverlayStyle.light
                        : SystemUiOverlayStyle.dark)
                    .copyWith(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: isDark
                      ? const Color(0xFF0F131A)
                      : const Color(0xFFF6F8FC),
                  systemNavigationBarIconBrightness:
                      isDark ? Brightness.light : Brightness.dark,
                );
                return AnnotatedRegion<SystemUiOverlayStyle>(
                  value: overlayStyle,
                  child: _WebInitialFocusGuard(
                    child: KeyboardDismissOverlay(
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                );
              },
              home: entryGate(sportId),
            );
          },
        ),
      ),
    );
  }
}

class _WebInitialFocusGuard extends StatefulWidget {
  final Widget child;

  const _WebInitialFocusGuard({required this.child});

  @override
  State<_WebInitialFocusGuard> createState() => _WebInitialFocusGuardState();
}

class _WebInitialFocusGuardState extends State<_WebInitialFocusGuard> {
  bool _descendantsAreFocusable = !kIsWeb;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() => _descendantsAreFocusable = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: WidgetOrderTraversalPolicy(),
      descendantsAreFocusable: _descendantsAreFocusable,
      child: widget.child,
    );
  }
}

class _EntryGate extends StatefulWidget {
  final TrainingService trainingService;
  final MealLogService mealLogService;
  final OptionRepository optionRepository;
  final LocaleService localeService;
  final SettingsService settingsService;
  final BackupService? driveBackupService;
  final String sportId;

  const _EntryGate({
    super.key,
    required this.sportId,
    required this.trainingService,
    required this.mealLogService,
    required this.optionRepository,
    required this.localeService,
    required this.settingsService,
    this.driveBackupService,
  });

  @override
  State<_EntryGate> createState() => _EntryGateState();
}

class _EntryGateState extends State<_EntryGate> with WidgetsBindingObserver {
  static const String _welcomeSeenKey = 'welcome_seen_v1';

  bool _parentRefreshBusy = false;
  bool _startupSportSelected = false;
  bool _sportSelectionInFlight = false;
  bool _welcomeSeen = false;
  bool _welcomeDismissInFlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _welcomeSeen =
        widget.optionRepository.getValue<bool>(_welcomeSeenKey) ?? false;
    final hasStoredSport = widget.optionRepository.getValue<String>(
          SportCatalog.currentSportOptionKey,
        ) !=
        null;
    final isSupportMode =
        FamilyAccessService(widget.optionRepository).loadState().isSupportMode;
    _startupSportSelected = hasStoredSport || isSupportMode;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }
    unawaited(_refreshParentSharedDataOnResume());
  }

  Future<void> _refreshParentSharedDataOnResume() async {
    final backup = widget.driveBackupService;
    if (backup == null || _parentRefreshBusy) {
      return;
    }
    _parentRefreshBusy = true;
    try {
      final refreshed = await backup.refreshParentSharedDataIfNeeded();
      if (!refreshed) {
        return;
      }
      widget.localeService.load();
      widget.settingsService.load();
      if (!mounted) {
        return;
      }
      SportScope.read(context)?.reloadFromStorage();
      setState(() {});
    } finally {
      _parentRefreshBusy = false;
    }
  }

  void _markWelcomeSeen() {
    if (_welcomeDismissInFlight) {
      return;
    }
    _welcomeDismissInFlight = true;
    unawaited(_markWelcomeSeenAsync());
  }

  Future<void> _markWelcomeSeenAsync() async {
    try {
      await widget.optionRepository.setValue(_welcomeSeenKey, true);
      if (!mounted) {
        return;
      }
      setState(() {
        _welcomeSeen = true;
        _welcomeDismissInFlight = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _welcomeDismissInFlight = false);
    }
  }

  void _markStartupSportSelected(String sportId) {
    if (_sportSelectionInFlight) {
      return;
    }
    _sportSelectionInFlight = true;
    unawaited(_markStartupSportSelectedAsync(sportId));
  }

  Future<void> _markStartupSportSelectedAsync(String sportId) async {
    try {
      await SportService(widget.optionRepository).setCurrentSportId(sportId);
      if (!mounted) {
        return;
      }
      SportScope.read(context)?.reloadFromStorage();
      setState(() {
        _startupSportSelected = true;
        _sportSelectionInFlight = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _sportSelectionInFlight = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_startupSportSelected) {
      return SportStartSelectionScreen(onSelected: _markStartupSportSelected);
    }
    if (!_welcomeSeen) {
      return WelcomeScreen(onStart: _markWelcomeSeen);
    }
    return HomeScreen(
      key: ValueKey<String>('home-screen-${widget.sportId}'),
      trainingService: widget.trainingService,
      mealLogService: widget.mealLogService,
      optionRepository: widget.optionRepository,
      localeService: widget.localeService,
      settingsService: widget.settingsService,
      driveBackupService: widget.driveBackupService,
    );
  }
}
