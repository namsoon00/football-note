import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'domain/entities/training_entry.dart';
import 'domain/repositories/option_repository.dart';
import 'infrastructure/hive_option_repository.dart';
import 'infrastructure/hive_training_repository.dart';
import 'application/training_service.dart';
import 'application/locale_service.dart';
import 'application/settings_service.dart';
import 'application/backup_service.dart';
import 'application/drive_backup_service.dart';
import 'application/training_plan_reminder_service.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/welcome_screen.dart';
import 'presentation/theme/app_theme.dart';

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
  final optionRepository = HiveOptionRepository(optionBox);
  final localeService = LocaleService(optionRepository);
  localeService.load();
  final settingsService = SettingsService(optionRepository);
  settingsService.load();
  const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  final driveBackupRepository = DriveBackupService(
    trainingBox,
    optionBox,
    webClientId: webClientId,
  );
  final backupService = BackupService(driveBackupRepository);
  final trainingService = TrainingService(
    trainingRepository,
    backupService: backupService,
  );
  await backupService.autoBackupDaily();
  final reminderService =
      TrainingPlanReminderService(optionRepository, settingsService);
  await reminderService.initialize();
  await reminderService.syncFromStorage();
  settingsService.addListener(() {
    unawaited(reminderService.syncFromStorage());
  });

  runApp(FootballNoteApp(
    trainingService: trainingService,
    optionRepository: optionRepository,
    localeService: localeService,
    settingsService: settingsService,
    driveBackupService: backupService,
  ));
}

class FootballNoteApp extends StatelessWidget {
  final TrainingService trainingService;
  final OptionRepository optionRepository;
  final LocaleService localeService;
  final SettingsService settingsService;
  final BackupService? driveBackupService;

  const FootballNoteApp({
    super.key,
    required this.trainingService,
    required this.optionRepository,
    required this.localeService,
    required this.settingsService,
    this.driveBackupService,
  });

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) => AnimatedBuilder(
        animation: Listenable.merge([localeService, settingsService]),
        builder: (context, _) => MaterialApp(
          title: 'Football Training Log',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: settingsService.themeMode,
          locale: localeService.locale,
          supportedLocales: const [
            Locale('en'),
            Locale('ko', 'KR'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: _EntryGate(
            trainingService: trainingService,
            optionRepository: optionRepository,
            localeService: localeService,
            settingsService: settingsService,
            driveBackupService: driveBackupService,
          ),
        ),
      ),
    );
  }
}

class _EntryGate extends StatefulWidget {
  final TrainingService trainingService;
  final OptionRepository optionRepository;
  final LocaleService localeService;
  final SettingsService settingsService;
  final BackupService? driveBackupService;

  const _EntryGate({
    required this.trainingService,
    required this.optionRepository,
    required this.localeService,
    required this.settingsService,
    this.driveBackupService,
  });

  @override
  State<_EntryGate> createState() => _EntryGateState();
}

class _EntryGateState extends State<_EntryGate> {
  bool _entered = false;

  @override
  Widget build(BuildContext context) {
    if (_entered) {
      return HomeScreen(
        trainingService: widget.trainingService,
        optionRepository: widget.optionRepository,
        localeService: widget.localeService,
        settingsService: widget.settingsService,
        driveBackupService: widget.driveBackupService,
      );
    }
    return WelcomeScreen(onStart: () => setState(() => _entered = true));
  }
}
