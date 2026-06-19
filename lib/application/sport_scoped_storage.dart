import '../domain/entities/sport_definition.dart';
import '../domain/repositories/option_repository.dart';
import 'sport_service.dart';

String currentSportIdForOptions(
  OptionRepository options, {
  String? sportId,
}) {
  return SportCatalog.normalizeSportId(
    sportId ?? SportService(options).currentSportId(),
  );
}

String sportScopedOptionKey(
  OptionRepository options,
  String baseKey, {
  String? sportId,
}) {
  return SportCatalog.optionKey(
    baseKey,
    sportId: currentSportIdForOptions(options, sportId: sportId),
  );
}
