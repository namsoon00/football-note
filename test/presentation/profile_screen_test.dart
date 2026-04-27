import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/family_access_service.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/profile_screen.dart';

void main() {
  testWidgets('Profile tests expose 20 questions for MBTI and position', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProfileScreen(optionRepository: _MemoryOptionRepository()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.psychology_alt_outlined));
    await tester.pumpAndSettle();

    final mbtiStartButton = _findTestStartButton('MBTI 테스트');
    await tester.ensureVisible(mbtiStartButton);
    await tester.tap(mbtiStartButton);
    await tester.pumpAndSettle();
    expect(find.text('MBTI 테스트'), findsWidgets);
    expect(find.text('20개를 다 고르면 결과가 저장돼요.'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    final positionStartButton = _findTestStartButton('포지션 테스트');
    await tester.ensureVisible(positionStartButton);
    await tester.tap(positionStartButton);
    await tester.pumpAndSettle();
    expect(find.text('포지션 테스트'), findsWidgets);
    expect(find.text('20개를 다 고르면 결과가 저장돼요.'), findsOneWidget);
  });

  testWidgets('Saved MBTI result shows type and description', (
    WidgetTester tester,
  ) async {
    final repository = _MemoryOptionRepository()
      ..seed('profile_mbti_result', 'ENTJ');

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProfileScreen(optionRepository: repository),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ENTJ · 전술 지휘형'), findsNothing);

    await tester.tap(find.byIcon(Icons.psychology_alt_outlined));
    await tester.pumpAndSettle();

    expect(find.text('ENTJ · 전술 지휘형'), findsOneWidget);
    expect(find.text('전술 방향을 정리하고 목표 달성을 주도하는 성향입니다.'), findsOneWidget);
  });

  testWidgets('Saved profile answers can be reviewed from the test card', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _MemoryOptionRepository()
      ..seed('profile_mbti_result', 'ENTJ')
      ..seed('profile_mbti_answers', <int>[0, 1]);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProfileScreen(optionRepository: repository),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('저장한 응답 2개'), findsNothing);

    await tester.tap(find.byIcon(Icons.psychology_alt_outlined));
    await tester.pumpAndSettle();

    expect(find.text('저장한 응답 2개'), findsOneWidget);

    await tester.ensureVisible(find.text('저장한 응답 2개'));
    await tester.tap(find.text('저장한 응답 2개'));
    await tester.pumpAndSettle();

    expect(find.text('1. 경기 전에 나는?'), findsOneWidget);
    expect(find.text('왜 하는지 큰 그림'), findsOneWidget);
  });

  testWidgets('Position result chip opens profile tests screen', (
    WidgetTester tester,
  ) async {
    final repository = _MemoryOptionRepository()
      ..seed('profile_position_test_result', 'MF · 미드필더형');

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProfileScreen(optionRepository: repository),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('포지션 MF'));
    await tester.pumpAndSettle();

    expect(find.text('테스트 결과와 응답'), findsOneWidget);
  });

  testWidgets('Profile level card opens level guide on tap', (
    WidgetTester tester,
  ) async {
    final repository = _MemoryOptionRepository()
      ..seed('player_level_total_xp_v2', 60);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProfileScreen(optionRepository: repository),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('선수 레벨'));
    await tester.pumpAndSettle();

    expect(find.text('레벨 가이드'), findsOneWidget);
  });

  testWidgets('parent mode can open profile tests in read-only mode', (
    WidgetTester tester,
  ) async {
    final repository = _MemoryOptionRepository()
      ..seed(FamilyAccessService.currentRoleLocalKey, FamilyRole.parent.name)
      ..seed('profile_mbti_result', 'ENTJ');

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProfileScreen(optionRepository: repository),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.psychology_alt_outlined));
    await tester.pumpAndSettle();

    expect(find.text('테스트 결과와 응답'), findsOneWidget);
    expect(find.text('ENTJ · 전술 지휘형'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '두 테스트 이어서 하기'),
      ).onPressed,
      isNull,
    );
  });
}

Finder _findTestStartButton(String title) {
  final card = find.ancestor(of: find.text(title), matching: find.byType(Card));
  return find.descendant(
    of: card,
    matching: find.widgetWithText(FilledButton, '테스트 시작'),
  );
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> _values = <String, dynamic>{};

  void seed(String key, dynamic value) {
    _values[key] = value;
  }

  @override
  List<String> getOptions(String key, List<String> defaults) {
    final value = _values[key];
    if (value is List<String>) {
      return value;
    }
    return defaults;
  }

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final value = _values[key];
    if (value is List<int>) {
      return value;
    }
    return defaults;
  }

  @override
  T? getValue<T>(String key) => _values[key] as T?;

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {
    _values[key] = options;
  }

  @override
  Future<void> setValue(String key, dynamic value) async {
    _values[key] = value;
  }
}
