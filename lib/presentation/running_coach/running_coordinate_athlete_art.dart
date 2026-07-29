import 'dart:ui' as ui;

import 'package:flutter/services.dart';

const runningCoordinateAthleteArtAsset =
    'assets/images/running_guides/running_coordinate_athlete_v1.png';

Future<ui.Image>? _runningCoordinateAthleteArtFuture;

/// Loads the neutral athlete used beneath measured coordinate traces.
///
/// The artwork is only an instructional visual layer. The colored traces in
/// the comparison remain anchored to the pose coordinates measured from the
/// user's video.
Future<ui.Image> loadRunningCoordinateAthleteArt() {
  return _runningCoordinateAthleteArtFuture ??=
      _loadRunningCoordinateAthleteArt();
}

Future<ui.Image> _loadRunningCoordinateAthleteArt() async {
  final data = await rootBundle.load(runningCoordinateAthleteArtAsset);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  try {
    final frame = await codec.getNextFrame();
    return frame.image;
  } finally {
    codec.dispose();
  }
}
