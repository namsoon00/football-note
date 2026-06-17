import 'package:flutter/material.dart';

import '../../domain/entities/sport_definition.dart';

IconData sportPrimaryConditioningIcon(String sportId) {
  switch (SportCatalog.normalizeSportId(sportId)) {
    case SportCatalog.baseballId:
    case SportCatalog.basketballId:
    case SportCatalog.tennisId:
      return Icons.directions_run_rounded;
    case SportCatalog.footballId:
    default:
      return Icons.sports_gymnastics_rounded;
  }
}

IconData sportSecondaryConditioningIcon(String sportId) {
  switch (SportCatalog.normalizeSportId(sportId)) {
    case SportCatalog.baseballId:
      return Icons.sports_baseball;
    case SportCatalog.basketballId:
      return Icons.sports_basketball;
    case SportCatalog.tennisId:
      return Icons.sports_tennis;
    case SportCatalog.footballId:
    default:
      return Icons.sports_soccer;
  }
}
