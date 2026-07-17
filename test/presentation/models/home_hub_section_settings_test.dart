import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/presentation/models/home_hub_section_settings.dart';

void main() {
  group('HomeHubSectionSettings', () {
    test('defaults prioritize usable actions before motivational progress', () {
      final settings = HomeHubSectionSettings.defaults();

      expect(
        settings.sections.map((item) => item.section),
        <HomeHubSectionId>[
          HomeHubSectionId.dailyFlow,
          HomeHubSectionId.quickActions,
          HomeHubSectionId.continueSection,
          HomeHubSectionId.clubSchedule,
          HomeHubSectionId.meal,
          HomeHubSectionId.streak,
          HomeHubSectionId.challenge,
          HomeHubSectionId.level,
        ],
      );
      expect(settings.customized, isFalse);
    });

    test('decode preserves stored section order', () {
      final settings = HomeHubSectionSettings.decode(
        jsonEncode(
          <String, dynamic>{
            'sections': <Map<String, dynamic>>[
              <String, dynamic>{'id': 'level', 'visible': true},
              <String, dynamic>{'id': 'meal', 'visible': false},
              <String, dynamic>{'id': 'club_schedule', 'visible': true},
            ],
          },
        ),
      );

      expect(
        settings.sections.map((item) => item.section).take(3),
        <HomeHubSectionId>[
          HomeHubSectionId.level,
          HomeHubSectionId.meal,
          HomeHubSectionId.clubSchedule,
        ],
      );
      expect(
        settings.sections
            .firstWhere((item) => item.section == HomeHubSectionId.meal)
            .visible,
        isFalse,
      );
      expect(settings.customized, isTrue);
    });

    test('decode keeps pinned sections', () {
      final settings = HomeHubSectionSettings.decode(
        jsonEncode(
          <String, dynamic>{
            'sections': <Map<String, dynamic>>[
              <String, dynamic>{'id': 'club_schedule', 'visible': true},
              <String, dynamic>{
                'id': 'daily_flow',
                'visible': true,
                'pinned': true,
              },
            ],
          },
        ),
      );

      expect(settings.isPinned(HomeHubSectionId.dailyFlow), isTrue);
      expect(settings.isPinned(HomeHubSectionId.clubSchedule), isFalse);
    });

    test('orders unpinned visible sections by usage', () {
      final settings = HomeHubSectionSettings.defaults();

      expect(
        settings.visibleSectionsByUsage(
          <HomeHubSectionId, int>{
            HomeHubSectionId.challenge: 9,
            HomeHubSectionId.quickActions: 3,
          },
        ).take(3),
        <HomeHubSectionId>[
          HomeHubSectionId.challenge,
          HomeHubSectionId.quickActions,
          HomeHubSectionId.dailyFlow,
        ],
      );
    });

    test('pinned sections keep their visible slot during usage ordering', () {
      final settings = HomeHubSectionSettings.defaults().setPinned(
        HomeHubSectionId.dailyFlow,
        true,
      );

      expect(
        settings.visibleSectionsByUsage(
          <HomeHubSectionId, int>{
            HomeHubSectionId.challenge: 9,
            HomeHubSectionId.quickActions: 3,
          },
        ).take(3),
        <HomeHubSectionId>[
          HomeHubSectionId.dailyFlow,
          HomeHubSectionId.challenge,
          HomeHubSectionId.quickActions,
        ],
      );
    });

    test('usage counts round-trip through storage json', () {
      final encoded = HomeHubSectionSettings.encodeUsageCounts(
        <HomeHubSectionId, int>{
          HomeHubSectionId.dailyFlow: 4,
          HomeHubSectionId.meal: 0,
        },
      );

      expect(
        HomeHubSectionSettings.decodeUsageCounts(encoded),
        <HomeHubSectionId, int>{HomeHubSectionId.dailyFlow: 4},
      );
    });

    test('decode appends missing sections by default order', () {
      final settings = HomeHubSectionSettings.decode(
        jsonEncode(
          <String, dynamic>{
            'sections': <Map<String, dynamic>>[
              <String, dynamic>{'id': 'level', 'visible': true},
              <String, dynamic>{'id': 'daily_flow', 'visible': true},
            ],
          },
        ),
      );

      expect(settings.sections.first.section, HomeHubSectionId.level);
      expect(settings.sections[1].section, HomeHubSectionId.dailyFlow);
      expect(settings.sections[2].section, HomeHubSectionId.quickActions);
      expect(settings.sections[3].section, HomeHubSectionId.continueSection);
    });
  });
}
