import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../domain/repositories/option_repository.dart';

class SettingsService extends ChangeNotifier {
  final OptionRepository _repository;
  bool _notificationScheduled = false;
  bool _disposed = false;

  ThemeMode _themeMode = ThemeMode.light;
  bool _reminderEnabled = true;
  bool _reminderVibrationEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 19, minute: 0);
  bool _levelUpAlertEnabled = true;
  bool _xpAlertEnabled = true;
  bool _inactivityAlertEnabled = true;
  bool _familySyncAlertEnabled = true;
  bool _leagueFixtureAlertEnabled = true;
  bool _weatherAlertEnabled = true;
  TimeOfDay _weatherAlertTime = const TimeOfDay(hour: 7, minute: 0);
  int _inactivityAlertDays = 3;

  SettingsService(this._repository);

  ThemeMode get themeMode => _themeMode;
  bool get reminderEnabled => _reminderEnabled;
  bool get reminderVibrationEnabled => _reminderVibrationEnabled;
  TimeOfDay get reminderTime => _reminderTime;
  bool get levelUpAlertEnabled => _levelUpAlertEnabled;
  bool get xpAlertEnabled => _xpAlertEnabled;
  bool get inactivityAlertEnabled => _inactivityAlertEnabled;
  bool get familySyncAlertEnabled => _familySyncAlertEnabled;
  bool get leagueFixtureAlertEnabled => _leagueFixtureAlertEnabled;
  bool get weatherAlertEnabled => _weatherAlertEnabled;
  TimeOfDay get weatherAlertTime => _weatherAlertTime;
  int get inactivityAlertDays => _inactivityAlertDays;

  void load() {
    final theme = _repository.getValue<String>('theme_mode');
    _themeMode = _parseThemeMode(theme) ?? ThemeMode.light;
    _reminderEnabled = _repository.getValue<bool>('reminder_enabled') ?? true;
    _reminderVibrationEnabled =
        _repository.getValue<bool>('reminder_vibration_enabled') ?? true;
    final time = _repository.getValue<String>('reminder_time');
    _reminderTime = _parseTime(time) ?? _reminderTime;
    _levelUpAlertEnabled =
        _repository.getValue<bool>('level_up_alert_enabled') ??
            _levelUpAlertEnabled;
    _xpAlertEnabled =
        _repository.getValue<bool>('xp_alert_enabled') ?? _xpAlertEnabled;
    _inactivityAlertEnabled =
        _repository.getValue<bool>('inactivity_alert_enabled') ??
            _inactivityAlertEnabled;
    _familySyncAlertEnabled =
        _repository.getValue<bool>('family_sync_alert_enabled') ??
            _familySyncAlertEnabled;
    _leagueFixtureAlertEnabled =
        _repository.getValue<bool>('league_fixture_alert_enabled') ??
            _leagueFixtureAlertEnabled;
    _weatherAlertEnabled =
        _repository.getValue<bool>('weather_alert_enabled') ??
            _weatherAlertEnabled;
    final weatherTime = _repository.getValue<String>('weather_alert_time');
    _weatherAlertTime = _parseTime(weatherTime) ?? _weatherAlertTime;
    _inactivityAlertDays = _clampInt(
      _repository.getValue<num>('inactivity_alert_days')?.toInt(),
      fallback: _inactivityAlertDays,
      min: 1,
      max: 14,
    );
    _notifyListenersSafely();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _repository.setValue('theme_mode', mode.name);
    _notifyListenersSafely();
  }

  Future<void> setReminderEnabled(bool enabled) async {
    _reminderEnabled = enabled;
    await _repository.setValue('reminder_enabled', enabled);
    _notifyListenersSafely();
  }

  Future<void> setReminderVibrationEnabled(bool enabled) async {
    _reminderVibrationEnabled = enabled;
    await _repository.setValue('reminder_vibration_enabled', enabled);
    _notifyListenersSafely();
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    _reminderTime = time;
    await _repository.setValue('reminder_time', _formatTime(time));
    _notifyListenersSafely();
  }

  Future<void> setLevelUpAlertEnabled(bool enabled) async {
    _levelUpAlertEnabled = enabled;
    await _repository.setValue('level_up_alert_enabled', enabled);
    _notifyListenersSafely();
  }

  Future<void> setXpAlertEnabled(bool enabled) async {
    _xpAlertEnabled = enabled;
    await _repository.setValue('xp_alert_enabled', enabled);
    _notifyListenersSafely();
  }

  Future<void> setInactivityAlertEnabled(bool enabled) async {
    _inactivityAlertEnabled = enabled;
    await _repository.setValue('inactivity_alert_enabled', enabled);
    _notifyListenersSafely();
  }

  Future<void> setFamilySyncAlertEnabled(bool enabled) async {
    _familySyncAlertEnabled = enabled;
    await _repository.setValue('family_sync_alert_enabled', enabled);
    _notifyListenersSafely();
  }

  Future<void> setLeagueFixtureAlertEnabled(bool enabled) async {
    _leagueFixtureAlertEnabled = enabled;
    await _repository.setValue('league_fixture_alert_enabled', enabled);
    _notifyListenersSafely();
  }

  Future<void> setWeatherAlertEnabled(bool enabled) async {
    _weatherAlertEnabled = enabled;
    await _repository.setValue('weather_alert_enabled', enabled);
    _notifyListenersSafely();
  }

  Future<void> setWeatherAlertTime(TimeOfDay time) async {
    _weatherAlertTime = time;
    await _repository.setValue('weather_alert_time', _formatTime(time));
    _notifyListenersSafely();
  }

  Future<void> setInactivityAlertDays(int days) async {
    _inactivityAlertDays = days.clamp(1, 14);
    await _repository.setValue('inactivity_alert_days', _inactivityAlertDays);
    _notifyListenersSafely();
  }

  void _notifyListenersSafely() {
    if (_disposed) return;
    if (SchedulerBinding.instance.schedulerPhase !=
        SchedulerPhase.persistentCallbacks) {
      notifyListeners();
      return;
    }
    if (_notificationScheduled) return;
    _notificationScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _notificationScheduled = false;
      if (!_disposed) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
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
