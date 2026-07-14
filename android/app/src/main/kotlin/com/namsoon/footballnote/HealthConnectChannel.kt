package com.namsoon.footballnote

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.os.Handler
import android.os.Looper
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.ExerciseSegment
import androidx.health.connect.client.records.ExerciseSessionRecord
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.time.Duration
import java.time.Instant
import java.util.Locale
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class HealthConnectChannel(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, channelName)
    private val mainHandler = Handler(Looper.getMainLooper())
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val permissionContract =
        PermissionController.createRequestPermissionResultContract()
    private var pendingPermissionResult: MethodChannel.Result? = null

    init {
        channel.setMethodCallHandler(this)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        pendingPermissionResult = null
        scope.cancel()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getStatus" -> launchForResult(result) {
                statusMap()
            }
            "requestPermissions" -> requestPermissions(result)
            "readJumpRopeSessions" -> launchForResult(result) {
                readJumpRopeSessions(call)
            }
            else -> result.notImplemented()
        }
    }

    fun onActivityResult(requestCode: Int): Boolean {
        if (requestCode != permissionRequestCode) return false
        val result = pendingPermissionResult ?: return true
        pendingPermissionResult = null
        scope.launch {
            val granted = runCatching { hasAllPermissions() }.getOrDefault(false)
            mainHandler.post { result.success(granted) }
        }
        return true
    }

    private fun requestPermissions(result: MethodChannel.Result) {
        if (pendingPermissionResult != null) {
            result.error(
                "permission_request_in_progress",
                "A Health Connect permission request is already open.",
                null,
            )
            return
        }

        scope.launch {
            val sdkStatus = HealthConnectClient.getSdkStatus(activity)
            if (sdkStatus != HealthConnectClient.SDK_AVAILABLE) {
                mainHandler.post { result.success(false) }
                return@launch
            }
            if (hasAllPermissions()) {
                mainHandler.post { result.success(true) }
                return@launch
            }

            val intent = permissionContract.createIntent(activity, requiredPermissions)
            mainHandler.post {
                try {
                    pendingPermissionResult = result
                    activity.startActivityForResult(intent, permissionRequestCode)
                } catch (error: ActivityNotFoundException) {
                    pendingPermissionResult = null
                    result.error(
                        "permission_activity_missing",
                        error.message ?: "Health Connect permission screen is unavailable.",
                        null,
                    )
                }
            }
        }
    }

    private suspend fun statusMap(): Map<String, Any> {
        val sdkStatus = HealthConnectClient.getSdkStatus(activity)
        val availability = when (sdkStatus) {
            HealthConnectClient.SDK_AVAILABLE -> "available"
            HealthConnectClient.SDK_UNAVAILABLE_PROVIDER_UPDATE_REQUIRED -> "updateRequired"
            else -> "unavailable"
        }
        val permissionsGranted = sdkStatus == HealthConnectClient.SDK_AVAILABLE &&
            hasAllPermissions()
        return mapOf(
            "availability" to availability,
            "permissionsGranted" to permissionsGranted,
        )
    }

    private suspend fun hasAllPermissions(): Boolean {
        return HealthConnectClient.getOrCreate(activity)
            .permissionController
            .getGrantedPermissions()
            .containsAll(requiredPermissions)
    }

    private suspend fun readJumpRopeSessions(
        call: MethodCall,
    ): List<Map<String, Any>> {
        val sdkStatus = HealthConnectClient.getSdkStatus(activity)
        if (sdkStatus != HealthConnectClient.SDK_AVAILABLE) {
            throw HealthConnectChannelException(
                "health_connect_unavailable",
                "Health Connect is unavailable on this device.",
            )
        }
        if (!hasAllPermissions()) {
            throw HealthConnectChannelException(
                "health_connect_permission_denied",
                "Health Connect exercise permission is not granted.",
            )
        }

        val startMillis = call.argument<Number>("startEpochMillis")?.toLong()
            ?: throw HealthConnectChannelException(
                "missing_start",
                "Start time is missing.",
            )
        val endMillis = call.argument<Number>("endEpochMillis")?.toLong()
            ?: throw HealthConnectChannelException(
                "missing_end",
                "End time is missing.",
            )
        val client = HealthConnectClient.getOrCreate(activity)
        val records = mutableListOf<ExerciseSessionRecord>()
        var pageToken: String? = null
        do {
            val response = client.readRecords(
                ReadRecordsRequest(
                    recordType = ExerciseSessionRecord::class,
                    timeRangeFilter = TimeRangeFilter.between(
                        Instant.ofEpochMilli(startMillis),
                        Instant.ofEpochMilli(endMillis),
                    ),
                    ascendingOrder = true,
                    pageSize = 500,
                    pageToken = pageToken,
                ),
            )
            records.addAll(response.records)
            pageToken = response.pageToken?.takeIf { it.isNotBlank() }
        } while (pageToken != null)
        return records.mapNotNull(::jumpRopeSessionMap)
    }

    private fun jumpRopeSessionMap(
        record: ExerciseSessionRecord,
    ): Map<String, Any>? {
        val jumpSegments = record.segments.filter {
            it.segmentType == ExerciseSegment.EXERCISE_SEGMENT_TYPE_JUMP_ROPE
        }
        val matchedBySegment = jumpSegments.isNotEmpty()
        val matchedByText = containsJumpRopeKeyword(record.title) ||
            containsJumpRopeKeyword(record.notes)
        if (!matchedBySegment && !matchedByText) return null

        val sessionStartTime = if (matchedBySegment) {
            jumpSegments.minOf { it.startTime }
        } else {
            record.startTime
        }
        val sessionEndTime = if (matchedBySegment) {
            jumpSegments.maxOf { it.endTime }
        } else {
            record.endTime
        }
        val durationMillis = if (matchedBySegment) {
            jumpSegments.sumOf { segment ->
                Duration.between(segment.startTime, segment.endTime)
                    .toMillis()
                    .coerceAtLeast(0L)
            }
        } else {
            Duration.between(record.startTime, record.endTime)
                .toMillis()
                .coerceAtLeast(0L)
        }
        if (durationMillis <= 0L) return null

        val id = record.metadata.id.ifBlank {
            listOf(
                record.metadata.dataOrigin.packageName,
                record.startTime.toEpochMilli().toString(),
                record.endTime.toEpochMilli().toString(),
            ).joinToString(":")
        }
        return mapOf(
            "id" to id,
            "startEpochMillis" to sessionStartTime.toEpochMilli(),
            "endEpochMillis" to sessionEndTime.toEpochMilli(),
            "durationMillis" to durationMillis,
            "jumpCount" to jumpSegments.sumOf { it.repetitions },
            "title" to (record.title ?: ""),
            "sourcePackage" to record.metadata.dataOrigin.packageName,
            "matchedBySegment" to matchedBySegment,
        )
    }

    private fun containsJumpRopeKeyword(value: String?): Boolean {
        if (value.isNullOrBlank()) return false
        val compact = value
            .lowercase(Locale.US)
            .replace(Regex("[\\s_\\-]"), "")
        return compact.contains("jumprope") ||
            compact.contains("jumpingrope") ||
            compact.contains("skippingrope") ||
            compact.contains("skipping") ||
            compact.contains("줄넘기") ||
            compact.contains("縄跳び") ||
            compact.contains("なわとび") ||
            compact.contains("跳绳")
    }

    private fun launchForResult(
        result: MethodChannel.Result,
        block: suspend () -> Any,
    ) {
        scope.launch {
            try {
                val value = block()
                mainHandler.post { result.success(value) }
            } catch (error: HealthConnectChannelException) {
                mainHandler.post { result.error(error.code, error.message, null) }
            } catch (error: Exception) {
                mainHandler.post {
                    result.error(
                        "health_connect_failed",
                        error.message ?: "Health Connect operation failed.",
                        null,
                    )
                }
            }
        }
    }

    private class HealthConnectChannelException(
        val code: String,
        override val message: String,
    ) : Exception(message)

    companion object {
        private const val channelName = "com.namsoon.footballnote/health_connect"
        private const val permissionRequestCode = 38012
        private val requiredPermissions = setOf(
            HealthPermission.getReadPermission(ExerciseSessionRecord::class),
        )
    }
}
