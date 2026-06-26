class NotificationAppLink {
  static const scheme = 'footballnote';
  static const notificationTitle = '태오의노트';
  static const Set<String> _hosts = {
    'calendar',
    'challenge',
    'level',
    'league',
    'notifications',
    'weather',
    'world-cup',
    'xp',
  };

  static String calendarPlan({
    required String planId,
    required DateTime scheduledAt,
    required bool atStartTime,
  }) {
    return Uri(
      scheme: scheme,
      host: 'calendar',
      path: '/plan',
      queryParameters: {
        'planId': planId,
        'date': _dateToken(scheduledAt),
        if (atStartTime) 'atStart': '1',
      },
    ).toString();
  }

  static String inactivityReminder({
    required int daysSince,
    required DateTime targetDay,
  }) {
    return Uri(
      scheme: scheme,
      host: 'calendar',
      path: '/inactivity',
      queryParameters: {
        'days': daysSince.toString(),
        'date': _dateToken(targetDay),
      },
    ).toString();
  }

  static String challengeRound({
    required String runId,
    required int roundNumber,
  }) {
    return Uri(
      scheme: scheme,
      host: 'challenge',
      path: '/round',
      queryParameters: {'runId': runId, 'round': roundNumber.toString()},
    ).toString();
  }

  static String levelGuide({required int level}) {
    return Uri(
      scheme: scheme,
      host: 'level',
      path: '/guide',
      queryParameters: {'level': level.toString()},
    ).toString();
  }

  static String xpHistory({required int totalXp}) {
    return Uri(
      scheme: scheme,
      host: 'xp',
      path: '/history',
      queryParameters: {'totalXp': totalXp.toString()},
    ).toString();
  }

  static String familySync({required String role, required DateTime syncedAt}) {
    return Uri(
      scheme: scheme,
      host: 'notifications',
      path: '/family-sync',
      queryParameters: {'role': role, 'syncedAt': syncedAt.toIso8601String()},
    ).toString();
  }

  static String leagueFixture({
    required String leagueType,
    required String fixtureKey,
    required DateTime kickoffAt,
  }) {
    return Uri(
      scheme: scheme,
      host: 'league',
      path: '/fixture',
      queryParameters: {
        'leagueType': leagueType,
        'fixtureKey': fixtureKey,
        'date': _dateToken(kickoffAt),
      },
    ).toString();
  }

  static String worldCupFixture({
    required int matchNumber,
    required String teamName,
    required DateTime kickoffAt,
  }) {
    return Uri(
      scheme: scheme,
      host: 'world-cup',
      path: '/fixture',
      queryParameters: {
        'match': matchNumber.toString(),
        'team': teamName,
        'date': _dateToken(kickoffAt),
      },
    ).toString();
  }

  static String weatherToday() => _weather(action: 'today');

  static String weatherOutfit() => _weather(action: 'outfit');

  static String weatherTomorrow() => _weather(action: 'tomorrow');

  static String weatherWeekly() => _weather(action: 'weekly');

  static String _weather({required String action}) {
    return Uri(
      scheme: scheme,
      host: 'weather',
      path: '/detail',
      queryParameters: {'action': action},
    ).toString();
  }

  static Uri? tryParse(String payload) {
    final trimmed = payload.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;
    if (uri.scheme == scheme) return _normalize(uri);
    if (uri.scheme.isNotEmpty) return null;
    if (!trimmed.startsWith('/')) return null;
    return _normalize(uri);
  }

  static String _dateToken(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  static Uri? _normalize(Uri uri) {
    final host = uri.host.trim();
    if (_hosts.contains(host)) {
      return Uri(
        scheme: scheme,
        host: host,
        pathSegments: uri.pathSegments,
        queryParameters: uri.queryParameters,
      );
    }

    final segments = uri.pathSegments;
    if (segments.isEmpty) return null;
    final first = segments.first.trim();
    if (_hosts.contains(first)) {
      return Uri(
        scheme: scheme,
        host: first,
        pathSegments: segments.skip(1),
        queryParameters: uri.queryParameters,
      );
    }

    final inferredHost = _hostForHostlessPath(first, uri.queryParameters);
    if (inferredHost == null) return null;
    return Uri(
      scheme: scheme,
      host: inferredHost,
      pathSegments: segments,
      queryParameters: uri.queryParameters,
    );
  }

  static String? _hostForHostlessPath(
    String firstSegment,
    Map<String, String> queryParameters,
  ) {
    switch (firstSegment) {
      case 'plan':
      case 'inactivity':
        return 'calendar';
      case 'round':
        return 'challenge';
      case 'guide':
        return 'level';
      case 'history':
        return 'xp';
      case 'fixture':
        return queryParameters.containsKey('match') ? 'world-cup' : 'league';
      case 'detail':
        return 'weather';
      case 'family-sync':
        return 'notifications';
    }
    return null;
  }
}
