import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/family_access_service.dart';
import 'package:football_note/application/parent_shared_feedback_service.dart';
import 'package:football_note/domain/entities/training_entry.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/parent_feedback_screen.dart';

void main() {
  testWidgets('player mode can save a reaction to parent feedback', (
    WidgetTester tester,
  ) async {
    final repository = _MemoryOptionRepository();
    final entry = _entry();
    await ParentSharedFeedbackService(
      repository,
    ).saveFeedbackForEntry(entry, '턴 타이밍이 좋아졌어요.');
    await repository.setValue(
      FamilyAccessService.currentRoleLocalKey,
      FamilyRole.child.name,
    );

    await _pumpHost(tester, repository: repository, entry: entry);
    await tester.tap(find.text('open'));
    await _pumpTestTransition(tester);

    expect(find.text('턴 타이밍이 좋아졌어요.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, '고마워요'));
    await tester.pump();

    final saveButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '피드백 저장'),
    );
    expect(saveButton.onPressed, isNotNull);

    await tester.tap(find.widgetWithText(FilledButton, '피드백 저장'));
    await _pumpTestTransition(tester);

    final raw = repository.getValue<Map>(
      FamilyAccessService.parentTrainingFeedbackKey,
    );
    final saved = raw!.values.single as Map;
    expect(saved['message'], '턴 타이밍이 좋아졌어요.');
    expect(saved['reactions'], <String>['thanks']);
  });

  testWidgets('player reaction auto saves without tapping save', (
    WidgetTester tester,
  ) async {
    final repository = _MemoryOptionRepository();
    final entry = _entry();
    await ParentSharedFeedbackService(
      repository,
    ).saveFeedbackForEntry(entry, '턴 타이밍이 좋아졌어요.');
    await repository.setValue(
      FamilyAccessService.currentRoleLocalKey,
      FamilyRole.child.name,
    );

    await _pumpHost(tester, repository: repository, entry: entry);
    await tester.tap(find.text('open'));
    await _pumpTestTransition(tester);

    await tester.tap(find.widgetWithText(FilterChip, '고마워요'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();

    final raw = repository.getValue<Map>(
      FamilyAccessService.parentTrainingFeedbackKey,
    );
    final saved = raw!.values.single as Map;
    expect(saved['message'], '턴 타이밍이 좋아졌어요.');
    expect(saved['reactions'], <String>['thanks']);
    expect(find.byType(ParentFeedbackScreen), findsOneWidget);
  });

  testWidgets('parent feedback message auto saves without closing', (
    WidgetTester tester,
  ) async {
    final repository = _MemoryOptionRepository();
    final entry = _entry();
    await repository.setValue(
      FamilyAccessService.currentRoleLocalKey,
      FamilyRole.parent.name,
    );

    await _pumpHost(tester, repository: repository, entry: entry);
    await tester.tap(find.text('open'));
    await _pumpTestTransition(tester);

    await tester.enterText(find.byType(TextField).first, '몸을 열고 받는 동작이 좋아요.');
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();

    final raw = repository.getValue<Map>(
      FamilyAccessService.parentTrainingFeedbackKey,
    );
    final saved = raw!.values.single as Map;
    expect(saved['message'], '몸을 열고 받는 동작이 좋아요.');
    expect(find.byType(ParentFeedbackScreen), findsOneWidget);
  });

  testWidgets('parent mode can only view player reactions', (
    WidgetTester tester,
  ) async {
    final repository = _MemoryOptionRepository();
    final entry = _entry();
    await ParentSharedFeedbackService(
      repository,
    ).saveFeedbackForEntry(entry, '턴 타이밍이 좋아졌어요.', <String>['thanks']);
    await repository.setValue(
      FamilyAccessService.currentRoleLocalKey,
      FamilyRole.parent.name,
    );

    await _pumpHost(tester, repository: repository, entry: entry);
    await tester.tap(find.text('open'));
    await _pumpTestTransition(tester);

    expect(find.text('턴 타이밍이 좋아졌어요.'), findsOneWidget);
    expect(find.text('고마워요'), findsOneWidget);

    final proudChip = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, '뿌듯해요'),
    );
    expect(proudChip.onSelected, isNull);

    final saveButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '피드백 저장'),
    );
    expect(saveButton.onPressed, isNull);
  });
}

Future<void> _pumpHost(
  WidgetTester tester, {
  required _MemoryOptionRepository repository,
  required TrainingEntry entry,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ko', 'KR'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ko', 'KR')],
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ParentFeedbackScreen(
                      entry: entry,
                      optionRepository: repository,
                      driveBackupService: null,
                    ),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await _pumpTestTransition(tester);
}

Future<void> _pumpTestTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

TrainingEntry _entry() {
  return TrainingEntry(
    date: DateTime(2026, 4, 22, 18),
    createdAt: DateTime(2026, 4, 22, 18),
    durationMinutes: 70,
    intensity: 4,
    type: '드리블',
    mood: 4,
    injury: false,
    notes: '기존 메모',
    location: '학교 운동장',
    program: '볼터치',
  );
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> _values = <String, dynamic>{};

  @override
  List<String> getOptions(String key, List<String> defaults) {
    final value = _values[key];
    if (value is List<String>) return value;
    return defaults;
  }

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final value = _values[key];
    if (value is List<int>) return value;
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
