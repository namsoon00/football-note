import 'dart:convert';

import 'package:flutter/material.dart';

import '../../application/backup_service.dart';
import '../../application/locale_service.dart';
import '../../application/meal_log_service.dart';
import '../../application/notification_app_link.dart';
import '../../application/player_level_service.dart';
import '../../application/settings_service.dart';
import '../../application/training_service.dart';
import '../../application/training_plan_reminder_service.dart';
import '../../application/world_cup_schedule.dart';
import '../../domain/entities/league_standings.dart';
import '../../domain/repositories/option_repository.dart';
import '../screens/challenge_screen.dart';
import '../screens/club_schedule_screen.dart';
import '../screens/home_screen.dart';
import '../screens/league_standings_screen.dart';
import '../screens/notification_center_screen.dart';
import '../screens/player_level_guide_screen.dart';
import '../screens/player_xp_history_screen.dart';
import '../screens/weather_detail_screen.dart';
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
    final appLink = NotificationAppLink.tryParse(normalized);
    if (appLink != null) {
      _openWhenReady(
        normalized,
        (dependencies) =>
            _screenForAppLink(appLink, dependencies) ??
            _notificationCenterBuilder(dependencies),
      );
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
          initialSelectedDay: _worldCupDayFromLegacyPayload(normalized),
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
      if (normalized.startsWith('weather:')) {
        return WeatherDetailScreen(
          initialAction: _weatherActionFromLegacyPayload(normalized),
        );
      }
      return _homeScreen(
        dependencies,
        initialIndex: 2,
        initialCalendarSelectedDay: _planDayForId(dependencies, normalized),
      );
    });
  }

  static Widget? _screenForAppLink(
    Uri uri,
    NotificationTapDependencies dependencies,
  ) {
    switch (uri.host) {
      case 'calendar':
        return _homeScreen(
          dependencies,
          initialIndex: 2,
          initialCalendarSelectedDay: _dateFromQuery(uri),
        );
      case 'xp':
        return PlayerXpHistoryScreen(
          optionRepository: dependencies.optionRepository,
        );
      case 'level':
        final level = int.tryParse(uri.queryParameters['level'] ?? '');
        final currentLevel = level ??
            PlayerLevelService(dependencies.optionRepository).loadState().level;
        return PlayerLevelGuideScreen(
          currentLevel: currentLevel,
          optionRepository: dependencies.optionRepository,
          driveBackupService: dependencies.driveBackupService,
        );
      case 'challenge':
        return ChallengeScreen(
          trainingService: dependencies.trainingService,
          mealLogService: dependencies.mealLogService,
          optionRepository: dependencies.optionRepository,
          localeService: dependencies.localeService,
          settingsService: dependencies.settingsService,
          driveBackupService: dependencies.driveBackupService,
        );
      case 'club':
        return ClubScheduleScreen(
          optionRepository: dependencies.optionRepository,
        );
      case 'world-cup':
        return WorldCupScreen(
          initialSelectedDay: _dateFromQuery(uri),
          optionRepository: dependencies.optionRepository,
          settingsService: dependencies.settingsService,
        );
      case 'league':
        return LeagueStandingsScreen(
          initialType:
              _leagueTypeFromName(uri.queryParameters['leagueType'] ?? '') ??
                  LeagueStandingsType.kLeague1,
          optionRepository: dependencies.optionRepository,
          settingsService: dependencies.settingsService,
        );
      case 'weather':
        return WeatherDetailScreen(initialAction: _weatherActionFromLink(uri));
      case 'notifications':
        return _notificationCenterBuilder(dependencies);
    }
    return null;
  }

  static Widget _homeScreen(
    NotificationTapDependencies dependencies, {
    int initialIndex = 0,
    DateTime? initialCalendarSelectedDay,
  }) {
    return HomeScreen(
      trainingService: dependencies.trainingService,
      mealLogService: dependencies.mealLogService,
      optionRepository: dependencies.optionRepository,
      localeService: dependencies.localeService,
      settingsService: dependencies.settingsService,
      driveBackupService: dependencies.driveBackupService,
      initialIndex: initialIndex,
      initialCalendarSelectedDay: initialCalendarSelectedDay,
    );
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

  static DateTime? _dateFromQuery(Uri uri) {
    final raw = uri.queryParameters['date'] ?? uri.queryParameters['day'];
    if (raw == null || raw.trim().isEmpty) return null;
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static WeatherDetailInitialAction _weatherActionFromLink(Uri uri) {
    final action = (uri.queryParameters['action'] ??
            (uri.pathSegments.isEmpty ? '' : uri.pathSegments.last))
        .trim()
        .toLowerCase();
    return _weatherActionFromToken(action);
  }

  static WeatherDetailInitialAction _weatherActionFromLegacyPayload(
    String payload,
  ) {
    final parts = payload.split(':');
    final token = parts.length > 1 ? parts[1] : '';
    return _weatherActionFromToken(token);
  }

  static WeatherDetailInitialAction _weatherActionFromToken(String token) {
    switch (token.trim().toLowerCase()) {
      case 'outfit':
      case 'outfit-guide':
        return WeatherDetailInitialAction.outfitGuide;
      case 'tomorrow':
        return WeatherDetailInitialAction.tomorrowForecast;
      case 'weekly':
      case 'week':
        return WeatherDetailInitialAction.weeklyForecast;
      default:
        return WeatherDetailInitialAction.none;
    }
  }

  static DateTime? _planDayForId(
    NotificationTapDependencies dependencies,
    String planId,
  ) {
    if (planId.trim().isEmpty || planId.contains(':')) return null;
    final raw = dependencies.optionRepository.getValue<String>(
      TrainingPlanReminderService.plansStorageKeyFor(
        dependencies.optionRepository,
      ),
    );
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      for (final item in decoded.whereType<Map>()) {
        if (item['id']?.toString() != planId) continue;
        final scheduledAt = DateTime.tryParse(
          item['scheduledAt']?.toString() ?? '',
        );
        if (scheduledAt == null) return null;
        return DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static DateTime? _worldCupDayFromLegacyPayload(String payload) {
    final parts = payload.split(':');
    if (parts.length < 2) return null;
    final matchNumber = int.tryParse(parts[1]);
    if (matchNumber == null) return null;
    for (final fixture in worldCupFixtures) {
      if (fixture.matchNumber == matchNumber) return fixture.localDay;
    }
    return null;
  }

  static LeagueStandingsType? _leagueTypeFromName(String value) {
    for (final type in LeagueStandingsType.values) {
      if (type.name == value) return type;
    }
    return null;
  }
}
