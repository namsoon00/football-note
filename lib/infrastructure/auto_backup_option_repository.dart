import 'dart:async';

import '../application/backup_service.dart';
import '../application/drive_backup_service.dart';
import '../application/family_access_service.dart';
import '../domain/repositories/option_repository.dart';

class AutoBackupOptionRepository implements OptionRepository {
  static const Duration _defaultDebounceDuration = Duration(milliseconds: 600);
  static const Set<String> _localOnlyKeys = <String>{
    FamilyAccessService.currentRoleLocalKey,
    DriveBackupService.connectedDriveEmailLocalKey,
    DriveBackupService.connectedDriveLabelLocalKey,
    DriveBackupService.connectedDriveSubjectLocalKey,
    DriveBackupService.recordDriveEmailLocalKey,
    DriveBackupService.recordDriveLabelLocalKey,
    DriveBackupService.recordDriveSubjectLocalKey,
    DriveBackupService.parentDriveEmailLocalKey,
    DriveBackupService.parentDriveLabelLocalKey,
    DriveBackupService.parentDriveSubjectLocalKey,
  };

  final OptionRepository _delegate;
  final BackupService _backupService;
  final Duration _debounceDuration;
  Timer? _timer;
  Future<void>? _inFlight;
  bool _rerunAfterInFlight = false;

  AutoBackupOptionRepository(
    this._delegate,
    this._backupService, {
    Duration debounceDuration = _defaultDebounceDuration,
  }) : _debounceDuration = debounceDuration;

  @override
  List<String> getOptions(String key, List<String> defaults) {
    return _delegate.getOptions(key, defaults);
  }

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    return _delegate.getIntOptions(key, defaults);
  }

  @override
  T? getValue<T>(String key) => _delegate.getValue<T>(key);

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {
    await _delegate.saveOptions(key, options);
    _scheduleBackupForKey(key);
  }

  @override
  Future<void> setValue(String key, dynamic value) async {
    await _delegate.setValue(key, value);
    _scheduleBackupForKey(key);
  }

  void _scheduleBackupForKey(String key) {
    if (_shouldSkipAutoBackup(key)) return;
    _timer?.cancel();
    _timer = Timer(_debounceDuration, _runBackup);
  }

  bool _shouldSkipAutoBackup(String key) {
    return _localOnlyKeys.contains(key) ||
        key.startsWith('drive_') ||
        key.startsWith('local_pre_restore_');
  }

  void _runBackup() {
    if (_inFlight != null) {
      _rerunAfterInFlight = true;
      return;
    }
    _inFlight = _backupService
        .backupIfSignedIn(requireAutoOnSave: true)
        .then<void>((_) {})
        .catchError((_) {})
        .whenComplete(() {
          _inFlight = null;
          if (_rerunAfterInFlight) {
            _rerunAfterInFlight = false;
            _timer?.cancel();
            _timer = Timer(_debounceDuration, _runBackup);
          }
        });
  }
}
