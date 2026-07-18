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
import 'package:path_provider/path_provider.dart';
import 'firebase_options.dart';
import 'domain/entities/training_entry.dart';
import 'domain/repositories/backup_repository.dart';
import 'domain/repositories/option_repository.dart';
import 'infrastructure/auto_backup_option_repository.dart';
import 'infrastructure/hive_startup_recovery.dart';
import 'infrastructure/hive_option_repository.dart';
import 'infrastructure/hive_training_repository.dart';
import 'application/training_service.dart';
import 'application/firebase_startup.dart';
import 'application/locale_service.dart';
import 'application/settings_service.dart';
import 'application/backup_service.dart';
import 'application/club_training_reminder_service.dart';
import 'application/drive_backup_service.dart';
import 'application/family_access_service.dart';
import 'application/health_connect_jump_rope_import_notification_service.dart';
import 'application/health_connect_jump_rope_sync_service.dart';
import 'application/meal_log_service.dart';
import 'application/league_fixture_reminder_service.dart';
import 'application/notification_app_link.dart';
import 'application/sport_service.dart';
import 'application/sport_state_controller.dart';
import 'application/training_plan_reminder_service.dart';
import 'application/weather_reminder_service.dart';
import 'domain/entities/sport_definition.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/sport_start_selection_screen.dart';
import 'presentation/screens/welcome_screen.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/navigation/notification_tap_router.dart';
import 'presentation/widgets/football_loading_bar.dart';
import 'presentation/widgets/keyboard_dismiss_overlay.dart';
import 'presentation/widgets/sport_scope.dart';

const int _trainingEntryHiveTypeId = 1;

Future<void> main() async {
  runZonedGuarded<void>(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
      };
      runApp(const FootballNoteBootstrapApp());
    },
    (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'football_note startup',
        ),
      );
    },
  );
}

Future<void> _initializeFirebase() async {
  await initializeOptionalFirebase(
    isWeb: kIsWeb,
    isConfigured: DefaultFirebaseOptions.isCurrentPlatformConfigured,
    hasApps: () => Firebase.apps.isNotEmpty,
    initializeApp: () => Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ),
    reportError: (error, stackTrace) => FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'football_note startup',
        context: ErrorDescription('while initializing optional Firebase'),
      ),
    ),
  );
}

Future<_FootballNoteDependencies> _initializeAppDependencies() async {
  await _runStartupStage<void>('firebase', _initializeFirebase);
  final hivePath = await _runStartupStage<String?>(
    'hive_storage',
    _initializeHiveStorage,
  );
  await _runStartupStage<void>('hive_adapters', () async {
    if (!Hive.isAdapterRegistered(_trainingEntryHiveTypeId)) {
      Hive.registerAdapter(TrainingEntryAdapter());
    }
  });
  final trainingBox = await _runStartupStage<Box<TrainingEntry>>(
    'training_entries_box',
    () => openRecoverableHiveBox<TrainingEntry>(
      'training_entries',
      path: hivePath,
      compactionStrategy:
          HiveTrainingRepository.trainingEntryCompactionStrategy,
    ),
  );
  final trainingIndexBox = await _runStartupStage<Box<dynamic>>(
    'training_entries_index_box',
    () => openRecoverableHiveBox<dynamic>(
      HiveTrainingRepository.indexBoxNameFor('training_entries'),
      path: hivePath,
    ),
  );
  final optionBox = await _runStartupStage<Box<dynamic>>(
    'options_box',
    () => openRecoverableHiveBox<dynamic>(
      'options',
      path: hivePath,
    ),
  );
  await _runStartupStage<void>(
    'date_formatting',
    () => initializeDateFormatting('ko_KR'),
  );
  final trainingRepository = HiveTrainingRepository(
    trainingBox,
    indexBox: trainingIndexBox,
  );
  await _runStartupStage<void>(
    'training_entries_index',
    trainingRepository.ensureIndexReady,
  );
  final baseOptionRepository = HiveOptionRepository(optionBox);
  const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  final backupService = _createBackupService(
    trainingBox,
    optionBox,
    webClientId: webClientId,
  );
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
  final healthConnectJumpRopeImportNotificationService =
      MethodChannelHealthConnectJumpRopePlatform.isSupportedDevice
          ? HealthConnectJumpRopeImportNotificationService(
              optionRepository: optionRepository,
              settingsService: settingsService,
            )
          : null;
  final healthConnectJumpRopeSyncService =
      MethodChannelHealthConnectJumpRopePlatform.isSupportedDevice
          ? HealthConnectJumpRopeSyncService(
              trainingService: trainingService,
              optionRepository: optionRepository,
              importNotifier: healthConnectJumpRopeImportNotificationService!,
            )
          : null;
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
  HealthConnectJumpRopeImportNotificationService.onNotificationPayloadTap =
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

  unawaited(
    _warmStartupServices(
      backupService: backupService,
      settingsService: settingsService,
      reminderService: reminderService,
      leagueFixtureReminderService: leagueFixtureReminderService,
      weatherReminderService: weatherReminderService,
      clubTrainingReminderService: clubTrainingReminderService,
      trainingService: trainingService,
      healthConnectJumpRopeSyncService: healthConnectJumpRopeSyncService,
    ),
  );

  return _FootballNoteDependencies(
    trainingService: trainingService,
    mealLogService: mealLogService,
    optionRepository: optionRepository,
    localeService: localeService,
    settingsService: settingsService,
    sportController: sportController,
    backupService: backupService,
    healthConnectJumpRopeSyncService: healthConnectJumpRopeSyncService,
  );
}

