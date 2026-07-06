import 'dart:async';

import 'package:flutter/services.dart';

class AppSoundEffects {
  const AppSoundEffects._();

  static void playTap() {
    unawaited(HapticFeedback.selectionClick());
    unawaited(SystemSound.play(SystemSoundType.click));
  }

  static void playReward() {
    unawaited(HapticFeedback.mediumImpact());
    unawaited(SystemSound.play(SystemSoundType.alert));
  }

  static void playMissionComplete() {
    unawaited(HapticFeedback.heavyImpact());
    unawaited(SystemSound.play(SystemSoundType.alert));
  }

  static void playRewardClaimed() {
    unawaited(HapticFeedback.mediumImpact());
    unawaited(SystemSound.play(SystemSoundType.click));
  }
}
