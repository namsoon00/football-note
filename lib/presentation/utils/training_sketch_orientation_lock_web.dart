import 'dart:js_interop';

import 'package:web/web.dart' as web;

const _orientationAttemptTimeout = Duration(milliseconds: 800);

Future<void> setTrainingSketchBrowserOrientation({
  required bool landscape,
}) async {
  if (landscape) {
    await _requestFullscreenForOrientationLock();
    await _lockLandscape();
    return;
  }

  _unlockOrientation();
  await _exitFullscreen();
}

Future<void> _requestFullscreenForOrientationLock() async {
  if (web.document.fullscreenElement != null) return;
  final root = web.document.documentElement;
  if (root == null) return;

  try {
    await root.requestFullscreen().toDart.timeout(_orientationAttemptTimeout);
  } catch (_) {
    // Browsers may reject fullscreen outside supported mobile contexts.
  }
}

Future<void> _lockLandscape() async {
  try {
    await web.window.screen.orientation
        .lock('landscape')
        .toDart
        .timeout(_orientationAttemptTimeout);
  } catch (_) {
    // Unsupported browsers keep the current viewport; the UI follows MediaQuery.
  }
}

void _unlockOrientation() {
  try {
    web.window.screen.orientation.unlock();
  } catch (_) {
    // Ignore unsupported orientation APIs.
  }
}

Future<void> _exitFullscreen() async {
  if (web.document.fullscreenElement == null) return;
  try {
    await web.document.exitFullscreen().toDart.timeout(
          _orientationAttemptTimeout,
        );
  } catch (_) {
    // Ignore browsers that reject exiting fullscreen from this context.
  }
}