Future<T> _runStartupStage<T>(
  String stage,
  FutureOr<T> Function() action,
) async {
  try {
    return await action();
  } catch (error, stackTrace) {
    Error.throwWithStackTrace(
      _StartupStageException(
        stage: stage,
        error: error,
      ),
      stackTrace,
    );
  }
}

BackupService _createBackupService(
  Box<TrainingEntry> trainingBox,
  Box<dynamic> optionBox, {
  required String webClientId,
}) {
  try {
    return BackupService(
      DriveBackupService(
        trainingBox,
        optionBox,
        webClientId: webClientId,
      ),
    );
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'football_note startup',
        context: ErrorDescription('while creating optional Drive backup'),
      ),
    );
    return BackupService(const _DisabledBackupRepository());
  }
}

Future<String?> _initializeHiveStorage() async {
  if (kIsWeb) {
    await Hive.initFlutter();
    return null;
  }
  final appDirectory = await getApplicationDocumentsDirectory();
  final hivePath = appDirectory.path;
  Hive.init(hivePath);
  return hivePath;
}

Future<void> _warmStartupServices({
  required BackupService backupService,
  required SettingsService settingsService,
  required TrainingPlanReminderService reminderService,
  required LeagueFixtureReminderService leagueFixtureReminderService,
  required WeatherReminderService weatherReminderService,
  required ClubTrainingReminderService clubTrainingReminderService,
  required TrainingService trainingService,
  required HealthConnectJumpRopeSyncService? healthConnectJumpRopeSyncService,
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
    if (settingsService.reminderEnabled) {
      await reminderService.initialize();
      handleLaunchPayload(await reminderService.launchPayload());
      await reminderService.syncAll(
          entries: await trainingService.allEntries());
    }
  } catch (_) {
    // Reminder sync can recover on later app interactions.
  }
  try {
    if (settingsService.reminderEnabled &&
        settingsService.leagueFixtureAlertEnabled) {
      await leagueFixtureReminderService.initialize();
      handleLaunchPayload(await leagueFixtureReminderService.launchPayload());
    }
  } catch (_) {
    // Fixture notification launch handling can recover on later interactions.
  }
  try {
    if (settingsService.reminderEnabled &&
        settingsService.weatherAlertEnabled) {
      await weatherReminderService.initialize();
      handleLaunchPayload(await weatherReminderService.launchPayload());
      await weatherReminderService.syncSettingsDrivenReminders();
    }
  } catch (_) {
    // Weather reminder sync can recover on later settings or app interactions.
  }
  try {
    if (settingsService.reminderEnabled &&
        settingsService.clubTrainingAlertEnabled) {
      await clubTrainingReminderService.initialize();
      handleLaunchPayload(await clubTrainingReminderService.launchPayload());
      await clubTrainingReminderService.syncSettingsDrivenReminders();
    }
  } catch (_) {
    // Club training reminder sync can recover on later schedule changes.
  }
  try {
    handleLaunchPayload(
      await healthConnectJumpRopeSyncService?.importNotificationLaunchPayload(),
    );
  } catch (_) {
    // Health Connect notification launch handling can recover later.
  }
  try {
    await healthConnectJumpRopeSyncService?.syncIfEnabled();
  } catch (_) {
    // Health Connect sync can recover on the next app resume or settings action.
  }
}

