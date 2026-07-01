import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/club_schedule_service.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/club_schedule_screen.dart';

void main() {
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
}

Widget _buildApp(Widget child) {
  return MaterialApp(
    locale: const Locale('ko', 'KR'),
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
