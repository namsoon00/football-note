import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/running_video_analysis_service.dart';

void main() {
  test('web analysis budget is independent and browser-memory bounded', () {
    expect(
      RunningVideoAnalysisService.webMaxVideoBytes,
      96 * 1024 * 1024,
    );
    expect(
      RunningVideoAnalysisService.webMaxVideoBytes,
      lessThan(RunningVideoAnalysisService.mobileMaxVideoBytes),
    );
  });

  test('only browser Blob URLs qualify for zero-copy URL reuse', () {
    expect(
      RunningVideoAnalysisService.isReusableBrowserVideoUrl(
        'blob:https://example.test/clip-id',
      ),
      isTrue,
    );
    expect(
      RunningVideoAnalysisService.isReusableBrowserVideoUrl(
        'https://example.test/clip.mp4',
      ),
      isFalse,
    );
    expect(
      RunningVideoAnalysisService.isReusableBrowserVideoUrl('/tmp/clip.mp4'),
      isFalse,
    );
  });
}
