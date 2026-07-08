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
      _locale = null;
      _notifyListenersSafely();
      return;
    }
    _locale = _localeForStoredValue(values.first);
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

  Locale? _localeForStoredValue(String raw) {
    final languageCode = raw.trim().replaceAll('_', '-').split('-').first;
    return switch (languageCode) {
      'en' => const Locale('en'),
      'ja' => const Locale('ja'),
      'ko' => const Locale('ko', 'KR'),
      _ => null,
    };
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
