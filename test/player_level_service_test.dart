import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/player_level_service.dart';
import 'package:football_note/domain/repositories/option_repository.dart';

void main() {
  test('reward becomes available and can be claimed once', () async {
    final repository = _MemoryOptionRepository()
      ..seed(PlayerLevelService.totalXpKey, 60);
    final service = PlayerLevelService(repository);

    final statuses = service.loadRewardStatuses();
    final level2Reward = statuses.firstWhere((item) => item.reward.level == 2);
    final level4Reward = statuses.firstWhere((item) => item.reward.level == 4);

    expect(level2Reward.isAvailable, isTrue);
    expect(level2Reward.isClaimed, isFalse);
    expect(level4Reward.isAvailable, isFalse);

    final claim = await service.claimRewardForLevel(2);
    final secondClaim = await service.claimRewardForLevel(2);

    expect(claim, isNotNull);
    expect(claim!.reward.level, 2);
    expect(secondClaim, isNull);
    expect(
      repository.getValue<List>(PlayerLevelService.claimedRewardLevelsKey),
      contains(2),
    );
  });

  test('custom reward name is stored and returned on claim', () async {
    final repository = _MemoryOptionRepository()
      ..seed(PlayerLevelService.totalXpKey, 60);
    final service = PlayerLevelService(repository);

    await service.setCustomRewardName(2, '새 축구 양말');
    final statuses = service.loadRewardStatuses();
    final level2Reward = statuses.firstWhere((item) => item.reward.level == 2);
    final claim = await service.claimRewardForLevel(2);

    expect(level2Reward.customRewardName, '새 축구 양말');
    expect(service.customRewardNameForLevel(2), '새 축구 양말');
    expect(claim, isNotNull);
    expect(claim!.customRewardName, '새 축구 양말');
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
