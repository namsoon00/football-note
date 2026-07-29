import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'running_coach_sample_video.dart';

Future<RunningCoachPreparedSampleVideo>
    prepareRunningCoachSampleVideoForAnalysis(String assetPath) async {
  final bytes = await rootBundle.load(assetPath);
  final name = assetPath.split('/').last;
  return RunningCoachPreparedSampleVideo(
    file: XFile.fromData(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      mimeType: 'video/mp4',
      name: name,
    ),
    dispose: () async {},
  );
}
