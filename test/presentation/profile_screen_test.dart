import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

    expect(find.text('20개 문항으로 훈련 성향을 더 세밀하게 정리합니다.'), findsOneWidget);
    expect(
      find.text('20개 문항으로 플레이 선호를 분석해 어울리는 포지션을 찾습니다.'),
      findsOneWidget,
    );

    final mbtiStartButton = _findTestStartButton('MBTI 테스트');
    await tester.ensureVisible(mbtiStartButton);
    await tester.tap(mbtiStartButton);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('20. 원정 경기 준비에서 더 안심되는 방식은 무엇인가요?'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('20. 원정 경기 준비에서 더 안심되는 방식은 무엇인가요?'), findsOneWidget);

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    final positionStartButton = _findTestStartButton('포지션 테스트');
    await tester.ensureVisible(positionStartButton);
    await tester.tap(positionStartButton);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('20. 팀 전술판을 볼 때 가장 먼저 확인하는 기호는 무엇인가요?'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('20. 팀 전술판을 볼 때 가장 먼저 확인하는 기호는 무엇인가요?'), findsOneWidget);
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
