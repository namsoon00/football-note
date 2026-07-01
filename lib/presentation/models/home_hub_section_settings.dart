import 'dart:convert';

enum HomeHubSectionId {
  clubSchedule('club_schedule'),
  level('level'),
  challenge('challenge'),
  streak('streak'),
  meal('meal'),
  dailyFlow('daily_flow'),
  quickActions('quick_actions'),
  continueSection('continue');

  final String storageId;

  const HomeHubSectionId(this.storageId);

  static HomeHubSectionId? fromStorageId(String value) {
    for (final section in values) {
      if (section.storageId == value) return section;
    }
    return null;
  }
}

class HomeHubSectionSetting {
  final HomeHubSectionId section;
  final bool visible;

  const HomeHubSectionSetting({
    required this.section,
    required this.visible,
  });

  HomeHubSectionSetting copyWith({bool? visible}) {
    return HomeHubSectionSetting(
      section: section,
      visible: visible ?? this.visible,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': section.storageId,
        'visible': visible,
      };
}

class HomeHubSectionSettings {
  static const String storageKey = 'home_hub_sections_v1';
  static const String legacyLayoutKey = 'home_hub_layout_v1';

  static const List<HomeHubSectionId> defaultOrder = <HomeHubSectionId>[
    HomeHubSectionId.clubSchedule,
    HomeHubSectionId.level,
    HomeHubSectionId.challenge,
    HomeHubSectionId.streak,
    HomeHubSectionId.meal,
    HomeHubSectionId.dailyFlow,
    HomeHubSectionId.quickActions,
    HomeHubSectionId.continueSection,
  ];

  static const List<HomeHubSectionId> routineFirstOrder = <HomeHubSectionId>[
    HomeHubSectionId.clubSchedule,
    HomeHubSectionId.dailyFlow,
    HomeHubSectionId.quickActions,
    HomeHubSectionId.continueSection,
    HomeHubSectionId.level,
    HomeHubSectionId.challenge,
    HomeHubSectionId.streak,
    HomeHubSectionId.meal,
  ];

  final List<HomeHubSectionSetting> sections;

  const HomeHubSectionSettings({required this.sections});

  factory HomeHubSectionSettings.defaults() {
    return HomeHubSectionSettings.fromOrder(defaultOrder);
  }

  factory HomeHubSectionSettings.fromOrder(List<HomeHubSectionId> order) {
    return HomeHubSectionSettings(
      sections: order
          .map(
            (section) => HomeHubSectionSetting(
              section: section,
              visible: true,
            ),
          )
          .toList(growable: false),
    );
  }

  factory HomeHubSectionSettings.decode(
    String? raw, {
    String? legacyLayout,
  }) {
    if (raw == null || raw.trim().isEmpty) {
      return _fromLegacyLayout(legacyLayout);
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return _fromLegacyLayout(legacyLayout);
      final items = decoded['sections'];
      if (items is! List) return _fromLegacyLayout(legacyLayout);
      final parsed = <HomeHubSectionSetting>[];
      for (final item in items) {
        if (item is! Map) continue;
        final section = HomeHubSectionId.fromStorageId(
          item['id']?.toString() ?? '',
        );
        if (section == null) continue;
        parsed.add(
          HomeHubSectionSetting(
            section: section,
            visible: item['visible'] != false,
          ),
        );
      }
      return HomeHubSectionSettings(
        sections: _normalizedSections(parsed),
      );
    } catch (_) {
      return _fromLegacyLayout(legacyLayout);
    }
  }

  String encode() {
    return jsonEncode(<String, dynamic>{
      'version': 1,
      'sections': sections.map((section) => section.toMap()).toList(),
    });
  }

  List<HomeHubSectionId> get visibleSections => sections
      .where((section) => section.visible)
      .map((section) => section.section)
      .toList(growable: false);

  HomeHubSectionSettings move(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= sections.length) return this;
    final next = List<HomeHubSectionSetting>.of(sections);
    if (newIndex > oldIndex) newIndex -= 1;
    if (newIndex < 0) newIndex = 0;
    if (newIndex > next.length) newIndex = next.length;
    final moved = next.removeAt(oldIndex);
    next.insert(newIndex, moved);
    return HomeHubSectionSettings(sections: next);
  }

  HomeHubSectionSettings setVisible(
    HomeHubSectionId section,
    bool visible,
  ) {
    return HomeHubSectionSettings(
      sections: sections
          .map(
            (item) => item.section == section
                ? item.copyWith(visible: visible)
                : item,
          )
          .toList(growable: false),
    );
  }

  static HomeHubSectionSettings _fromLegacyLayout(String? legacyLayout) {
    if (legacyLayout == 'routine_first') {
      return HomeHubSectionSettings.fromOrder(routineFirstOrder);
    }
    return HomeHubSectionSettings.defaults();
  }

  static List<HomeHubSectionSetting> _normalizedSections(
    List<HomeHubSectionSetting> parsed,
  ) {
    final bySection = <HomeHubSectionId, HomeHubSectionSetting>{};
    for (final item in parsed) {
      bySection.putIfAbsent(item.section, () => item);
    }
    return <HomeHubSectionSetting>[
      for (final item in parsed)
        if (bySection[item.section] == item) item,
      for (final section in defaultOrder)
        if (!bySection.containsKey(section))
          HomeHubSectionSetting(section: section, visible: true),
    ];
  }
}
