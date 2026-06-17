import 'package:flutter/foundation.dart';

import '../domain/entities/sport_definition.dart';
import '../domain/repositories/option_repository.dart';
import 'sport_service.dart';

class SportStateController extends ChangeNotifier {
  final OptionRepository _options;
  late String _currentSportId;

  SportStateController(this._options) {
    _currentSportId = SportService(_options).currentSportId();
  }

  String get currentSportId => _currentSportId;

  Future<bool> setCurrentSportId(String sportId) async {
    final normalizedSportId = SportCatalog.normalizeSportId(sportId);
    if (_currentSportId == normalizedSportId) {
      return false;
    }
    await SportService(_options).setCurrentSportId(normalizedSportId);
    _currentSportId = normalizedSportId;
    notifyListeners();
    return true;
  }

  bool reloadFromStorage() {
    final normalizedSportId = SportService(_options).currentSportId();
    if (_currentSportId == normalizedSportId) {
      return false;
    }
    _currentSportId = normalizedSportId;
    notifyListeners();
    return true;
  }
}
