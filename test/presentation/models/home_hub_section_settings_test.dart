import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/presentation/models/home_hub_section_settings.dart';

void main() {
  group('HomeHubSectionSettings', () {
    test('defaults prioritize motivational progress before training actions',
        () {
      final settings = HomeHubSectionSettings.defaults();

      expect(
        settings.sections.map((item) => item.section),
        <HomeHubSectionId>[
          HomeHubSectionId.challenge,
          HomeHubSectionId.level,
          HomeHubSectionId.streak,
          HomeHubSectionId.dailyFlow,
          HomeHubSectionId.continueSection,
          HomeHubSectionId.quickActions,
          HomeHubSectionId.clubSchedule,
          HomeHubSectionId.meal,
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
          HomeHubSectionId.level,
        ],
      );
    });

    test('pinned sections keep their visible slot during usage ordering', () {
      final settings = HomeHubSectionSettings.defaults().setPinned(
        HomeHubSectionId.level,
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
          HomeHubSectionId.challenge,
          HomeHubSectionId.level,
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
      expect(settings.sections[2].section, HomeHubSectionId.challenge);
      expect(settings.sections[3].section, HomeHubSectionId.streak);
    });
  });
}
