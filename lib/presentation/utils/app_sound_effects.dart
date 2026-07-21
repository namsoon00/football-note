import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class AppSoundEffects {
  const AppSoundEffects._();

  static bool _enabled = true;
  static final AudioPlayer _tapPlayer = _buildPlayer('app-sfx-tap');
  static final AudioPlayer _rewardPlayer = _buildPlayer('app-sfx-reward');
  static final AudioPlayer _missionCompletePlayer =
      _buildPlayer('app-sfx-mission-complete');
  static final AudioPlayer _rewardClaimedPlayer =
      _buildPlayer('app-sfx-reward-claimed');
  static final AudioPlayer _sketchMovePlayer =
      _buildPlayer('app-sfx-sketch-move');

  static void setEnabled(bool enabled) {
    _enabled = enabled;
    if (!enabled) {
      unawaited(_stopAll());
    }
  }

  static void playTap() {
    unawaited(HapticFeedback.selectionClick());
    unawaited(_play(_tapPlayer, 'sounds/tap.wav', volume: 0.48));
  }

  static void playReward() {
    unawaited(HapticFeedback.mediumImpact());
    unawaited(_play(_rewardPlayer, 'sounds/reward.wav', volume: 0.64));
  }

  static void playMissionComplete() {
    unawaited(HapticFeedback.heavyImpact());
    unawaited(
      _play(
        _missionCompletePlayer,
        'sounds/mission_complete.wav',
        volume: 0.72,
      ),
    );
  }

  static void playRewardClaimed() {
    unawaited(HapticFeedback.mediumImpact());
    unawaited(
      _play(
        _rewardClaimedPlayer,
        'sounds/reward_claimed.wav',
        volume: 0.58,
      ),
    );
  }

  static void playSketchMove() {
    unawaited(HapticFeedback.lightImpact());
    unawaited(_play(_sketchMovePlayer, 'sounds/tap.wav', volume: 0.36));
  }

  static AudioPlayer _buildPlayer(String id) {
    final player = AudioPlayer(playerId: id);
    unawaited(player.setPlayerMode(PlayerMode.lowLatency));
    unawaited(player.setReleaseMode(ReleaseMode.stop));
    return player;
  }

  static Future<void> _play(
    AudioPlayer player,
    String assetPath, {
    required double volume,
  }) async {
    if (!_enabled) return;
    try {
      await player.stop();
      if (!_enabled) return;
      await player.play(AssetSource(assetPath), volume: volume);
    } catch (_) {
      // Sound effects should never block the primary reward or mission flow.
    }
  }

  static Future<void> _stopAll() async {
    try {
      await Future.wait<void>([
        _tapPlayer.stop(),
        _rewardPlayer.stop(),
        _missionCompletePlayer.stop(),
        _rewardClaimedPlayer.stop(),
        _sketchMovePlayer.stop(),
      ]);
    } catch (_) {
      // Stopping effects should not affect a settings change.
    }
  }
}