class _StartupStageException implements Exception {
  final String stage;
  final Object error;

  const _StartupStageException({
    required this.stage,
    required this.error,
  });

  @override
  String toString() => 'Startup failed at $stage: $error';
}

class _DisabledBackupRepository implements BackupRepository {
  const _DisabledBackupRepository();

  @override
  Future<void> autoBackupDaily() async {}

  @override
  Future<void> backup() async {
    throw StateError('Drive backup is unavailable.');
  }

  @override
  Future<bool> backupIfSignedIn({bool requireAutoOnSave = false}) async {
    return false;
  }

  @override
  DateTime? getLastBackup() => null;

  @override
  bool isAutoDailyEnabled() => false;

  @override
  bool isAutoOnSaveEnabled() => false;

  @override
  Future<void> restoreLatest() async {
    throw StateError('Drive restore is unavailable.');
  }

  @override
  Future<void> setAutoDailyEnabled(bool value) async {}

  @override
  Future<void> setAutoOnSaveEnabled(bool value) async {}
}

class _FootballNoteDependencies {
  final TrainingService trainingService;
  final MealLogService mealLogService;
  final OptionRepository optionRepository;
  final LocaleService localeService;
  final SettingsService settingsService;
  final SportStateController sportController;
  final BackupService backupService;
  final HealthConnectJumpRopeSyncService? healthConnectJumpRopeSyncService;

  const _FootballNoteDependencies({
    required this.trainingService,
    required this.mealLogService,
    required this.optionRepository,
    required this.localeService,
    required this.settingsService,
    required this.sportController,
    required this.backupService,
    required this.healthConnectJumpRopeSyncService,
  });
}

class FootballNoteBootstrapApp extends StatefulWidget {
  const FootballNoteBootstrapApp({super.key});

  @override
  State<FootballNoteBootstrapApp> createState() =>
      _FootballNoteBootstrapAppState();
}

class _FootballNoteBootstrapAppState extends State<FootballNoteBootstrapApp> {
  late Future<_FootballNoteDependencies> _dependenciesFuture;
  Object? _reportedStartupError;

  @override
  void initState() {
    super.initState();
    _dependenciesFuture = _initializeAppDependencies();
  }

  void _retry() {
    setState(() {
      _reportedStartupError = null;
      _dependenciesFuture = _initializeAppDependencies();
    });
  }

  void _reportStartupError(Object error, StackTrace? stackTrace) {
    if (identical(_reportedStartupError, error)) {
      return;
    }
    _reportedStartupError = error;
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'football_note startup',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_FootballNoteDependencies>(
      future: _dependenciesFuture,
      builder: (context, snapshot) {
        final dependencies = snapshot.data;
        if (dependencies != null) {
          return FootballNoteApp(
            trainingService: dependencies.trainingService,
            mealLogService: dependencies.mealLogService,
            optionRepository: dependencies.optionRepository,
            localeService: dependencies.localeService,
            settingsService: dependencies.settingsService,
            sportController: dependencies.sportController,
            driveBackupService: dependencies.backupService,
            healthConnectJumpRopeSyncService:
                dependencies.healthConnectJumpRopeSyncService,
          );
        }

        if (snapshot.hasError) {
          _reportStartupError(snapshot.error!, snapshot.stackTrace);
          return _StartupShell(
            builder: (context) => _StartupFailureScreen(
              error: snapshot.error!,
              onRetry: _retry,
            ),
          );
        }

        return _StartupShell(
          builder: (context) => const _StartupLoadingScreen(),
        );
      },
    );
  }
}

class _StartupShell extends StatelessWidget {
  final WidgetBuilder builder;

