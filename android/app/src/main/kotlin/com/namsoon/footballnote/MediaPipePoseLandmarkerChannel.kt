package com.namsoon.footballnote

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageFormat
import android.graphics.Matrix
import android.graphics.Rect
import android.graphics.YuvImage
import android.os.Handler
import android.os.Looper
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.Optional
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import kotlin.math.max
import kotlin.math.roundToInt

class MediaPipePoseLandmarkerChannel(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, channelName)
    private val executor: ExecutorService = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var poseLandmarker: PoseLandmarker? = null
    private var lastTimestampMs = 0L

    init {
        channel.setMethodCallHandler(this)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        executor.execute {
            poseLandmarker?.close()
            poseLandmarker = null
        }
        executor.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            detectMethodName -> detectPoseFromNv21(call, result)
            closeMethodName -> closeLandmarker(result)
            else -> result.notImplemented()
        }
    }

    private fun detectPoseFromNv21(call: MethodCall, result: MethodChannel.Result) {
        val bytes = call.argument<ByteArray>("bytes")
        val width = call.argument<Int>("width") ?: 0
        val height = call.argument<Int>("height") ?: 0
        val rotationDegrees = call.argument<Int>("rotationDegrees") ?: 0
        val timestampMs = call.argument<Number>("timestampMs")?.toLong() ?: 0L

        if (bytes == null || width <= 0 || height <= 0) {
            result.error(
                "invalid_frame",
                "MediaPipe pose detection requires NV21 bytes with width and height.",
                null,
            )
            return
        }

        executor.execute {
            try {
                val detection = detectPose(
                    bytes = bytes,
                    width = width,
                    height = height,
                    rotationDegrees = rotationDegrees,
                    timestampMs = timestampMs,
                )
                mainHandler.post { result.success(detection) }
            } catch (error: Exception) {
                mainHandler.post {
                    result.error(
                        "mediapipe_pose_failed",
                        error.message ?: "MediaPipe pose detection failed.",
                        null,
                    )
                }
            }
        }
    }

    private fun closeLandmarker(result: MethodChannel.Result) {
        executor.execute {
            poseLandmarker?.close()
            poseLandmarker = null
            mainHandler.post { result.success(null) }
        }
    }

    private fun detectPose(
        bytes: ByteArray,
        width: Int,
        height: Int,
        rotationDegrees: Int,
        timestampMs: Long,
    ): Map<String, Any?> {
        val sourceBitmap = nv21ToBitmap(bytes, width, height)
        val rotatedBitmap = rotateBitmap(sourceBitmap, rotationDegrees)
        if (rotatedBitmap !== sourceBitmap) {
            sourceBitmap.recycle()
        }
        val bitmap = resizeBitmapIfNeeded(rotatedBitmap)
        if (bitmap !== rotatedBitmap) {
            rotatedBitmap.recycle()
        }

        try {
            val mpImage = BitmapImageBuilder(bitmap).build()
            val safeTimestampMs = nextTimestamp(timestampMs)
            val result = landmarker().detectForVideo(mpImage, safeTimestampMs)
            val landmarks = result.landmarks().firstOrNull().orEmpty()
            val worldLandmarks = result.worldLandmarks().firstOrNull().orEmpty()
            val encodedLandmarks = landmarks.mapIndexed { index, landmark ->
                val world = worldLandmarks.getOrNull(index)
                mapOf(
                    "index" to index,
                    "x" to (landmark.x() * bitmap.width),
                    "y" to (landmark.y() * bitmap.height),
                    "z" to landmark.z(),
                    "visibility" to optionalFloat(landmark.visibility()),
                    "presence" to optionalFloat(landmark.presence()),
                    "worldX" to world?.x(),
                    "worldY" to world?.y(),
                    "worldZ" to world?.z(),
                    "worldVisibility" to world?.visibility()?.let(::optionalFloat),
                )
            }
            return mapOf(
                "imageWidth" to bitmap.width,
                "imageHeight" to bitmap.height,
                "landmarks" to encodedLandmarks,
            )
        } finally {
            bitmap.recycle()
        }
    }

    private fun landmarker(): PoseLandmarker {
        poseLandmarker?.let { return it }

        val baseOptions = BaseOptions.builder()
            .setModelAssetPath(modelAssetPath)
            .build()
        val options = PoseLandmarker.PoseLandmarkerOptions.builder()
            .setBaseOptions(baseOptions)
            .setRunningMode(RunningMode.VIDEO)
            .setNumPoses(1)
            .setMinPoseDetectionConfidence(minimumPoseDetectionConfidence)
            .setMinPosePresenceConfidence(minimumPosePresenceConfidence)
            .setMinTrackingConfidence(minimumTrackingConfidence)
            .build()
        return PoseLandmarker.createFromOptions(context, options).also {
            poseLandmarker = it
        }
    }

    private fun nextTimestamp(timestampMs: Long): Long {
        val safeTimestampMs = max(timestampMs, lastTimestampMs + 1)
        lastTimestampMs = safeTimestampMs
        return safeTimestampMs
    }

    private fun nv21ToBitmap(bytes: ByteArray, width: Int, height: Int): Bitmap {
        val image = YuvImage(bytes, ImageFormat.NV21, width, height, null)
        val output = ByteArrayOutputStream()
        image.compressToJpeg(Rect(0, 0, width, height), jpegQuality, output)
        val jpegBytes = output.toByteArray()
        return BitmapFactory.decodeByteArray(jpegBytes, 0, jpegBytes.size)
            ?: throw IllegalArgumentException("Could not decode the camera frame.")
    }

    private fun rotateBitmap(source: Bitmap, rotationDegrees: Int): Bitmap {
        val normalizedRotation = ((rotationDegrees % 360) + 360) % 360
        if (normalizedRotation == 0) {
            return source
        }

        val matrix = Matrix().apply {
            postRotate(normalizedRotation.toFloat())
        }
        return Bitmap.createBitmap(source, 0, 0, source.width, source.height, matrix, true)
    }

    private fun resizeBitmapIfNeeded(source: Bitmap): Bitmap {
        val longEdge = max(source.width, source.height)
        if (longEdge <= maxAnalysisLongEdgePx) {
            return source
        }

        val scale = maxAnalysisLongEdgePx.toFloat() / longEdge.toFloat()
        val targetWidth = max(1, (source.width * scale).roundToInt())
        val targetHeight = max(1, (source.height * scale).roundToInt())
        return Bitmap.createScaledBitmap(source, targetWidth, targetHeight, true)
    }

    private fun optionalFloat(value: Optional<Float>): Float? =
        if (value.isPresent) value.get() else null

    companion object {
        private const val channelName = "football_note/mediapipe_pose_landmarker"
        private const val detectMethodName = "detectPoseFromNv21"
        private const val closeMethodName = "close"
        private const val modelAssetPath = "pose_landmarker_lite.task"
        private const val minimumPoseDetectionConfidence = 0.45f
        private const val minimumPosePresenceConfidence = 0.45f
        private const val minimumTrackingConfidence = 0.45f
        private const val jpegQuality = 95
        private const val maxAnalysisLongEdgePx = 720
    }
}
