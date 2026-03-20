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
    expect(find.text('움직이는 화면'), findsOneWidget);
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
    expect(find.text('경기 상황 읽기'), findsOneWidget);
    expect(find.text('움직이는 화면'), findsOneWidget);
    expect(find.text('공과 러너의 전개를 따라가며 장면을 읽어보세요.'), findsOneWidget);
    expect(find.text('LIVE 전개 읽기'), findsOneWidget);
    expect(find.text('중앙 압박 직전, 오른쪽 하프스페이스가 열려 있어요.'), findsOneWidget);
    expect(find.text('오른쪽 하프스페이스로 빠른 전진 패스'), findsOneWidget);

    await tester.ensureVisible(find.text('오른쪽 하프스페이스로 빠른 전진 패스'));
    await tester.tap(find.text('오른쪽 하프스페이스로 빠른 전진 패스'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('중앙 압박 전, 열린 하프스페이스를 빠르게 쓰는 판단이 좋습니다.'), findsOneWidget);
  });
}

Map<String, dynamic> _boardQuestion() {
  return <String, dynamic>{
    'id': 'scn01_decision',
    'koQuestion': '운동장 상황을 보면 가장 좋은 다음 선택은?',
    'enQuestion': 'Looking at the pitch, what is the best next action?',
    'options': <Map<String, String>>[
      <String, String>{
        'koText': '오른쪽 하프스페이스로 빠른 전진 패스',
        'enText': 'Quick forward pass into the right half-space',
      },
      <String, String>{
        'koText': '볼을 멈추고 중앙 압박을 기다린다',
        'enText': 'Stop the ball and wait for central pressure',
      },
      <String, String>{
        'koText': '가장 먼 측면으로 큰 전환만 시도한다',
        'enText': 'Force a long switch to the far wing',
      },
    ],
    'correctIndex': 0,
    'koExplain': '중앙 압박 전, 열린 하프스페이스를 빠르게 쓰는 판단이 좋습니다.',
    'enExplain':
        'Before central pressure arrives, the open half-space is the best route.',
    'scenario': <String, dynamic>{
      'koTitle': '중앙 압박 직전, 오른쪽 하프스페이스가 열려 있어요.',
      'enTitle':
          'Central pressure is closing, but the right half-space is open.',
      'koMovementCaption': '움직임을 보면 공과 2선 러너가 오른쪽 하프스페이스로 같이 속도를 냅니다.',
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
