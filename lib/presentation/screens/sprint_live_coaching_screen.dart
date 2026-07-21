import 'package:flutter/material.dart';

import 'running_live_coach_screen.dart';

/// Compatibility entry point for callers that still reference the former
/// sprint-only screen. The live session is now unified in one coach.
@Deprecated('Use RunningLiveCoachScreen for live sprint coaching.')
class SprintLiveCoachingScreen extends StatelessWidget {
  const SprintLiveCoachingScreen({super.key});

  @override
  Widget build(BuildContext context) => const RunningLiveCoachScreen();
}
