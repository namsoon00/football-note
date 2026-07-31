package com.namsoon.footballnote

import android.content.Context
import android.graphics.Bitmap
import android.graphics.PointF
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
        var coarsePoseLandmarker: PoseLandmarker? = null
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
            if (durationMs > maxVideoDurationMs) {
                throw AnalysisException(
                    "video_too_long",
                    "Please trim the running clip to 15 seconds or less.",
                )
            }

            val coarseLandmarker = makePoseLandmarker()
            coarsePoseLandmarker = coarseLandmarker
            val coarsePass = runPosePass(
                poseLandmarker = coarseLandmarker,
                retriever = retriever,
                timestampsMs = coarseSampleTimestamps(durationMs),
                collectSharpness = true,
            )
            val frameSamples = coarsePass.samples

            if (frameSamples.size < minimumValidFrames) {
                throw AnalysisException(
                    "no_pose_detected",
                    "We could not detect a clear running pose in this video.",
                )
            }
            if (!hasSufficientSharpness(coarsePass.sharpnessValues)) {
                throw videoTooBlurry()
            }

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
            val candidateSet = if (detectedCandidateSet.windows.isEmpty()) {
                fallbackContactCandidateWindows(frameSamples, durationMs)
            } else {
                detectedCandidateSet
            }
            if (candidateSet.windows.isEmpty()) {
                throw insufficientContactEvidence(
                    "coarseValid=${frameSamples.size}; candidates=0",
                )
            }
            val denseTimestamps = denseTimestampsForContactWindows(
                candidateSet.windows,
                durationMs,
            )
            if (denseTimestamps.isEmpty()) {
                throw insufficientContactEvidence(
                    "coarseValid=${frameSamples.size}; candidates=${candidateSet.windows.size}; dense=0",
                )
            }
            val denseLandmarker = makePoseLandmarker()
            densePoseLandmarker = denseLandmarker
            val densePass = runPosePass(
                poseLandmarker = denseLandmarker,
                retriever = retriever,
                timestampsMs = denseTimestamps,
                collectSharpness = false,
            )
            val contactFrames = validateDenseContactFrames(
                samples = densePass.samples,
                windows = candidateSet.windows,
                groundY = candidateSet.groundY,
                direction = direction,
            )
            val uniqueContactFrameCount = contactFrames
                .map { it.timestampMs }
                .distinct()
                .size
            val usesContactProxy = uniqueContactFrameCount < minimumValidatedContactFrames
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
            if (metricContactFrames.isEmpty()) {
                throw insufficientContactEvidence(
                    "coarseValid=${frameSamples.size}; candidates=${candidateSet.windows.size}; " +
                        "denseValid=${densePass.samples.size}; contacts=$uniqueContactFrameCount; " +
                        "proxySource=$contactProxySource; proxies=0",
                )
            }

            val footStrikeRatio = metricContactFrames
                .map { it.footStrikeRatio }
                .average()
            val kneeAngles = metricContactFrames.map { it.kneeAngleDegrees }
            val elbowAngles = frameSamples.mapNotNull { it.averageElbowAngleDegrees() }
            if (elbowAngles.isEmpty()) {
                throw AnalysisException(
                    "no_pose_detected",
                    "We could not detect a clear running pose in this video.",
                )
            }
            val stanceKneeAngle = kneeAngles.average()
            val elbowAngle = elbowAngles.average()
            val contactConfidence = metricContactFrames
                .map { it.confidence }
                .average()
                .coerceIn(0.0, 1.0)
            val contactQualityReason = if (usesContactProxy) "contact_phase_proxy" else null
            val coreConfidence = frameSamples
                .map { it.coreLandmarkConfidence }
                .average()
            val armConfidenceValues = frameSamples
                .mapNotNull { it.armLandmarkConfidence() }
            val armConfidence = armConfidenceValues.average()

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
                "metricQualities" to mapOf(
                    "posture" to metricQualityPayload(
                        coreConfidence,
                        frameSamples.size,
                    ),
                    "bounce" to metricQualityPayload(
                        coreConfidence,
                        frameSamples.size,
                    ),
                    "footStrike" to metricQualityPayload(
                        contactConfidence,
                        metricContactFrames.size,
                        contactQualityReason,
                    ),
                    "kneeFlexion" to metricQualityPayload(
                        contactConfidence,
                        metricContactFrames.size,
                        contactQualityReason,
                    ),
                    "armCarriage" to metricQualityPayload(
                        armConfidence,
                        armConfidenceValues.size,
                    ),
                ),
                "coarseSamples" to sampleSummaryPayload(
                    attemptedFrames = sampleCount,
                    validFrames = coarsePass.samples.size,
                    poseFrameCount = coarsePass.poseFrames.size,
                ),
                "denseSamples" to sampleSummaryPayload(
                    attemptedFrames = denseTimestamps.size,
                    validFrames = densePass.samples.size,
                    poseFrameCount = densePass.poseFrames.size,
                    maxFrameBudget = maxDenseFrameBudget,
                    targetFps = denseTargetFps,
                ),
                "contactWindows" to contactWindowPayloads(
                    windows = candidateSet.windows,
                    denseTimestamps = denseTimestamps,
                    contactFrames = contactFrames,
                ),
                "validatedContactFrameTimestampsMs" to contactFrames
                    .map { it.timestampMs.toInt() }
                    .distinct()
                    .sorted(),
                "contactConfidence" to roundTo3(contactConfidence),
                "poseFrames" to mergePoseFrames(
                    coarsePass.poseFrames,
                    densePass.poseFrames,
                ),
            )
        } finally {
            retriever.release()
            coarsePoseLandmarker?.close()
            densePoseLandmarker?.close()
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

    private fun coarseSampleTimestamps(durationMs: Long): List<Long> =
        (0 until sampleCount).map { index ->
            val fraction = if (sampleCount == 1) {
                0.5
            } else {
                sampleStartFraction +
                    (sampleEndFraction - sampleStartFraction) *
                    (index.toDouble() / (sampleCount - 1))
            }
            (durationMs.toDouble() * fraction)
                .roundToLong()
                .coerceIn(0L, durationMs)
        }

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

    private fun deriveContactCandidateWindows(
        samples: List<FrameSample>,
        durationMs: Long,
    ): ContactCandidateSet {
        val footBottoms = samples.flatMap { sample ->
            FootSide.values().mapNotNull { side ->
                sample.footBottom(side)?.let { evidence -> sample to evidence }
            }
        }
        val groundY = footBottoms.maxOfOrNull { it.second.bottomPoint.y.toDouble() }
            ?: return ContactCandidateSet(emptyList(), 0.0)
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
                val nearGround = groundY - bottomY <= groundTolerance
                val localExtremum =
                    (previousY == null || bottomY >= previousY - localTolerance) &&
                        (nextY == null || bottomY >= nextY - localTolerance)
                if (!nearGround || !localExtremum) {
                    continue
                }
                val proximityFactor = (
                    1.0 - ((groundY - bottomY).coerceAtLeast(0.0) /
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

        val selected = mutableListOf<ContactCandidate>()
        val rankedCandidates = candidates.sortedWith(
            compareByDescending<ContactCandidate> { it.confidence }
                .thenBy { it.centerTimestampMs },
        )
        for (candidate in rankedCandidates) {
            val overlapsExisting = selected.any { selectedCandidate ->
                selectedCandidate.side == candidate.side &&
                    (
                        abs(selectedCandidate.centerTimestampMs - candidate.centerTimestampMs) <
                            minimumContactCenterSeparationMs ||
                            candidate.startTimestampMs <= selectedCandidate.endTimestampMs &&
                            candidate.endTimestampMs >= selectedCandidate.startTimestampMs
                        )
            }
            if (!overlapsExisting) {
                selected.add(candidate)
            }
            if (selected.size >= maxContactWindows) {
                break
            }
        }

        return ContactCandidateSet(
            windows = selected.sortedBy { it.centerTimestampMs },
            groundY = groundY,
        )
    }

    private fun fallbackContactCandidateWindows(
        samples: List<FrameSample>,
        durationMs: Long,
    ): ContactCandidateSet {
        val footBottoms = samples.flatMap { sample ->
            FootSide.values().mapNotNull { side ->
                sample.footBottom(side)?.let { evidence -> sample to evidence }
            }
        }
        val groundY = footBottoms.maxOfOrNull { it.second.bottomPoint.y.toDouble() }
            ?: return ContactCandidateSet(emptyList(), 0.0)
        val windows = FootSide.values().mapNotNull { side ->
            val candidate = samples
                .mapNotNull { sample ->
                    sample.footBottom(side)?.let { evidence -> sample to evidence }
                }
                .maxByOrNull { it.second.bottomPoint.y }
                ?: return@mapNotNull null
            val (sample, evidence) = candidate
            ContactCandidate(
                side = side,
                centerTimestampMs = sample.timestampMs,
                startTimestampMs = max(0L, sample.timestampMs - denseWindowRadiusMs),
                endTimestampMs = min(durationMs, sample.timestampMs + denseWindowRadiusMs),
                confidence = evidence.confidence.coerceIn(0.0, 1.0),
            )
        }
        return ContactCandidateSet(
            windows = windows.sortedBy { it.centerTimestampMs },
            groundY = groundY,
        )
    }

    private fun denseTimestampsForContactWindows(
        windows: List<ContactCandidate>,
        durationMs: Long,
    ): List<Long> {
        val timestampDistances = mutableMapOf<Long, Long>()
        for (window in windows) {
            var timestampMs = window.startTimestampMs
            while (timestampMs <= window.endTimestampMs) {
                recordDenseTimestamp(
                    timestampDistances,
                    timestampMs.coerceIn(0L, durationMs),
                    window.centerTimestampMs,
                )
                timestampMs += denseFrameIntervalMs
            }
            recordDenseTimestamp(
                timestampDistances,
                window.centerTimestampMs.coerceIn(0L, durationMs),
                window.centerTimestampMs,
            )
        }
        return timestampDistances.entries
            .sortedWith(compareBy<Map.Entry<Long, Long>> { it.value }.thenBy { it.key })
            .take(maxDenseFrameBudget)
            .map { it.key }
            .toSet()
            .sorted()
    }

    private fun recordDenseTimestamp(
        timestampDistances: MutableMap<Long, Long>,
        timestampMs: Long,
        centerTimestampMs: Long,
    ) {
        val distance = abs(timestampMs - centerTimestampMs)
        val existing = timestampDistances[timestampMs]
        if (existing == null || distance < existing) {
            timestampDistances[timestampMs] = distance
        }
    }

    private fun validateDenseContactFrames(
        samples: List<FrameSample>,
        windows: List<ContactCandidate>,
        groundY: Double,
        direction: AnalysisDirection,
    ): List<ContactFrameAnalysis> {
        val orderedSamples = samples.sortedBy { it.timestampMs }
        val selectedByTimestamp = TreeMap<Long, ContactFrameAnalysis>()
        for (window in windows.sortedBy { it.centerTimestampMs }) {
            val contactFrame = selectDenseContactFrame(
                window = window,
                orderedSamples = orderedSamples,
                groundY = groundY,
                direction = direction,
            ) ?: continue
            val existing = selectedByTimestamp[contactFrame.timestampMs]
            if (existing == null || contactFrame.confidence > existing.confidence) {
                selectedByTimestamp[contactFrame.timestampMs] = contactFrame
            }
        }
        return selectedByTimestamp.values.toList()
    }

    private fun contactProxyFrames(
        samples: List<FrameSample>,
        windows: List<ContactCandidate>,
        direction: AnalysisDirection,
        confidencePenalty: Double,
    ): List<ContactFrameAnalysis> {
        val selectedByTimestamp = TreeMap<Long, ContactFrameAnalysis>()
        for (window in windows.sortedBy { it.centerTimestampMs }) {
            val candidate = samples
                .asSequence()
                .filter { sample ->
                    sample.timestampMs >= window.startTimestampMs &&
                        sample.timestampMs <= window.endTimestampMs
                }
                .mapNotNull { sample ->
                    sample.footBottom(window.side)?.let { evidence -> sample to evidence }
                }
                .sortedWith(
                    compareBy<Pair<FrameSample, FootBottomEvidence>> {
                        abs(it.first.timestampMs - window.centerTimestampMs)
                    }.thenBy { it.first.timestampMs },
                )
                .firstOrNull() ?: continue
            val (sample, evidence) = candidate
            val confidence = (
                min(window.confidence, sample.contactLandmarkConfidence(window.side, evidence)) *
                    confidencePenalty
                ).coerceIn(0.0, 1.0)
            val proxy = ContactFrameAnalysis(
                timestampMs = sample.timestampMs,
                windowCenterTimestampMs = window.centerTimestampMs,
                side = window.side,
                footStrikeRatio = sample.contactFootStrikeRatio(window.side, direction),
                kneeAngleDegrees = sample.contactKneeAngleDegrees(window.side),
                confidence = confidence,
            )
            val existing = selectedByTimestamp[proxy.timestampMs]
            if (existing == null || proxy.confidence > existing.confidence) {
                selectedByTimestamp[proxy.timestampMs] = proxy
            }
        }
        return selectedByTimestamp.values.toList()
    }

    private fun selectDenseContactFrame(
        window: ContactCandidate,
        orderedSamples: List<FrameSample>,
        groundY: Double,
        direction: AnalysisDirection,
    ): ContactFrameAnalysis? {
        val candidates = orderedSamples
            .filter { sample ->
                sample.timestampMs >= window.startTimestampMs &&
                    sample.timestampMs <= window.endTimestampMs
            }
            .mapNotNull { sample ->
                denseContactCandidate(sample, window.side, groundY)
            }
        val eligibleCandidates = mutableListOf<ContactFrameCandidate>()
        val persistentCandidates = mutableListOf<ContactFrameCandidate>()
        for (index in candidates.indices) {
            val current = candidates[index]
            if (!current.isEligibleContact()) {
                continue
            }
            eligibleCandidates.add(current)
            val previous = candidates.getOrNull(index - 1)
            val next = candidates.getOrNull(index + 1)
            if (enteredGroundBand(current, previous)) {
                return current.toContactFrame(window, direction)
            }
            if (hasGroundBandPersistence(current, previous, next)) {
                persistentCandidates.add(current)
            }
        }
        val candidatesForSelection = if (persistentCandidates.isEmpty()) {
            eligibleCandidates
        } else {
            persistentCandidates
        }
        return candidatesForSelection
            .sortedWith(
                compareByDescending<ContactFrameCandidate> { it.confidence }
                    .thenBy { abs(it.sample.timestampMs - window.centerTimestampMs) }
                    .thenBy { it.sample.timestampMs },
            )
            .firstOrNull()
            ?.toContactFrame(window, direction)
    }

    private fun denseContactCandidate(
        sample: FrameSample,
        side: FootSide,
        groundY: Double,
    ): ContactFrameCandidate? {
        val evidence = sample.footBottom(side) ?: return null
        val tolerance = (sample.bodyScale * denseContactGroundToleranceRatio)
            .coerceAtLeast(1.0)
        val proximity = groundY - evidence.bottomPoint.y.toDouble()
        val inGroundBand = proximity >= -tolerance * 0.35 && proximity <= tolerance
        val proximityFactor = (
            1.0 - (proximity.coerceAtLeast(0.0) / tolerance)
            ).coerceIn(0.0, 1.0)
        val confidence = (
            sample.contactLandmarkConfidence(side, evidence) *
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
            denseFrameIntervalMs * 2

    private fun hasGroundBandPersistence(
        current: ContactFrameCandidate,
        previous: ContactFrameCandidate?,
        next: ContactFrameCandidate?,
    ): Boolean =
        listOfNotNull(previous, next).any { neighbor ->
            neighbor.isEligibleContact() &&
                abs(neighbor.sample.timestampMs - current.sample.timestampMs) <=
                denseFrameIntervalMs * 2
        }

    private fun ContactFrameCandidate.toContactFrame(
        window: ContactCandidate,
        direction: AnalysisDirection,
    ): ContactFrameAnalysis =
        ContactFrameAnalysis(
            timestampMs = sample.timestampMs,
            windowCenterTimestampMs = window.centerTimestampMs,
            side = side,
            footStrikeRatio = sample.contactFootStrikeRatio(side, direction),
            kneeAngleDegrees = sample.contactKneeAngleDegrees(side),
            confidence = confidence,
        )

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

    private fun contactWindowPayloads(
        windows: List<ContactCandidate>,
        denseTimestamps: List<Long>,
        contactFrames: List<ContactFrameAnalysis>,
    ): List<Map<String, Any?>> =
        windows.map { window ->
            val validated = contactFrames.filter { frame ->
                frame.side == window.side &&
                    frame.windowCenterTimestampMs == window.centerTimestampMs &&
                    frame.timestampMs >= window.startTimestampMs &&
                    frame.timestampMs <= window.endTimestampMs
            }
            mapOf(
                "side" to window.side.token,
                "startTimestampMs" to window.startTimestampMs.toInt(),
                "centerTimestampMs" to window.centerTimestampMs.toInt(),
                "endTimestampMs" to window.endTimestampMs.toInt(),
                "coarseConfidence" to roundTo3(window.confidence),
                "denseSampleCount" to denseTimestamps.count { timestampMs ->
                    timestampMs >= window.startTimestampMs &&
                        timestampMs <= window.endTimestampMs
                },
                "validatedContactFrameTimestampsMs" to validated
                    .map { it.timestampMs.toInt() }
                    .distinct()
                    .sorted(),
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

        val leftShoulder =
            confidentLandmarkPoint(
                landmarks,
                leftShoulderIndex,
                imageWidth,
                imageHeight,
            ) ?: return null
        val rightShoulder =
            confidentLandmarkPoint(
                landmarks,
                rightShoulderIndex,
                imageWidth,
                imageHeight,
            ) ?: return null
        val leftHip =
            confidentLandmarkPoint(
                landmarks,
                leftHipIndex,
                imageWidth,
                imageHeight,
            ) ?: return null
        val rightHip =
            confidentLandmarkPoint(
                landmarks,
                rightHipIndex,
                imageWidth,
                imageHeight,
            ) ?: return null
        val leftKnee =
            confidentLandmarkPoint(
                landmarks,
                leftKneeIndex,
                imageWidth,
                imageHeight,
            ) ?: return null
        val rightKnee =
            confidentLandmarkPoint(
                landmarks,
                rightKneeIndex,
                imageWidth,
                imageHeight,
            ) ?: return null
        val leftAnkle =
            confidentLandmarkPoint(
                landmarks,
                leftAnkleIndex,
                imageWidth,
                imageHeight,
            ) ?: return null
        val rightAnkle =
            confidentLandmarkPoint(
                landmarks,
                rightAnkleIndex,
                imageWidth,
                imageHeight,
            ) ?: return null

        val shoulderCenter = midpoint(leftShoulder.point, rightShoulder.point)
        val hipCenter = midpoint(leftHip.point, rightHip.point)
        val ankleCenter = midpoint(leftAnkle.point, rightAnkle.point)
        val torsoScale = distance(shoulderCenter, hipCenter)
        val legScale = distance(hipCenter, ankleCenter)
        val bodyScale = max(torsoScale, legScale)
        if (bodyScale < minimumBodyScalePx) {
            return null
        }

        return FrameSample(
            timestampMs = timestampMs,
            leftShoulder = copyPoint(leftShoulder.point),
            rightShoulder = copyPoint(rightShoulder.point),
            leftHip = copyPoint(leftHip.point),
            rightHip = copyPoint(rightHip.point),
            leftKnee = copyPoint(leftKnee.point),
            rightKnee = copyPoint(rightKnee.point),
            shoulderCenter = shoulderCenter,
            hipCenter = hipCenter,
            leftAnkle = copyPoint(leftAnkle.point),
            rightAnkle = copyPoint(rightAnkle.point),
            leftHeel =
                confidentLandmarkPoint(landmarks, leftHeelIndex, imageWidth, imageHeight)
                    ?.point
                    ?.let(::copyPoint),
            rightHeel =
                confidentLandmarkPoint(landmarks, rightHeelIndex, imageWidth, imageHeight)
                    ?.point
                    ?.let(::copyPoint),
            leftToe =
                confidentLandmarkPoint(landmarks, leftFootIndex, imageWidth, imageHeight)
                    ?.point
                    ?.let(::copyPoint),
            rightToe =
                confidentLandmarkPoint(landmarks, rightFootIndex, imageWidth, imageHeight)
                    ?.point
                    ?.let(::copyPoint),
            leftElbow =
                confidentLandmarkPoint(landmarks, leftElbowIndex, imageWidth, imageHeight)
                    ?.point
                    ?.let(::copyPoint),
            rightElbow =
                confidentLandmarkPoint(landmarks, rightElbowIndex, imageWidth, imageHeight)
                    ?.point
                    ?.let(::copyPoint),
            leftWrist =
                confidentLandmarkPoint(landmarks, leftWristIndex, imageWidth, imageHeight)
                    ?.point
                    ?.let(::copyPoint),
            rightWrist =
                confidentLandmarkPoint(landmarks, rightWristIndex, imageWidth, imageHeight)
                    ?.point
                    ?.let(::copyPoint),
            leftShoulderConfidence = leftShoulder.confidence,
            rightShoulderConfidence = rightShoulder.confidence,
            leftHipConfidence = leftHip.confidence,
            rightHipConfidence = rightHip.confidence,
            leftKneeConfidence = leftKnee.confidence,
            rightKneeConfidence = rightKnee.confidence,
            leftAnkleConfidence = leftAnkle.confidence,
            rightAnkleConfidence = rightAnkle.confidence,
            leftHeelConfidence =
                confidentLandmarkPoint(landmarks, leftHeelIndex, imageWidth, imageHeight)
                    ?.confidence,
            rightHeelConfidence =
                confidentLandmarkPoint(landmarks, rightHeelIndex, imageWidth, imageHeight)
                    ?.confidence,
            leftToeConfidence =
                confidentLandmarkPoint(landmarks, leftFootIndex, imageWidth, imageHeight)
                    ?.confidence,
            rightToeConfidence =
                confidentLandmarkPoint(landmarks, rightFootIndex, imageWidth, imageHeight)
                    ?.confidence,
            leftElbowConfidence =
                confidentLandmarkPoint(landmarks, leftElbowIndex, imageWidth, imageHeight)
                    ?.confidence,
            rightElbowConfidence =
                confidentLandmarkPoint(landmarks, rightElbowIndex, imageWidth, imageHeight)
                    ?.confidence,
            leftWristConfidence =
                confidentLandmarkPoint(landmarks, leftWristIndex, imageWidth, imageHeight)
                    ?.confidence,
            rightWristConfidence =
                confidentLandmarkPoint(landmarks, rightWristIndex, imageWidth, imageHeight)
                    ?.confidence,
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
        val groundY: Double,
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

    private data class FrameSample(
        val timestampMs: Long,
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
        val leftToe: PointF?,
        val rightToe: PointF?,
        val leftElbow: PointF?,
        val rightElbow: PointF?,
        val leftWrist: PointF?,
        val rightWrist: PointF?,
        val leftShoulderConfidence: Double,
        val rightShoulderConfidence: Double,
        val leftHipConfidence: Double,
        val rightHipConfidence: Double,
        val leftKneeConfidence: Double,
        val rightKneeConfidence: Double,
        val leftAnkleConfidence: Double,
        val rightAnkleConfidence: Double,
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
        val coreLandmarkConfidence: Double
            get() = listOf(
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
            if (leftElbowConfidence != null && leftWristConfidence != null) {
                confidences.add(
                    listOf(leftShoulderConfidence, leftElbowConfidence, leftWristConfidence)
                        .average(),
                )
            }
            if (rightElbowConfidence != null && rightWristConfidence != null) {
                confidences.add(
                    listOf(rightShoulderConfidence, rightElbowConfidence, rightWristConfidence)
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

        fun footBottom(side: FootSide): FootBottomEvidence? {
            val ankle = when (side) {
                FootSide.left -> leftAnkle
                FootSide.right -> rightAnkle
            }
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
                .minOrNull() ?: ankleConfidence
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

        fun contactKneeAngleDegrees(side: FootSide): Double =
            when (side) {
                FootSide.left -> jointAngle(leftHip, leftKnee, leftAnkle)
                FootSide.right -> jointAngle(rightHip, rightKnee, rightAnkle)
            }

        fun contactLandmarkConfidence(
            side: FootSide,
            footEvidence: FootBottomEvidence,
        ): Double {
            val hipConfidence = when (side) {
                FootSide.left -> leftHipConfidence
                FootSide.right -> rightHipConfidence
            }
            val kneeConfidence = when (side) {
                FootSide.left -> leftKneeConfidence
                FootSide.right -> rightKneeConfidence
            }
            return min(footEvidence.confidence, min(hipConfidence, kneeConfidence))
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
        private const val sampleCount = 14
        private const val minimumValidFrames = 6
        private const val minimumSharpnessSampleCount = 6
        private const val minimumMedianSharpness = 0.018
        private const val sharpnessHorizontalInsetFraction = 0.10
        private const val sharpnessTopFraction = 0.32
        private const val sharpnessBottomFraction = 0.68
        private const val sharpnessSampleWidth = 96
        private const val sharpnessSampleHeight = 64
        private const val minVideoDurationMs = 1500L
        private const val maxVideoDurationMs = 15000L
        private const val minimumLikelihood = 0.35f
        private const val minimumBodyScalePx = 40.0
        private const val mediaPipePoseLandmarkCount = 33
        private const val sampleStartFraction = 0.15
        private const val sampleEndFraction = 0.85
        private const val stationaryThresholdRatio = 0.12
        private const val denseTargetFps = 30
        private const val denseFrameIntervalMs = 33L
        private const val denseWindowRadiusMs = 180L
        private const val maxDenseFrameBudget = 48
        private const val maxContactWindows = 6
        private const val minimumContactCenterSeparationMs = 120L
        private const val minimumValidatedContactFrames = 3
        private const val minimumContactFrameConfidence = 0.34
        private const val contactProxyConfidencePenalty = 0.60
        private const val coarseContactProxyConfidencePenalty = 0.42
        private const val coarseContactGroundToleranceRatio = 0.12
        private const val denseContactGroundToleranceRatio = 0.13
        private const val localFootExtremumToleranceRatio = 0.025
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
