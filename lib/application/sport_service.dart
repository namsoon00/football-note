import '../domain/entities/sport_definition.dart';
import '../domain/repositories/option_repository.dart';

class SportService {
  // Keeps the public app focused on one sport without mutating a user's
  // persisted selection, so the other sport data can be restored later.
  static String? _fixedSportIdForCurrentSession;

  final OptionRepository _options;

  SportService(this._options);

  static void setFixedSportForCurrentSession(String? sportId) {
    _fixedSportIdForCurrentSession =
        sportId == null ? null : SportCatalog.normalizeSportId(sportId);
  }

  String currentSportId() {
    final fixedSportId = _fixedSportIdForCurrentSession;
    if (fixedSportId != null) {
      return fixedSportId;
    }
    return SportCatalog.normalizeSportId(
      _options.getValue<String>(SportCatalog.currentSportOptionKey),
    );
  }

  SportDefinition currentSport() => SportCatalog.byId(currentSportId());

  Future<void> setCurrentSportId(String sportId) async {
    if (_fixedSportIdForCurrentSession != null) {
      return;
    }
    await _options.setValue(
      SportCatalog.currentSportOptionKey,
      SportCatalog.normalizeSportId(sportId),
    );
  }
}
