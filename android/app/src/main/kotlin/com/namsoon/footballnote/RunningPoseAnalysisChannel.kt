package com.namsoon.footballnote

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageFormat
import android.graphics.Matrix
import android.graphics.PointF
import android.graphics.Rect
import android.graphics.YuvImage
import android.media.MediaMetadataRetriever
import android.os.Handler
import android.os.Looper
import com.google.mediapipe.tasks.components.containers.Landmark
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.components.containers.NormalizedLandmark
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import java.io.ByteArrayOutputStream
import java.util.Optional
import java.util.TreeMap
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import kotlin.math.abs
import kotlin.math.atan2
import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.math.roundToLong

class RunningPoseAnalysisChannel(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, channelName)
    private val executor: ExecutorService = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    init {
        channel.setMethodCallHandler(this)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        executor.shutdownNow()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            methodName -> executor.execute {
                val path = call.argument<String>("path")
                if (path.isNullOrBlank()) {
                    mainHandler.post {
                        result.error("missing_file", "Video file is missing.", null)
                    }
                    return@execute
                }
                try {
                    val analysis = analyzeVideo(path)
                    mainHandler.post { result.success(analysis) }
                } catch (error: AnalysisException) {
                    mainHandler.post { result.error(error.code, error.message, null) }
                } catch (error: Exception) {
                    mainHandler.post {
                        result.error(
                            "analysis_failed",
                            error.message ?: "Running video analysis failed.",
                            null,
                        )
                    }
                }
            }
            previewPoseMethodName -> executor.execute {
                val path = call.argument<String>("path")
                if (path.isNullOrBlank()) {
                    mainHandler.post {
                        result.error("missing_file", "Video file is missing.", null)
                    }
                    return@execute
                }
                try {
                    val preview = analyzePreviewPose(path)
                    mainHandler.post { result.success(preview) }
                } catch (error: AnalysisException) {
                    mainHandler.post { result.error(error.code, error.message, null) }
                } catch (error: Exception) {
                    mainHandler.post {
                        result.error(
                            "preview_pose_failed",
                            error.message ?: "Running video preview pose analysis failed.",
                            null,
                        )
                    }
                }
            }
            evidenceFramesMethodName -> {
                val path = call.argument<String>("path")
                if (path.isNullOrBlank()) {
                    result.error("missing_file", "Video file is missing.", null)
                    return
                }
                val timestamps = call.argument<List<Any?>>("timestampsMs")
                    ?.mapNotNull { (it as? Number)?.toLong() }
                    ?.distinct()
                    ?.sorted()
                    ?: emptyList()
                val maximumDimension = (call.argument<Number>("maxDimension")?.toInt() ?: 640)
                    .coerceIn(160, 960)
                val jpegQuality = (call.argument<Number>("jpegQuality")?.toInt() ?: 72)
                    .coerceIn(45, 92)
                executor.execute {
                    try {
                        val frames = extractEvidenceFrames(
                            path,
                            timestamps,
                            maximumDimension,
                            jpegQuality,
                        )
                        mainHandler.post { result.success(frames) }
                    } catch (error: AnalysisException) {
                        mainHandler.post { result.error(error.code, error.message, null) }
                    } catch (error: Exception) {
                        mainHandler.post {
                            result.error(
                                "evidence_frame_failed",
                                error.message ?: "Could not extract video evidence frames.",
                                null,
                            )
                        }
                    }
                }
            }
            liveFrameMethodName -> executor.execute {
                try {
                    val frame = analyzeLiveFrame(call.arguments as? Map<*, *>)
                    mainHandler.post { result.success(frame) }
                } catch (error: AnalysisException) {
                    mainHandler.post { result.error(error.code, error.message, null) }
                } catch (error: Exception) {
                    mainHandler.post {
                        result.error(
                            "live_pose_failed",
                            error.message ?: "Could not analyze the live camera frame.",
                            null,
                        )
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun analyzePreviewPose(path: String): Map<String, Any?> {
        val file = File(path)
        if (!file.exists()) {
            throw AnalysisException("missing_file", "Video file is missing.")
        }

        val retriever = MediaMetadataRetriever()
        var poseLandmarker: PoseLandmarker? = null

        try {
            retriever.setDataSource(path)
            val durationMs = retriever
                .extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
                ?.toLongOrNull() ?: 0L
            if (durationMs < minVideoDurationMs) {
                throw AnalysisException(
                    "video_too_short",
                    "Please select a running clip that is at least 1.5 seconds long.",
                )
            }
            if (durationMs > maxDecodableVideoDurationMs) {
                throw AnalysisException(
                    "video_too_long",
                    "This video is longer than the bounded on-device decoding budget.",
                )
            }

            val previewTimestamps = previewPoseTimestamps(durationMs)
            val landmarker = makePoseLandmarker()
            poseLandmarker = landmarker
            val previewPass = runPosePass(
                poseLandmarker = landmarker,
                retriever = retriever,
                timestampsMs = previewTimestamps,
                collectSharpness = false,
            )
            if (previewPass.poseFrames.isEmpty()) {
                throw AnalysisException(
                    "preview_pose_unavailable",
                    "No readable pose frame was found for preview.",
                )
            }
            return mapOf(
                "durationMs" to durationMs.toInt(),
                "sampledFrames" to previewTimestamps.size,
                "validFrames" to previewPass.samples.size,
                "perspectiveQuality" to
                    perspectiveQualityPayload(previewPass.samples).toPayload(),
                "poseFrames" to previewPass.poseFrames,
            )
        } finally {
            retriever.release()
            poseLandmarker?.close()
        }
    }

    private fun analyzeLiveFrame(arguments: Map<*, *>?): Map<String, Any?>? {
        val args = arguments ?: throw AnalysisException(
            "live_pose_invalid_frame",
            "Live camera frame data is missing.",
        )
        val width = (args["width"] as? Number)?.toInt() ?: 0
        val height = (args["height"] as? Number)?.toInt() ?: 0
        val format = args["format"]?.toString() ?: ""
        val planes = args["planes"] as? List<*> ?: emptyList<Any>()
        val rotationDegrees = Math.floorMod(
            (args["rotationDegrees"] as? Number)?.toInt() ?: 0,
            360,
        )
        val isFrontCamera = args["isFrontCamera"] as? Boolean ?: false
        val maximumDimension = ((args["maxDimension"] as? Number)?.toInt() ?: 360)
            .coerceIn(160, 640)
        if (width <= 0 || height <= 0 || planes.isEmpty()) {
            throw AnalysisException(
                "live_pose_invalid_frame",
                "Live camera frame dimensions are invalid.",
            )
        }

        var sourceBitmap = bitmapFromLiveFrame(
            width = width,
            height = height,
            format = format,
            planes = planes,
        )
        sourceBitmap = normalizeLiveBitmap(
            source = sourceBitmap,
            rotationDegrees = rotationDegrees,
            mirror = isFrontCamera,
            maximumDimension = maximumDimension,
        )
        val poseLandmarker = makePoseLandmarker(RunningMode.IMAGE)
        try {
            val pose = try {
                poseLandmarker.detect(BitmapImageBuilder(sourceBitmap).build())
            } catch (error: Exception) {
                throw mediaPipeFailure(
                    error,
                    fallbackMessage = "MediaPipe pose inference failed.",
                )
            }
            return poseFrameFromResult(
                pose,
                timestampMs = 0L,
                imageWidth = sourceBitmap.width,
                imageHeight = sourceBitmap.height,
            )
        } finally {
            poseLandmarker.close()
            sourceBitmap.recycle()
        }
    }

    private fun bitmapFromLiveFrame(
        width: Int,
        height: Int,
        format: String,
        planes: List<*>,
    ): Bitmap {
        return when (format) {
            "yuv420" -> bitmapFromYuv420(width, height, planes)
            "nv21" -> bitmapFromNv21(width, height, planes)
            else -> throw AnalysisException(
                "live_pose_unsupported",
                "Live camera frame format is not supported: $format",
            )
        }
    }

    private fun bitmapFromNv21(width: Int, height: Int, planes: List<*>): Bitmap {
        val firstPlane = planes.firstOrNull() as? Map<*, *>
            ?: throw AnalysisException("live_pose_invalid_frame", "NV21 plane is missing.")
        val bytes = firstPlane["bytes"] as? ByteArray
            ?: throw AnalysisException("live_pose_invalid_frame", "NV21 bytes are missing.")
        return bitmapFromNv21Bytes(bytes, width, height)
    }

    private fun bitmapFromYuv420(width: Int, height: Int, planes: List<*>): Bitmap {
        if (planes.size < 3) {
            throw AnalysisException("live_pose_invalid_frame", "YUV planes are missing.")
        }
        val yPlane = planes[0] as? Map<*, *>
            ?: throw AnalysisException("live_pose_invalid_frame", "Y plane is missing.")
        val uPlane = planes[1] as? Map<*, *>
            ?: throw AnalysisException("live_pose_invalid_frame", "U plane is missing.")
        val vPlane = planes[2] as? Map<*, *>
            ?: throw AnalysisException("live_pose_invalid_frame", "V plane is missing.")
        val yBytes = yPlane["bytes"] as? ByteArray
            ?: throw AnalysisException("live_pose_invalid_frame", "Y bytes are missing.")
        val uBytes = uPlane["bytes"] as? ByteArray
            ?: throw AnalysisException("live_pose_invalid_frame", "U bytes are missing.")
        val vBytes = vPlane["bytes"] as? ByteArray
            ?: throw AnalysisException("live_pose_invalid_frame", "V bytes are missing.")
        val yRowStride = (yPlane["bytesPerRow"] as? Number)?.toInt() ?: width
        val uRowStride = (uPlane["bytesPerRow"] as? Number)?.toInt() ?: width / 2
        val vRowStride = (vPlane["bytesPerRow"] as? Number)?.toInt() ?: width / 2
        val uPixelStride = (uPlane["bytesPerPixel"] as? Number)?.toInt() ?: 1
        val vPixelStride = (vPlane["bytesPerPixel"] as? Number)?.toInt() ?: 1
        val ySize = width * height
        val nv21 = ByteArray(ySize + (width * height / 2))
        for (row in 0 until height) {
            val sourceOffset = row * yRowStride
            val destinationOffset = row * width
            System.arraycopy(yBytes, sourceOffset, nv21, destinationOffset, width)
        }
        var outputOffset = ySize
        for (row in 0 until height / 2) {
            val uRowOffset = row * uRowStride
            val vRowOffset = row * vRowStride
            for (column in 0 until width / 2) {
                nv21[outputOffset++] = vBytes[vRowOffset + column * vPixelStride]
                nv21[outputOffset++] = uBytes[uRowOffset + column * uPixelStride]
            }
        }
        return bitmapFromNv21Bytes(nv21, width, height)
    }

    private fun bitmapFromNv21Bytes(bytes: ByteArray, width: Int, height: Int): Bitmap {
        val jpeg = ByteArrayOutputStream()
        val image = YuvImage(bytes, ImageFormat.NV21, width, height, null)
        if (!image.compressToJpeg(Rect(0, 0, width, height), 72, jpeg)) {
            throw AnalysisException(
                "live_pose_invalid_frame",
                "Live camera frame could not be converted.",
            )
        }
        return BitmapFactory.decodeByteArray(jpeg.toByteArray(), 0, jpeg.size())
            ?: throw AnalysisException(
                "live_pose_invalid_frame",
                "Live camera JPEG could not be decoded.",
            )
    }

    private fun normalizeLiveBitmap(
        source: Bitmap,
        rotationDegrees: Int,
        mirror: Boolean,
        maximumDimension: Int,
    ): Bitmap {
        val matrix = Matrix()
        if (rotationDegrees != 0) {
            matrix.postRotate(rotationDegrees.toFloat())
        }
        if (mirror) {
            matrix.postScale(-1f, 1f)
        }
        val rotated = if (rotationDegrees != 0 || mirror) {
            Bitmap.createBitmap(source, 0, 0, source.width, source.height, matrix, true)
        } else {
            source
        }
        if (rotated !== source) {
            source.recycle()
        }
        val scaled = scaleBitmap(rotated, maximumDimension)
        if (scaled !== rotated) {
            rotated.recycle()
        }
        return scaled
    }

    private fun extractEvidenceFrames(
        path: String,
        timestampsMs: List<Long>,
        maximumDimension: Int,
        jpegQuality: Int = 72,
    ): List<Map<String, Any>> {
        val file = File(path)
        if (!file.exists()) {
            throw AnalysisException("missing_file", "Video file is missing.")
        }
        if (timestampsMs.isEmpty()) return emptyList()
        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(path)
            return timestampsMs.distinct().sorted().take(24).mapNotNull { timestampMs ->
                val source = retriever.getFrameAtTime(
                    timestampMs * 1000L,
                    MediaMetadataRetriever.OPTION_CLOSEST,
                ) ?: return@mapNotNull null
                val scaled = scaleBitmap(source, maximumDimension)
                if (scaled !== source) source.recycle()
                val bytes = ByteArrayOutputStream().use { output ->
                    scaled.compress(Bitmap.CompressFormat.JPEG, jpegQuality, output)
                    output.toByteArray()
                }
                val width = scaled.width
                val height = scaled.height
                scaled.recycle()
                if (bytes.isEmpty()) return@mapNotNull null
                mapOf(
                    "timestampMs" to timestampMs,
                    "bytes" to bytes,
                    "width" to width,
                    "height" to height,
                )
            }
        } finally {
            retriever.release()
        }
    }

    private fun scaleBitmap(source: Bitmap, maximumDimension: Int): Bitmap {
        val longestSide = max(source.width, source.height)
        if (longestSide <= maximumDimension || longestSide <= 0) return source
        val scale = maximumDimension.toDouble() / longestSide.toDouble()
        val width = max(1, (source.width * scale).roundToInt())
        val height = max(1, (source.height * scale).roundToInt())
        return Bitmap.createScaledBitmap(source, width, height, true)
    }

    private fun analyzeVideo(path: String): Map<String, Any?> {
        val file = File(path)
        if (!file.exists()) {
            throw AnalysisException("missing_file", "Video file is missing.")
        }

        val retriever = MediaMetadataRetriever()
        var coarsePoseLandmarker: PoseLandmarker? = null
        var recoveryPoseLandmarker: PoseLandmarker? = null
        var densePoseLandmarker: PoseLandmarker? = null

        try {
            retriever.setDataSource(path)
            val durationMs = retriever
                .extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
                ?.toLongOrNull() ?: 0L
            if (durationMs < minVideoDurationMs) {
                throw AnalysisException(
                    "video_too_short",
                    "Please select a running clip that is at least 1.5 seconds long.",
                )
            }
            if (durationMs > maxDecodableVideoDurationMs) {
                throw AnalysisException(
                    "video_too_long",
                    "This video is longer than the bounded on-device decoding budget.",
                )
            }

            val coarseLandmarker = makePoseLandmarker()
            coarsePoseLandmarker = coarseLandmarker
            val coarseFrameTimestamps = coarseSampleTimestamps(durationMs)
            val coarsePass = runPosePass(
                poseLandmarker = coarseLandmarker,
                retriever = retriever,
                timestampsMs = coarseFrameTimestamps,
                collectSharpness = true,
            )
            var frameSamples = coarsePass.samples

            if (frameSamples.size < 2) {
                throw AnalysisException(
                    "no_pose_detected",
                    "We could not detect a clear running pose in this video.",
                )
            }
            val hasUsableSharpness = hasSufficientSharpness(coarsePass.sharpnessValues)

            var recoveryFrameTimestamps = emptyList<Long>()
            var recoveryPass = PosePassResult(
                samples = emptyList(),
                poseFrames = emptyList(),
                sharpnessValues = emptyList(),
            )
            val preliminaryPerspective = perspectiveQualityPayload(frameSamples)
            val preliminaryCandidates = mergeContactCandidateSets(
                deriveContactCandidateWindows(frameSamples, durationMs),
                fallbackContactCandidateWindows(frameSamples, durationMs),
            )
            val needsRecovery = durationMs > maxVideoDurationMs ||
                preliminaryCandidates.windows.size < minimumValidatedContactFrames ||
                preliminaryPerspective.scaleDriftRatio > maximumScaleDriftRatio ||
                frameSamples.size.toDouble() / coarseFrameTimestamps.size.coerceAtLeast(1) < 0.45
            if (needsRecovery) {
                recoveryFrameTimestamps = recoverySampleTimestamps(frameSamples, durationMs)
                if (recoveryFrameTimestamps.isNotEmpty()) {
                    val recoveryLandmarker = makePoseLandmarker()
                    recoveryPoseLandmarker = recoveryLandmarker
                    recoveryPass = runPosePass(
                        poseLandmarker = recoveryLandmarker,
                        retriever = retriever,
                        timestampsMs = recoveryFrameTimestamps,
                        collectSharpness = false,
                    )
                    frameSamples = mergeFrameSamples(frameSamples, recoveryPass.samples)
                }
            }

            val perspectiveQuality = perspectiveQualityPayload(frameSamples)
            val direction = resolveDirection(frameSamples)
            val leanDegrees = frameSamples
                .map { it.forwardLeanDegrees(direction) }
                .average()
            val normalizedShoulderYs = frameSamples.map {
                it.shoulderCenter.y.toDouble() / it.bodyScale.coerceAtLeast(1.0)
            }
            val lowerBouncePosition = percentile(normalizedShoulderYs, 0.10)
            val upperBouncePosition = percentile(normalizedShoulderYs, 0.90)
            val bounceRatio = if (lowerBouncePosition == null || upperBouncePosition == null) {
                0.0
            } else {
                (upperBouncePosition - lowerBouncePosition).coerceAtLeast(0.0)
            }
            val detectedCandidateSet = deriveContactCandidateWindows(frameSamples, durationMs)
            val fallbackCandidateSet = fallbackContactCandidateWindows(frameSamples, durationMs)
            val candidateSet = mergeContactCandidateSets(
                detectedCandidateSet,
                fallbackCandidateSet,
            )
            val denseTimestamps = denseTimestampsForContactWindows(
                candidateSet.windows,
                durationMs,
            )
            val denseLandmarker = makePoseLandmarker()
            densePoseLandmarker = denseLandmarker
            val densePass = runPosePass(
                poseLandmarker = denseLandmarker,
                retriever = retriever,
                timestampsMs = denseTimestamps,
                collectSharpness = false,
            )
            val contactValidations = validateDenseContactFrames(
                samples = densePass.samples,
                windows = candidateSet.windows,
                groundLine = candidateSet.groundLine,
                direction = direction,
            )
            val contactFrames = contactValidations.mapNotNull { it.contact }
            val confirmedContactFrames = contactFrames.filterNot { it.isKinematicEstimate }
            val estimatedContactFrames = contactFrames.filter { it.isKinematicEstimate }
            val uniqueConfirmedContactFrameCount = confirmedContactFrames
                .map { it.timestampMs }
                .distinct()
                .size
            val usesKinematicContactEstimate = estimatedContactFrames.isNotEmpty()
            // A single verified contact remains an observed measurement, even
            // though it is still below the three-step coaching threshold.
            // Only fall back to a phase proxy when no continuous contact event
            // could be confirmed at all.
            val usesContactProxy = contactFrames.isEmpty()
            val hasCompleteContactSample =
                uniqueConfirmedContactFrameCount >= minimumValidatedContactFrames
            val denseContactProxyFrames = if (usesContactProxy) {
                contactProxyFrames(
                    samples = densePass.samples,
                    windows = candidateSet.windows,
                    direction = direction,
                    confidencePenalty = contactProxyConfidencePenalty,
                )
            } else {
                emptyList()
            }
            val usesCoarseContactProxy =
                usesContactProxy && denseContactProxyFrames.isEmpty()
            val contactProxySource = if (usesCoarseContactProxy) "coarse" else "dense"
            val metricContactFrames = when {
                !usesContactProxy -> contactFrames
                denseContactProxyFrames.isNotEmpty() -> denseContactProxyFrames
                else -> contactProxyFrames(
                    samples = frameSamples,
                    windows = candidateSet.windows,
                    direction = direction,
                    confidencePenalty = coarseContactProxyConfidencePenalty,
                )
            }
            val footStrikeRatio = metricContactFrames
                .takeIf { it.isNotEmpty() }
                ?.map { it.footStrikeRatio }
                ?.average()
            val kneeAngles = metricContactFrames.map { it.kneeAngleDegrees }
            val elbowAngles = frameSamples.mapNotNull { it.averageElbowAngleDegrees() }
            val stanceKneeAngle = kneeAngles.takeIf { it.isNotEmpty() }?.average()
            val elbowAngle = elbowAngles.takeIf { it.isNotEmpty() }?.average()
            val contactConfidence = metricContactFrames
                .takeIf { it.isNotEmpty() }
                ?.map { it.confidence }
                ?.average()
                ?.coerceIn(0.0, 1.0) ?: 0.0
            val contactQualityReason = when {
                usesContactProxy -> "contact_phase_proxy"
                usesKinematicContactEstimate -> "kinematic_contact_estimate"
                hasCompleteContactSample -> null
                else -> "limited_contact_samples"
            }
            val coreConfidence = frameSamples
                .map { it.coreLandmarkConfidence }
                .average()
            val armConfidenceValues = frameSamples
                .mapNotNull { it.armLandmarkConfidence() }
            val armConfidence = armConfidenceValues.average()
            val analyzedFrameTimestamps = (
                coarseFrameTimestamps + recoveryFrameTimestamps + denseTimestamps
            ).toSet()
            val validFrameTimestamps = (frameSamples + densePass.samples)
                .map { it.timestampMs }
                .toSet()
            val baseMetricQualities = mapOf(
                "posture" to metricQualityPayload(
                    if (hasUsableSharpness) coreConfidence else min(coreConfidence, 0.58),
                    frameSamples.size,
                    if (hasUsableSharpness) null else "low_sharpness",
                ),
                "bounce" to metricQualityPayload(
                    if (hasUsableSharpness) coreConfidence else min(coreConfidence, 0.58),
                    frameSamples.size,
                    if (hasUsableSharpness) null else "low_sharpness",
                ),
                "footStrike" to metricQualityPayload(
                    if (hasUsableSharpness) contactConfidence else min(contactConfidence, 0.58),
                    metricContactFrames.size,
                    if (metricContactFrames.isEmpty()) {
                        "coordinates_unavailable"
                    } else {
                        contactQualityReason ?: if (hasUsableSharpness) null else "low_sharpness"
                    },
                ),
                "kneeFlexion" to metricQualityPayload(
                    if (hasUsableSharpness) contactConfidence else min(contactConfidence, 0.58),
                    metricContactFrames.size,
                    if (metricContactFrames.isEmpty()) {
                        "coordinates_unavailable"
                    } else {
                        contactQualityReason ?: if (hasUsableSharpness) null else "low_sharpness"
                    },
                ),
                "armCarriage" to metricQualityPayload(
                    if (armConfidenceValues.isEmpty()) {
                        0.0
                    } else if (hasUsableSharpness) {
                        armConfidence
                    } else {
                        min(armConfidence, 0.58)
                    },
                    armConfidenceValues.size,
                    if (armConfidenceValues.isEmpty()) {
                        "coordinates_unavailable"
                    } else if (hasUsableSharpness) {
                        null
                    } else {
                        "low_sharpness"
                    },
                ),
            )

            return mapOf(
                "analysisVersion" to 2,
                "durationMs" to durationMs.toInt(),
                "sampledFrames" to analyzedFrameTimestamps.size,
                "validFrames" to validFrameTimestamps.size,
                "direction" to direction.token,
                "forwardLeanDegrees" to roundTo3(leanDegrees),
                "verticalBounceRatio" to roundTo3(bounceRatio.coerceAtLeast(0.0)),
                "footStrikeDistanceRatio" to footStrikeRatio?.let(::roundTo3),
                "stanceKneeAngleDegrees" to stanceKneeAngle?.let(::roundTo3),
                "elbowAngleDegrees" to elbowAngle?.let(::roundTo3),
                "metricQualities" to mapOf(
                    "posture" to applyPerspectiveQuality(
                        "posture",
                        baseMetricQualities.getValue("posture"),
                        perspectiveQuality,
                    ),
                    "bounce" to applyPerspectiveQuality(
                        "bounce",
                        baseMetricQualities.getValue("bounce"),
                        perspectiveQuality,
                    ),
                    "footStrike" to applyPerspectiveQuality(
                        "footStrike",
                        baseMetricQualities.getValue("footStrike"),
                        perspectiveQuality,
                    ),
                    "kneeFlexion" to applyPerspectiveQuality(
                        "kneeFlexion",
                        baseMetricQualities.getValue("kneeFlexion"),
                        perspectiveQuality,
                    ),
                    "armCarriage" to applyPerspectiveQuality(
                        "armCarriage",
                        baseMetricQualities.getValue("armCarriage"),
                        perspectiveQuality,
                    ),
                ),
                "coarseSamples" to sampleSummaryPayload(
                    attemptedFrames = coarseFrameTimestamps.size,
                    validFrames = coarsePass.samples.size,
                    poseFrameCount = coarsePass.poseFrames.size,
                    maxFrameBudget = maxCoarseFrameBudget,
                    targetFps = coarseTargetFps,
                ),
                "denseSamples" to sampleSummaryPayload(
                    attemptedFrames = denseTimestamps.size,
                    validFrames = densePass.samples.size,
                    poseFrameCount = densePass.poseFrames.size,
                    maxFrameBudget = maxDenseFrameBudget,
                    targetFps = denseTargetFps,
                ),
                "recoverySamples" to sampleSummaryPayload(
                    attemptedFrames = recoveryFrameTimestamps.size,
                    validFrames = recoveryPass.samples.size,
                    poseFrameCount = recoveryPass.poseFrames.size,
                    maxFrameBudget = maxRecoveryFrameBudget,
                    targetFps = recoveryTargetFps,
                ),
                "contactWindows" to contactWindowPayloads(
                    windows = candidateSet.windows,
                    denseTimestamps = denseTimestamps,
                    contactValidations = contactValidations,
                ),
                "validatedContactFrameTimestampsMs" to confirmedContactFrames
                    .map { it.timestampMs.toInt() }
                    .distinct()
                    .sorted(),
                "estimatedContactFrameTimestampsMs" to estimatedContactFrames
                    .map { it.timestampMs.toInt() }
                    .distinct()
                    .sorted(),
                "contactConfidence" to roundTo3(contactConfidence),
                "perspectiveQuality" to perspectiveQuality.toPayload(),
                "poseFrames" to mergePoseFrames(
                    mergePoseFrames(coarsePass.poseFrames, recoveryPass.poseFrames),
                    densePass.poseFrames,
                ),
            )
        } finally {
            retriever.release()
            coarsePoseLandmarker?.close()
            recoveryPoseLandmarker?.close()
            densePoseLandmarker?.close()
        }
    }

    private fun makePoseLandmarker(
        runningMode: RunningMode = RunningMode.VIDEO,
    ): PoseLandmarker {
        ensureModelAssetAvailable()

        val baseOptions = BaseOptions.builder()
            .setModelAssetPath(modelAssetPath)
            .build()
        val options = PoseLandmarker.PoseLandmarkerOptions.builder()
            .setBaseOptions(baseOptions)
            .setRunningMode(runningMode)
            .setNumPoses(1)
            .setMinPoseDetectionConfidence(minimumLikelihood)
            .setMinPosePresenceConfidence(minimumLikelihood)
            .setMinTrackingConfidence(minimumLikelihood)
            .build()

        return try {
            PoseLandmarker.createFromOptions(context, options)
        } catch (error: Exception) {
            throw mediaPipeFailure(
                error,
                fallbackMessage = "MediaPipe pose initialization failed.",
            )
        }
    }

    private fun ensureModelAssetAvailable() {
        try {
            context.assets.open(modelAssetPath).use { }
        } catch (error: IOException) {
            throw AnalysisException(
                "model_missing",
                "MediaPipe pose model is missing from the Android assets.",
            )
        }
    }

    private fun detectPose(
        poseLandmarker: PoseLandmarker,
        bitmap: Bitmap,
        timestampMs: Long,
    ): PoseLandmarkerResult {
        return try {
            val mpImage = BitmapImageBuilder(bitmap).build()
            poseLandmarker.detectForVideo(mpImage, timestampMs)
        } catch (error: Exception) {
            throw mediaPipeFailure(
                error,
                fallbackMessage = "MediaPipe pose inference failed.",
            )
        }
    }

    private fun mediaPipeFailure(error: Exception, fallbackMessage: String): AnalysisException =
        AnalysisException(
            "mediapipe_pose_failed",
            error.message ?: fallbackMessage,
        )

    private fun insufficientContactEvidence(detail: String? = null): AnalysisException =
        AnalysisException(
            "insufficient_contact_evidence",
            "We could not verify enough dense foot-contact frames in this video." +
                (detail?.let { " ($it)" } ?: ""),
        )

    private fun videoTooBlurry(): AnalysisException =
        AnalysisException(
            "video_too_blurry",
            "This video is too blurry for precise running coaching.",
        )

    private fun coarseSampleTimestamps(durationMs: Long): List<Long> {
        val requestedIntervalCount =
            ((durationMs + coarseFrameIntervalMs - 1L) / coarseFrameIntervalMs)
                .coerceAtLeast(1L)
        val intervalCount = requestedIntervalCount
            .coerceAtMost((maxCoarseFrameBudget - 1).toLong())
            .toInt()
        return (0..intervalCount).map { index ->
            ((durationMs.toDouble() * index) / intervalCount)
                .roundToLong()
                .coerceIn(0L, durationMs)
        }
    }

    private fun previewPoseTimestamps(durationMs: Long): List<Long> {
        val requestedIntervalCount =
            ((durationMs + previewPoseFrameIntervalMs - 1L) / previewPoseFrameIntervalMs)
                .coerceAtLeast(1L)
        val intervalCount = requestedIntervalCount
            .coerceAtMost((maxPreviewPoseFrameBudget - 1).toLong())
            .toInt()
        return (0..intervalCount).map { index ->
            ((durationMs.toDouble() * index) / intervalCount)
                .roundToLong()
                .coerceIn(0L, durationMs)
        }
    }

    private fun recoverySampleTimestamps(
        samples: List<FrameSample>,
        durationMs: Long,
    ): List<Long> {
        if (samples.isEmpty()) return emptyList()
        val maximumWindowMs = 8000L
        var selectedStartMs = (samples.first().timestampMs - maximumWindowMs / 2)
            .coerceIn(0L, max(0L, durationMs - maximumWindowMs))
        var selectedScore = -1.0
        for (center in samples) {
            val startMs = (center.timestampMs - maximumWindowMs / 2)
                .coerceIn(0L, max(0L, durationMs - maximumWindowMs))
            val endMs = min(durationMs, startMs + maximumWindowMs)
            val visible = samples.filter { it.timestampMs in startMs..endMs }
            val scales = visible.map { it.bodyScale }.filter { it > 0.0 }
            val lower = percentile(scales, 0.10) ?: 0.0
            val upper = percentile(scales, 0.90) ?: lower
            val driftPenalty = if (lower > 0) min(0.7, (upper - lower) / lower) else 0.7
            val confidence = if (visible.isEmpty()) {
                0.0
            } else {
                visible.map { it.coreLandmarkConfidence }.average()
            }
            val runningMotion = recoveryRunningMotionScore(visible)
            val score = visible.size * confidence *
                (0.20 + 0.80 * runningMotion) * (1 - driftPenalty)
            if (score > selectedScore || (score == selectedScore && startMs < selectedStartMs)) {
                selectedScore = score
                selectedStartMs = startMs
            }
        }
        val selectedEndMs = min(durationMs, selectedStartMs + maximumWindowMs)
        val intervalCount = max(
            1,
            min(
                maxRecoveryFrameBudget - 1,
                kotlin.math.ceil(
                    (selectedEndMs - selectedStartMs).toDouble() / recoveryFrameIntervalMs,
                ).toInt(),
            ),
        )
        return (0..intervalCount).map { index ->
            (selectedStartMs +
                ((selectedEndMs - selectedStartMs).toDouble() * index / intervalCount))
                .roundToLong()
                .coerceIn(0L, durationMs)
        }
    }

    private fun recoveryRunningMotionScore(samples: List<FrameSample>): Double {
        if (samples.size < 3) return 0.0
        var hipTravel = 0.0
        var ankleTravel = 0.0
        var kneeTravel = 0.0
        var transitions = 0
        for (index in 1 until samples.size) {
            val previous = samples[index - 1]
            val current = samples[index]
            if (current.timestampMs - previous.timestampMs > 400L) continue
            val scale = max(1.0, (previous.bodyScale + current.bodyScale) / 2)
            fun normalizedDistance(first: PointF?, second: PointF?): Double =
                if (first == null || second == null) 0.0 else
                    hypot(
                        (second.x - first.x).toDouble(),
                        (second.y - first.y).toDouble(),
                    ) / scale
            hipTravel += normalizedDistance(previous.hipCenter, current.hipCenter)
            ankleTravel += normalizedDistance(previous.leftAnkle, current.leftAnkle)
            ankleTravel += normalizedDistance(previous.rightAnkle, current.rightAnkle)
            kneeTravel += normalizedDistance(previous.leftKnee, current.leftKnee)
            kneeTravel += normalizedDistance(previous.rightKnee, current.rightKnee)
            transitions += 1
        }
        if (transitions == 0) return 0.0
        return (
            (hipTravel / transitions / 0.10) * 0.35 +
                (ankleTravel / transitions / 0.22) * 0.45 +
                (kneeTravel / transitions / 0.16) * 0.20
            ).coerceIn(0.0, 1.0)
    }

    private fun mergeFrameSamples(
        first: List<FrameSample>,
        second: List<FrameSample>,
    ): List<FrameSample> = (first + second)
        .groupBy { it.timestampMs }
        .map { (_, values) -> values.maxBy { it.coreLandmarkConfidence } }
        .sortedBy { it.timestampMs }

    private fun runPosePass(
        poseLandmarker: PoseLandmarker,
        retriever: MediaMetadataRetriever,
        timestampsMs: List<Long>,
        collectSharpness: Boolean,
    ): PosePassResult {
        val samples = mutableListOf<FrameSample>()
        val poseFrames = mutableListOf<Map<String, Any?>>()
        val sharpnessValues = mutableListOf<Double>()
        var lastAnalysisTimestampMs = -1L
        for (timestampMs in timestampsMs.distinct().sorted()) {
            val bitmap = retriever.getFrameAtTime(
                timestampMs * 1000L,
                MediaMetadataRetriever.OPTION_CLOSEST,
            ) ?: continue
            try {
                if (collectSharpness) {
                    frameSharpness(bitmap)?.let(sharpnessValues::add)
                }
                val analysisTimestampMs = max(timestampMs, lastAnalysisTimestampMs + 1)
                lastAnalysisTimestampMs = analysisTimestampMs
                val pose = detectPose(poseLandmarker, bitmap, analysisTimestampMs)
                poseFrameFromResult(
                    pose,
                    timestampMs = timestampMs,
                    imageWidth = bitmap.width,
                    imageHeight = bitmap.height,
                )?.let(poseFrames::add)
                extractFrameSample(
                    pose,
                    timestampMs = timestampMs,
                    imageWidth = bitmap.width,
                    imageHeight = bitmap.height,
                )?.let(samples::add)
            } finally {
                bitmap.recycle()
            }
        }
        return PosePassResult(
            samples = samples.toList(),
            poseFrames = poseFrames.toList(),
            sharpnessValues = sharpnessValues.toList(),
        )
    }

    private fun hasSufficientSharpness(values: List<Double>): Boolean {
        if (values.size < minimumSharpnessSampleCount) {
            return false
        }
        val medianSharpness = median(values) ?: return false
        return medianSharpness >= minimumMedianSharpness
    }

    private fun frameSharpness(bitmap: Bitmap): Double? {
        val cropLeft = (bitmap.width * sharpnessHorizontalInsetFraction).toInt()
        val cropRight = bitmap.width - cropLeft
        val cropTop = (bitmap.height * sharpnessTopFraction).toInt()
        val cropBottom = (bitmap.height * sharpnessBottomFraction).toInt()
        val cropWidth = cropRight - cropLeft
        val cropHeight = cropBottom - cropTop
        if (cropWidth < 3 || cropHeight < 3) {
            return null
        }

        val luminance = DoubleArray(sharpnessSampleWidth * sharpnessSampleHeight)
        for (y in 0 until sharpnessSampleHeight) {
            val sourceY = cropTop + (y * cropHeight / sharpnessSampleHeight)
            for (x in 0 until sharpnessSampleWidth) {
                val sourceX = cropLeft + (x * cropWidth / sharpnessSampleWidth)
                val color = bitmap.getPixel(sourceX, sourceY)
                val red = ((color shr 16) and 0xFF) / 255.0
                val green = ((color shr 8) and 0xFF) / 255.0
                val blue = (color and 0xFF) / 255.0
                luminance[(y * sharpnessSampleWidth) + x] =
                    (0.299 * red) + (0.587 * green) + (0.114 * blue)
            }
        }

        var sum = 0.0
        var squaredSum = 0.0
        var count = 0
        for (y in 1 until sharpnessSampleHeight - 1) {
            for (x in 1 until sharpnessSampleWidth - 1) {
                val index = (y * sharpnessSampleWidth) + x
                val laplacian =
                    (4.0 * luminance[index]) -
                        luminance[index - 1] -
                        luminance[index + 1] -
                        luminance[index - sharpnessSampleWidth] -
                        luminance[index + sharpnessSampleWidth]
                sum += laplacian
                squaredSum += laplacian * laplacian
                count += 1
            }
        }
        if (count == 0) {
            return null
        }
        val mean = sum / count.toDouble()
        return max(0.0, (squaredSum / count.toDouble()) - (mean * mean))
    }

    private fun median(values: List<Double>): Double? {
        if (values.isEmpty()) {
            return null
        }
        val sortedValues = values.sorted()
        val upperIndex = sortedValues.size / 2
        val lowerIndex = (sortedValues.size - 1) / 2
        return (sortedValues[lowerIndex] + sortedValues[upperIndex]) / 2.0
    }

    private fun percentile(values: List<Double>, fraction: Double): Double? {
        if (values.isEmpty()) {
            return null
        }
        val sortedValues = values.sorted()
        val index = ((sortedValues.size - 1) * fraction)
            .coerceIn(0.0, (sortedValues.size - 1).toDouble())
        val lowerIndex = kotlin.math.floor(index).toInt()
        val upperIndex = kotlin.math.ceil(index).toInt()
        if (lowerIndex == upperIndex) {
            return sortedValues[lowerIndex]
        }
        val weight = index - lowerIndex
        return sortedValues[lowerIndex] +
            ((sortedValues[upperIndex] - sortedValues[lowerIndex]) * weight)
    }

    private fun leastSquaresGroundLine(points: List<GroundPoint>): GroundLine {
        if (points.isEmpty()) {
            return GroundLine(slope = 0.0, intercept = 0.0)
        }
        val meanX = points.map { it.x }.average()
        val meanY = points.map { it.y }.average()
        val covariance = points.sumOf { point ->
            (point.x - meanX) * (point.y - meanY)
        }
        val variance = points.sumOf { point ->
            val delta = point.x - meanX
            delta * delta
        }
        val slope = if (variance <= 0.0001) 0.0 else covariance / variance
        return GroundLine(
            slope = slope,
            intercept = meanY - (slope * meanX),
        )
    }

    private fun groundLineForFootEvidence(
        observations: List<FootObservation>,
    ): GroundLine? {
        if (observations.isEmpty()) {
            return null
        }
        val points = observations.map { observation ->
            GroundPoint(
                x = observation.evidence.bottomPoint.x.toDouble(),
                y = observation.evidence.bottomPoint.y.toDouble(),
                bodyScale = observation.sample.bodyScale,
            )
        }
        val lowerEnvelopeCount = min(
            points.size,
            max(
                groundLineMinimumSamples,
                kotlin.math.ceil(points.size * groundLineSampleFraction).toInt(),
            ),
        )
        val lowerEnvelope = points
            .sortedByDescending { it.y }
            .take(lowerEnvelopeCount)
        var line = leastSquaresGroundLine(lowerEnvelope)
        val residuals = lowerEnvelope.map { point -> point.y - line.yAt(point.x) }
        val residualCenter = percentile(residuals, 0.5) ?: 0.0
        val medianDeviation = percentile(
            residuals.map { residual -> abs(residual - residualCenter) },
            0.5,
        ) ?: 0.0
        val averageScale = max(1.0, lowerEnvelope.map { it.bodyScale }.average())
        val residualTolerance = max(averageScale * 0.025, medianDeviation * 2.5)
        val inliers = lowerEnvelope.filter { point ->
            abs(point.y - line.yAt(point.x) - residualCenter) <= residualTolerance
        }
        if (inliers.size >= 2) {
            line = leastSquaresGroundLine(inliers)
        }
        return line
    }

    private fun groundGap(
        groundLine: GroundLine,
        evidence: FootBottomEvidence,
    ): Double = groundLine.yAt(evidence.bottomPoint.x.toDouble()) - evidence.bottomPoint.y.toDouble()

    private fun selectContactCandidateWindows(
        candidates: List<ContactCandidate>,
    ): List<ContactCandidate> {
        val deduped = mutableListOf<ContactCandidate>()
        val rankedCandidates = candidates.sortedWith(
            compareByDescending<ContactCandidate> { it.confidence }
                .thenBy { it.centerTimestampMs },
        )
        for (candidate in rankedCandidates) {
            val duplicatesSameStep = deduped.any { selectedCandidate ->
                selectedCandidate.side == candidate.side &&
                    abs(selectedCandidate.centerTimestampMs - candidate.centerTimestampMs) <
                    minimumContactCenterSeparationMs
            }
            if (!duplicatesSameStep) {
                deduped.add(candidate)
            }
        }
        if (deduped.size <= maxContactWindows) {
            return deduped.sortedBy { it.centerTimestampMs }
        }
        val ordered = deduped.sortedBy { it.centerTimestampMs }
        val firstTime = ordered.first().centerTimestampMs
        val lastTime = ordered.last().centerTimestampMs
        val selected = mutableListOf<ContactCandidate>()
        val selectedIndexes = mutableSetOf<Int>()
        for (slot in 0 until maxContactWindows) {
            val target = if (maxContactWindows <= 1) {
                (firstTime + lastTime) / 2.0
            } else {
                firstTime + ((lastTime - firstTime).toDouble() * slot) /
                    (maxContactWindows - 1).toDouble()
            }
            var bestIndex: Int? = null
            for (index in ordered.indices) {
                if (selectedIndexes.contains(index)) continue
                val currentBest = bestIndex
                if (currentBest == null) {
                    bestIndex = index
                    continue
                }
                val current = ordered[index]
                val best = ordered[currentBest]
                val distance = abs(current.centerTimestampMs.toDouble() - target)
                val bestDistance = abs(best.centerTimestampMs.toDouble() - target)
                if (distance < bestDistance ||
                    (distance == bestDistance && current.confidence > best.confidence) ||
                    (distance == bestDistance && current.confidence == best.confidence &&
                        current.centerTimestampMs < best.centerTimestampMs)
                ) {
                    bestIndex = index
                }
            }
            bestIndex?.let {
                selectedIndexes.add(it)
                selected.add(ordered[it])
            }
        }
        return selected.sortedBy { it.centerTimestampMs }
    }

    private fun deriveContactCandidateWindows(
        samples: List<FrameSample>,
        durationMs: Long,
    ): ContactCandidateSet {
        val footObservations = samples.flatMap { sample ->
            FootSide.values().mapNotNull { side ->
                sample.footBottom(side)?.let { evidence ->
                    FootObservation(sample = sample, side = side, evidence = evidence)
                }
            }
        }
        val groundLine = groundLineForFootEvidence(footObservations)
            ?: return ContactCandidateSet(
                windows = emptyList(),
                groundLine = GroundLine(slope = 0.0, intercept = 0.0),
            )
        val averageScale = samples.map { it.bodyScale }.average().coerceAtLeast(1.0)
        val groundTolerance = averageScale * coarseContactGroundToleranceRatio
        val localTolerance = averageScale * localFootExtremumToleranceRatio
        val candidates = mutableListOf<ContactCandidate>()

        for (side in FootSide.values()) {
            val sideEvidence = samples.mapNotNull { sample ->
                sample.footBottom(side)?.let { evidence -> sample to evidence }
            }
            for (index in sideEvidence.indices) {
                val (sample, evidence) = sideEvidence[index]
                val bottomY = evidence.bottomPoint.y.toDouble()
                val previousY =
                    sideEvidence.getOrNull(index - 1)?.second?.bottomPoint?.y?.toDouble()
                val nextY =
                    sideEvidence.getOrNull(index + 1)?.second?.bottomPoint?.y?.toDouble()
                val gap = groundGap(groundLine, evidence)
                val nearGround =
                    gap >= -groundTolerance * 0.55 && gap <= groundTolerance * 1.1
                val localExtremum =
                    (previousY == null || bottomY >= previousY - localTolerance) &&
                        (nextY == null || bottomY >= nextY - localTolerance)
                if (!nearGround || !localExtremum) {
                    continue
                }
                val proximityFactor = (
                    1.0 - (gap.coerceAtLeast(0.0) /
                        groundTolerance.coerceAtLeast(1.0))
                    ).coerceIn(0.0, 1.0)
                candidates.add(
                    ContactCandidate(
                        side = side,
                        centerTimestampMs = sample.timestampMs,
                        startTimestampMs = max(0L, sample.timestampMs - denseWindowRadiusMs),
                        endTimestampMs = min(durationMs, sample.timestampMs + denseWindowRadiusMs),
                        confidence = (evidence.confidence * proximityFactor)
                            .coerceIn(0.0, 1.0),
                    ),
                )
            }
        }

        return ContactCandidateSet(
            windows = selectContactCandidateWindows(candidates),
            groundLine = groundLine,
        )
    }

    private fun fallbackContactCandidateWindows(
        samples: List<FrameSample>,
        durationMs: Long,
    ): ContactCandidateSet {
        val footObservations = samples.flatMap { sample ->
            FootSide.values().mapNotNull { side ->
                sample.footBottom(side)?.let { evidence ->
                    FootObservation(sample = sample, side = side, evidence = evidence)
                }
            }
        }
        val groundLine = groundLineForFootEvidence(footObservations)
            ?: return ContactCandidateSet(
                windows = emptyList(),
                groundLine = GroundLine(slope = 0.0, intercept = 0.0),
            )
        val averageScale = samples.map { it.bodyScale }.average().coerceAtLeast(1.0)
        val localTolerance = averageScale * kinematicContactMotionToleranceRatio
        val candidates = mutableListOf<ContactCandidate>()
        for (side in FootSide.values()) {
            val sideEvidence = samples
                .mapNotNull { sample ->
                    sample.footBottom(side)?.let { evidence -> sample to evidence }
                }
                .sortedBy { it.first.timestampMs }
            val lowerEnvelopeY = percentile(
                sideEvidence.map { it.second.bottomPoint.y.toDouble() },
                kinematicContactLowerPercentile,
            ) ?: continue
            for (index in sideEvidence.indices) {
                val (sample, evidence) = sideEvidence[index]
                val currentY = evidence.bottomPoint.y.toDouble()
                val previous = sideEvidence.getOrNull(index - 1)
                val next = sideEvidence.getOrNull(index + 1)
                val closeToPrevious = previous != null &&
                    sample.timestampMs - previous.first.timestampMs <= coarseFrameIntervalMs * 2
                val closeToNext = next != null &&
                    next.first.timestampMs - sample.timestampMs <= coarseFrameIntervalMs * 2
                val locallyLow =
                    (!closeToPrevious ||
                        currentY >= previous!!.second.bottomPoint.y.toDouble() - localTolerance) &&
                        (!closeToNext ||
                            currentY >= next!!.second.bottomPoint.y.toDouble() - localTolerance)
                if (currentY < lowerEnvelopeY || !locallyLow) {
                    continue
                }
                candidates.add(
                    ContactCandidate(
                        side = side,
                        centerTimestampMs = sample.timestampMs,
                        startTimestampMs = max(0L, sample.timestampMs - denseWindowRadiusMs),
                        endTimestampMs = min(durationMs, sample.timestampMs + denseWindowRadiusMs),
                        confidence = evidence.confidence.coerceIn(0.0, 1.0),
                    ),
                )
            }
        }
        return ContactCandidateSet(
            windows = selectContactCandidateWindows(candidates),
            groundLine = groundLine,
        )
    }

    private fun mergeContactCandidateSets(
        detected: ContactCandidateSet,
        fallback: ContactCandidateSet,
    ): ContactCandidateSet = ContactCandidateSet(
        windows = selectContactCandidateWindows(detected.windows + fallback.windows),
        groundLine = if (detected.windows.isNotEmpty()) {
            detected.groundLine
        } else {
            fallback.groundLine
        },
    )

    private fun denseTimestampsForContactWindows(
        windows: List<ContactCandidate>,
        durationMs: Long,
    ): List<Long> {
        val selectedWindows = windows.take(maxContactWindows)
        if (selectedWindows.isEmpty()) {
            return emptyList()
        }
        // Reserve an even budget for every candidate window. A global sort by
        // distance to the coarse centres can starve the real contact near a
        // window edge when several steps overlap.
        val perWindowBudget = max(3, maxDenseFrameBudget / selectedWindows.size)
        val timestamps = mutableSetOf<Long>()
        for (window in selectedWindows) {
            val frameTimes = mutableListOf<Long>()
            var timestampMs = window.startTimestampMs
            while (timestampMs <= window.endTimestampMs) {
                frameTimes.add(timestampMs.coerceIn(0L, durationMs))
                timestampMs += denseFrameIntervalMs
            }
            if (frameTimes.isEmpty() || frameTimes.last() != window.endTimestampMs) {
                frameTimes.add(window.endTimestampMs.coerceIn(0L, durationMs))
            }
            val selected = linkedSetOf<Long>()
            val nearestToCenter = frameTimes.sortedWith(
                compareBy<Long> { abs(it - window.centerTimestampMs) }.thenBy { it },
            )
            selected.addAll(nearestToCenter.take(min(3, perWindowBudget)))
            val remaining = perWindowBudget - selected.size
            for (index in 0 until remaining) {
                val fraction = if (remaining <= 1) {
                    0.5
                } else {
                    index.toDouble() / (remaining - 1).toDouble()
                }
                val frameIndex = ((frameTimes.size - 1) * fraction).roundToInt()
                selected.add(frameTimes[frameIndex])
            }
            for (timestamp in nearestToCenter) {
                if (selected.size >= perWindowBudget) {
                    break
                }
                selected.add(timestamp)
            }
            timestamps.addAll(selected)
        }
        return timestamps.sorted().take(maxDenseFrameBudget)
    }

    private fun validateDenseContactFrames(
        samples: List<FrameSample>,
        windows: List<ContactCandidate>,
        groundLine: GroundLine,
        direction: AnalysisDirection,
    ): List<ContactWindowValidation> {
        val orderedSamples = samples.sortedBy { it.timestampMs }
        val validations = windows.sortedBy { it.centerTimestampMs }.map { window ->
            val selection = selectDenseContactFrame(
                window = window,
                orderedSamples = orderedSamples,
                groundLine = groundLine,
                direction = direction,
            )
            ContactWindowValidation(
                window = window,
                contact = selection.contact,
                candidateFrameCount = selection.candidateFrameCount,
                rejectedFrameCounts = selection.rejectedFrameCounts,
            )
        }
        val selectedIndexes = mutableListOf<Int>()
        val rankedIndexes = validations.indices
            .filter { validations[it].contact != null }
            .sortedWith(
                compareByDescending<Int> { validations[it].contact!!.confidence }
                    .thenBy { validations[it].contact!!.timestampMs },
            )
        for (index in rankedIndexes) {
            val timestampMs = validations[index].contact!!.timestampMs
            val isSameEvent = selectedIndexes.any { selectedIndex ->
                abs(validations[selectedIndex].contact!!.timestampMs - timestampMs) <
                    minimumDistinctContactSeparationMs
            }
            if (!isSameEvent) {
                selectedIndexes.add(index)
            }
        }
        val selectedIndexSet = selectedIndexes.toSet()
        return validations.mapIndexed { index, validation ->
            if (validation.contact == null || selectedIndexSet.contains(index)) {
                validation
            } else {
                validation.copy(contact = null)
            }
        }
    }

    private fun contactProxyFrames(
        samples: List<FrameSample>,
        windows: List<ContactCandidate>,
        direction: AnalysisDirection,
        confidencePenalty: Double,
    ): List<ContactFrameAnalysis> {
        val proxies = mutableListOf<ContactFrameAnalysis>()
        for (window in windows.sortedBy { it.centerTimestampMs }) {
            val candidate = samples
                .asSequence()
                .filter { sample ->
                    sample.timestampMs >= window.startTimestampMs &&
                        sample.timestampMs <= window.endTimestampMs
                }
                .flatMap { sample ->
                    FootSide.values().asSequence().mapNotNull { side ->
                        val evidence = sample.footBottom(side) ?: return@mapNotNull null
                        val confidence = sample.contactLandmarkConfidence(side, evidence)
                            ?: return@mapNotNull null
                        ContactProxyCandidate(sample, side, confidence)
                    }
                }
                .sortedWith(
                    compareBy<ContactProxyCandidate> {
                        abs(it.sample.timestampMs - window.centerTimestampMs)
                    }.thenByDescending { it.landmarkConfidence }
                        .thenBy { it.sample.timestampMs },
                )
                .firstOrNull() ?: continue
            val kneeAngleDegrees = candidate.sample.contactKneeAngleDegrees(candidate.side)
                ?: continue
            val confidence = (
                min(window.confidence, candidate.landmarkConfidence) *
                    confidencePenalty
                ).coerceIn(0.0, 1.0)
            val proxy = ContactFrameAnalysis(
                timestampMs = candidate.sample.timestampMs,
                windowCenterTimestampMs = window.centerTimestampMs,
                side = candidate.side,
                footStrikeRatio = candidate.sample.contactFootStrikeRatio(
                    candidate.side,
                    direction,
                ),
                kneeAngleDegrees = kneeAngleDegrees,
                confidence = confidence,
            )
            proxies.add(proxy)
        }
        val selected = mutableListOf<ContactFrameAnalysis>()
        for (proxy in proxies.sortedWith(
            compareByDescending<ContactFrameAnalysis> { it.confidence }
                .thenBy { it.timestampMs },
        )) {
            if (selected.any { existing ->
                abs(existing.timestampMs - proxy.timestampMs) <
                    minimumDistinctContactSeparationMs
            }) {
                continue
            }
            selected.add(proxy)
        }
        return selected.sortedBy { it.timestampMs }
    }

    private fun selectDenseContactFrame(
        window: ContactCandidate,
        orderedSamples: List<FrameSample>,
        groundLine: GroundLine,
        direction: AnalysisDirection,
    ): ContactFrameSelection {
        val alternateSide = if (window.side == FootSide.left) {
            FootSide.right
        } else {
            FootSide.left
        }
        val preferred = selectDenseContactFrameForSide(
            window = window,
            side = window.side,
            orderedSamples = orderedSamples,
            groundLine = groundLine,
            direction = direction,
        )
        val alternate = selectDenseContactFrameForSide(
            window = window,
            side = alternateSide,
            orderedSamples = orderedSamples,
            groundLine = groundLine,
            direction = direction,
        )
        val selectedContact = listOfNotNull(preferred.contact, alternate.contact)
            .maxByOrNull { contact ->
                val preferredBias = if (contact.side == window.side) 1.03 else 1.0
                contactSelectionScore(
                    contact.timestampMs,
                    contact.confidence,
                    window,
                ) * preferredBias
            }
        val rejectedFrameCounts = preferred.rejectedFrameCounts.toMutableMap()
        for ((reason, count) in alternate.rejectedFrameCounts) {
            rejectedFrameCounts[reason] = (rejectedFrameCounts[reason] ?: 0) + count
        }
        return ContactFrameSelection(
            contact = selectedContact,
            candidateFrameCount = max(
                preferred.candidateFrameCount,
                alternate.candidateFrameCount,
            ),
            rejectedFrameCounts = rejectedFrameCounts.toMap(),
        )
    }

    private fun contactSelectionScore(
        timestampMs: Long,
        confidence: Double,
        window: ContactCandidate,
    ): Double {
        val distanceRatio = (
            abs(timestampMs - window.centerTimestampMs).toDouble() /
                denseWindowRadiusMs.coerceAtLeast(1L).toDouble()
            ).coerceIn(0.0, 1.0)
        return confidence * (1.0 - (distanceRatio * 0.65))
    }

    private fun selectDenseContactFrameForSide(
        window: ContactCandidate,
        side: FootSide,
        orderedSamples: List<FrameSample>,
        groundLine: GroundLine,
        direction: AnalysisDirection,
    ): ContactFrameSelection {
        val rejectedFrameCounts = mutableMapOf<String, Int>()
        val candidates = orderedSamples
            .filter { sample ->
                sample.timestampMs >= window.startTimestampMs &&
                    sample.timestampMs <= window.endTimestampMs
            }
            .mapNotNull { sample ->
                val evidence = sample.footBottom(side)
                if (evidence == null) {
                    incrementContactRejection(rejectedFrameCounts, "missing_foot_landmark")
                    return@mapNotNull null
                }
                if (sample.contactLandmarkConfidence(side, evidence) == null) {
                    incrementContactRejection(rejectedFrameCounts, "missing_contact_joint_chain")
                    return@mapNotNull null
                }
                val candidate = denseContactCandidate(sample, side, groundLine)
                if (candidate == null) {
                    incrementContactRejection(rejectedFrameCounts, "missing_foot_landmark")
                }
                candidate
            }
        val temporalCandidates = mutableListOf<ContactFrameCandidate>()
        val persistentCandidates = mutableListOf<ContactFrameCandidate>()
        for (index in candidates.indices) {
            val current = candidates[index]
            if (!current.inGroundBand) {
                incrementContactRejection(rejectedFrameCounts, "outside_ground_band")
                continue
            }
            if (!current.isEligibleContact()) {
                incrementContactRejection(rejectedFrameCounts, "low_contact_confidence")
                continue
            }
            val previous = candidates.getOrNull(index - 1)
            val next = candidates.getOrNull(index + 1)
            if (!hasTemporalNeighbor(current, previous) &&
                !hasTemporalNeighbor(current, next)
            ) {
                incrementContactRejection(rejectedFrameCounts, "insufficient_motion_window")
                continue
            }
            if (!hasGroundBandPersistence(current, previous, next)) {
                incrementContactRejection(
                    rejectedFrameCounts,
                    "insufficient_contact_persistence",
                )
                continue
            }
            if (!isFootAtLocalBottom(current, previous, next)) {
                incrementContactRejection(rejectedFrameCounts, "unstable_foot_motion")
                continue
            }
            if (enteredGroundBand(current, previous)) {
                temporalCandidates.add(current)
            } else {
                persistentCandidates.add(current)
            }
        }
        // Never fall back to an isolated near-ground frame. It is retained as
        // an explicit phase proxy only, not promoted to initial contact.
        val candidatesForSelection = if (temporalCandidates.isNotEmpty()) {
            temporalCandidates
        } else {
            persistentCandidates
        }
        val selected = candidatesForSelection
            .sortedWith(
                compareByDescending<ContactFrameCandidate> {
                    contactSelectionScore(
                        it.sample.timestampMs,
                        it.confidence,
                        window,
                    )
                }
                    .thenByDescending { it.confidence }
                    .thenBy { abs(it.sample.timestampMs - window.centerTimestampMs) }
                    .thenBy { it.sample.timestampMs },
            )
            .firstOrNull()
        val kinematicLowerEnvelope = percentile(
            candidates.map { it.evidence.bottomPoint.y.toDouble() },
            kinematicContactLowerPercentile,
        )
        val kinematicCandidates = if (kinematicLowerEnvelope == null) {
            emptyList()
        } else {
            candidates.filterIndexed { index, _ ->
                isKinematicContactCandidate(
                    candidates = candidates,
                    index = index,
                    lowerEnvelopeY = kinematicLowerEnvelope,
                )
            }
        }
        val kinematicSelection = kinematicCandidates
            .sortedWith(
                compareByDescending<ContactFrameCandidate> {
                    contactSelectionScore(
                        it.sample.timestampMs,
                        it.confidence,
                        window,
                    )
                }
                    .thenByDescending { it.confidence }
                    .thenBy { abs(it.sample.timestampMs - window.centerTimestampMs) }
                    .thenBy { it.sample.timestampMs },
            )
            .firstOrNull()
        val strictContact = selected?.toContactFrame(
            window = window,
            direction = direction,
            isKinematicEstimate = false,
        )
        val kinematicContact = if (strictContact == null) {
            kinematicSelection?.toContactFrame(
                window = window,
                direction = direction,
                isKinematicEstimate = true,
                confidence = kinematicSelection.confidence * kinematicContactConfidencePenalty,
            )
        } else {
            null
        }
        return ContactFrameSelection(
            contact = strictContact ?: kinematicContact,
            candidateFrameCount = max(
                candidates.count { it.inGroundBand },
                kinematicCandidates.size,
            ),
            rejectedFrameCounts = rejectedFrameCounts.toMap(),
        )
    }

    private fun incrementContactRejection(
        rejectedFrameCounts: MutableMap<String, Int>,
        reason: String,
    ) {
        rejectedFrameCounts[reason] = (rejectedFrameCounts[reason] ?: 0) + 1
    }

    private fun hasTemporalNeighbor(
        current: ContactFrameCandidate,
        neighbor: ContactFrameCandidate?,
    ): Boolean =
        neighbor != null &&
            abs(neighbor.sample.timestampMs - current.sample.timestampMs) <=
                contactMotionNeighborGapMs

    private fun denseContactCandidate(
        sample: FrameSample,
        side: FootSide,
        groundLine: GroundLine,
    ): ContactFrameCandidate? {
        val evidence = sample.footBottom(side) ?: return null
        val landmarkConfidence = sample.contactLandmarkConfidence(side, evidence)
            ?: return null
        val tolerance = (sample.bodyScale * denseContactGroundToleranceRatio)
            .coerceAtLeast(1.0)
        val proximity = groundGap(groundLine, evidence)
        val inGroundBand = proximity >= -tolerance * 0.55 && proximity <= tolerance * 1.1
        val proximityFactor = (
            1.0 - (proximity.coerceAtLeast(0.0) / tolerance)
            ).coerceIn(0.0, 1.0)
        val confidence = (
            landmarkConfidence *
                (0.75 + (0.25 * proximityFactor))
            ).coerceIn(0.0, 1.0)
        return ContactFrameCandidate(
            sample = sample,
            side = side,
            evidence = evidence,
            proximity = proximity,
            tolerance = tolerance,
            confidence = confidence,
            inGroundBand = inGroundBand,
        )
    }

    private fun ContactFrameCandidate.isEligibleContact(): Boolean =
        inGroundBand && confidence >= minimumContactFrameConfidence

    private fun enteredGroundBand(
        current: ContactFrameCandidate,
        previous: ContactFrameCandidate?,
    ): Boolean =
        previous != null &&
            previous.proximity > current.tolerance &&
            abs(previous.sample.timestampMs - current.sample.timestampMs) <=
            contactMotionNeighborGapMs

    private fun hasGroundBandPersistence(
        current: ContactFrameCandidate,
        previous: ContactFrameCandidate?,
        next: ContactFrameCandidate?,
    ): Boolean =
        listOfNotNull(previous, next).any { neighbor ->
            neighbor.isEligibleContact() &&
                abs(neighbor.sample.timestampMs - current.sample.timestampMs) <=
                contactMotionNeighborGapMs
        }

    private fun isFootAtLocalBottom(
        current: ContactFrameCandidate,
        previous: ContactFrameCandidate?,
        next: ContactFrameCandidate?,
    ): Boolean {
        val tolerance = max(1.0, current.sample.bodyScale * contactMotionToleranceRatio)
        val currentY = current.evidence.bottomPoint.y.toDouble()
        val isLowestNearPrevious = previous == null ||
            abs(current.sample.timestampMs - previous.sample.timestampMs) > contactMotionNeighborGapMs ||
            currentY >= previous.evidence.bottomPoint.y.toDouble() - tolerance
        val isLowestNearNext = next == null ||
            abs(next.sample.timestampMs - current.sample.timestampMs) > contactMotionNeighborGapMs ||
            currentY >= next.evidence.bottomPoint.y.toDouble() - tolerance
        return isLowestNearPrevious && isLowestNearNext
    }

    private fun isKinematicContactCandidate(
        candidates: List<ContactFrameCandidate>,
        index: Int,
        lowerEnvelopeY: Double,
    ): Boolean {
        val current = candidates[index]
        if (current.confidence < minimumContactFrameConfidence ||
            current.evidence.bottomPoint.y.toDouble() < lowerEnvelopeY
        ) {
            return false
        }
        val previous = candidates.getOrNull(index - 1)
        val next = candidates.getOrNull(index + 1)
        val hasPrevious = hasTemporalNeighbor(current, previous)
        val hasNext = hasTemporalNeighbor(current, next)
        if (!hasPrevious && !hasNext) {
            return false
        }
        val tolerance = max(
            1.0,
            current.sample.bodyScale * kinematicContactMotionToleranceRatio,
        )
        val currentY = current.evidence.bottomPoint.y.toDouble()
        val isLowestNearPrevious = !hasPrevious ||
            currentY >= previous!!.evidence.bottomPoint.y.toDouble() - tolerance
        val isLowestNearNext = !hasNext ||
            currentY >= next!!.evidence.bottomPoint.y.toDouble() - tolerance
        return isLowestNearPrevious && isLowestNearNext
    }

    private fun ContactFrameCandidate.toContactFrame(
        window: ContactCandidate,
        direction: AnalysisDirection,
        isKinematicEstimate: Boolean,
        confidence: Double = this.confidence,
    ): ContactFrameAnalysis? {
        val kneeAngleDegrees = sample.contactKneeAngleDegrees(side) ?: return null
        return ContactFrameAnalysis(
            timestampMs = sample.timestampMs,
            windowCenterTimestampMs = window.centerTimestampMs,
            side = side,
            footStrikeRatio = sample.contactFootStrikeRatio(side, direction),
            kneeAngleDegrees = kneeAngleDegrees,
            confidence = confidence,
            isKinematicEstimate = isKinematicEstimate,
        )
    }

    private fun sampleSummaryPayload(
        attemptedFrames: Int,
        validFrames: Int,
        poseFrameCount: Int,
        maxFrameBudget: Int? = null,
        targetFps: Int? = null,
    ): Map<String, Any?> {
        val payload = mutableMapOf<String, Any?>(
            "attemptedFrames" to attemptedFrames,
            "validFrames" to validFrames,
            "poseFrameCount" to poseFrameCount,
        )
        if (maxFrameBudget != null) {
            payload["maxFrameBudget"] = maxFrameBudget
        }
        if (targetFps != null) {
            payload["targetFps"] = targetFps
        }
        return payload
    }

    private fun metricQualityPayload(
        confidence: Double,
        sampleCount: Int,
        reason: String? = null,
    ): Map<String, Any?> = buildMap {
        put("confidence", roundTo3(confidence.coerceIn(0.0, 1.0)))
        put("sampleCount", sampleCount)
        if (reason != null) {
            put("reason", reason)
        }
    }

    private fun perspectiveQualityPayload(samples: List<FrameSample>): PerspectiveQuality {
        if (samples.isEmpty()) {
            return PerspectiveQuality(
                evaluatedFrameCount = 0,
                medianBodyScaleRatio = 0.0,
                minBodyScaleRatio = 0.0,
                visibilityCoverage = 0.0,
                sideViewScore = 0.0,
                scaleDriftRatio = 0.0,
                cutOffFrameRatio = 0.0,
                issues = emptyList(),
            )
        }
        val bodyScaleRatios = samples.map { sample ->
            sample.bodyScale / min(sample.imageWidth, sample.imageHeight).coerceAtLeast(1)
        }
        val medianBodyScaleRatio = median(bodyScaleRatios) ?: 0.0
        val minBodyScaleRatio = bodyScaleRatios.minOrNull() ?: 0.0
        val scales = samples.map { it.bodyScale }.filter { it > 0.0 }
        val lowerScale = percentile(scales, 0.10) ?: 0.0
        val upperScale = percentile(scales, 0.90) ?: lowerScale
        val scaleDriftRatio = if (lowerScale <= 0.0) {
            0.0
        } else {
            (upperScale - lowerScale) / lowerScale
        }
        val visibilityCoverage = samples.map { sample ->
            listOf(
                sample.leftShoulder,
                sample.rightShoulder,
                sample.leftHip,
                sample.rightHip,
                sample.leftKnee,
                sample.rightKnee,
                sample.leftAnkle,
                sample.rightAnkle,
            ).count { it != null } / 8.0
        }.average()
        val sideRatios = samples.mapNotNull { it.sideViewWidthRatio() }
        val sideWidthRatio = median(sideRatios) ?: 1.0
        val sideViewScore = (1.0 - ((sideWidthRatio - 0.18) / 0.34))
            .coerceIn(0.0, 1.0)
        val cutOffFrameRatio = samples.count { it.touchesFrameEdge() } /
            samples.size.toDouble()
        val issues = mutableListOf<String>()
        if (medianBodyScaleRatio < minimumBodyScaleRatio ||
            minBodyScaleRatio < minimumBodyScaleRatio * 0.72
        ) {
            issues.add("tooSmall")
        }
        if (sideViewScore < minimumSideViewScore) {
            issues.add("notSideOn")
        }
        if (cutOffFrameRatio > maximumCutOffFrameRatio ||
            visibilityCoverage < minimumVisibilityCoverage
        ) {
            issues.add("bodyCutOff")
        }
        if (scaleDriftRatio > maximumScaleDriftRatio) {
            issues.add("scaleDrift")
        }
        return PerspectiveQuality(
            evaluatedFrameCount = samples.size,
            medianBodyScaleRatio = roundTo3(medianBodyScaleRatio),
            minBodyScaleRatio = roundTo3(minBodyScaleRatio),
            visibilityCoverage = roundTo3(visibilityCoverage),
            sideViewScore = roundTo3(sideViewScore),
            scaleDriftRatio = roundTo3(scaleDriftRatio),
            cutOffFrameRatio = roundTo3(cutOffFrameRatio),
            issues = issues,
        )
    }

    private fun perspectiveReasonForMetric(
        quality: PerspectiveQuality,
        metric: String,
    ): String? {
        if (quality.issues.contains("tooSmall")) return "too_small_runner"
        if (quality.issues.contains("bodyCutOff")) return "body_cut_off"
        val isLowerBody = metric == "footStrike" || metric == "kneeFlexion"
        if (isLowerBody && quality.issues.contains("notSideOn")) {
            return "not_side_on"
        }
        if ((isLowerBody || metric == "bounce") && quality.issues.contains("scaleDrift")) {
            return "scale_drift"
        }
        return null
    }

    private fun applyPerspectiveQuality(
        metric: String,
        baseQuality: Map<String, Any?>,
        perspectiveQuality: PerspectiveQuality,
    ): Map<String, Any?> {
        val reason = perspectiveReasonForMetric(perspectiveQuality, metric)
            ?: return baseQuality
        val confidence = (baseQuality["confidence"] as? Number)?.toDouble() ?: 0.0
        val sampleCount = (baseQuality["sampleCount"] as? Number)?.toInt() ?: 0
        return metricQualityPayload(
            confidence = min(confidence, if (reason == "too_small_runner") 0.0 else 0.55),
            sampleCount = sampleCount,
            reason = reason,
        )
    }

    private fun contactWindowPayloads(
        windows: List<ContactCandidate>,
        denseTimestamps: List<Long>,
        contactValidations: List<ContactWindowValidation>,
    ): List<Map<String, Any?>> =
        windows.map { window ->
            val validation = contactValidations.firstOrNull { candidate ->
                candidate.window.side == window.side &&
                    candidate.window.centerTimestampMs == window.centerTimestampMs
            }
            val contact = validation?.contact
            val validated = contact?.takeUnless { it.isKinematicEstimate }
                ?.let(::listOf)
                .orEmpty()
            val estimated = contact?.takeIf { it.isKinematicEstimate }
                ?.let(::listOf)
                .orEmpty()
            mapOf(
                "side" to (validation?.contact?.side ?: window.side).token,
                "startTimestampMs" to window.startTimestampMs.toInt(),
                "centerTimestampMs" to window.centerTimestampMs.toInt(),
                "endTimestampMs" to window.endTimestampMs.toInt(),
                "coarseConfidence" to roundTo3(window.confidence),
                "denseSampleCount" to denseTimestamps.count { timestampMs ->
                    timestampMs >= window.startTimestampMs &&
                        timestampMs <= window.endTimestampMs
                },
                "candidateFrameCount" to (validation?.candidateFrameCount ?: 0),
                "rejectedFrameCounts" to (validation?.rejectedFrameCounts ?: emptyMap<String, Int>()),
                "validatedContactFrameTimestampsMs" to validated
                    .map { it.timestampMs.toInt() }
                    .distinct()
                    .sorted(),
                "estimatedContactFrameTimestampsMs" to estimated
                    .map { it.timestampMs.toInt() }
                    .distinct()
                    .sorted(),
                "selectionMethod" to when {
                    validated.isNotEmpty() -> "ground"
                    estimated.isNotEmpty() -> "kinematic"
                    else -> null
                },
                "confidence" to roundTo3(
                    if (validated.isEmpty()) {
                        0.0
                    } else {
                        validated.map { it.confidence }.average()
                    }
                ),
            )
        }

    private fun mergePoseFrames(
        coarsePoseFrames: List<Map<String, Any?>>,
        densePoseFrames: List<Map<String, Any?>>,
    ): List<Map<String, Any?>> {
        val byTimestamp = TreeMap<Int, Map<String, Any?>>()
        for (poseFrame in coarsePoseFrames + densePoseFrames) {
            val timestampMs = poseFrame["timestampMs"] as? Int ?: continue
            byTimestamp[timestampMs] = poseFrame
        }
        return byTimestamp.values.toList()
    }

    private fun poseFrameFromResult(
        result: PoseLandmarkerResult,
        timestampMs: Long,
        imageWidth: Int,
        imageHeight: Int,
    ): Map<String, Any?>? {
        val landmarks = result.landmarks().firstOrNull() ?: return null
        if (landmarks.size < mediaPipePoseLandmarkCount) {
            return null
        }
        val worldLandmarks = result.worldLandmarks().firstOrNull()

        return mapOf(
            "timestampMs" to timestampMs.toInt(),
            "imageWidth" to imageWidth,
            "imageHeight" to imageHeight,
            "landmarks" to landmarks
                .take(mediaPipePoseLandmarkCount)
                .mapIndexed { index, landmark ->
                    val visibility = optionalFloat(landmark.visibility())
                    val presence = optionalFloat(landmark.presence())
                    val world = worldLandmarks?.getOrNull(index)
                    val payload = mutableMapOf<String, Any?>(
                        "index" to index,
                        "x" to landmark.x().toDouble(),
                        "y" to landmark.y().toDouble(),
                        "z" to landmark.z().toDouble(),
                        "visibility" to visibility?.toDouble(),
                        "presence" to presence?.toDouble(),
                        "confidence" to landmarkConfidence(landmark).toDouble(),
                    )
                    if (world != null) {
                        val imageConfidence = landmarkConfidence(landmark).toDouble()
                        payload["worldX"] = world.x().toDouble()
                        payload["worldY"] = world.y().toDouble()
                        payload["worldZ"] = world.z().toDouble()
                        payload["worldVisibility"] = optionalFloat(world.visibility())?.toDouble()
                        payload["worldPresence"] = optionalFloat(world.presence())?.toDouble()
                        payload["worldConfidence"] =
                            landmarkConfidence(world).takeIf { it > 0f }?.toDouble()
                                ?: imageConfidence
                    }
                    payload
                },
        )
    }

    private fun extractFrameSample(
        result: PoseLandmarkerResult,
        timestampMs: Long,
        imageWidth: Int,
        imageHeight: Int,
    ): FrameSample? {
        val landmarks = result.landmarks().firstOrNull() ?: return null
        if (landmarks.size <= rightFootIndex) {
            return null
        }

        fun optionalPoint(index: Int): ConfidentPoint? =
            confidentLandmarkPoint(landmarks, index, imageWidth, imageHeight)

        val leftShoulder = optionalPoint(leftShoulderIndex)
        val rightShoulder = optionalPoint(rightShoulderIndex)
        val leftHip = optionalPoint(leftHipIndex)
        val rightHip = optionalPoint(rightHipIndex)
        val leftKnee = optionalPoint(leftKneeIndex)
        val rightKnee = optionalPoint(rightKneeIndex)
        val leftAnkle = optionalPoint(leftAnkleIndex)
        val rightAnkle = optionalPoint(rightAnkleIndex)
        val leftHeel = optionalPoint(leftHeelIndex)
        val rightHeel = optionalPoint(rightHeelIndex)
        val leftToe = optionalPoint(leftFootIndex)
        val rightToe = optionalPoint(rightFootIndex)
        val leftElbow = optionalPoint(leftElbowIndex)
        val rightElbow = optionalPoint(rightElbowIndex)
        val leftWrist = optionalPoint(leftWristIndex)
        val rightWrist = optionalPoint(rightWristIndex)

        // In side-view running footage, the far-side leg can be briefly
        // occluded at exactly the moment the visible foot lands. Keep that
        // torso frame for analysis; lower-body metrics still require a full
        // hip-knee-ankle chain on the individual side being measured.
        val shoulderPoints = listOfNotNull(leftShoulder, rightShoulder).map { it.point }
        val hipPoints = listOfNotNull(leftHip, rightHip).map { it.point }
        if (shoulderPoints.isEmpty() || hipPoints.isEmpty()) {
            return null
        }
        val shoulderCenter = centerOfPoints(shoulderPoints)
        val hipCenter = centerOfPoints(hipPoints)
        val anklePoints = listOfNotNull(leftAnkle, rightAnkle).map { it.point }
        val torsoScale = distance(shoulderCenter, hipCenter)
        val legScale = anklePoints
            .takeIf { it.isNotEmpty() }
            ?.let { distance(hipCenter, centerOfPoints(it)) }
            ?: 0.0
        val bodyScale = max(torsoScale, legScale)
        if (bodyScale < minimumBodyScalePx) {
            return null
        }

        return FrameSample(
            timestampMs = timestampMs,
            imageWidth = imageWidth,
            imageHeight = imageHeight,
            leftShoulder = leftShoulder?.point?.let(::copyPoint),
            rightShoulder = rightShoulder?.point?.let(::copyPoint),
            leftHip = leftHip?.point?.let(::copyPoint),
            rightHip = rightHip?.point?.let(::copyPoint),
            leftKnee = leftKnee?.point?.let(::copyPoint),
            rightKnee = rightKnee?.point?.let(::copyPoint),
            shoulderCenter = shoulderCenter,
            hipCenter = hipCenter,
            leftAnkle = leftAnkle?.point?.let(::copyPoint),
            rightAnkle = rightAnkle?.point?.let(::copyPoint),
            leftHeel = leftHeel?.point?.let(::copyPoint),
            rightHeel = rightHeel?.point?.let(::copyPoint),
            leftToe = leftToe?.point?.let(::copyPoint),
            rightToe = rightToe?.point?.let(::copyPoint),
            leftElbow = leftElbow?.point?.let(::copyPoint),
            rightElbow = rightElbow?.point?.let(::copyPoint),
            leftWrist = leftWrist?.point?.let(::copyPoint),
            rightWrist = rightWrist?.point?.let(::copyPoint),
            leftShoulderConfidence = leftShoulder?.confidence,
            rightShoulderConfidence = rightShoulder?.confidence,
            leftHipConfidence = leftHip?.confidence,
            rightHipConfidence = rightHip?.confidence,
            leftKneeConfidence = leftKnee?.confidence,
            rightKneeConfidence = rightKnee?.confidence,
            leftAnkleConfidence = leftAnkle?.confidence,
            rightAnkleConfidence = rightAnkle?.confidence,
            leftHeelConfidence = leftHeel?.confidence,
            rightHeelConfidence = rightHeel?.confidence,
            leftToeConfidence = leftToe?.confidence,
            rightToeConfidence = rightToe?.confidence,
            leftElbowConfidence = leftElbow?.confidence,
            rightElbowConfidence = rightElbow?.confidence,
            leftWristConfidence = leftWrist?.confidence,
            rightWristConfidence = rightWrist?.confidence,
            bodyScale = bodyScale,
        )
    }

    private fun confidentLandmarkPoint(
        landmarks: List<NormalizedLandmark>,
        index: Int,
        imageWidth: Int,
        imageHeight: Int,
    ): ConfidentPoint? {
        if (index !in landmarks.indices) {
            return null
        }

        val landmark = landmarks[index]
        val confidence = landmarkConfidence(landmark)
        if (confidence < minimumLikelihood) {
            return null
        }
        return ConfidentPoint(
            point = PointF(
                landmark.x() * imageWidth.toFloat(),
                landmark.y() * imageHeight.toFloat(),
            ),
            confidence = confidence.toDouble(),
        )
    }

    private fun optionalFloat(value: Optional<Float>): Float? =
        if (value.isPresent) value.get() else null

    private fun landmarkConfidence(landmark: NormalizedLandmark): Float {
        val visibility = optionalFloat(landmark.visibility())
        val presence = optionalFloat(landmark.presence())
        val confidence = when {
            visibility != null && presence != null -> min(visibility, presence)
            visibility != null -> visibility
            presence != null -> presence
            else -> 0f
        }
        return confidence.coerceIn(0f, 1f)
    }

    private fun landmarkConfidence(landmark: Landmark): Float {
        val visibility = optionalFloat(landmark.visibility())
        val presence = optionalFloat(landmark.presence())
        val confidence = when {
            visibility != null && presence != null -> min(visibility, presence)
            visibility != null -> visibility
            presence != null -> presence
            else -> 0f
        }
        return confidence.coerceIn(0f, 1f)
    }

    private fun resolveDirection(samples: List<FrameSample>): AnalysisDirection {
        val hipMovement =
            samples.last().hipCenter.x.toDouble() - samples.first().hipCenter.x.toDouble()
        val averageScale = samples.map { it.bodyScale }.average().coerceAtLeast(1.0)
        if (abs(hipMovement) >= averageScale * stationaryThresholdRatio) {
            return if (hipMovement > 0) {
                AnalysisDirection.leftToRight
            } else {
                AnalysisDirection.rightToLeft
            }
        }

        // A treadmill runner has almost no image-space hip travel. Use the
        // visible heel-toe orientation before declaring the clip stationary;
        // posture and landing evidence both need a defensible facing side.
        val footDirections = samples.flatMap { sample ->
            FootSide.values().mapNotNull { side ->
                val foot = sample.footBottom(side) ?: return@mapNotNull null
                val normalizedDirection =
                    (foot.toe.x - foot.heel.x).toDouble() /
                        sample.bodyScale.coerceAtLeast(1.0)
                normalizedDirection.takeIf { abs(it) >= minimumFacingDirectionRatio }
            }
        }
        val facingDirection = median(footDirections)
        return when {
            facingDirection == null || abs(facingDirection) < minimumFacingDirectionRatio ->
                AnalysisDirection.stationary
            facingDirection > 0 -> AnalysisDirection.leftToRight
            else -> AnalysisDirection.rightToLeft
        }
    }

    private fun midpoint(first: PointF, second: PointF): PointF =
        PointF(
            (first.x + second.x) / 2f,
            (first.y + second.y) / 2f,
        )

    private fun centerOfPoints(points: List<PointF>): PointF =
        PointF(
            points.map { it.x }.average().toFloat(),
            points.map { it.y }.average().toFloat(),
        )

    private fun distance(first: PointF, second: PointF): Double {
        val dx = first.x - second.x
        val dy = first.y - second.y
        return kotlin.math.hypot(dx.toDouble(), dy.toDouble())
    }

    private fun copyPoint(point: PointF): PointF = PointF(point.x, point.y)

    private fun roundTo3(value: Double): Double = (value * 1000.0).roundToInt() / 1000.0

    private data class PosePassResult(
        val samples: List<FrameSample>,
        val poseFrames: List<Map<String, Any?>>,
        val sharpnessValues: List<Double>,
    )

    private data class ConfidentPoint(
        val point: PointF,
        val confidence: Double,
    )

    private data class ContactCandidateSet(
        val windows: List<ContactCandidate>,
        val groundLine: GroundLine,
    )

    private data class GroundLine(
        val slope: Double,
        val intercept: Double,
    ) {
        fun yAt(x: Double): Double = slope * x + intercept
    }

    private data class GroundPoint(
        val x: Double,
        val y: Double,
        val bodyScale: Double,
    )

    private data class FootObservation(
        val sample: FrameSample,
        val side: FootSide,
        val evidence: FootBottomEvidence,
    )

    private data class ContactCandidate(
        val side: FootSide,
        val centerTimestampMs: Long,
        val startTimestampMs: Long,
        val endTimestampMs: Long,
        val confidence: Double,
    )

    private data class ContactFrameAnalysis(
        val timestampMs: Long,
        val windowCenterTimestampMs: Long,
        val side: FootSide,
        val footStrikeRatio: Double,
        val kneeAngleDegrees: Double,
        val confidence: Double,
        val isKinematicEstimate: Boolean = false,
    )

    private data class ContactProxyCandidate(
        val sample: FrameSample,
        val side: FootSide,
        val landmarkConfidence: Double,
    )

    private data class ContactFrameSelection(
        val contact: ContactFrameAnalysis?,
        val candidateFrameCount: Int,
        val rejectedFrameCounts: Map<String, Int>,
    )

    private data class ContactWindowValidation(
        val window: ContactCandidate,
        val contact: ContactFrameAnalysis?,
        val candidateFrameCount: Int,
        val rejectedFrameCounts: Map<String, Int>,
    )

    private data class ContactFrameCandidate(
        val sample: FrameSample,
        val side: FootSide,
        val evidence: FootBottomEvidence,
        val proximity: Double,
        val tolerance: Double,
        val confidence: Double,
        val inGroundBand: Boolean,
    )

    private data class FootBottomEvidence(
        val bottomPoint: PointF,
        val ankle: PointF,
        val heel: PointF,
        val toe: PointF,
        val confidence: Double,
    )

    private data class PerspectiveQuality(
        val evaluatedFrameCount: Int,
        val medianBodyScaleRatio: Double,
        val minBodyScaleRatio: Double,
        val visibilityCoverage: Double,
        val sideViewScore: Double,
        val scaleDriftRatio: Double,
        val cutOffFrameRatio: Double,
        val issues: List<String>,
    ) {
        fun toPayload(): Map<String, Any?> = mapOf(
            "evaluatedFrameCount" to evaluatedFrameCount,
            "medianBodyScaleRatio" to medianBodyScaleRatio,
            "minBodyScaleRatio" to minBodyScaleRatio,
            "visibilityCoverage" to visibilityCoverage,
            "sideViewScore" to sideViewScore,
            "scaleDriftRatio" to scaleDriftRatio,
            "cutOffFrameRatio" to cutOffFrameRatio,
            "issues" to issues,
        )
    }

    private data class FrameSample(
        val timestampMs: Long,
        val imageWidth: Int,
        val imageHeight: Int,
        val leftShoulder: PointF?,
        val rightShoulder: PointF?,
        val leftHip: PointF?,
        val rightHip: PointF?,
        val leftKnee: PointF?,
        val rightKnee: PointF?,
        val shoulderCenter: PointF,
        val hipCenter: PointF,
        val leftAnkle: PointF?,
        val rightAnkle: PointF?,
        val leftHeel: PointF?,
        val rightHeel: PointF?,
        val leftToe: PointF?,
        val rightToe: PointF?,
        val leftElbow: PointF?,
        val rightElbow: PointF?,
        val leftWrist: PointF?,
        val rightWrist: PointF?,
        val leftShoulderConfidence: Double?,
        val rightShoulderConfidence: Double?,
        val leftHipConfidence: Double?,
        val rightHipConfidence: Double?,
        val leftKneeConfidence: Double?,
        val rightKneeConfidence: Double?,
        val leftAnkleConfidence: Double?,
        val rightAnkleConfidence: Double?,
        val leftHeelConfidence: Double?,
        val rightHeelConfidence: Double?,
        val leftToeConfidence: Double?,
        val rightToeConfidence: Double?,
        val leftElbowConfidence: Double?,
        val rightElbowConfidence: Double?,
        val leftWristConfidence: Double?,
        val rightWristConfidence: Double?,
        val bodyScale: Double,
    ) {
        fun sideViewWidthRatio(): Double? {
            fun pointDistance(first: PointF, second: PointF): Double {
                return hypot(
                    (first.x - second.x).toDouble(),
                    (first.y - second.y).toDouble(),
                )
            }
            val widths = mutableListOf<Double>()
            if (leftShoulder != null && rightShoulder != null) {
                widths.add(
                    pointDistance(leftShoulder, rightShoulder) /
                        bodyScale.coerceAtLeast(1.0),
                )
            }
            if (leftHip != null && rightHip != null) {
                widths.add(
                    pointDistance(leftHip, rightHip) /
                        bodyScale.coerceAtLeast(1.0),
                )
            }
            return widths.takeIf { it.isNotEmpty() }?.average()
        }

        fun touchesFrameEdge(): Boolean {
            val marginX = imageWidth * edgeCutOffMarginRatio
            val marginY = imageHeight * edgeCutOffMarginRatio
            return listOfNotNull(
                leftShoulder,
                rightShoulder,
                leftHip,
                rightHip,
                leftKnee,
                rightKnee,
                leftAnkle,
                rightAnkle,
                leftHeel,
                rightHeel,
                leftToe,
                rightToe,
            ).any { point ->
                point.x <= marginX ||
                    point.x >= imageWidth - marginX ||
                    point.y <= marginY ||
                    point.y >= imageHeight - marginY
            }
        }

        val coreLandmarkConfidence: Double
            get() = listOfNotNull(
                leftShoulderConfidence,
                rightShoulderConfidence,
                leftHipConfidence,
                rightHipConfidence,
                leftKneeConfidence,
                rightKneeConfidence,
                leftAnkleConfidence,
                rightAnkleConfidence,
            ).average()

        fun armLandmarkConfidence(): Double? {
            val confidences = mutableListOf<Double>()
            if (leftShoulderConfidence != null &&
                leftElbowConfidence != null &&
                leftWristConfidence != null
            ) {
                confidences.add(
                    listOfNotNull(
                        leftShoulderConfidence,
                        leftElbowConfidence,
                        leftWristConfidence,
                    )
                        .average(),
                )
            }
            if (rightShoulderConfidence != null &&
                rightElbowConfidence != null &&
                rightWristConfidence != null
            ) {
                confidences.add(
                    listOfNotNull(
                        rightShoulderConfidence,
                        rightElbowConfidence,
                        rightWristConfidence,
                    )
                        .average(),
                )
            }
            return confidences.takeIf { it.isNotEmpty() }?.average()
        }

        fun forwardLeanDegrees(direction: AnalysisDirection): Double {
            val verticalTravel = max(1.0, hipCenter.y.toDouble() - shoulderCenter.y.toDouble())
            val forwardOffset = when (direction) {
                AnalysisDirection.leftToRight -> {
                    shoulderCenter.x.toDouble() - hipCenter.x.toDouble()
                }
                AnalysisDirection.rightToLeft -> {
                    hipCenter.x.toDouble() - shoulderCenter.x.toDouble()
                }
                AnalysisDirection.stationary -> {
                    0.0
                }
            }
            return Math.toDegrees(atan2(forwardOffset, verticalTravel))
        }

        fun leadFootStrikeRatio(direction: AnalysisDirection): Double {
            val leftFoot = leftHeel ?: leftAnkle
            val rightFoot = rightHeel ?: rightAnkle
            if (leftFoot == null && rightFoot == null) {
                return 0.0
            }
            val forwardReachPx = when (direction) {
                AnalysisDirection.leftToRight -> {
                    max(leftFoot?.x ?: Float.NEGATIVE_INFINITY, rightFoot?.x ?: Float.NEGATIVE_INFINITY)
                        .toDouble() - hipCenter.x.toDouble()
                }
                AnalysisDirection.rightToLeft -> {
                    hipCenter.x.toDouble() -
                        min(leftFoot?.x ?: Float.POSITIVE_INFINITY, rightFoot?.x ?: Float.POSITIVE_INFINITY)
                            .toDouble()
                }
                AnalysisDirection.stationary -> {
                    max(
                        leftFoot?.let { abs(it.x.toDouble() - hipCenter.x.toDouble()) } ?: 0.0,
                        rightFoot?.let { abs(it.x.toDouble() - hipCenter.x.toDouble()) } ?: 0.0,
                    )
                }
            }
            return forwardReachPx / bodyScale.coerceAtLeast(1.0)
        }

        fun footBottom(side: FootSide): FootBottomEvidence? {
            val ankle = when (side) {
                FootSide.left -> leftAnkle
                FootSide.right -> rightAnkle
            } ?: return null
            val heel = when (side) {
                FootSide.left -> leftHeel
                FootSide.right -> rightHeel
            }
            val toe = when (side) {
                FootSide.left -> leftToe
                FootSide.right -> rightToe
            }
            val ankleConfidence = when (side) {
                FootSide.left -> leftAnkleConfidence
                FootSide.right -> rightAnkleConfidence
            }
            val heelConfidence = when (side) {
                FootSide.left -> leftHeelConfidence
                FootSide.right -> rightHeelConfidence
            }
            val toeConfidence = when (side) {
                FootSide.left -> leftToeConfidence
                FootSide.right -> rightToeConfidence
            }
            val bottomPoint = listOfNotNull(ankle, heel, toe).maxByOrNull { it.y } ?: ankle
            val confidence = listOfNotNull(ankleConfidence, heelConfidence, toeConfidence)
                .minOrNull() ?: return null
            return FootBottomEvidence(
                bottomPoint = bottomPoint,
                ankle = ankle,
                heel = heel ?: ankle,
                toe = toe ?: ankle,
                confidence = confidence,
            )
        }

        fun contactFootStrikeRatio(
            side: FootSide,
            direction: AnalysisDirection,
        ): Double {
            val foot = footBottom(side) ?: return 0.0
            val footX = foot.ankle.x.toDouble()
            val forwardReachPx = when (direction) {
                AnalysisDirection.leftToRight -> footX - hipCenter.x.toDouble()
                AnalysisDirection.rightToLeft -> hipCenter.x.toDouble() - footX
                AnalysisDirection.stationary -> abs(footX - hipCenter.x.toDouble())
            }
            return forwardReachPx.coerceAtLeast(0.0) / bodyScale.coerceAtLeast(1.0)
        }

        fun contactKneeAngleDegrees(side: FootSide): Double? {
            val (hip, knee, ankle) = when (side) {
                FootSide.left -> Triple(leftHip, leftKnee, leftAnkle)
                FootSide.right -> Triple(rightHip, rightKnee, rightAnkle)
            }
            if (hip == null || knee == null || ankle == null) {
                return null
            }
            return jointAngle(hip, knee, ankle)
        }

        fun contactLandmarkConfidence(
            side: FootSide,
            footEvidence: FootBottomEvidence,
        ): Double? {
            val hipConfidence = when (side) {
                FootSide.left -> leftHipConfidence
                FootSide.right -> rightHipConfidence
            }
            val kneeConfidence = when (side) {
                FootSide.left -> leftKneeConfidence
                FootSide.right -> rightKneeConfidence
            }
            val hip = when (side) {
                FootSide.left -> leftHip
                FootSide.right -> rightHip
            }
            val knee = when (side) {
                FootSide.left -> leftKnee
                FootSide.right -> rightKnee
            }
            if (hip == null || knee == null || hipConfidence == null || kneeConfidence == null) {
                return null
            }
            return min(footEvidence.confidence, min(hipConfidence, kneeConfidence))
        }

        fun averageElbowAngleDegrees(): Double? {
            val angles = mutableListOf<Double>()
            val leftArm = listOfNotNull(leftShoulder, leftElbow, leftWrist)
            if (leftArm.size == 3) {
                angles.add(jointAngle(leftArm[0], leftArm[1], leftArm[2]))
            }
            val rightArm = listOfNotNull(rightShoulder, rightElbow, rightWrist)
            if (rightArm.size == 3) {
                angles.add(jointAngle(rightArm[0], rightArm[1], rightArm[2]))
            }
            return angles.takeIf { it.isNotEmpty() }?.average()
        }

        fun leadKneeAngleDegrees(direction: AnalysisDirection): Double? {
            val leftFoot = leftHeel ?: leftAnkle
            val rightFoot = rightHeel ?: rightAnkle
            if (leftFoot == null && rightFoot == null) {
                return null
            }
            val useLeft = when (direction) {
                AnalysisDirection.leftToRight ->
                    (leftFoot?.x ?: Float.NEGATIVE_INFINITY) >=
                        (rightFoot?.x ?: Float.NEGATIVE_INFINITY)
                AnalysisDirection.rightToLeft ->
                    (leftFoot?.x ?: Float.POSITIVE_INFINITY) <=
                        (rightFoot?.x ?: Float.POSITIVE_INFINITY)
                AnalysisDirection.stationary -> {
                    (leftFoot?.let { abs(it.x.toDouble() - hipCenter.x.toDouble()) } ?: 0.0) >=
                        (rightFoot?.let { abs(it.x.toDouble() - hipCenter.x.toDouble()) } ?: 0.0)
                }
            }
            return if (useLeft) {
                val leftLeg = listOfNotNull(leftHip, leftKnee, leftAnkle)
                if (leftLeg.size != 3) {
                    null
                } else {
                    jointAngle(leftLeg[0], leftLeg[1], leftLeg[2])
                }
            } else {
                val rightLeg = listOfNotNull(rightHip, rightKnee, rightAnkle)
                if (rightLeg.size != 3) {
                    null
                } else {
                    jointAngle(rightLeg[0], rightLeg[1], rightLeg[2])
                }
            }
        }

        private fun jointAngle(first: PointF, vertex: PointF, third: PointF): Double {
            val firstX = first.x - vertex.x
            val firstY = first.y - vertex.y
            val secondX = third.x - vertex.x
            val secondY = third.y - vertex.y
            val firstLength = hypot(firstX.toDouble(), firstY.toDouble())
            val secondLength = hypot(secondX.toDouble(), secondY.toDouble())
            if (firstLength <= 0.0 || secondLength <= 0.0) {
                return 180.0
            }
            val cosine =
                ((firstX * secondX) + (firstY * secondY)) / (firstLength * secondLength)
            return Math.toDegrees(kotlin.math.acos(cosine.coerceIn(-1.0, 1.0)))
        }
    }

    private enum class AnalysisDirection(val token: String) {
        leftToRight("leftToRight"),
        rightToLeft("rightToLeft"),
        stationary("stationary"),
    }

    private enum class FootSide(val token: String) {
        left("left"),
        right("right"),
    }

    private class AnalysisException(
        val code: String,
        override val message: String,
    ) : Exception(message)

    companion object {
        private const val channelName = "football_note/running_pose_analysis"
        private const val methodName = "analyzeRunningVideo"
        private const val previewPoseMethodName = "analyzeRunningVideoPreviewPose"
        private const val evidenceFramesMethodName = "extractRunningEvidenceFrames"
        private const val liveFrameMethodName = "analyzeRunningLiveFrame"
        private const val coarseTargetFps = 8
        private const val coarseFrameIntervalMs = 125L
        private const val maxCoarseFrameBudget = 481
        private const val previewPoseFrameIntervalMs = 1000L
        private const val maxPreviewPoseFrameBudget = 9
        private const val recoveryTargetFps = 15
        private const val recoveryFrameIntervalMs = 67L
        private const val maxRecoveryFrameBudget = 120
        private const val minimumValidFrames = 6
        private const val minimumSharpnessSampleCount = 6
        private const val minimumMedianSharpness = 0.018
        private const val sharpnessHorizontalInsetFraction = 0.10
        private const val sharpnessTopFraction = 0.32
        private const val sharpnessBottomFraction = 0.68
        private const val sharpnessSampleWidth = 96
        private const val sharpnessSampleHeight = 64
        private const val minVideoDurationMs = 1500L
        private const val maxVideoDurationMs = 60000L
        private const val maxDecodableVideoDurationMs = 600000L
        private const val minimumLikelihood = 0.35f
        private const val minimumBodyScalePx = 40.0
        private const val mediaPipePoseLandmarkCount = 33
        private const val stationaryThresholdRatio = 0.12
        private const val denseTargetFps = 30
        private const val denseFrameIntervalMs = 33L
        private const val denseWindowRadiusMs = 500L
        private const val maxDenseFrameBudget = 240
        private const val maxContactWindows = 8
        private const val minimumContactCenterSeparationMs = 320L
        private const val minimumDistinctContactSeparationMs = 120L
        private const val minimumFacingDirectionRatio = 0.02
        private const val minimumValidatedContactFrames = 3
        private const val minimumContactFrameConfidence = 0.34
        private const val kinematicContactConfidencePenalty = 0.82
        private const val kinematicContactLowerPercentile = 0.65
        private const val kinematicContactMotionToleranceRatio = 0.025
        private const val contactProxyConfidencePenalty = 0.60
        private const val coarseContactProxyConfidencePenalty = 0.42
        private const val coarseContactGroundToleranceRatio = 0.15
        private const val denseContactGroundToleranceRatio = 0.16
        private const val localFootExtremumToleranceRatio = 0.035
        private const val contactMotionToleranceRatio = 0.035
        private const val contactMotionNeighborGapMs = 100L
        private const val groundLineSampleFraction = 0.45
        private const val groundLineMinimumSamples = 3
        private const val minimumBodyScaleRatio = 0.12
        private const val minimumSideViewScore = 0.46
        private const val maximumScaleDriftRatio = 0.34
        private const val maximumCutOffFrameRatio = 0.18
        private const val minimumVisibilityCoverage = 0.62
        private const val edgeCutOffMarginRatio = 0.025
        private const val modelAssetPath = "pose_landmarker_full.task"
        private const val leftShoulderIndex = 11
        private const val rightShoulderIndex = 12
        private const val leftElbowIndex = 13
        private const val rightElbowIndex = 14
        private const val leftWristIndex = 15
        private const val rightWristIndex = 16
        private const val leftHipIndex = 23
        private const val rightHipIndex = 24
        private const val leftKneeIndex = 25
        private const val rightKneeIndex = 26
        private const val leftAnkleIndex = 27
        private const val rightAnkleIndex = 28
        private const val leftHeelIndex = 29
        private const val rightHeelIndex = 30
        private const val leftFootIndex = 31
        private const val rightFootIndex = 32
    }
}
