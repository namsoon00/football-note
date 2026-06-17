import '../domain/entities/sport_definition.dart';
import '../domain/repositories/option_repository.dart';

class SportService {
  final OptionRepository _options;

  SportService(this._options);

  String currentSportId() {
    return SportCatalog.normalizeSportId(
      _options.getValue<String>(SportCatalog.currentSportOptionKey),
    );
  }

  SportDefinition currentSport() => SportCatalog.byId(currentSportId());

  Future<void> setCurrentSportId(String sportId) async {
    await _options.setValue(
      SportCatalog.currentSportOptionKey,
      SportCatalog.normalizeSportId(sportId),
    );
  }
}
