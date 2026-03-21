import 'package:flutter/material.dart';
import '../domain/repositories/option_repository.dart';

class SettingsService extends ChangeNotifier {
  final OptionRepository _repository;

  ThemeMode _themeMode = ThemeMode.light;
  bool _reminderEnabled = true;
  bool _reminderVibrationEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 19, minute: 0);
  bool _wakeAlarmEnabled = false;
  TimeOfDay _wakeAlarmTime = const TimeOfDay(hour: 5, minute: 30);
  List<int> _wakeAlarmWeekdays = const [
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
  ];
  int _wakeAlarmRepeatCount = 4;
  int _wakeAlarmRepeatIntervalMinutes = 5;
  bool _levelUpAlertEnabled = true;
  bool _xpAlertEnabled = true;
  bool _inactivityAlertEnabled = true;
  int _inactivityAlertDays = 3;

  SettingsService(this._repository);

  ThemeMode get themeMode => _themeMode;
  bool get reminderEnabled => _reminderEnabled;
  bool get reminderVibrationEnabled => _reminderVibrationEnabled;
  TimeOfDay get reminderTime => _reminderTime;
  bool get wakeAlarmEnabled => _wakeAlarmEnabled;
  TimeOfDay get wakeAlarmTime => _wakeAlarmTime;
  List<int> get wakeAlarmWeekdays => List<int>.unmodifiable(_wakeAlarmWeekdays);
  int get wakeAlarmRepeatCount => _wakeAlarmRepeatCount;
  int get wakeAlarmRepeatIntervalMinutes => _wakeAlarmRepeatIntervalMinutes;
  bool get levelUpAlertEnabled => _levelUpAlertEnabled;
  bool get xpAlertEnabled => _xpAlertEnabled;
  bool get inactivityAlertEnabled => _inactivityAlertEnabled;
  int get inactivityAlertDays => _inactivityAlertDays;

  void load() {
    final theme = _repository.getValue<String>('theme_mode');
    _themeMode = _parseThemeMode(theme) ?? ThemeMode.light;
    _reminderEnabled = _repository.getValue<bool>('reminder_enabled') ?? true;
    _reminderVibrationEnabled =
        _repository.getValue<bool>('reminder_vibration_enabled') ?? true;
    final time = _repository.getValue<String>('reminder_time');
    _reminderTime = _parseTime(time) ?? _reminderTime;
    _wakeAlarmEnabled =
        _repository.getValue<bool>('wake_alarm_enabled') ?? _wakeAlarmEnabled;
    _wakeAlarmTime =
        _parseTime(_repository.getValue<String>('wake_alarm_time')) ??
        _wakeAlarmTime;
    _wakeAlarmWeekdays = _sanitizeWeekdays(
      _repository.getValue<List>('wake_alarm_weekdays'),
      fallback: _wakeAlarmWeekdays,
    );
    _wakeAlarmRepeatCount = _clampInt(
      _repository.getValue<num>('wake_alarm_repeat_count')?.toInt(),
      fallback: _wakeAlarmRepeatCount,
      min: 1,
      max: 8,
    );
    _wakeAlarmRepeatIntervalMinutes = _clampInt(
      _repository.getValue<num>('wake_alarm_repeat_interval_minutes')?.toInt(),
      fallback: _wakeAlarmRepeatIntervalMinutes,
      min: 1,
      max: 15,
    );
    _levelUpAlertEnabled =
        _repository.getValue<bool>('level_up_alert_enabled') ??
        _levelUpAlertEnabled;
    _xpAlertEnabled =
        _repository.getValue<bool>('xp_alert_enabled') ?? _xpAlertEnabled;
    _inactivityAlertEnabled =
        _repository.getValue<bool>('inactivity_alert_enabled') ??
        _inactivityAlertEnabled;
    _inactivityAlertDays = _clampInt(
      _repository.getValue<num>('inactivity_alert_days')?.toInt(),
      fallback: _inactivityAlertDays,
      min: 1,
      max: 14,
    );
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _repository.setValue('theme_mode', mode.name);
    notifyListeners();
  }

  Future<void> setReminderEnabled(bool enabled) async {
    _reminderEnabled = enabled;
    await _repository.setValue('reminder_enabled', enabled);
    notifyListeners();
  }

  Future<void> setReminderVibrationEnabled(bool enabled) async {
    _reminderVibrationEnabled = enabled;
    await _repository.setValue('reminder_vibration_enabled', enabled);
    notifyListeners();
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    _reminderTime = time;
    await _repository.setValue('reminder_time', _formatTime(time));
    notifyListeners();
  }

  Future<void> setWakeAlarmEnabled(bool enabled) async {
    _wakeAlarmEnabled = enabled;
    await _repository.setValue('wake_alarm_enabled', enabled);
    notifyListeners();
  }

  Future<void> setWakeAlarmTime(TimeOfDay time) async {
    _wakeAlarmTime = time;
    await _repository.setValue('wake_alarm_time', _formatTime(time));
    notifyListeners();
  }

  Future<void> setWakeAlarmWeekdays(List<int> weekdays) async {
    _wakeAlarmWeekdays = _sanitizeWeekdays(
      weekdays,
      fallback: _wakeAlarmWeekdays,
    );
    await _repository.setValue('wake_alarm_weekdays', _wakeAlarmWeekdays);
    notifyListeners();
  }

  Future<void> setWakeAlarmRepeatCount(int count) async {
    _wakeAlarmRepeatCount = count.clamp(1, 8);
    await _repository.setValue(
      'wake_alarm_repeat_count',
      _wakeAlarmRepeatCount,
    );
    notifyListeners();
  }

  Future<void> setWakeAlarmRepeatIntervalMinutes(int minutes) async {
    _wakeAlarmRepeatIntervalMinutes = minutes.clamp(1, 15);
    await _repository.setValue(
      'wake_alarm_repeat_interval_minutes',
      _wakeAlarmRepeatIntervalMinutes,
    );
    notifyListeners();
  }

  Future<void> setLevelUpAlertEnabled(bool enabled) async {
    _levelUpAlertEnabled = enabled;
    await _repository.setValue('level_up_alert_enabled', enabled);
    notifyListeners();
  }

  Future<void> setXpAlertEnabled(bool enabled) async {
    _xpAlertEnabled = enabled;
    await _repository.setValue('xp_alert_enabled', enabled);
    notifyListeners();
  }

  Future<void> setInactivityAlertEnabled(bool enabled) async {
    _inactivityAlertEnabled = enabled;
    await _repository.setValue('inactivity_alert_enabled', enabled);
    notifyListeners();
  }

  Future<void> setInactivityAlertDays(int days) async {
    _inactivityAlertDays = days.clamp(1, 14);
    await _repository.setValue('inactivity_alert_days', _inactivityAlertDays);
    notifyListeners();
  }

  ThemeMode? _parseThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return null;
    }
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null || !value.contains(':')) return null;
    final parts = value.split(':');
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  List<int> _sanitizeWeekdays(
    List<dynamic>? raw, {
    required List<int> fallback,
  }) {
    final weekdays =
        (raw ?? const <dynamic>[])
            .map(
              (item) =>
                  (item is num) ? item.toInt() : int.tryParse('$item') ?? 0,
            )
            .where(
              (value) => value >= DateTime.monday && value <= DateTime.sunday,
            )
            .toSet()
            .toList(growable: false)
          ..sort();
    if (weekdays.isEmpty) {
      return List<int>.from(fallback);
    }
    return weekdays;
  }

  int _clampInt(
    int? value, {
    required int fallback,
    required int min,
    required int max,
  }) {
    if (value == null) return fallback;
    return value.clamp(min, max);
  }
}
