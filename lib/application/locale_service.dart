import 'package:flutter/material.dart';
import '../domain/repositories/option_repository.dart';

class LocaleService extends ChangeNotifier {
  static const _key = 'locale';

  final OptionRepository _optionRepository;
  Locale? _locale;

  LocaleService(this._optionRepository);

  Locale? get locale => _locale;

  void load() {
    final values = _optionRepository.getOptions(_key, const []);
    if (values.isEmpty) {
      _locale = const Locale('ko', 'KR');
      notifyListeners();
      return;
    }
    final raw = values.first;
    if (raw == 'en') {
      _locale = const Locale('en');
    } else if (raw == 'ko') {
      _locale = const Locale('ko', 'KR');
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    if (locale == null) {
      await _optionRepository.saveOptions(_key, const []);
    } else {
      await _optionRepository.saveOptions(
        _key,
        [locale.languageCode],
      );
    }
    notifyListeners();
  }
}
