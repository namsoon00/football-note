import 'package:flutter/material.dart';

import '../../application/backup_service.dart';
import '../../application/locale_service.dart';
import '../../application/meal_log_service.dart';
import '../../application/player_level_service.dart';
import '../../application/settings_service.dart';
import '../../application/training_service.dart';
import '../../domain/entities/league_standings.dart';
import '../../domain/repositories/option_repository.dart';
import '../screens/challenge_screen.dart';
import '../screens/home_screen.dart';
import '../screens/league_standings_screen.dart';
import '../screens/notification_center_screen.dart';
import '../screens/player_level_guide_screen.dart';
import '../screens/player_xp_history_screen.dart';
import '../screens/world_cup_screen.dart';
import '../widgets/app_page_route.dart';

class NotificationTapDependencies {
  final TrainingService trainingService;
  final MealLogService mealLogService;
  final OptionRepository optionRepository;
  final LocaleService localeService;
  final SettingsService settingsService;
  final BackupService? driveBackupService;

  const NotificationTapDependencies({
    required this.trainingService,
    required this.mealLogService,
    required this.optionRepository,
    required this.localeService,
    required this.settingsService,
    this.driveBackupService,
  });
}

class NotificationTapRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static NotificationTapDependencies? _dependencies;
  static String? _pendingPayload;

  static void configure(NotificationTapDependencies dependencies) {
    _dependencies = dependencies;
    final pending = _pendingPayload;
    if (pending != null) {
      _pendingPayload = null;
      handlePayload(pending);
    }
  }

  static void handlePayload(String? payload) {
    final normalized = payload?.trim();
    if (normalized == null || normalized.isEmpty) {
      _openWhenReady('', _notificationCenterBuilder);
      return;
    }
    _openWhenReady(normalized, (dependencies) {
      if (normalized.startsWith('xp:')) {
        return PlayerXpHistoryScreen(
          optionRepository: dependencies.optionRepository,
        );
      }
      if (normalized.startsWith('levelup:')) {
        final level = int.tryParse(normalized.split(':').last);
        final currentLevel = level ??
            PlayerLevelService(dependencies.optionRepository).loadState().level;
        return PlayerLevelGuideScreen(
          currentLevel: currentLevel,
          optionRepository: dependencies.optionRepository,
          driveBackupService: dependencies.driveBackupService,
        );
      }
      if (normalized.startsWith('challenge:')) {
        return ChallengeScreen(
          trainingService: dependencies.trainingService,
          mealLogService: dependencies.mealLogService,
          optionRepository: dependencies.optionRepository,
          localeService: dependencies.localeService,
          settingsService: dependencies.settingsService,
          driveBackupService: dependencies.driveBackupService,
        );
      }
      if (normalized.startsWith('worldcup:') ||
          normalized.startsWith('worldcup_fixture:')) {
        return WorldCupScreen(
          optionRepository: dependencies.optionRepository,
          settingsService: dependencies.settingsService,
        );
      }
      if (normalized.startsWith('league_fixture:')) {
        return LeagueStandingsScreen(
          initialType: _leagueTypeFromPayload(normalized) ??
              LeagueStandingsType.kLeague1,
          optionRepository: dependencies.optionRepository,
          settingsService: dependencies.settingsService,
        );
      }
      final legacyLeagueType = _leagueTypeFromName(normalized.split(':').first);
      if (legacyLeagueType != null) {
        return LeagueStandingsScreen(
          initialType: legacyLeagueType,
          optionRepository: dependencies.optionRepository,
          settingsService: dependencies.settingsService,
        );
      }
      if (normalized.startsWith('family-sync:')) {
        return _notificationCenterBuilder(dependencies);
      }
      return HomeScreen(
        trainingService: dependencies.trainingService,
        mealLogService: dependencies.mealLogService,
        optionRepository: dependencies.optionRepository,
        localeService: dependencies.localeService,
        settingsService: dependencies.settingsService,
        driveBackupService: dependencies.driveBackupService,
        initialIndex: 2,
      );
    });
  }

  static Widget _notificationCenterBuilder(
    NotificationTapDependencies dependencies,
  ) {
    return NotificationCenterScreen(
      optionRepository: dependencies.optionRepository,
      settingsService: dependencies.settingsService,
    );
  }

  static void _openWhenReady(
    String payload,
    Widget Function(NotificationTapDependencies dependencies) builder,
  ) {
    final dependencies = _dependencies;
    final navigator = navigatorKey.currentState;
    if (dependencies == null || navigator == null) {
      _pendingPayload = payload;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final readyDependencies = _dependencies;
        final readyNavigator = navigatorKey.currentState;
        if (readyDependencies == null || readyNavigator == null) return;
        if (_pendingPayload != payload) return;
        _pendingPayload = null;
        readyNavigator.push(
          AppPageRoute<void>(builder: (_) => builder(readyDependencies)),
        );
      });
      return;
    }
    navigator.push(AppPageRoute<void>(builder: (_) => builder(dependencies)));
  }

  static LeagueStandingsType? _leagueTypeFromPayload(String payload) {
    final parts = payload.split(':');
    if (parts.length < 2) return null;
    return _leagueTypeFromName(parts[1]);
  }

  static LeagueStandingsType? _leagueTypeFromName(String value) {
    for (final type in LeagueStandingsType.values) {
      if (type.name == value) return type;
    }
    return null;
  }
}
