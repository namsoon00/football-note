package com.namsoon.footballnote

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    private var runningPoseAnalysisChannel: RunningPoseAnalysisChannel? = null
    private var healthConnectChannel: HealthConnectChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        if (runningPoseAnalysisChannel == null) {
            runningPoseAnalysisChannel = RunningPoseAnalysisChannel(
                flutterEngine.dartExecutor.binaryMessenger,
            )
        }
        if (healthConnectChannel == null) {
            healthConnectChannel = HealthConnectChannel(
                this,
                flutterEngine.dartExecutor.binaryMessenger,
            )
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: android.content.Intent?) {
        if (healthConnectChannel?.onActivityResult(requestCode) == true) {
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onDestroy() {
        healthConnectChannel?.dispose()
        healthConnectChannel = null
        runningPoseAnalysisChannel?.dispose()
        runningPoseAnalysisChannel = null
        super.onDestroy()
    }
}
