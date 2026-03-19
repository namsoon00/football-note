import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/locale_service.dart';
import 'package:football_note/application/settings_service.dart';
import 'package:football_note/application/training_service.dart';
import 'package:football_note/domain/entities/training_entry.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/infrastructure/hive_option_repository.dart';
import 'package:football_note/infrastructure/hive_training_repository.dart';
import 'package:football_note/presentation/screens/space_speed_game_screen.dart';
import 'package:hive/hive.dart';

import '../helpers/test_asset_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<TrainingEntry> trainingBox;
  late Box optionBox;
  late TrainingService trainingService;
  late HiveOptionRepository optionRepository;
  late LocaleService localeService;
  late SettingsService settingsService;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'football_note_space_speed_game',
    );
    Hive.init(tempDir.path);
    Hive.registerAdapter(TrainingEntryAdapter());
  });

  setUp(() async {
    trainingBox = await Hive.openBox<TrainingEntry>(
      'training_entries_${DateTime.now().microsecondsSinceEpoch}',
    );
    optionBox = await Hive.openBox(
      'options_${DateTime.now().microsecondsSinceEpoch}',
    );
    trainingService = TrainingService(HiveTrainingRepository(trainingBox));
    optionRepository = HiveOptionRepository(optionBox);
    localeService = LocaleService(optionRepository)..load();
    settingsService = SettingsService(optionRepository)..load();
  });

  tearDown(() async {
    await trainingBox.close();
    await optionBox.close();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  Widget buildScreen() {
    return DefaultAssetBundle(
      bundle: TestAssetBundle(),
      child: MaterialApp(
        locale: const Locale('ko', 'KR'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ko', 'KR')],
        home: SpaceSpeedGameScreen(
          trainingService: trainingService,
          localeService: localeService,
          optionRepository: optionRepository,
          settingsService: settingsService,
        ),
      ),
    );
  }

  testWidgets('패스 버튼을 누르면 충전 UI가 즉시 나타난다', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.text('게임 시작'));
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.sports_soccer)),
    );
    await tester.pump();

    expect(find.textContaining('파워 '), findsOneWidget);

    await gesture.up();
    await tester.pump();

    expect(find.textContaining('파워 '), findsNothing);
  });
}
