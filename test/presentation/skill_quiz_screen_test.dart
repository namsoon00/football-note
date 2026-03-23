import 'dart:convert';

import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/skill_quiz_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'skill quiz shows entry hub cards without top-right mode button',
    (WidgetTester tester) async {
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
      expect(find.byTooltip('퀴즈 모드 선택'), findsNothing);

      await tester.scrollUntilVisible(
        find.text('전체 문제 보기'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('전체 문제 보기'), findsOneWidget);
      expect(find.text('퀴즈 히스토리'), findsOneWidget);

      await tester.tap(find.text('전체 문제 보기'));
      await tester.pumpAndSettle();

      expect(find.text('코치용 퀴즈 라이브러리'), findsOneWidget);
      expect(find.textContaining('전체 900문제'), findsOneWidget);
      expect(find.textContaining('자동 검증 통과'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('퀴즈 히스토리'), findsOneWidget);
      expect(find.text('오늘의 문제'), findsOneWidget);
    },
  );

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

    expect(find.text('O'), findsWidgets);
    expect(find.text('X'), findsWidgets);

    await tester.tap(find.text('O').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('정답 포인트'), findsOneWidget);
    expect(find.textContaining('다음에 볼 포인트:'), findsWidgets);
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
            'lastWrongAt':
                now.subtract(const Duration(days: 2)).toIso8601String(),
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

    final savedIds = (jsonDecode(
      repository.getValue<String>(
        SkillQuizScreen.dailyQuestionsKey,
      )!,
    ) as List<dynamic>)
        .cast<String>();
    expect(savedIds, hasLength(10));
  });

  testWidgets('correct answer does not show green success badge', (
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

    await tester.tap(find.text('오늘의 문제'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('O').first);
    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Icon &&
            widget.icon == Icons.check_circle &&
            widget.color == const Color(0xFF0FA968),
      ),
      findsNothing,
    );
  });

  testWidgets('short answer can reveal answer after one wrong try', (
    WidgetTester tester,
  ) async {
    final repository = _MemoryOptionRepository()
      ..seed(
        SkillQuizScreen.sessionKey,
        jsonEncode(<String, dynamic>{
          'mode': 'daily',
          'questionIds': <String>['sa_short_0'],
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
          'answerRevealed': false,
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

    await tester.tap(find.text('이어하기'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '모름');
    await tester.tap(find.text('정답 확인'));
    await tester.pumpAndSettle();

    expect(find.text('정답 보기'), findsOneWidget);

    await tester.ensureVisible(find.text('정답 보기'));
    await tester.tap(find.text('정답 보기'));
    await tester.pumpAndSettle();

    expect(find.textContaining('정답:'), findsOneWidget);
    expect(find.text('다음'), findsOneWidget);
  });

  testWidgets('quiz history opens saved past sessions', (
    WidgetTester tester,
  ) async {
    final finishedAt = DateTime(2026, 3, 23, 9, 30);
    final repository = _MemoryOptionRepository()
      ..seed(
        SkillQuizScreen.historyKey,
        jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': '1',
            'mode': 'focus',
            'finishedAt': finishedAt.toIso8601String(),
            'totalQuestions': 8,
            'score': 6,
            'bestStreak': 3,
            'bestCombo': 3,
            'timeouts': 0,
            'avgResponseMs': 3200,
            'wrongQuestions': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'sa_short_0',
                'promptKo': '테스트 문제',
                'promptEn': 'Test prompt',
                'answerKo': '압박',
                'answerEn': 'Pressing',
                'explanationKo': '테스트 해설',
                'explanationEn': 'Test explanation',
                'category': 'tactics',
                'style': 'shortAnswer',
              },
            ],
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

    await tester.scrollUntilVisible(
      find.text('퀴즈 히스토리'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('퀴즈 히스토리'));
    await tester.pumpAndSettle();

    expect(find.text('퀴즈 히스토리'), findsWidgets);
    expect(find.textContaining('6/8 정답'), findsOneWidget);

    await tester.tap(find.textContaining('2026.03.23'));
    await tester.pumpAndSettle();

    expect(find.text('테스트 문제'), findsOneWidget);
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
