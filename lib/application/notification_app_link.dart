class NotificationAppLink {
  static const scheme = 'footballnote';
  static const notificationTitle = '태오의 노트';
  static const Set<String> _hosts = {
    'calendar',
    'challenge',
    'level',
    'league',
    'notifications',
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

  static Uri? tryParse(String payload) {
    final trimmed = payload.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.scheme == scheme) return uri;
    if (uri == null || !trimmed.startsWith('/')) return null;
    final segments = uri.pathSegments;
    if (segments.isEmpty || !_hosts.contains(segments.first)) return null;
    return Uri(
      scheme: scheme,
      host: segments.first,
      pathSegments: segments.skip(1),
      queryParameters: uri.queryParameters,
    );
  }

  static String _dateToken(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}
