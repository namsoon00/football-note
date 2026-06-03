import 'package:football_note/application/family_access_service.dart';
import 'package:football_note/application/parent_shared_feedback_service.dart';
import 'package:football_note/domain/entities/training_entry.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stores feedback by entry createdAt and clears it safely', () async {
    final repository = _MemoryOptionRepository();
    final service = ParentSharedFeedbackService(repository);
    final entry = TrainingEntry(
      date: DateTime(2026, 4, 22),
      createdAt: DateTime(2026, 4, 22, 18, 30),
      durationMinutes: 60,
      intensity: 4,
      type: '드리블',
      mood: 4,
      injury: false,
      notes: '',
      location: '메인 구장',
    );

    final saved = await service.saveFeedbackForEntry(
      entry,
      '턴 타이밍이 좋아졌고 시야가 더 넓어졌어요.',
    );

    expect(saved, isNotNull);
    expect(
      service.feedbackForEntry(entry)?.message,
      '턴 타이밍이 좋아졌고 시야가 더 넓어졌어요.',
    );
    final raw = repository.getValue<Map>(
      FamilyAccessService.parentTrainingFeedbackKey,
    );
    expect(raw, isNotNull);
    expect(raw!.keys.single, ParentSharedFeedbackService.entryIdFor(entry));

    await service.saveFeedbackForEntry(entry, '');

    expect(service.feedbackForEntry(entry), isNull);
    final cleared = repository.getValue<Map>(
      FamilyAccessService.parentTrainingFeedbackKey,
    );
    expect(cleared, isEmpty);
  });

  test('stores multiple player reactions without feedback text', () async {
    final repository = _MemoryOptionRepository();
    final service = ParentSharedFeedbackService(repository);
    final entry = TrainingEntry(
      date: DateTime(2026, 4, 22),
      createdAt: DateTime(2026, 4, 22, 18, 30),
      durationMinutes: 60,
      intensity: 4,
      type: '드리블',
      mood: 4,
      injury: false,
      notes: '',
      location: '메인 구장',
    );

    final saved = await service.saveFeedbackForEntry(entry, '', [
      'proud',
      'thanks',
    ]);

    expect(saved, isNotNull);
    expect(saved!.message, isEmpty);
    expect(saved.reactions, ['proud', 'thanks']);
    expect(service.feedbackForEntry(entry)?.reactions, ['proud', 'thanks']);
    expect(service.feedbackForEntry(entry)?.reaction, 'proud,thanks');
    expect(service.loadAll(), hasLength(1));
  });

  test('reads legacy single reaction parent feedback', () async {
    final repository = _MemoryOptionRepository();
    final service = ParentSharedFeedbackService(repository);
    final entry = TrainingEntry(
      date: DateTime(2026, 4, 22),
      createdAt: DateTime(2026, 4, 22, 18, 30),
      durationMinutes: 60,
      intensity: 4,
      type: '드리블',
      mood: 4,
      injury: false,
      notes: '',
      location: '메인 구장',
    );
    await repository.setValue(
      FamilyAccessService.parentTrainingFeedbackKey,
      <String, dynamic>{
        ParentSharedFeedbackService.entryIdFor(entry): <String, dynamic>{
          'message': '',
          'reaction': 'review',
        },
      },
    );

    expect(service.feedbackForEntry(entry)?.reactions, ['review']);
  });
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> _values = <String, dynamic>{};

  @override
  List<String> getOptions(String key, List<String> defaults) {
    final value = _values[key];
    if (value is List<String>) return List<String>.of(value);
    return List<String>.of(defaults);
  }

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final value = _values[key];
    if (value is List<int>) return List<int>.of(value);
    return List<int>.of(defaults);
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
