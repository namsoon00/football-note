import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/backup_service.dart';
import 'package:football_note/application/sprint_capture_calibration_service.dart';
import 'package:football_note/domain/repositories/backup_repository.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/infrastructure/auto_backup_option_repository.dart';

void main() {
  test('option writes trigger save-time backup by default', () async {
    final backupRepository = _FakeBackupRepository();
    final repository = AutoBackupOptionRepository(
      _MemoryOptionRepository(),
      BackupService(backupRepository),
      debounceDuration: Duration.zero,
    );

    await repository.setValue('training_plans_v1', '[]');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(backupRepository.backupIfSignedInCount, 1);
    expect(backupRepository.requireAutoOnSaveValues, <bool>[true]);
  });

  test(
    'local drive and role metadata do not trigger save-time backup',
    () async {
      final backupRepository = _FakeBackupRepository();
      final repository = AutoBackupOptionRepository(
        _MemoryOptionRepository(),
        BackupService(backupRepository),
        debounceDuration: Duration.zero,
      );

      await repository.setValue('drive_last_backup', '2026-05-12T00:00:00.000');
      await repository.setValue('family_current_role_local_v1', 'parent');
      await repository.setValue('local_pre_restore_backup', '{}');
      await repository.setValue('welcome_seen_v1', true);
      await repository.setValue('tab_quick_guide_seen_parent_mode_v1', true);
      await repository.setValue(
        SprintCaptureCalibrationProfileService.selectedProfileOptionKey,
        'responsive',
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(backupRepository.backupIfSignedInCount, 0);
    },
  );
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> _values = <String, dynamic>{};

  @override
  List<String> getOptions(String key, List<String> defaults) {
    final value = _values[key];
    if (value is List) {
      return value.map((item) => item.toString()).toList(growable: false);
    }
    return defaults;
  }

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final value = _values[key];
    if (value is List) {
      return value
          .map((item) => int.tryParse(item.toString()) ?? 0)
          .toList(growable: false);
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

class _FakeBackupRepository implements BackupRepository {
  int backupIfSignedInCount = 0;
  final List<bool> requireAutoOnSaveValues = <bool>[];
  bool autoDailyEnabled = true;
  bool autoOnSaveEnabled = true;

  @override
  Future<void> backup() async {}

  @override
  Future<bool> backupIfSignedIn({bool requireAutoOnSave = false}) async {
    backupIfSignedInCount += 1;
    requireAutoOnSaveValues.add(requireAutoOnSave);
    return true;
  }

  @override
  Future<void> autoBackupDaily() async {}

  @override
  DateTime? getLastBackup() => null;

  @override
  bool isAutoDailyEnabled() => autoDailyEnabled;

  @override
  bool isAutoOnSaveEnabled() => autoOnSaveEnabled;

  @override
  Future<void> restoreLatest() async {}

  @override
  Future<void> setAutoDailyEnabled(bool value) async {
    autoDailyEnabled = value;
  }

  @override
  Future<void> setAutoOnSaveEnabled(bool value) async {
    autoOnSaveEnabled = value;
  }
}
