import 'package:image_picker/image_picker.dart';

class RunningCoachPreparedSampleVideo {
  final XFile file;
  final Future<void> Function() dispose;

  const RunningCoachPreparedSampleVideo({
    required this.file,
    required this.dispose,
  });
}

typedef RunningCoachSampleVideoPreparer
    = Future<RunningCoachPreparedSampleVideo> Function(String assetPath);