  const _StartupShell({required this.builder});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final overlayStyle =
            (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
                .copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor:
              isDark ? const Color(0xFF0F131A) : const Color(0xFFF6F8FC),
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        );
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: Builder(builder: builder),
    );
  }
}

class _StartupLoadingScreen extends StatelessWidget {
  const _StartupLoadingScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  label: l10n.startupLoadingTitle,
                  liveRegion: true,
                  child: const FootballLoadingBar(),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.startupLoadingTitle,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.startupLoadingBody,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.45,
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

class _StartupFailureScreen extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _StartupFailureScreen({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final diagnostics = _StartupDiagnostics.from(error);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.sizeOf(context).height -
                    MediaQuery.paddingOf(context).vertical -
                    56,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 44,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.startupErrorTitle,
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.startupErrorBody,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outlineVariant,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.startupErrorDetailsLabel,
                            style: textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            '${l10n.startupErrorStepLabel}: '
                            '${diagnostics.stage}\n'
                            '${l10n.startupErrorMessageLabel}: '
                            '${diagnostics.message}',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.startupRetryAction),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StartupDiagnostics {
  final String stage;
  final String message;

  const _StartupDiagnostics({
    required this.stage,
    required this.message,
  });

  factory _StartupDiagnostics.from(Object error) {
    if (error is _StartupStageException) {
      return _StartupDiagnostics(
        stage: error.stage,
        message: _summarizeError(error.error),
      );
    }
    return _StartupDiagnostics(
      stage: 'unknown',
      message: _summarizeError(error),
    );
  }

  static String _summarizeError(Object error) {
    final text = error.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.length <= 420) {
      return text;
    }
    return '${text.substring(0, 420)}...';
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
  final HealthConnectJumpRopeSyncService? healthConnectJumpRopeSyncService;

  const FootballNoteApp({
    super.key,
    required this.trainingService,
    required this.mealLogService,
    required this.optionRepository,
    required this.localeService,
    required this.settingsService,
    required this.sportController,
    this.healthConnectJumpRopeSyncService,
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
          healthConnectJumpRopeSyncService: healthConnectJumpRopeSyncService,
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
  final HealthConnectJumpRopeSyncService? healthConnectJumpRopeSyncService;
  final String sportId;

  const _EntryGate({
    super.key,
    required this.sportId,
    required this.trainingService,
    required this.mealLogService,
    required this.optionRepository,
    required this.localeService,
    required this.settingsService,
    this.healthConnectJumpRopeSyncService,
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
  bool _healthConnectSyncBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _welcomeSeen =
        widget.optionRepository.getValue<bool>(_welcomeSeenKey) ?? false;
    final storedSportId = widget.optionRepository.getValue<String>(
      SportCatalog.currentSportOptionKey,
    );
    final hasStoredSport = storedSportId?.trim().isNotEmpty == true;
    final isSupportMode =
        FamilyAccessService(widget.optionRepository).loadState().isSupportMode;
    _startupSportSelected = hasStoredSport || isSupportMode || _welcomeSeen;
    if (!hasStoredSport && _welcomeSeen && !isSupportMode) {
      unawaited(
        SportService(widget.optionRepository).setCurrentSportId(
          SportCatalog.normalizeSportId(widget.sportId),
        ),
      );
    }
    unawaited(_syncHealthConnectJumpRopeIfNeeded());
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
    unawaited(_syncHealthConnectJumpRopeIfNeeded());
  }

  Future<void> _syncHealthConnectJumpRopeIfNeeded() async {
    if (_healthConnectSyncBusy) return;
    if (FamilyAccessService(widget.optionRepository)
        .loadState()
        .isSupportMode) {
      return;
    }
    final healthConnectJumpRopeSyncService =
        widget.healthConnectJumpRopeSyncService;
    if (healthConnectJumpRopeSyncService == null) {
      return;
    }
    _healthConnectSyncBusy = true;
    try {
      await healthConnectJumpRopeSyncService.syncIfEnabled();
    } finally {
      _healthConnectSyncBusy = false;
    }
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
      healthConnectJumpRopeSyncService: widget.healthConnectJumpRopeSyncService,
    );
  }
}
