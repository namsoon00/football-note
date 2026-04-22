import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/family_access_service.dart';
import 'package:football_note/domain/repositories/option_repository.dart';

void main() {
  test('defaults to child role and falls back to profile name', () {
    final repository = _MemoryOptionRepository()
      ..seed('profile_name', 'Minjun');

    final state = FamilyAccessService(repository).loadState();

    expect(state.currentRole, FamilyRole.child);
    expect(state.childName, 'Minjun');
    expect(state.parentName, isEmpty);
    expect(state.backupPolicy.childOwnsCoreData, isTrue);
    expect(state.backupPolicy.parentMergesFamilyLayerOnly, isTrue);
  });

  test('saving members creates family id and persists both names', () async {
    final repository = _MemoryOptionRepository();
    final service = FamilyAccessService(repository);

    await service.saveMembers(childName: 'Minjun', parentName: 'Dad');

    final state = service.loadState();
    expect(state.familyId, startsWith('family-'));
    expect(state.childName, 'Minjun');
    expect(state.parentName, 'Dad');
  });

  test(
    'shared backup keys exclude local role and include reward names and parent feedback',
    () {
      expect(
        FamilyAccessService.isLocalOnlyOptionKey(
          FamilyAccessService.currentRoleLocalKey,
        ),
        isTrue,
      );
      expect(
        FamilyAccessService.isSharedBackupOptionKey(
          FamilyAccessService.currentRoleLocalKey,
        ),
        isFalse,
      );
      expect(
        FamilyAccessService.isSharedBackupOptionKey(
          FamilyAccessService.linkedRoleKey,
        ),
        isTrue,
      );
      expect(
        FamilyAccessService.isSharedBackupOptionKey(
          'player_custom_reward_names_v1',
        ),
        isTrue,
      );
      expect(
        FamilyAccessService.isSharedBackupOptionKey(
          FamilyAccessService.parentTrainingFeedbackKey,
        ),
        isTrue,
      );
      expect(
        FamilyAccessService.isSharedBackupOptionKey(
          FamilyAccessService.messagesKey,
        ),
        isFalse,
      );
    },
  );

  test(
    'coach role is loaded as support role and becomes linked role',
    () async {
      final repository = _MemoryOptionRepository();
      final service = FamilyAccessService(repository);

      await service.setCurrentRole(FamilyRole.coach);

      final state = service.loadState();
      expect(state.currentRole, FamilyRole.coach);
      expect(state.linkedRole, FamilyRole.coach);
      expect(state.isSupportMode, isTrue);
      expect(service.canEditRewardNames(FamilyRole.coach), isTrue);
    },
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
