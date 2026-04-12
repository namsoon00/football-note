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
import kotlin.math.max
import kotlin.math.min

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
            val strideRatio = topAverage(
                frameSamples.map { it.strideReachRatio(direction) },
            )

            return mapOf(
                "durationMs" to durationMs.toInt(),
                "sampledFrames" to sampleCount,
                "validFrames" to frameSamples.size,
                "direction" to direction.token,
                "forwardLeanDegrees" to roundTo3(leanDegrees),
                "verticalBounceRatio" to roundTo3(bounceRatio.coerceAtLeast(0.0)),
                "strideReachRatio" to roundTo3(strideRatio.coerceAtLeast(0.0)),
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
            shoulderCenter = shoulderCenter,
            hipCenter = hipCenter,
            leftAnkle = copyPoint(leftAnkle.position),
            rightAnkle = copyPoint(rightAnkle.position),
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

    private fun topAverage(values: List<Double>): Double {
        if (values.isEmpty()) {
            return 0.0
        }
        val clipped = values.map { it.coerceAtLeast(0.0) }.sorted()
        val windowSize = max(1, clipped.size / 3)
        return clipped.takeLast(windowSize).average()
    }

    private fun roundTo3(value: Double): Double = (value * 1000.0).toInt() / 1000.0

    private data class FrameSample(
        val shoulderCenter: PointF,
        val hipCenter: PointF,
        val leftAnkle: PointF,
        val rightAnkle: PointF,
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

        fun strideReachRatio(direction: AnalysisDirection): Double {
            val forwardReachPx = when (direction) {
                AnalysisDirection.leftToRight -> {
                    max(leftAnkle.x, rightAnkle.x).toDouble() - hipCenter.x.toDouble()
                }
                AnalysisDirection.rightToLeft -> {
                    hipCenter.x.toDouble() - min(leftAnkle.x, rightAnkle.x).toDouble()
                }
                AnalysisDirection.stationary -> {
                    max(
                        abs(leftAnkle.x.toDouble() - hipCenter.x.toDouble()),
                        abs(rightAnkle.x.toDouble() - hipCenter.x.toDouble()),
                    )
                }
            }
            return forwardReachPx.coerceAtLeast(0.0) / bodyScale.coerceAtLeast(1.0)
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
        private const val sampleCount = 10
        private const val minimumValidFrames = 3
        private const val minVideoDurationMs = 1500L
        private const val minimumLikelihood = 0.45f
        private const val minimumBodyScalePx = 40.0
        private const val sampleStartFraction = 0.15
        private const val sampleEndFraction = 0.85
        private const val stationaryThresholdRatio = 0.12
    }
}
