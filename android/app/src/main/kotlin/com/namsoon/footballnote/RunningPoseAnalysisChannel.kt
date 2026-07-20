package com.namsoon.footballnote

import android.content.Context
import android.graphics.Bitmap
import android.graphics.PointF
import android.media.MediaMetadataRetriever
import android.os.Handler
import android.os.Looper
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
import java.util.Optional
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
        if (call.method != methodName) {
            result.notImplemented()
            return
        }

        val path = call.argument<String>("path")
        if (path.isNullOrBlank()) {
            result.error("missing_file", "Video file is missing.", null)
            return
        }

        executor.execute {
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
    }

    private fun analyzeVideo(path: String): Map<String, Any?> {
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

            val landmarker = makePoseLandmarker()
            poseLandmarker = landmarker
            val frameSamples = mutableListOf<FrameSample>()
            val poseFrames = mutableListOf<Map<String, Any?>>()
            var lastTimestampMs = 0L
            repeat(sampleCount) { index ->
                val fraction = if (sampleCount == 1) {
                    0.5
                } else {
                    sampleStartFraction +
                        (sampleEndFraction - sampleStartFraction) *
                        (index.toDouble() / (sampleCount - 1))
                }
                val timeUs = (durationMs.toDouble() * 1000.0 * fraction).roundToLong()
                val bitmap = retriever.getFrameAtTime(
                    timeUs,
                    MediaMetadataRetriever.OPTION_CLOSEST,
                ) ?: return@repeat
                try {
                    val requestedTimestampMs =
                        (durationMs.toDouble() * fraction).roundToLong()
                    val analysisTimestampMs = max(requestedTimestampMs, lastTimestampMs + 1)
                    lastTimestampMs = analysisTimestampMs
                    val pose = detectPose(landmarker, bitmap, analysisTimestampMs)
                    poseFrameFromResult(
                        pose,
                        timestampMs = requestedTimestampMs,
                        imageWidth = bitmap.width,
                        imageHeight = bitmap.height,
                    )?.let(poseFrames::add)
                    extractFrameSample(
                        pose,
                        imageWidth = bitmap.width,
                        imageHeight = bitmap.height,
                    )?.let(frameSamples::add)
                } finally {
                    bitmap.recycle()
                }
            }

            if (frameSamples.size < minimumValidFrames) {
                throw AnalysisException(
                    "no_pose_detected",
                    "We could not detect a clear running pose in this video.",
                )
            }

            val direction = resolveDirection(frameSamples)
            val averageScale = frameSamples.map { it.bodyScale }.average().coerceAtLeast(1.0)
            val leanDegrees = frameSamples
                .map { it.forwardLeanDegrees(direction) }
                .average()
            val shoulderYs = frameSamples.map { it.shoulderCenter.y.toDouble() }
            val bounceRatio = (
                (shoulderYs.maxOrNull() ?: 0.0) -
                    (shoulderYs.minOrNull() ?: 0.0)
                ) / averageScale
            val loadingWindowSize = max(1, frameSamples.size / 3)
            val loadingSamples = frameSamples
                .sortedBy { it.leadFootStrikeRatio(direction) }
                .takeLast(loadingWindowSize)
            val footStrikeRatio = loadingSamples
                .map { it.leadFootStrikeRatio(direction) }
                .average()
            val kneeAngles = loadingSamples.mapNotNull { it.leadKneeAngleDegrees(direction) }
            val elbowAngles = frameSamples.mapNotNull { it.averageElbowAngleDegrees() }
            if (kneeAngles.isEmpty() || elbowAngles.isEmpty()) {
                throw AnalysisException(
                    "no_pose_detected",
                    "We could not detect a clear running pose in this video.",
                )
            }
            val stanceKneeAngle = kneeAngles.average()
            val elbowAngle = elbowAngles.average()

            return mapOf(
                "durationMs" to durationMs.toInt(),
                "sampledFrames" to sampleCount,
                "validFrames" to frameSamples.size,
                "direction" to direction.token,
                "forwardLeanDegrees" to roundTo3(leanDegrees),
                "verticalBounceRatio" to roundTo3(bounceRatio.coerceAtLeast(0.0)),
                "footStrikeDistanceRatio" to roundTo3(footStrikeRatio),
                "stanceKneeAngleDegrees" to roundTo3(stanceKneeAngle),
                "elbowAngleDegrees" to roundTo3(elbowAngle),
                "poseFrames" to poseFrames,
            )
        } finally {
            retriever.release()
            poseLandmarker?.close()
        }
    }

    private fun makePoseLandmarker(): PoseLandmarker {
        ensureModelAssetAvailable()

        val baseOptions = BaseOptions.builder()
            .setModelAssetPath(modelAssetPath)
            .build()
        val options = PoseLandmarker.PoseLandmarkerOptions.builder()
            .setBaseOptions(baseOptions)
            .setRunningMode(RunningMode.VIDEO)
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

        return mapOf(
            "timestampMs" to timestampMs.toInt(),
            "imageWidth" to imageWidth,
            "imageHeight" to imageHeight,
            "landmarks" to landmarks
                .take(mediaPipePoseLandmarkCount)
                .mapIndexed { index, landmark ->
                    val visibility = optionalFloat(landmark.visibility())
                    val presence = optionalFloat(landmark.presence())
                    mapOf(
                        "index" to index,
                        "x" to landmark.x().toDouble(),
                        "y" to landmark.y().toDouble(),
                        "z" to landmark.z().toDouble(),
                        "visibility" to visibility?.toDouble(),
                        "presence" to presence?.toDouble(),
                        "confidence" to landmarkConfidence(landmark).toDouble(),
                    )
                },
        )
    }

    private fun extractFrameSample(
        result: PoseLandmarkerResult,
        imageWidth: Int,
        imageHeight: Int,
    ): FrameSample? {
        val landmarks = result.landmarks().firstOrNull() ?: return null
        if (landmarks.size <= leftFootIndex) {
            return null
        }

        val leftShoulder =
            confidentPoint(landmarks, leftShoulderIndex, imageWidth, imageHeight) ?: return null
        val rightShoulder =
            confidentPoint(landmarks, rightShoulderIndex, imageWidth, imageHeight) ?: return null
        val leftHip = confidentPoint(landmarks, leftHipIndex, imageWidth, imageHeight) ?: return null
        val rightHip =
            confidentPoint(landmarks, rightHipIndex, imageWidth, imageHeight) ?: return null
        val leftKnee =
            confidentPoint(landmarks, leftKneeIndex, imageWidth, imageHeight) ?: return null
        val rightKnee =
            confidentPoint(landmarks, rightKneeIndex, imageWidth, imageHeight) ?: return null
        val leftAnkle =
            confidentPoint(landmarks, leftAnkleIndex, imageWidth, imageHeight) ?: return null
        val rightAnkle =
            confidentPoint(landmarks, rightAnkleIndex, imageWidth, imageHeight) ?: return null

        val shoulderCenter = midpoint(leftShoulder, rightShoulder)
        val hipCenter = midpoint(leftHip, rightHip)
        val ankleCenter = midpoint(leftAnkle, rightAnkle)
        val torsoScale = distance(shoulderCenter, hipCenter)
        val legScale = distance(hipCenter, ankleCenter)
        val bodyScale = max(torsoScale, legScale)
        if (bodyScale < minimumBodyScalePx) {
            return null
        }

        return FrameSample(
            leftShoulder = copyPoint(leftShoulder),
            rightShoulder = copyPoint(rightShoulder),
            leftHip = copyPoint(leftHip),
            rightHip = copyPoint(rightHip),
            leftKnee = copyPoint(leftKnee),
            rightKnee = copyPoint(rightKnee),
            shoulderCenter = shoulderCenter,
            hipCenter = hipCenter,
            leftAnkle = copyPoint(leftAnkle),
            rightAnkle = copyPoint(rightAnkle),
            leftHeel =
                confidentPoint(landmarks, leftHeelIndex, imageWidth, imageHeight)
                    ?.let(::copyPoint),
            rightHeel =
                confidentPoint(landmarks, rightHeelIndex, imageWidth, imageHeight)
                    ?.let(::copyPoint),
            leftElbow =
                confidentPoint(landmarks, leftElbowIndex, imageWidth, imageHeight)
                    ?.let(::copyPoint),
            rightElbow =
                confidentPoint(landmarks, rightElbowIndex, imageWidth, imageHeight)
                    ?.let(::copyPoint),
            leftWrist =
                confidentPoint(landmarks, leftWristIndex, imageWidth, imageHeight)
                    ?.let(::copyPoint),
            rightWrist =
                confidentPoint(landmarks, rightWristIndex, imageWidth, imageHeight)
                    ?.let(::copyPoint),
            bodyScale = bodyScale,
        )
    }

    private fun confidentPoint(
        landmarks: List<NormalizedLandmark>,
        index: Int,
        imageWidth: Int,
        imageHeight: Int,
    ): PointF? {
        if (index !in landmarks.indices) {
            return null
        }

        val landmark = landmarks[index]
        val confidence = landmarkConfidence(landmark)
        if (confidence < minimumLikelihood) {
            return null
        }
        return PointF(
            landmark.x() * imageWidth.toFloat(),
            landmark.y() * imageHeight.toFloat(),
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

    private fun resolveDirection(samples: List<FrameSample>): AnalysisDirection {
        val hipMovement =
            samples.last().hipCenter.x.toDouble() - samples.first().hipCenter.x.toDouble()
        val averageScale = samples.map { it.bodyScale }.average().coerceAtLeast(1.0)
        return when {
            abs(hipMovement) < averageScale * stationaryThresholdRatio -> {
                AnalysisDirection.stationary
            }
            hipMovement > 0 -> AnalysisDirection.leftToRight
            else -> AnalysisDirection.rightToLeft
        }
    }

    private fun midpoint(first: PointF, second: PointF): PointF =
        PointF(
            (first.x + second.x) / 2f,
            (first.y + second.y) / 2f,
        )

    private fun distance(first: PointF, second: PointF): Double {
        val dx = first.x - second.x
        val dy = first.y - second.y
        return kotlin.math.hypot(dx.toDouble(), dy.toDouble())
    }

    private fun copyPoint(point: PointF): PointF = PointF(point.x, point.y)

    private fun roundTo3(value: Double): Double = (value * 1000.0).roundToInt() / 1000.0

    private data class FrameSample(
        val leftShoulder: PointF,
        val rightShoulder: PointF,
        val leftHip: PointF,
        val rightHip: PointF,
        val leftKnee: PointF,
        val rightKnee: PointF,
        val shoulderCenter: PointF,
        val hipCenter: PointF,
        val leftAnkle: PointF,
        val rightAnkle: PointF,
        val leftHeel: PointF?,
        val rightHeel: PointF?,
        val leftElbow: PointF?,
        val rightElbow: PointF?,
        val leftWrist: PointF?,
        val rightWrist: PointF?,
        val bodyScale: Double,
    ) {
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
                    abs(shoulderCenter.x.toDouble() - hipCenter.x.toDouble())
                }
            }
            if (direction != AnalysisDirection.stationary && forwardOffset <= 0.0) {
                return 0.0
            }
            return Math.toDegrees(atan2(abs(forwardOffset), verticalTravel))
        }

        fun leadFootStrikeRatio(direction: AnalysisDirection): Double {
            val leftFoot = leftHeel ?: leftAnkle
            val rightFoot = rightHeel ?: rightAnkle
            val forwardReachPx = when (direction) {
                AnalysisDirection.leftToRight -> {
                    max(leftFoot.x, rightFoot.x).toDouble() - hipCenter.x.toDouble()
                }
                AnalysisDirection.rightToLeft -> {
                    hipCenter.x.toDouble() - min(leftFoot.x, rightFoot.x).toDouble()
                }
                AnalysisDirection.stationary -> {
                    max(
                        abs(leftFoot.x.toDouble() - hipCenter.x.toDouble()),
                        abs(rightFoot.x.toDouble() - hipCenter.x.toDouble()),
                    )
                }
            }
            return forwardReachPx / bodyScale.coerceAtLeast(1.0)
        }

        fun averageElbowAngleDegrees(): Double? {
            val angles = mutableListOf<Double>()
            if (leftElbow != null && leftWrist != null) {
                angles.add(jointAngle(leftShoulder, leftElbow, leftWrist))
            }
            if (rightElbow != null && rightWrist != null) {
                angles.add(jointAngle(rightShoulder, rightElbow, rightWrist))
            }
            return angles.takeIf { it.isNotEmpty() }?.average()
        }

        fun leadKneeAngleDegrees(direction: AnalysisDirection): Double? {
            val leftFoot = leftHeel ?: leftAnkle
            val rightFoot = rightHeel ?: rightAnkle
            val useLeft = when (direction) {
                AnalysisDirection.leftToRight -> leftFoot.x >= rightFoot.x
                AnalysisDirection.rightToLeft -> leftFoot.x <= rightFoot.x
                AnalysisDirection.stationary -> {
                    abs(leftFoot.x.toDouble() - hipCenter.x.toDouble()) >=
                        abs(rightFoot.x.toDouble() - hipCenter.x.toDouble())
                }
            }
            return if (useLeft) {
                jointAngle(leftHip, leftKnee, leftAnkle)
            } else {
                jointAngle(rightHip, rightKnee, rightAnkle)
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

    private class AnalysisException(
        val code: String,
        override val message: String,
    ) : Exception(message)

    companion object {
        private const val channelName = "football_note/running_pose_analysis"
        private const val methodName = "analyzeRunningVideo"
        private const val sampleCount = 14
        private const val minimumValidFrames = 6
        private const val minVideoDurationMs = 1500L
        private const val minimumLikelihood = 0.45f
        private const val minimumBodyScalePx = 40.0
        private const val mediaPipePoseLandmarkCount = 33
        private const val sampleStartFraction = 0.15
        private const val sampleEndFraction = 0.85
        private const val stationaryThresholdRatio = 0.12
        private const val modelAssetPath = "pose_landmarker_lite.task"
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
    }
}
