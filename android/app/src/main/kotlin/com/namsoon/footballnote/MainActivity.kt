package com.namsoon.footballnote

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    private var runningPoseAnalysisChannel: RunningPoseAnalysisChannel? = null
    private var healthConnectChannel: HealthConnectChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        if (runningPoseAnalysisChannel == null) {
            runningPoseAnalysisChannel = RunningPoseAnalysisChannel(
                this,
                flutterEngine.dartExecutor.binaryMessenger,
            )
        }
        if (healthConnectChannel == null) {
            healthConnectChannel = HealthConnectChannel(
                this,
                flutterEngine.dartExecutor.binaryMessenger,
            )
        }
        healthConnectChannel?.handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        healthConnectChannel?.handleIntent(intent)
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
