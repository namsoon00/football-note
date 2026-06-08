import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../domain/repositories/option_repository.dart';

class LocaleService extends ChangeNotifier {
  static const _key = 'locale';

  final OptionRepository _optionRepository;
  Locale? _locale;
  bool _notificationScheduled = false;
  bool _disposed = false;

  LocaleService(this._optionRepository);

  Locale? get locale => _locale;

  void load() {
    final values = _optionRepository.getOptions(_key, const []);
    if (values.isEmpty) {
      _locale = const Locale('ko', 'KR');
      _notifyListenersSafely();
      return;
    }
    final raw = values.first;
    if (raw == 'en') {
      _locale = const Locale('en');
    } else if (raw == 'ja') {
      _locale = const Locale('ja');
    } else if (raw == 'ko') {
      _locale = const Locale('ko', 'KR');
    }
    _notifyListenersSafely();
  }

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    if (locale == null) {
      await _optionRepository.saveOptions(_key, const []);
    } else {
      await _optionRepository.saveOptions(_key, [locale.languageCode]);
    }
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
}
