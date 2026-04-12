package com.namsoon.footballnote

import android.graphics.PointF
import android.media.MediaMetadataRetriever
import android.os.Handler
import android.os.Looper
import com.google.android.gms.tasks.Tasks
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.pose.Pose
import com.google.mlkit.vision.pose.PoseDetection
import com.google.mlkit.vision.pose.PoseLandmark
import com.google.mlkit.vision.pose.defaults.PoseDetectorOptions
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import kotlin.math.abs
import kotlin.math.atan2
import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

class RunningPoseAnalysisChannel(
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

    private fun analyzeVideo(path: String): Map<String, Any> {
        val file = File(path)
        if (!file.exists()) {
            throw AnalysisException("missing_file", "Video file is missing.")
        }

        val retriever = MediaMetadataRetriever()
        val options = PoseDetectorOptions.Builder()
            .setDetectorMode(PoseDetectorOptions.STREAM_MODE)
            .build()
        val detector = PoseDetection.getClient(options)

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

            val frameSamples = mutableListOf<FrameSample>()
            repeat(sampleCount) { index ->
                val fraction = if (sampleCount == 1) {
                    0.5
                } else {
                    sampleStartFraction +
                        (sampleEndFraction - sampleStartFraction) *
                        (index.toDouble() / (sampleCount - 1))
                }
                val timeUs = (durationMs * 1000.0 * fraction).toLong()
                val bitmap = retriever.getFrameAtTime(
                    timeUs,
                    MediaMetadataRetriever.OPTION_CLOSEST,
                ) ?: return@repeat
                try {
                    val pose = Tasks.await(detector.process(InputImage.fromBitmap(bitmap, 0)))
                    extractFrameSample(pose)?.let(frameSamples::add)
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
            )
        } finally {
            retriever.release()
            detector.close()
        }
    }

    private fun extractFrameSample(pose: Pose): FrameSample? {
        val leftShoulder = confidentLandmark(pose, PoseLandmark.LEFT_SHOULDER) ?: return null
        val rightShoulder = confidentLandmark(pose, PoseLandmark.RIGHT_SHOULDER) ?: return null
        val leftHip = confidentLandmark(pose, PoseLandmark.LEFT_HIP) ?: return null
        val rightHip = confidentLandmark(pose, PoseLandmark.RIGHT_HIP) ?: return null
        val leftKnee = confidentLandmark(pose, PoseLandmark.LEFT_KNEE) ?: return null
        val rightKnee = confidentLandmark(pose, PoseLandmark.RIGHT_KNEE) ?: return null
        val leftAnkle = confidentLandmark(pose, PoseLandmark.LEFT_ANKLE) ?: return null
        val rightAnkle = confidentLandmark(pose, PoseLandmark.RIGHT_ANKLE) ?: return null

        val shoulderCenter = midpoint(leftShoulder.position, rightShoulder.position)
        val hipCenter = midpoint(leftHip.position, rightHip.position)
        val ankleCenter = midpoint(leftAnkle.position, rightAnkle.position)
        val torsoScale = distance(shoulderCenter, hipCenter)
        val legScale = distance(hipCenter, ankleCenter)
        val bodyScale = max(torsoScale, legScale)
        if (bodyScale < minimumBodyScalePx) {
            return null
        }

        return FrameSample(
            leftShoulder = copyPoint(leftShoulder.position),
            rightShoulder = copyPoint(rightShoulder.position),
            leftHip = copyPoint(leftHip.position),
            rightHip = copyPoint(rightHip.position),
            leftKnee = copyPoint(leftKnee.position),
            rightKnee = copyPoint(rightKnee.position),
            shoulderCenter = shoulderCenter,
            hipCenter = hipCenter,
            leftAnkle = copyPoint(leftAnkle.position),
            rightAnkle = copyPoint(rightAnkle.position),
            leftHeel = confidentLandmark(pose, PoseLandmark.LEFT_HEEL)?.let { copyPoint(it.position) },
            rightHeel = confidentLandmark(pose, PoseLandmark.RIGHT_HEEL)?.let { copyPoint(it.position) },
            leftElbow = confidentLandmark(pose, PoseLandmark.LEFT_ELBOW)?.let { copyPoint(it.position) },
            rightElbow = confidentLandmark(pose, PoseLandmark.RIGHT_ELBOW)?.let { copyPoint(it.position) },
            leftWrist = confidentLandmark(pose, PoseLandmark.LEFT_WRIST)?.let { copyPoint(it.position) },
            rightWrist = confidentLandmark(pose, PoseLandmark.RIGHT_WRIST)?.let { copyPoint(it.position) },
            bodyScale = bodyScale,
        )
    }

    private fun confidentLandmark(pose: Pose, type: Int): PoseLandmark? =
        pose.getPoseLandmark(type)?.takeIf { it.inFrameLikelihood >= minimumLikelihood }

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
        private const val sampleStartFraction = 0.15
        private const val sampleEndFraction = 0.85
        private const val stationaryThresholdRatio = 0.12
    }
}
