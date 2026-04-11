package com.namsoon.footballnote

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    private var runningPoseAnalysisChannel: RunningPoseAnalysisChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        if (runningPoseAnalysisChannel == null) {
            runningPoseAnalysisChannel = RunningPoseAnalysisChannel(
                flutterEngine.dartExecutor.binaryMessenger,
            )
        }
    }

    override fun onDestroy() {
        runningPoseAnalysisChannel?.dispose()
        runningPoseAnalysisChannel = null
        super.onDestroy()
    }
}
