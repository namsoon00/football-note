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
  final bool pinned;

  const HomeHubSectionSetting({
    required this.section,
    required this.visible,
    this.pinned = false,
  });

  HomeHubSectionSetting copyWith({
    bool? visible,
    bool? pinned,
  }) {
    return HomeHubSectionSetting(
      section: section,
      visible: visible ?? this.visible,
      pinned: pinned ?? this.pinned,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': section.storageId,
        'visible': visible,
        'pinned': pinned,
      };
}

class HomeHubSectionSettings {
  static const String storageKey = 'home_hub_sections_v1';
  static const String usageStorageKey = 'home_hub_section_usage_v1';
  static const String legacyLayoutKey = 'home_hub_layout_v1';

  static const List<HomeHubSectionId> defaultOrder = <HomeHubSectionId>[
    HomeHubSectionId.clubSchedule,
    HomeHubSectionId.dailyFlow,
    HomeHubSectionId.quickActions,
    HomeHubSectionId.continueSection,
    HomeHubSectionId.meal,
    HomeHubSectionId.challenge,
    HomeHubSectionId.streak,
    HomeHubSectionId.level,
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
            pinned: item['pinned'] == true,
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

  List<HomeHubSectionId> visibleSectionsByUsage(
    Map<HomeHubSectionId, int> usageCounts,
  ) {
    final visibleItems =
        sections.where((section) => section.visible).toList(growable: false);
    if (visibleItems.length < 2 ||
        usageCounts.values.every((count) => count <= 0)) {
      return visibleSections;
    }

    final originalIndexes = <HomeHubSectionId, int>{
      for (var index = 0; index < visibleItems.length; index++)
        visibleItems[index].section: index,
    };
    final pinnedSlots = <int, HomeHubSectionSetting>{};
    final movableItems = <HomeHubSectionSetting>[];
    for (var index = 0; index < visibleItems.length; index++) {
      final item = visibleItems[index];
      if (item.pinned) {
        pinnedSlots[index] = item;
      } else {
        movableItems.add(item);
      }
    }
    if (movableItems.length < 2) {
      return visibleItems
          .map((section) => section.section)
          .toList(growable: false);
    }

    movableItems.sort((a, b) {
      final usageCompare = (usageCounts[b.section] ?? 0).compareTo(
        usageCounts[a.section] ?? 0,
      );
      if (usageCompare != 0) return usageCompare;
      return originalIndexes[a.section]!.compareTo(originalIndexes[b.section]!);
    });

    final result = <HomeHubSectionId>[];
    var movableIndex = 0;
    for (var index = 0; index < visibleItems.length; index++) {
      final pinned = pinnedSlots[index];
      if (pinned != null) {
        result.add(pinned.section);
      } else {
        result.add(movableItems[movableIndex].section);
        movableIndex += 1;
      }
    }
    return result;
  }

  bool isPinned(HomeHubSectionId section) {
    return sections.any((item) => item.section == section && item.pinned);
  }

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

  HomeHubSectionSettings setPinned(
    HomeHubSectionId section,
    bool pinned,
  ) {
    return HomeHubSectionSettings(
      sections: sections
          .map(
            (item) =>
                item.section == section ? item.copyWith(pinned: pinned) : item,
          )
          .toList(growable: false),
    );
  }

  static Map<HomeHubSectionId, int> decodeUsageCounts(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return <HomeHubSectionId, int>{};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <HomeHubSectionId, int>{};
      final source = decoded['counts'] is Map ? decoded['counts'] : decoded;
      if (source is! Map) return <HomeHubSectionId, int>{};
      final counts = <HomeHubSectionId, int>{};
      for (final entry in source.entries) {
        final section = HomeHubSectionId.fromStorageId(
          entry.key?.toString() ?? '',
        );
        final value = entry.value;
        if (section == null || value is! num || value <= 0) continue;
        counts[section] = value.toInt();
      }
      return counts;
    } catch (_) {
      return <HomeHubSectionId, int>{};
    }
  }

  static String encodeUsageCounts(Map<HomeHubSectionId, int> usageCounts) {
    return jsonEncode(<String, dynamic>{
      'version': 1,
      'counts': <String, int>{
        for (final entry in usageCounts.entries)
          if (entry.value > 0) entry.key.storageId: entry.value,
      },
    });
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
      bySection[HomeHubSectionId.clubSchedule] ??
          const HomeHubSectionSetting(
            section: HomeHubSectionId.clubSchedule,
            visible: true,
          ),
      for (final item in parsed)
        if (item.section != HomeHubSectionId.clubSchedule &&
            bySection[item.section] == item)
          item,
      for (final section in defaultOrder)
        if (section != HomeHubSectionId.clubSchedule &&
            !bySection.containsKey(section))
          HomeHubSectionSetting(section: section, visible: true),
    ];
  }
}
