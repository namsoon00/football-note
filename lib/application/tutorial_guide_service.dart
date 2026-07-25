import 'package:flutter/foundation.dart';

import '../domain/repositories/option_repository.dart';

class TutorialGuideService {
  static const String parentSeenKey = 'tab_quick_guide_seen_parent_mode_v1';
  static const List<int> guidedTabIndexes = <int>[0, 1, 2, 3, 4];
  static final ValueNotifier<int> replayRequests = ValueNotifier<int>(0);

  static String childSeenKey(int tabIndex) =>
      'tab_quick_guide_seen_v1_$tabIndex';

  static Future<void> resetProgress(OptionRepository repository) async {
    await repository.setValue(parentSeenKey, false);
    for (final tabIndex in guidedTabIndexes) {
      await repository.setValue(childSeenKey(tabIndex), false);
    }
  }

  static void requestReplay() {
    replayRequests.value += 1;
  }
}
