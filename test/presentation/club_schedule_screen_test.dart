import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/club_schedule_service.dart';
import 'package:football_note/application/family_access_service.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/club_schedule_screen.dart';
import 'package:football_note/presentation/theme/app_theme.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const timezoneChannel = MethodChannel('flutter_timezone');
  const notificationsChannel = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );

  setUp(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(timezoneChannel, (
      call,
    ) async {
      if (call.method == 'getLocalTimezone') return 'Asia/Seoul';
      return <String>[];
    });
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      notificationsChannel,
      (call) async {
        switch (call.method) {
          case 'initialize':
          case 'requestNotificationsPermission':
          case 'requestExactAlarmsPermission':
          case 'zonedSchedule':
          case 'cancel':
            return true;
          default:
            return null;
        }
      },
    );
  });

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      timezoneChannel,
      null,
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      notificationsChannel,
      null,
    );
  });

  testWidgets('club schedule screen saves club name, weekday, and kit color', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final repository = _MemoryOptionRepository();

    await tester.pumpWidget(
      _buildApp(
        ClubScheduleScreen(optionRepository: repository),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('club-schedule-name-field')),
      '성남 U15',
    );
    await tester.tap(
      find.byKey(
        const ValueKey<String>('club-schedule-day-switch-1'),
      ),
    );
    await tester.pumpAndSettle();

    final uniformPicker = find.byKey(
      const ValueKey<String>('club-uniform-day-1-picker'),
    );
    await tester.ensureVisible(uniformPicker);
    await tester.tap(uniformPicker);
    await tester.pumpAndSettle();

    Slider slider(String key) {
      return tester.widget<Slider>(
        find.descendant(
          of: find.byKey(ValueKey<String>(key)),
          matching: find.byType(Slider),
        ),
      );
    }

    await tester.tap(
      find.byKey(const ValueKey<String>('club-uniform-color-preset-red')),
    );
    await tester.pump();

    expect(slider('club-uniform-color-hue-slider').value, closeTo(0, 0.1));
    expect(
      slider('club-uniform-color-saturation-slider').value,
      closeTo(0.83, 0.01),
    );
    expect(
      slider('club-uniform-color-brightness-slider').value,
      closeTo(0.86, 0.01),
    );

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    final saveButton = find.byKey(
      const ValueKey<String>('club-schedule-save-button'),
    );
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    final profile = ClubScheduleService(repository).loadProfile();
    expect(profile.clubName, '성남 U15');
    expect(profile.weekdaySchedules.first.weekday, DateTime.monday);
    expect(profile.weekdaySchedules.first.enabled, isTrue);
    expect(profile.weekdaySchedules.first.uniformColorValue, 0xFFDC2626);
    expect(find.text('클럽 일정을 저장했어요.'), findsOneWidget);
  });

  testWidgets('uniform color picker is visible on compact light Android layout',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final repository = _MemoryOptionRepository();

    await tester.pumpWidget(
      _buildApp(
        ClubScheduleScreen(optionRepository: repository),
        theme: AppTheme.light(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const ValueKey<String>('club-schedule-day-switch-1'),
      ),
    );
    await tester.pumpAndSettle();

    final logicalHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final uniformPicker = find.byKey(
      const ValueKey<String>('club-uniform-day-1-picker'),
    );
    for (var i = 0; i < 4; i += 1) {
      final pickerRect = tester.getRect(uniformPicker);
      if (pickerRect.top >= 0 && pickerRect.bottom <= logicalHeight) break;
      await tester.drag(find.byType(ListView), const Offset(0, -96));
      await tester.pumpAndSettle();
    }
    expect(
      tester.getRect(uniformPicker).bottom,
      lessThanOrEqualTo(logicalHeight),
    );
    await tester.tap(uniformPicker);
    await tester.pumpAndSettle();

    final sheet = find.byKey(
      const ValueKey<String>('club-uniform-color-sheet'),
    );
    expect(sheet, findsOneWidget);
    final sheetMaterial = tester.widget<Material>(sheet);
    expect(
      sheetMaterial.color,
      Theme.of(tester.element(sheet)).colorScheme.surface,
    );
    expect(
      find.byKey(const ValueKey<String>('club-uniform-color-preset-red')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('club-uniform-color-hue-slider')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('club-uniform-color-brightness-slider'),
      ),
      findsOneWidget,
    );

    final sheetRect = tester.getRect(sheet);
    expect(sheetRect.top, greaterThanOrEqualTo(0));
    expect(sheetRect.bottom, lessThanOrEqualTo(logicalHeight + 0.1));
  });

  testWidgets('start and end time buttons align in light layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final repository = _MemoryOptionRepository();

    await tester.pumpWidget(
      _buildApp(
        ClubScheduleScreen(optionRepository: repository),
        theme: AppTheme.light(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const ValueKey<String>('club-schedule-day-switch-1'),
      ),
    );
    await tester.pumpAndSettle();

    final startButton = find.byKey(
      const ValueKey<String>('club-schedule-start-1'),
    );
    final endButton = find.byKey(
      const ValueKey<String>('club-schedule-end-1'),
    );
    final timeSummary = find.byKey(
      const ValueKey<String>('club-schedule-time-summary-1'),
    );
    expect(startButton, findsOneWidget);
    expect(endButton, findsOneWidget);
    expect(timeSummary, findsOneWidget);

    final startRect = tester.getRect(startButton);
    final endRect = tester.getRect(endButton);
    final summaryRect = tester.getRect(timeSummary);

    expect(startRect.top, closeTo(endRect.top, 0.1));
    expect(startRect.bottom, closeTo(endRect.bottom, 0.1));
    expect(startRect.width, closeTo(endRect.width, 0.1));
    expect(summaryRect.top, greaterThan(startRect.bottom));
    expect(summaryRect.right, lessThanOrEqualTo(endRect.right + 0.1));
  });

  testWidgets('club schedule auto saves changes without pressing save', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final repository = _MemoryOptionRepository();

    await tester.pumpWidget(
      _buildApp(
        ClubScheduleScreen(optionRepository: repository),
        theme: AppTheme.light(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('club-schedule-name-field')),
      '성남 U15',
    );
    await tester.tap(
      find.byKey(
        const ValueKey<String>('club-schedule-day-switch-1'),
      ),
    );

    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    final profile = ClubScheduleService(repository).loadProfile();
    expect(profile.clubName, '성남 U15');
    expect(profile.weekdaySchedules.first.enabled, isTrue);
  });

  testWidgets('parent mode keeps club schedule read-only without auto save', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final repository = _MemoryOptionRepository();
    await repository.setValue(
      FamilyAccessService.currentRoleLocalKey,
      FamilyRole.parent.name,
    );
    final service = ClubScheduleService(repository);
    await service.saveProfile(
      ClubScheduleProfile.empty(now: DateTime(2026, 7, 2)).copyWith(
        clubName: '기존 클럽',
      ),
    );

    await tester.pumpWidget(
      _buildApp(
        ClubScheduleScreen(optionRepository: repository),
        theme: AppTheme.light(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('club-schedule-name-field')),
      '보호자 변경',
    );
    await tester.tap(
      find.byKey(
        const ValueKey<String>('club-schedule-day-switch-1'),
      ),
      warnIfMissed: false,
    );
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    final profile = service.loadProfile();
    expect(profile.clubName, '기존 클럽');
    expect(profile.weekdaySchedules.first.enabled, isFalse);
  });

  testWidgets('pending auto save asks before leaving', (tester) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final repository = _MemoryOptionRepository();

    await tester.pumpWidget(
      _buildApp(
        Builder(
          builder: (context) => TextButton(
            key: const ValueKey<String>('open-club-schedule'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ClubScheduleScreen(
                  optionRepository: repository,
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
        theme: AppTheme.light(),
      ),
    );
    await tester.tap(find.byKey(const ValueKey<String>('open-club-schedule')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const ValueKey<String>('club-schedule-day-switch-1'),
      ),
    );
    await tester.pump();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('club-schedule-unsaved-dialog')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('club-schedule-unsaved-save-leave')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('open-club-schedule')),
      findsOneWidget,
    );
    final profile = ClubScheduleService(repository).loadProfile();
    expect(profile.weekdaySchedules.first.enabled, isTrue);
  });
}

Widget _buildApp(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    locale: const Locale('ko', 'KR'),
    theme: theme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [
      Locale('en'),
      Locale('ko', 'KR'),
      Locale('ja'),
    ],
    home: child,
  );
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> values = <String, dynamic>{};

  @override
  T? getValue<T>(String key) => values[key] as T?;

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final value = values[key];
    if (value is List<int>) return List<int>.from(value);
    if (value is List) return value.whereType<int>().toList(growable: false);
    return List<int>.from(defaults);
  }

  @override
  List<String> getOptions(String key, List<String> defaults) {
    final value = values[key];
    if (value is List<String>) return List<String>.from(value);
    if (value is List) {
      return value.whereType<String>().toList(growable: false);
    }
    return List<String>.from(defaults);
  }

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {
    values[key] = List<dynamic>.from(options);
  }

  @override
  Future<void> setValue(String key, dynamic value) async {
    values[key] = value;
  }
}
