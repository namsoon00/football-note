import 'package:flutter/material.dart';
import '../domain/repositories/option_repository.dart';

class SettingsService extends ChangeNotifier {
  final OptionRepository _repository;

  ThemeMode _themeMode = ThemeMode.light;
  bool _reminderEnabled = true;
  bool _reminderVibrationEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 19, minute: 0);

  SettingsService(this._repository);

  ThemeMode get themeMode => _themeMode;
  bool get reminderEnabled => _reminderEnabled;
  bool get reminderVibrationEnabled => _reminderVibrationEnabled;
  TimeOfDay get reminderTime => _reminderTime;

  void load() {
    final theme = _repository.getValue<String>('theme_mode');
    _themeMode = _parseThemeMode(theme) ?? ThemeMode.light;
    _reminderEnabled = _repository.getValue<bool>('reminder_enabled') ?? true;
    _reminderVibrationEnabled =
        _repository.getValue<bool>('reminder_vibration_enabled') ?? true;
    final time = _repository.getValue<String>('reminder_time');
    _reminderTime = _parseTime(time) ?? _reminderTime;
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
    await _repository.setValue(
      'reminder_time',
      _formatTime(time),
    );
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
}
