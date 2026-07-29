import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'running_coach_sample_video.dart';

Future<RunningCoachPreparedSampleVideo>
    prepareRunningCoachSampleVideoForAnalysis(String assetPath) async {
  final tempDirectory = await Directory.systemTemp.createTemp(
    'running_coach_sample_',
  );
  final bytes = await rootBundle.load(assetPath);
  final path = '${tempDirectory.path}/${assetPath.split('/').last}';
  final file = File(path);
  await file.writeAsBytes(
    bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    flush: true,
  );
  return RunningCoachPreparedSampleVideo(
    file: XFile(path, name: assetPath.split('/').last),
    dispose: () async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    },
  );
}
