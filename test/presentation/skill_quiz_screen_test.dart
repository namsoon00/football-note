import 'dart:convert';

import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/skill_quiz_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('skill quiz shows football quiz mode menu', (
    WidgetTester tester,
  ) async {
    final repository = _MemoryOptionRepository();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SkillQuizScreen(optionRepository: repository),
      ),
    );
    await tester.pump();

    expect(find.text('축구 퀴즈'), findsOneWidget);
    expect(find.text('오늘의 문제'), findsOneWidget);

    await tester.tap(find.text('오늘의 문제'));
    await tester.pumpAndSettle();

    expect(find.textContaining('진행 1/10'), findsOneWidget);

    await tester.tap(find.byTooltip('퀴즈 모드 선택'));
    await tester.pumpAndSettle();

    expect(find.text('오늘의 축구 퀴즈'), findsOneWidget);
    expect(find.text('복습 모드'), findsOneWidget);
    expect(find.text('챌린지 모드'), findsOneWidget);
    expect(find.text('스피드 모드'), findsOneWidget);
  });

  testWidgets('skill quiz restores saved general football question session', (
    WidgetTester tester,
  ) async {
    final repository = _MemoryOptionRepository()
      ..seed(
        SkillQuizScreen.sessionKey,
        jsonEncode(<String, dynamic>{
          'mode': 'daily',
          'questionIds': <String>['ox_offside_own_half_0_0_t'],
          'index': 0,
          'score': 0,
          'streak': 0,
          'bestStreak': 0,
          'timeouts': 0,
          'answerCount': 0,
          'responseMillisSum': 0,
          'selectedIndex': null,
          'answered': false,
          'retryUsed': false,
          'retryFeedback': null,
          'wrongIds': <String>[],
          'finished': false,
          'speedLeft': 12,
        }),
      );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SkillQuizScreen(optionRepository: repository),
      ),
    );
    await tester.pump();

    expect(find.text('축구 퀴즈'), findsOneWidget);
    expect(find.text('이어하기'), findsOneWidget);

    await tester.tap(find.text('이어하기'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('자기 진영에 있는 공격수는 오프사이드 반칙 대상이 아니다.'),
      findsOneWidget,
    );
    expect(find.text('O'), findsWidgets);
    expect(find.text('X'), findsWidgets);

    await tester.tap(find.text('O').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('정답 포인트'), findsOneWidget);
    expect(find.textContaining('오프사이드는 상대 진영에서만 성립합니다.'), findsWidgets);
    expect(find.textContaining('정답은 O예요.'), findsWidgets);
  });

  testWidgets('daily quiz mixes in due wrong-answer questions', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    final repository = _MemoryOptionRepository()
      ..seed(
        SkillQuizScreen.pendingWrongScheduleKey,
        jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{
            'questionId': 'ox_offside_own_half_0_0_t',
            'dueAt': now.subtract(const Duration(days: 1)).toIso8601String(),
            'wrongCount': 1,
            'lastWrongAt': now
                .subtract(const Duration(days: 2))
                .toIso8601String(),
          },
        ]),
      );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SkillQuizScreen(optionRepository: repository),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('오늘의 문제'));
    await tester.pumpAndSettle();

    final savedIds =
        (jsonDecode(
                  repository.getValue<String>(
                    SkillQuizScreen.dailyQuestionsKey,
                  )!,
                )
                as List<dynamic>)
            .cast<String>();
    expect(savedIds, hasLength(10));
    expect(savedIds, contains('ox_offside_own_half_0_0_t'));
  });
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
