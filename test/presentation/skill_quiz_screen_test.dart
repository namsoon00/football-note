import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/skill_quiz_screen.dart';

void main() {
  testWidgets('skill quiz lets user start board quiz from type menu', (
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

    await tester.tap(find.byTooltip('퀴즈 세트 메뉴'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('타입별 퀴즈 선택'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('보드').last);
    await tester.tap(find.text('보드').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('보드 문제풀'), findsOneWidget);
    expect(find.textContaining('보드 세트'), findsOneWidget);
    expect(find.text('보드 퀴즈'), findsOneWidget);
    expect(find.text('코치 설명'), findsOneWidget);
  });

  testWidgets('skill quiz renders board-based scenario from saved session', (
    WidgetTester tester,
  ) async {
    final repository = _MemoryOptionRepository()
      ..seed(
        SkillQuizScreen.sessionKey,
        jsonEncode(<String, dynamic>{
          'reviewMode': false,
          'sessionSource': 'today',
          'index': 0,
          'score': 0,
          'selectedIndex': null,
          'answered': false,
          'retryUsed': false,
          'retryFeedback': null,
          'wrongIds': <String>[],
          'dailyQuestions': <Map<String, dynamic>>[_boardQuestion()],
          'questions': <Map<String, dynamic>>[_boardQuestion()],
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
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('보드 퀴즈'), findsOneWidget);
    expect(find.text('위치 먼저 보기'), findsOneWidget);
    expect(find.text('코치가 먼저 말해주는 힌트'), findsOneWidget);
    expect(find.text('코치 보드'), findsOneWidget);
    expect(find.text('중앙 압박이 오기 전, 오른쪽 앞 빈 공간이 열렸어요.'), findsWidgets);
    expect(find.text('오른쪽 앞 빈 공간으로 빠르게 패스'), findsOneWidget);

    await tester.ensureVisible(find.text('오른쪽 앞 빈 공간으로 빠르게 패스'));
    await tester.tap(find.text('오른쪽 앞 빈 공간으로 빠르게 패스'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.text('상대가 모이기 전에 오른쪽 앞 빈 공간을 바로 쓰는 선택이 가장 좋아요.'),
      findsOneWidget,
    );
  });
}

Map<String, dynamic> _boardQuestion() {
  return <String, dynamic>{
    'id': 'scn01_decision',
    'koQuestion': '이 장면에서 다음 플레이로 가장 좋은 선택은?',
    'enQuestion': 'Looking at the pitch, what is the best next action?',
    'options': <Map<String, String>>[
      <String, String>{
        'koText': '오른쪽 앞 빈 공간으로 빠르게 패스',
        'enText': 'Quick forward pass into the right half-space',
      },
      <String, String>{
        'koText': '공을 멈추고 상대가 오길 기다린다',
        'enText': 'Stop the ball and wait for central pressure',
      },
      <String, String>{
        'koText': '멀리 있는 측면으로만 크게 보낸다',
        'enText': 'Force a long switch to the far wing',
      },
    ],
    'correctIndex': 0,
    'koExplain': '상대가 모이기 전에 오른쪽 앞 빈 공간을 바로 쓰는 선택이 가장 좋아요.',
    'enExplain':
        'Before central pressure arrives, the open half-space is the best route.',
    'scenario': <String, dynamic>{
      'koTitle': '중앙 압박이 오기 전, 오른쪽 앞 빈 공간이 열렸어요.',
      'enTitle':
          'Central pressure is closing, but the right half-space is open.',
      'koMovementCaption': '공을 가진 친구와 앞쪽 친구가 오른쪽 빈 공간으로 함께 움직일 준비를 하고 있어요.',
      'enMovementCaption':
          'The ball and second runner accelerate together into the right half-space.',
      'boardPage': <String, dynamic>{
        'name': 'Right Half-space',
        'methodText': '',
        'items': <Map<String, dynamic>>[
          <String, dynamic>{
            'type': 'player',
            'x': 0.18,
            'y': 0.52,
            'size': 32,
            'rotationDeg': 0,
            'colorValue': 0xFFB3E5FC,
          },
          <String, dynamic>{
            'type': 'player',
            'x': 0.36,
            'y': 0.35,
            'size': 32,
            'rotationDeg': 0,
            'colorValue': 0xFFB3E5FC,
          },
          <String, dynamic>{
            'type': 'player',
            'x': 0.7,
            'y': 0.44,
            'size': 32,
            'rotationDeg': 0,
            'colorValue': 0xFFB3E5FC,
          },
          <String, dynamic>{
            'type': 'player',
            'x': 0.3,
            'y': 0.5,
            'size': 32,
            'rotationDeg': 0,
            'colorValue': 0xFFFFCCBC,
          },
          <String, dynamic>{
            'type': 'player',
            'x': 0.46,
            'y': 0.5,
            'size': 32,
            'rotationDeg': 0,
            'colorValue': 0xFFFFCCBC,
          },
          <String, dynamic>{
            'type': 'player',
            'x': 0.58,
            'y': 0.56,
            'size': 32,
            'rotationDeg': 0,
            'colorValue': 0xFFFFCCBC,
          },
          <String, dynamic>{
            'type': 'ball',
            'x': 0.18,
            'y': 0.52,
            'size': 26,
            'rotationDeg': 0,
            'colorValue': 0xFFFFF8E1,
          },
        ],
        'strokes': <Map<String, dynamic>>[
          <String, dynamic>{
            'points': <Map<String, double>>[
              <String, double>{'x': 0.7, 'y': 0.08},
              <String, double>{'x': 0.7, 'y': 0.92},
            ],
            'colorValue': 0x5CFFD54F,
            'width': 22,
          },
        ],
        'playerPath': <Map<String, double>>[
          <String, double>{'x': 0.36, 'y': 0.35},
          <String, double>{'x': 0.48, 'y': 0.33},
          <String, double>{'x': 0.78, 'y': 0.42},
        ],
        'ballPath': <Map<String, double>>[
          <String, double>{'x': 0.18, 'y': 0.52},
          <String, double>{'x': 0.48, 'y': 0.33},
        ],
      },
    },
  };
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
