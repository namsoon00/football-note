package com.namsoon.footballnote

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.changes.DeletionChange
import androidx.health.connect.client.changes.UpsertionChange
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.ExerciseSegment
import androidx.health.connect.client.records.ExerciseSessionRecord
import androidx.health.connect.client.records.metadata.DataOrigin
import androidx.health.connect.client.request.ChangesTokenRequest
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.time.Duration
import java.time.Instant
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
    private var pendingLaunchPayload: String? = null

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
            "createChangesToken" -> launchForResult(result) {
                createChangesToken()
            }
            "readChanges" -> launchForResult(result) {
                readChanges(call)
            }
            "openManageAccess" -> openManageAccess(result)
            "consumeLaunchPayload" -> {
                val payload = pendingLaunchPayload
                pendingLaunchPayload = null
                result.success(payload)
            }
            else -> result.notImplemented()
        }
    }

    fun handleIntent(intent: Intent?) {
        val action = intent?.action ?: return
        if (action == actionShowPermissionsRationale ||
            action == Intent.ACTION_VIEW_PERMISSION_USAGE
        ) {
            pendingLaunchPayload = privacyLaunchPayload
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
        ensureAvailableAndPermission()

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
                    dataOriginFilter = samsungHealthOrigins,
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

    private suspend fun createChangesToken(): String {
        ensureAvailableAndPermission()
        return HealthConnectClient.getOrCreate(activity).getChangesToken(
            ChangesTokenRequest(
                recordTypes = setOf(ExerciseSessionRecord::class),
                dataOriginFilters = samsungHealthOrigins,
            ),
        )
    }

    private suspend fun readChanges(call: MethodCall): Map<String, Any> {
        ensureAvailableAndPermission()
        var token = call.argument<String>("token")?.trim().orEmpty()
        if (token.isEmpty()) {
            throw HealthConnectChannelException(
                "missing_changes_token",
                "Health Connect changes token is missing.",
            )
        }

        val client = HealthConnectClient.getOrCreate(activity)
        val upserted = linkedMapOf<String, Map<String, Any>>()
        val removedIds = linkedSetOf<String>()
        var scannedCount = 0
        var tokenExpired = false
        var hasMore: Boolean
        do {
            val response = client.getChanges(token)
            token = response.nextChangesToken
            hasMore = response.hasMore
            if (response.changesTokenExpired) {
                tokenExpired = true
                break
            }
            for (change in response.changes) {
                scannedCount += 1
                when (change) {
                    is UpsertionChange -> {
                        val record = change.record as? ExerciseSessionRecord
                            ?: continue
                        if (!HealthConnectJumpRopeClassifier.isSamsungHealthSource(
                                record.metadata.dataOrigin.packageName,
                            )
                        ) {
                            continue
                        }
                        val recordId = stableRecordId(record)
                        val mapped = jumpRopeSessionMap(record)
                        if (mapped == null) {
                            upserted.remove(recordId)
                            removedIds.add(recordId)
                        } else {
                            removedIds.remove(recordId)
                            upserted[recordId] = mapped
                        }
                    }
                    is DeletionChange -> {
                        upserted.remove(change.recordId)
                        removedIds.add(change.recordId)
                    }
                }
            }
        } while (hasMore)

        return mapOf(
            "changesTokenExpired" to tokenExpired,
            "nextChangesToken" to token,
            "upsertedSessions" to upserted.values.toList(),
            "removedRecordIds" to removedIds.toList(),
            "scannedCount" to scannedCount,
        )
    }

    private fun openManageAccess(result: MethodChannel.Result) {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            Intent(actionManageHealthPermissions).putExtra(
                Intent.EXTRA_PACKAGE_NAME,
                activity.packageName,
            )
        } else {
            Intent(HealthConnectClient.ACTION_HEALTH_CONNECT_SETTINGS)
        }
        try {
            activity.startActivity(intent)
            result.success(true)
        } catch (_: ActivityNotFoundException) {
            result.success(false)
        }
    }

    private suspend fun ensureAvailableAndPermission() {
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
    }

    private fun jumpRopeSessionMap(
        record: ExerciseSessionRecord,
    ): Map<String, Any>? {
        if (!HealthConnectJumpRopeClassifier.isSamsungHealthSource(
                record.metadata.dataOrigin.packageName,
            )
        ) {
            return null
        }
        val jumpSegments = record.segments.filter {
            it.segmentType == ExerciseSegment.EXERCISE_SEGMENT_TYPE_JUMP_ROPE
        }
        val matchedBySegment = jumpSegments.isNotEmpty()
        val matchedByText = HealthConnectJumpRopeClassifier
            .containsJumpRopeKeyword(record.title) ||
            HealthConnectJumpRopeClassifier.containsJumpRopeKeyword(record.notes)
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

        val id = stableRecordId(record)
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

    private fun stableRecordId(record: ExerciseSessionRecord): String {
        return record.metadata.id.ifBlank {
            listOf(
                record.metadata.dataOrigin.packageName,
                record.startTime.toEpochMilli().toString(),
                record.endTime.toEpochMilli().toString(),
            ).joinToString(":")
        }
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
        private const val actionShowPermissionsRationale =
            "androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE"
        private const val actionManageHealthPermissions =
            "android.health.connect.action.MANAGE_HEALTH_PERMISSIONS"
        private const val privacyLaunchPayload =
            "taeonote://settings/health-connect-privacy"
        private val samsungHealthOrigins = setOf(
            DataOrigin(HealthConnectJumpRopeClassifier.samsungHealthPackageName),
        )
        private val requiredPermissions = setOf(
            HealthPermission.getReadPermission(ExerciseSessionRecord::class),
        )
    }
}
