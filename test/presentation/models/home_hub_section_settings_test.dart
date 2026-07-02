import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/presentation/models/home_hub_section_settings.dart';

void main() {
  group('HomeHubSectionSettings', () {
    test('defaults place club schedule first', () {
      final settings = HomeHubSectionSettings.defaults();

      expect(settings.sections.first.section, HomeHubSectionId.clubSchedule);
    });

    test('decode promotes stored club schedule to the top', () {
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
          HomeHubSectionId.clubSchedule,
          HomeHubSectionId.level,
          HomeHubSectionId.meal,
        ],
      );
      expect(
        settings.sections
            .firstWhere((item) => item.section == HomeHubSectionId.meal)
            .visible,
        isFalse,
      );
    });

    test('decode inserts missing club schedule at the top', () {
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

      expect(settings.sections.first.section, HomeHubSectionId.clubSchedule);
      expect(settings.sections[1].section, HomeHubSectionId.level);
    });
  });
}
