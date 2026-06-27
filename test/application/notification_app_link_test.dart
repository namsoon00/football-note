import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/notification_app_link.dart';

void main() {
  group('NotificationAppLink', () {
    test('normalizes generated notification links', () {
      final date = DateTime(2026, 6, 26, 9, 30);
      expect(NotificationAppLink.scheme, 'taeonote');

      expectLink(
        NotificationAppLink.calendarPlan(
          planId: 'plan-1',
          scheduledAt: date,
          atStartTime: true,
        ),
        host: 'calendar',
        path: '/plan',
      );
      expectLink(
        NotificationAppLink.inactivityReminder(daysSince: 3, targetDay: date),
        host: 'calendar',
        path: '/inactivity',
      );
      expectLink(
        NotificationAppLink.challengeRound(runId: 'run-1', roundNumber: 2),
        host: 'challenge',
        path: '/round',
      );
      expectLink(
        NotificationAppLink.levelGuide(level: 7),
        host: 'level',
        path: '/guide',
      );
      expectLink(
        NotificationAppLink.xpHistory(totalXp: 120),
        host: 'xp',
        path: '/history',
      );
      expectLink(
        NotificationAppLink.familySync(role: 'parent', syncedAt: date),
        host: 'notifications',
        path: '/family-sync',
      );
      expectLink(
        NotificationAppLink.leagueFixture(
          leagueType: 'kLeague1',
          fixtureKey: 'fixture-1',
          kickoffAt: date,
        ),
        host: 'league',
        path: '/fixture',
      );
      expectLink(
        NotificationAppLink.worldCupFixture(
          matchNumber: 12,
          teamName: 'Korea Republic',
          kickoffAt: date,
        ),
        host: 'world-cup',
        path: '/fixture',
      );
      expectLink(
        NotificationAppLink.weatherWeekly(),
        host: 'weather',
        path: '/detail',
      );
    });

    test('accepts Flutter route names and hostless app scheme paths', () {
      expectLink(
        '/calendar/plan?planId=plan-1&date=2026-06-26',
        host: 'calendar',
        path: '/plan',
      );
      expectLink(
        'taeonote:/calendar/plan?planId=plan-1&date=2026-06-26',
        host: 'calendar',
        path: '/plan',
      );
      expectLink(
        'taeonote:///weather/detail?action=outfit',
        host: 'weather',
        path: '/detail',
      );
    });

    test('accepts previous app scheme payloads as legacy aliases', () {
      final previousScheme = String.fromCharCodes(
        const <int>[
          102,
          111,
          111,
          116,
          98,
          97,
          108,
          108,
          110,
          111,
          116,
          101,
        ],
      );

      expectLink(
        '$previousScheme:/calendar/plan?planId=plan-1&date=2026-06-26',
        host: 'calendar',
        path: '/plan',
      );
      expectLink(
        '$previousScheme:///weather/detail?action=outfit',
        host: 'weather',
        path: '/detail',
      );
    });

    test('infers destination when the platform drops the app link host', () {
      expectLink(
        '/plan?planId=plan-1&date=2026-06-26',
        host: 'calendar',
        path: '/plan',
      );
      expectLink(
        '/inactivity?days=3&date=2026-06-26',
        host: 'calendar',
        path: '/inactivity',
      );
      expectLink(
        '/round?runId=run-1&round=2',
        host: 'challenge',
        path: '/round',
      );
      expectLink('/guide?level=7', host: 'level', path: '/guide');
      expectLink('/history?totalXp=120', host: 'xp', path: '/history');
      expectLink(
        '/fixture?leagueType=kLeague1&fixtureKey=fixture-1&date=2026-06-26',
        host: 'league',
        path: '/fixture',
      );
      expectLink(
        '/fixture?match=12&team=Korea%20Republic&date=2026-06-26',
        host: 'world-cup',
        path: '/fixture',
      );
      expectLink('/detail?action=tomorrow', host: 'weather', path: '/detail');
      expectLink(
        '/family-sync?role=parent&syncedAt=2026-06-26T09:30:00.000',
        host: 'notifications',
        path: '/family-sync',
      );
    });

    test('rejects non-notification routes', () {
      expect(NotificationAppLink.tryParse('https://example.com/plan'), isNull);
      expect(NotificationAppLink.tryParse('/unknown/path'), isNull);
      expect(NotificationAppLink.tryParse('plain-text'), isNull);
    });
  });
}

void expectLink(String value, {required String host, required String path}) {
  final uri = NotificationAppLink.tryParse(value);
  expect(uri, isNotNull);
  expect(uri!.scheme, NotificationAppLink.scheme);
  expect(uri.host, host);
  expect(uri.path, path);
}
