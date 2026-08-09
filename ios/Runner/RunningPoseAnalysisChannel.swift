import AVFoundation
import CoreMedia
import Flutter
import MediaPipeTasksVision
import UIKit

final class RunningPoseAnalysisChannel {
  private let channel: FlutterMethodChannel
  private let queue = DispatchQueue(
    label: "com.namsoon.footballnote.running-pose-analysis",
    qos: .userInitiated
  )

  init(binaryMessenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: Self.channelName,
      binaryMessenger: binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call: call, result: result)
    }
  }

  deinit {
    channel.setMethodCallHandler(nil)
  }

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case Self.methodName:
      guard
        let arguments = call.arguments as? [String: Any],
        let path = arguments["path"] as? String,
        !path.isEmpty
      else {
        result(FlutterError(code: "missing_file", message: "Video file is missing.", details: nil))
        return
      }
      queue.async {
        do {
          let analysis = try self.analyzeVideo(at: path)
          DispatchQueue.main.async {
            result(analysis)
          }
        } catch let error as AnalysisError {
          DispatchQueue.main.async {
            result(FlutterError(code: error.code, message: error.message, details: nil))
          }
        } catch {
          DispatchQueue.main.async {
            result(
              FlutterError(
                code: "analysis_failed",
                message: error.localizedDescription,
                details: nil
              )
            )
          }
        }
      }
    case Self.evidenceFramesMethodName:
      guard
        let arguments = call.arguments as? [String: Any],
        let path = arguments["path"] as? String,
        !path.isEmpty
      else {
        result(FlutterError(code: "missing_file", message: "Video file is missing.", details: nil))
        return
      }
      let timestamps = (arguments["timestampsMs"] as? [NSNumber])?.map(\.intValue) ?? []
      let maximumDimension = (arguments["maxDimension"] as? NSNumber)?.intValue ?? 640
      queue.async {
        do {
          let frames = try self.extractEvidenceFrames(
            at: path,
            timestampsMs: timestamps,
            maximumDimension: maximumDimension
          )
          DispatchQueue.main.async {
            result(frames)
          }
        } catch let error as AnalysisError {
          DispatchQueue.main.async {
            result(FlutterError(code: error.code, message: error.message, details: nil))
          }
        } catch {
          DispatchQueue.main.async {
            result(
              FlutterError(
                code: "evidence_frame_failed",
                message: error.localizedDescription,
                details: nil
              )
            )
          }
        }
      }
    case Self.liveFrameMethodName:
      queue.async {
        do {
          let frame = try self.analyzeLiveFrame(arguments: call.arguments as? [String: Any])
          DispatchQueue.main.async {
            result(frame)
          }
        } catch let error as AnalysisError {
          DispatchQueue.main.async {
            result(FlutterError(code: error.code, message: error.message, details: nil))
          }
        } catch {
          DispatchQueue.main.async {
            result(
              FlutterError(
                code: "live_pose_failed",
                message: error.localizedDescription,
                details: nil
              )
            )
          }
        }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func analyzeLiveFrame(arguments: [String: Any]?) throws -> [String: Any]? {
    guard let arguments else {
      throw AnalysisError(code: "live_pose_invalid_frame", message: "Live camera frame data is missing.")
    }
    guard
      let width = (arguments["width"] as? NSNumber)?.intValue,
      let height = (arguments["height"] as? NSNumber)?.intValue,
      width > 0,
      height > 0,
      let format = arguments["format"] as? String,
      let planes = arguments["planes"] as? [[String: Any]]
    else {
      throw AnalysisError(code: "live_pose_invalid_frame", message: "Live camera frame dimensions are invalid.")
    }
    guard format == "bgra8888" else {
      throw AnalysisError(
        code: "live_pose_unsupported",
        message: "Live camera frame format is not supported: \(format)."
      )
    }
    let rotationDegrees = ((arguments["rotationDegrees"] as? NSNumber)?.intValue ?? 0) % 360
    let isFrontCamera = (arguments["isFrontCamera"] as? NSNumber)?.boolValue ??
      (arguments["isFrontCamera"] as? Bool ?? false)
    let maximumDimension = min(
      640,
      max(160, (arguments["maxDimension"] as? NSNumber)?.intValue ?? 360)
    )
    let image = try liveImage(
      width: width,
      height: height,
      planes: planes,
      rotationDegrees: rotationDegrees,
      mirrored: isFrontCamera,
      maximumDimension: maximumDimension
    )
    let poseLandmarker = try makePoseLandmarker(runningMode: .image)
    let mpImage = try MPImage(uiImage: image)
    let pose: PoseLandmarkerResult
    do {
      pose = try poseLandmarker.detect(image: mpImage)
    } catch {
      throw mediaPipeFailure(
        error,
        fallbackMessage: "MediaPipe pose inference failed."
      )
    }
    return poseFrame(
      from: pose,
      timestampMs: 0,
      imageSize: image.size
    )
  }

  private func liveImage(
    width: Int,
    height: Int,
    planes: [[String: Any]],
    rotationDegrees: Int,
    mirrored: Bool,
    maximumDimension: Int
  ) throws -> UIImage {
    guard
      let firstPlane = planes.first,
      let typedData = firstPlane["bytes"] as? FlutterStandardTypedData
    else {
      throw AnalysisError(code: "live_pose_invalid_frame", message: "BGRA plane is missing.")
    }
    let bytesPerRow = (firstPlane["bytesPerRow"] as? NSNumber)?.intValue ?? width * 4
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo(
      rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue |
        CGBitmapInfo.byteOrder32Little.rawValue
    )
    guard
      let provider = CGDataProvider(data: typedData.data as CFData),
      let cgImage = CGImage(
        width: width,
        height: height,
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: bitmapInfo,
        provider: provider,
        decode: nil,
        shouldInterpolate: true,
        intent: .defaultIntent
      )
    else {
      throw AnalysisError(code: "live_pose_invalid_frame", message: "BGRA image could not be decoded.")
    }
    let source = UIImage(cgImage: cgImage)
    let normalized = normalizeLiveImage(
      source,
      rotationDegrees: rotationDegrees,
      mirrored: mirrored
    )
    return resizedImage(normalized, maximumDimension: maximumDimension)
  }

  private func normalizeLiveImage(
    _ image: UIImage,
    rotationDegrees: Int,
    mirrored: Bool
  ) -> UIImage {
    let normalizedRotation = ((rotationDegrees % 360) + 360) % 360
    guard normalizedRotation != 0 || mirrored else {
      return image
    }
    let sourceSize = image.size
    let swapsAxes = normalizedRotation == 90 || normalizedRotation == 270
    let targetSize = swapsAxes
      ? CGSize(width: sourceSize.height, height: sourceSize.width)
      : sourceSize
    let renderer = UIGraphicsImageRenderer(size: targetSize)
    return renderer.image { context in
      let cgContext = context.cgContext
      cgContext.translateBy(x: targetSize.width / 2, y: targetSize.height / 2)
      if mirrored {
        cgContext.scaleBy(x: -1, y: 1)
      }
      cgContext.rotate(by: CGFloat(normalizedRotation) * .pi / 180.0)
      image.draw(
        in: CGRect(
          x: -sourceSize.width / 2,
          y: -sourceSize.height / 2,
          width: sourceSize.width,
          height: sourceSize.height
        )
      )
    }
  }

  private func extractEvidenceFrames(
    at path: String,
    timestampsMs: [Int],
    maximumDimension: Int
  ) throws -> [[String: Any]] {
    guard FileManager.default.fileExists(atPath: path) else {
      throw AnalysisError(code: "missing_file", message: "Video file is missing.")
    }
    let uniqueTimestamps = Array(Set(timestampsMs.filter { $0 >= 0 })).sorted()
    guard !uniqueTimestamps.isEmpty else { return [] }
    let asset = AVAsset(url: URL(fileURLWithPath: path))
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    generator.requestedTimeToleranceBefore = .zero
    generator.requestedTimeToleranceAfter = .zero
    let safeMaximumDimension = max(160, min(maximumDimension, 960))
    var frames = [[String: Any]]()
    for timestampMs in uniqueTimestamps {
      let time = CMTime(value: CMTimeValue(timestampMs), timescale: 1000)
      guard let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) else {
        continue
      }
      let image = UIImage(cgImage: cgImage)
      let scaled = resizedImage(image, maximumDimension: safeMaximumDimension)
      guard let jpeg = scaled.jpegData(compressionQuality: 0.72) else { continue }
      frames.append([
        "timestampMs": timestampMs,
        "bytes": FlutterStandardTypedData(bytes: jpeg),
        "width": Int(scaled.size.width.rounded()),
        "height": Int(scaled.size.height.rounded())
      ])
    }
    return frames
  }

  private func resizedImage(_ image: UIImage, maximumDimension: Int) -> UIImage {
    let sourceSize = image.size
    let longestSide = max(sourceSize.width, sourceSize.height)
    guard longestSide > CGFloat(maximumDimension), longestSide > 0 else {
      return image
    }
    let scale = CGFloat(maximumDimension) / longestSide
    let targetSize = CGSize(
      width: max(1, (sourceSize.width * scale).rounded()),
      height: max(1, (sourceSize.height * scale).rounded())
    )
    let renderer = UIGraphicsImageRenderer(size: targetSize)
    return renderer.image { _ in
      image.draw(in: CGRect(origin: .zero, size: targetSize))
    }
  }

  private func analyzeVideo(at path: String) throws -> [String: Any] {
    guard FileManager.default.fileExists(atPath: path) else {
      throw AnalysisError(code: "missing_file", message: "Video file is missing.")
    }

    let asset = AVAsset(url: URL(fileURLWithPath: path))
    let durationSeconds = CMTimeGetSeconds(asset.duration)
    guard durationSeconds.isFinite, durationSeconds > 0 else {
      throw AnalysisError(code: "video_too_short", message: "The selected video is too short.")
    }

    let durationMs = Int((durationSeconds * 1000.0).rounded())
    guard durationMs >= Self.minVideoDurationMs else {
      throw AnalysisError(
        code: "video_too_short",
        message: "Please select a running clip that is at least 1.5 seconds long."
      )
    }
    guard durationMs <= Self.maxVideoDurationMs else {
      throw AnalysisError(
        code: "video_too_long",
        message: "Please trim the running clip to 60 seconds or less."
      )
    }

    let imageGenerator = AVAssetImageGenerator(asset: asset)
    imageGenerator.appliesPreferredTrackTransform = true
    imageGenerator.requestedTimeToleranceBefore = .zero
    imageGenerator.requestedTimeToleranceAfter = .zero

    let coarsePoseLandmarker = try makePoseLandmarker()
    let coarseFrameTimestamps = coarseSampleTimestamps(durationMs: durationMs)
    let coarsePass = try runPosePass(
      poseLandmarker: coarsePoseLandmarker,
      imageGenerator: imageGenerator,
      timestampsMs: coarseFrameTimestamps,
      collectSharpness: true
    )
    let frameSamples = coarsePass.samples

    guard frameSamples.count >= Self.minimumValidFrames else {
      throw AnalysisError(
        code: "no_pose_detected",
        message: "We could not detect a clear running pose in this video."
      )
    }
    guard hasSufficientSharpness(coarsePass.sharpnessValues) else {
      throw videoTooBlurry()
    }

    let perspectiveQuality = perspectiveQualityPayload(from: frameSamples)
    let direction = resolveDirection(from: frameSamples)
    let leanDegrees =
      frameSamples.map { $0.forwardLeanDegrees(direction: direction) }.reduce(0, +) /
      Double(frameSamples.count)
    let normalizedShoulderYs = frameSamples.map {
      Double($0.shoulderCenter.y) / max($0.bodyScale, 1.0)
    }
    let bounceRatio: Double
    if let lower = percentile(normalizedShoulderYs, fraction: 0.10),
      let upper = percentile(normalizedShoulderYs, fraction: 0.90)
    {
      bounceRatio = max(0, upper - lower)
    } else {
      bounceRatio = 0
    }
    let detectedCandidateSet = deriveContactCandidateWindows(
      from: frameSamples,
      durationMs: durationMs
    )
    let fallbackCandidateSet = fallbackContactCandidateWindows(
      from: frameSamples,
      durationMs: durationMs
    )
    let candidateSet = mergeContactCandidateSets(
      detected: detectedCandidateSet,
      fallback: fallbackCandidateSet
    )
    guard !candidateSet.windows.isEmpty else {
      throw insufficientContactEvidence(
        "coarseValid=\(frameSamples.count); candidates=0"
      )
    }
    let denseTimestamps = denseTimestampsForContactWindows(
      candidateSet.windows,
      durationMs: durationMs
    )
    guard !denseTimestamps.isEmpty else {
      throw insufficientContactEvidence(
        "coarseValid=\(frameSamples.count); candidates=\(candidateSet.windows.count); dense=0"
      )
    }
    let densePoseLandmarker = try makePoseLandmarker()
    let densePass = try runPosePass(
      poseLandmarker: densePoseLandmarker,
      imageGenerator: imageGenerator,
      timestampsMs: denseTimestamps,
      collectSharpness: false
    )
    let contactValidations = validateDenseContactFrames(
      densePass.samples,
      windows: candidateSet.windows,
      groundLine: candidateSet.groundLine,
      direction: direction
    )
    let contactFrames = contactValidations.compactMap(\.contact)
    let uniqueContactFrameCount = Set(contactFrames.map(\.timestampMs)).count
    let usesKinematicContactEstimate = contactFrames.contains {
      $0.isKinematicEstimate
    }
    // One confirmed contact is still useful as an observed frame, although it
    // remains below the three-step threshold for coaching or cadence. Use a
    // phase proxy only when no continuous contact event was confirmed.
    let usesContactProxy = uniqueContactFrameCount == 0
    let hasCompleteContactSample =
      uniqueContactFrameCount >= Self.minimumValidatedContactFrames
    let denseContactProxyFrames: [ContactFrameAnalysis] = usesContactProxy
      ? contactProxyFrames(
        from: densePass.samples,
        windows: candidateSet.windows,
        direction: direction,
        confidencePenalty: Self.contactProxyConfidencePenalty
      )
      : []
    let usesCoarseContactProxy =
      usesContactProxy && denseContactProxyFrames.isEmpty
    let contactProxySource = usesCoarseContactProxy ? "coarse" : "dense"
    let metricContactFrames: [ContactFrameAnalysis]
    if !usesContactProxy {
      metricContactFrames = contactFrames
    } else if !denseContactProxyFrames.isEmpty {
      metricContactFrames = denseContactProxyFrames
    } else {
      metricContactFrames = contactProxyFrames(
        from: frameSamples,
        windows: candidateSet.windows,
        direction: direction,
        confidencePenalty: Self.coarseContactProxyConfidencePenalty
      )
    }
    guard !metricContactFrames.isEmpty else {
      throw insufficientContactEvidence(
        "coarseValid=\(frameSamples.count); candidates=\(candidateSet.windows.count); denseValid=\(densePass.samples.count); contacts=\(uniqueContactFrameCount); proxySource=\(contactProxySource); proxies=0"
      )
    }
    let footStrikeRatio =
      metricContactFrames.map(\.footStrikeRatio).reduce(0, +) /
      Double(metricContactFrames.count)
    let kneeAngles = metricContactFrames.map(\.kneeAngleDegrees)
    let elbowAngles = frameSamples.compactMap { $0.averageElbowAngleDegrees }
    guard !elbowAngles.isEmpty else {
      throw AnalysisError(
        code: "no_pose_detected",
        message: "We could not detect a clear running pose in this video."
      )
    }
    let stanceKneeAngle = kneeAngles.reduce(0, +) / Double(kneeAngles.count)
    let elbowAngle = elbowAngles.reduce(0, +) / Double(elbowAngles.count)
    let contactConfidence = min(
      1.0,
      max(
        0.0,
        metricContactFrames.map(\.confidence).reduce(0, +) /
          Double(metricContactFrames.count)
      )
    )
    let contactQualityReason = usesContactProxy
      ? "contact_phase_proxy"
      : hasCompleteContactSample
        ? (usesKinematicContactEstimate ? "kinematic_contact_estimate" : nil)
        : "limited_contact_samples"
    let coreConfidence = frameSamples.map(\.coreLandmarkConfidence).reduce(0, +) /
      Double(frameSamples.count)
    let armConfidenceValues = frameSamples.compactMap(\.armLandmarkConfidence)
    let armConfidence = armConfidenceValues.reduce(0, +) /
      Double(armConfidenceValues.count)
    let analyzedFrameTimestamps = Set(coarseFrameTimestamps + denseTimestamps)
    let validFrameTimestamps = Set(
      (frameSamples + densePass.samples).map(\.timestampMs)
    )
    let baseMetricQualities: [String: [String: Any]] = [
      "posture": metricQualityPayload(
        confidence: coreConfidence,
        sampleCount: frameSamples.count
      ),
      "bounce": metricQualityPayload(
        confidence: coreConfidence,
        sampleCount: frameSamples.count
      ),
      "footStrike": metricQualityPayload(
        confidence: contactConfidence,
        sampleCount: metricContactFrames.count,
        reason: contactQualityReason
      ),
      "kneeFlexion": metricQualityPayload(
        confidence: contactConfidence,
        sampleCount: metricContactFrames.count,
        reason: contactQualityReason
      ),
      "armCarriage": metricQualityPayload(
        confidence: armConfidence,
        sampleCount: armConfidenceValues.count
      ),
    ]

    return [
      "durationMs": durationMs,
      "sampledFrames": analyzedFrameTimestamps.count,
      "validFrames": validFrameTimestamps.count,
      "direction": direction.rawValue,
      "forwardLeanDegrees": roundTo3(leanDegrees),
      "verticalBounceRatio": roundTo3(max(0, bounceRatio)),
      "footStrikeDistanceRatio": roundTo3(footStrikeRatio),
      "stanceKneeAngleDegrees": roundTo3(stanceKneeAngle),
      "elbowAngleDegrees": roundTo3(elbowAngle),
      "metricQualities": [
        "posture": applyPerspectiveQuality(
          metric: "posture",
          baseQuality: baseMetricQualities["posture"]!,
          perspectiveQuality: perspectiveQuality
        ),
        "bounce": applyPerspectiveQuality(
          metric: "bounce",
          baseQuality: baseMetricQualities["bounce"]!,
          perspectiveQuality: perspectiveQuality
        ),
        "footStrike": applyPerspectiveQuality(
          metric: "footStrike",
          baseQuality: baseMetricQualities["footStrike"]!,
          perspectiveQuality: perspectiveQuality
        ),
        "kneeFlexion": applyPerspectiveQuality(
          metric: "kneeFlexion",
          baseQuality: baseMetricQualities["kneeFlexion"]!,
          perspectiveQuality: perspectiveQuality
        ),
        "armCarriage": applyPerspectiveQuality(
          metric: "armCarriage",
          baseQuality: baseMetricQualities["armCarriage"]!,
          perspectiveQuality: perspectiveQuality
        ),
      ],
      "coarseSamples": sampleSummaryPayload(
        attemptedFrames: coarseFrameTimestamps.count,
        validFrames: coarsePass.samples.count,
        poseFrameCount: coarsePass.poseFrames.count,
        maxFrameBudget: Self.maxCoarseFrameBudget,
        targetFps: Self.coarseTargetFps
      ),
      "denseSamples": sampleSummaryPayload(
        attemptedFrames: denseTimestamps.count,
        validFrames: densePass.samples.count,
        poseFrameCount: densePass.poseFrames.count,
        maxFrameBudget: Self.maxDenseFrameBudget,
        targetFps: Self.denseTargetFps
      ),
      "contactWindows": contactWindowPayloads(
        windows: candidateSet.windows,
        denseTimestamps: denseTimestamps,
        contactValidations: contactValidations
      ),
      "validatedContactFrameTimestampsMs": Array(
        Set(contactFrames.map(\.timestampMs))
      ).sorted(),
      "contactConfidence": roundTo3(contactConfidence),
      "perspectiveQuality": perspectiveQuality.payload,
      "poseFrames": mergePoseFrames(
        coarsePoseFrames: coarsePass.poseFrames,
        densePoseFrames: densePass.poseFrames
      ),
    ]
  }

  private func makePoseLandmarker(
    runningMode: RunningMode = .video
  ) throws -> PoseLandmarker {
    guard let modelPath = Bundle.main.path(
      forResource: Self.modelResourceName,
      ofType: Self.modelResourceExtension
    ) else {
      throw AnalysisError(
        code: "model_missing",
        message: "MediaPipe pose model is missing from the iOS bundle."
      )
    }

    let options = PoseLandmarkerOptions()
    options.baseOptions.modelAssetPath = modelPath
    if runningMode == .video {
      options.runningMode = .video
    } else {
      options.runningMode = runningMode
    }
    options.numPoses = 1
    options.minPoseDetectionConfidence = Self.minimumLikelihood
    options.minPosePresenceConfidence = Self.minimumLikelihood
    options.minTrackingConfidence = Self.minimumLikelihood
    do {
      return try PoseLandmarker(options: options)
    } catch {
      throw mediaPipeFailure(
        error,
        fallbackMessage: "MediaPipe pose initialization failed."
      )
    }
  }

  private func mediaPipeFailure(_ error: Error, fallbackMessage: String) -> AnalysisError {
    let message = error.localizedDescription.isEmpty
      ? fallbackMessage
      : error.localizedDescription
    return AnalysisError(code: "mediapipe_pose_failed", message: message)
  }

  private func insufficientContactEvidence(_ detail: String? = nil) -> AnalysisError {
    let suffix = detail.map { " (\($0))" } ?? ""
    return AnalysisError(
      code: "insufficient_contact_evidence",
      message: "We could not verify enough dense foot-contact frames in this video.\(suffix)"
    )
  }

  private func videoTooBlurry() -> AnalysisError {
    AnalysisError(
      code: "video_too_blurry",
      message: "This video is too blurry for precise running coaching."
    )
  }

  private func coarseSampleTimestamps(durationMs: Int) -> [Int] {
    let requestedIntervalCount = max(
      1,
      (durationMs + Self.coarseFrameIntervalMs - 1) / Self.coarseFrameIntervalMs
    )
    let intervalCount = min(
      requestedIntervalCount,
      Self.maxCoarseFrameBudget - 1
    )
    return (0...intervalCount).map { index in
      min(
        durationMs,
        max(0, Int((Double(durationMs) * Double(index) / Double(intervalCount)).rounded()))
      )
    }
  }

  private func runPosePass(
    poseLandmarker: PoseLandmarker,
    imageGenerator: AVAssetImageGenerator,
    timestampsMs: [Int],
    collectSharpness: Bool
  ) throws -> PosePassResult {
    var frameSamples: [FrameSample] = []
    var poseFrames: [[String: Any]] = []
    var sharpnessValues: [Double] = []
    var lastAnalysisTimestampMs = -1
    var seenSourceTimestamps: Set<Int> = []

    for timestampMs in Array(Set(timestampsMs)).sorted() {
      let captureTime = CMTime(
        seconds: Double(timestampMs) / 1000.0,
        preferredTimescale: 600
      )
      try autoreleasepool {
        var actualTime = CMTime.invalid
        guard let cgImage = try? imageGenerator.copyCGImage(
          at: captureTime,
          actualTime: &actualTime
        ) else {
          return
        }
        guard
          let sourceTimestampMs = actualSourceTimestampMs(from: actualTime),
          !seenSourceTimestamps.contains(sourceTimestampMs)
        else {
          return
        }
        seenSourceTimestamps.insert(sourceTimestampMs)
        if collectSharpness, let sharpness = frameSharpness(cgImage) {
          sharpnessValues.append(sharpness)
        }
        let image = UIImage(cgImage: cgImage)
        let imageSize = CGSize(
          width: CGFloat(cgImage.width),
          height: CGFloat(cgImage.height)
        )
        let mpImage = try MPImage(uiImage: image)
        let analysisTimestampMs = max(sourceTimestampMs, lastAnalysisTimestampMs + 1)
        lastAnalysisTimestampMs = analysisTimestampMs

        let result: PoseLandmarkerResult
        do {
          result = try poseLandmarker.detect(
            videoFrame: mpImage,
            timestampInMilliseconds: analysisTimestampMs
          )
        } catch {
          throw mediaPipeFailure(
            error,
            fallbackMessage: "MediaPipe pose inference failed."
          )
        }
        if let poseFrame = poseFrame(
          from: result,
          timestampMs: sourceTimestampMs,
          imageSize: imageSize
        ) {
          poseFrames.append(poseFrame)
        }
        if let sample = extractFrameSample(
          from: result,
          timestampMs: sourceTimestampMs,
          imageSize: imageSize
        ) {
          frameSamples.append(sample)
        }
      }
    }

    return PosePassResult(
      samples: frameSamples.sorted { $0.timestampMs < $1.timestampMs },
      poseFrames: poseFrames.sorted {
        let first = $0["timestampMs"] as? Int ?? 0
        let second = $1["timestampMs"] as? Int ?? 0
        return first < second
      },
      sharpnessValues: sharpnessValues
    )
  }

  private func hasSufficientSharpness(_ values: [Double]) -> Bool {
    guard
      values.count >= Self.minimumSharpnessSampleCount,
      let medianSharpness = median(values)
    else {
      return false
    }
    return medianSharpness >= Self.minimumMedianSharpness
  }

  private func frameSharpness(_ image: CGImage) -> Double? {
    let imageWidth = image.width
    let imageHeight = image.height
    let cropLeft = Int((Double(imageWidth) * Self.sharpnessHorizontalInsetFraction).rounded(.down))
    let cropRight = imageWidth - cropLeft
    let cropTop = Int((Double(imageHeight) * Self.sharpnessTopFraction).rounded(.down))
    let cropBottom = Int((Double(imageHeight) * Self.sharpnessBottomFraction).rounded(.down))
    let cropWidth = cropRight - cropLeft
    let cropHeight = cropBottom - cropTop
    guard cropWidth >= 3, cropHeight >= 3 else {
      return nil
    }
    guard let croppedImage = image.cropping(
      to: CGRect(x: cropLeft, y: cropTop, width: cropWidth, height: cropHeight)
    ) else {
      return nil
    }

    let bytesPerPixel = 4
    let bytesPerRow = Self.sharpnessSampleWidth * bytesPerPixel
    let bitmapInfo =
      CGImageAlphaInfo.premultipliedLast.rawValue |
      CGBitmapInfo.byteOrder32Big.rawValue
    guard let context = CGContext(
      data: nil,
      width: Self.sharpnessSampleWidth,
      height: Self.sharpnessSampleHeight,
      bitsPerComponent: 8,
      bytesPerRow: bytesPerRow,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: bitmapInfo
    ) else {
      return nil
    }
    context.interpolationQuality = .none
    context.draw(
      croppedImage,
      in: CGRect(
        x: 0,
        y: 0,
        width: Self.sharpnessSampleWidth,
        height: Self.sharpnessSampleHeight
      )
    )
    guard let data = context.data else {
      return nil
    }

    let pixels = data.assumingMemoryBound(to: UInt8.self)
    var luminance = [Double](
      repeating: 0,
      count: Self.sharpnessSampleWidth * Self.sharpnessSampleHeight
    )
    for y in 0..<Self.sharpnessSampleHeight {
      for x in 0..<Self.sharpnessSampleWidth {
        let pixelOffset = (y * bytesPerRow) + (x * bytesPerPixel)
        let red = Double(pixels[pixelOffset]) / 255.0
        let green = Double(pixels[pixelOffset + 1]) / 255.0
        let blue = Double(pixels[pixelOffset + 2]) / 255.0
        luminance[(y * Self.sharpnessSampleWidth) + x] =
          (0.299 * red) + (0.587 * green) + (0.114 * blue)
      }
    }

    var sum = 0.0
    var squaredSum = 0.0
    var count = 0
    for y in 1..<(Self.sharpnessSampleHeight - 1) {
      for x in 1..<(Self.sharpnessSampleWidth - 1) {
        let index = (y * Self.sharpnessSampleWidth) + x
        let laplacian =
          (4.0 * luminance[index]) -
          luminance[index - 1] -
          luminance[index + 1] -
          luminance[index - Self.sharpnessSampleWidth] -
          luminance[index + Self.sharpnessSampleWidth]
        sum += laplacian
        squaredSum += laplacian * laplacian
        count += 1
      }
    }
    guard count > 0 else {
      return nil
    }
    let mean = sum / Double(count)
    return max(0, (squaredSum / Double(count)) - (mean * mean))
  }

  private func median(_ values: [Double]) -> Double? {
    guard !values.isEmpty else {
      return nil
    }
    let sortedValues = values.sorted()
    let upperIndex = sortedValues.count / 2
    let lowerIndex = (sortedValues.count - 1) / 2
    return (sortedValues[lowerIndex] + sortedValues[upperIndex]) / 2.0
  }

  private func percentile(_ values: [Double], fraction: Double) -> Double? {
    guard !values.isEmpty else {
      return nil
    }
    let sortedValues = values.sorted()
    let index = max(
      0,
      min(
        Double(sortedValues.count - 1),
        Double(sortedValues.count - 1) * fraction
      )
    )
    let lowerIndex = Int(index.rounded(.down))
    let upperIndex = Int(index.rounded(.up))
    if lowerIndex == upperIndex {
      return sortedValues[lowerIndex]
    }
    let weight = index - Double(lowerIndex)
    return sortedValues[lowerIndex] +
      ((sortedValues[upperIndex] - sortedValues[lowerIndex]) * weight)
  }

  private func actualSourceTimestampMs(from actualTime: CMTime) -> Int? {
    guard actualTime.isValid, actualTime.isNumeric else {
      return nil
    }
    let seconds = CMTimeGetSeconds(actualTime)
    guard seconds.isFinite, seconds >= 0 else {
      return nil
    }
    return max(0, Int((seconds * 1000.0).rounded()))
  }

  private func leastSquaresGroundLine(_ points: [GroundPoint]) -> GroundLine {
    guard !points.isEmpty else {
      return GroundLine(slope: 0, intercept: 0)
    }
    let meanX = points.map(\.x).reduce(0, +) / Double(points.count)
    let meanY = points.map(\.y).reduce(0, +) / Double(points.count)
    let covariance = points.reduce(0.0) { total, point in
      total + ((point.x - meanX) * (point.y - meanY))
    }
    let variance = points.reduce(0.0) { total, point in
      let delta = point.x - meanX
      return total + (delta * delta)
    }
    let slope = variance <= 0.0001 ? 0 : covariance / variance
    return GroundLine(slope: slope, intercept: meanY - (slope * meanX))
  }

  private func groundLineForFootEvidence(
    _ observations: [FootObservation]
  ) -> GroundLine? {
    guard !observations.isEmpty else {
      return nil
    }
    let points = observations.map { observation in
      GroundPoint(
        x: Double(observation.footEvidence.bottomPoint.x),
        y: Double(observation.footEvidence.bottomPoint.y),
        bodyScale: observation.sample.bodyScale
      )
    }
    let lowerEnvelopeCount = min(
      points.count,
      max(
        Self.groundLineMinimumSamples,
        Int(ceil(Double(points.count) * Self.groundLineSampleFraction))
      )
    )
    let lowerEnvelope = points
      .sorted { $0.y > $1.y }
      .prefix(lowerEnvelopeCount)
    var line = leastSquaresGroundLine(Array(lowerEnvelope))
    let residuals = lowerEnvelope.map { point in point.y - line.y(at: point.x) }
    let residualCenter = percentile(residuals, fraction: 0.5) ?? 0
    let medianDeviation = percentile(
      residuals.map { abs($0 - residualCenter) },
      fraction: 0.5
    ) ?? 0
    let averageScale = max(
      1,
      lowerEnvelope.map(\.bodyScale).reduce(0, +) / Double(lowerEnvelope.count)
    )
    let residualTolerance = max(averageScale * 0.025, medianDeviation * 2.5)
    let inliers = lowerEnvelope.filter { point in
      abs(point.y - line.y(at: point.x) - residualCenter) <= residualTolerance
    }
    if inliers.count >= 2 {
      line = leastSquaresGroundLine(Array(inliers))
    }
    return line
  }

  private func groundGap(
    _ groundLine: GroundLine,
    footEvidence: FootBottomEvidence
  ) -> Double {
    groundLine.y(at: Double(footEvidence.bottomPoint.x)) - Double(footEvidence.bottomPoint.y)
  }

  private func selectContactCandidateWindows(
    _ candidates: [ContactCandidate]
  ) -> [ContactCandidate] {
    var deduped: [ContactCandidate] = []
    let rankedCandidates = candidates.sorted {
      if $0.confidence == $1.confidence {
        return $0.centerTimestampMs < $1.centerTimestampMs
      }
      return $0.confidence > $1.confidence
    }
    for candidate in rankedCandidates {
      let duplicatesSameStep = deduped.contains { selectedCandidate in
        selectedCandidate.side == candidate.side &&
          abs(selectedCandidate.centerTimestampMs - candidate.centerTimestampMs) <
          Self.minimumContactCenterSeparationMs
      }
      if !duplicatesSameStep {
        deduped.append(candidate)
      }
    }
    if deduped.count <= Self.maxContactWindows {
      return deduped.sorted { $0.centerTimestampMs < $1.centerTimestampMs }
    }

    let ordered = deduped.sorted { $0.centerTimestampMs < $1.centerTimestampMs }
    guard let firstTime = ordered.first?.centerTimestampMs,
      let lastTime = ordered.last?.centerTimestampMs
    else {
      return []
    }
    var selected: [ContactCandidate] = []
    var selectedIndexes = Set<Int>()
    for slot in 0..<Self.maxContactWindows {
      let target = Self.maxContactWindows <= 1
        ? Double(firstTime + lastTime) / 2.0
        : Double(firstTime) +
          (Double(lastTime - firstTime) * Double(slot)) /
          Double(Self.maxContactWindows - 1)
      var bestIndex: Int?
      for index in ordered.indices where !selectedIndexes.contains(index) {
        guard let currentBest = bestIndex else {
          bestIndex = index
          continue
        }
        let current = ordered[index]
        let best = ordered[currentBest]
        let distance = abs(Double(current.centerTimestampMs) - target)
        let bestDistance = abs(Double(best.centerTimestampMs) - target)
        if distance < bestDistance ||
          (distance == bestDistance && current.confidence > best.confidence) ||
          (distance == bestDistance && current.confidence == best.confidence &&
            current.centerTimestampMs < best.centerTimestampMs)
        {
          bestIndex = index
        }
      }
      if let bestIndex {
        selectedIndexes.insert(bestIndex)
        selected.append(ordered[bestIndex])
      }
    }
    return selected.sorted { $0.centerTimestampMs < $1.centerTimestampMs }
  }

  private func deriveContactCandidateWindows(
    from samples: [FrameSample],
    durationMs: Int
  ) -> ContactCandidateSet {
    let footObservations = samples.flatMap { sample in
      FootSide.allCases.compactMap { side in
        sample.footBottom(side).map { evidence in
          FootObservation(sample: sample, side: side, footEvidence: evidence)
        }
      }
    }
    guard let groundLine = groundLineForFootEvidence(footObservations) else {
      return ContactCandidateSet(
        windows: [],
        groundLine: GroundLine(slope: 0, intercept: 0)
      )
    }
    let averageScale = max(samples.map(\.bodyScale).reduce(0, +) / Double(samples.count), 1)
    let groundTolerance = averageScale * Self.coarseContactGroundToleranceRatio
    let localTolerance = averageScale * Self.localFootExtremumToleranceRatio
    var candidates: [ContactCandidate] = []

    for side in FootSide.allCases {
      let sideEvidence = samples.compactMap { sample in
        sample.footBottom(side).map { evidence in (sample, evidence) }
      }
      for index in sideEvidence.indices {
        let sample = sideEvidence[index].0
        let evidence = sideEvidence[index].1
        let bottomY = Double(evidence.bottomPoint.y)
        let previousY: Double? = index > 0
          ? Double(sideEvidence[index - 1].1.bottomPoint.y)
          : nil
        let nextY: Double? = index + 1 < sideEvidence.count
          ? Double(sideEvidence[index + 1].1.bottomPoint.y)
          : nil
        let gap = groundGap(groundLine, footEvidence: evidence)
        let nearGround =
          gap >= -groundTolerance * 0.55 && gap <= groundTolerance * 1.1
        let localExtremum =
          (previousY == nil || bottomY >= previousY! - localTolerance) &&
          (nextY == nil || bottomY >= nextY! - localTolerance)
        guard nearGround, localExtremum else {
          continue
        }
        let proximityFactor = min(
          1.0,
          max(0.0, 1.0 - (max(0.0, gap) / max(1.0, groundTolerance)))
        )
        candidates.append(
          ContactCandidate(
            side: side,
            centerTimestampMs: sample.timestampMs,
            startTimestampMs: max(0, sample.timestampMs - Self.denseWindowRadiusMs),
            endTimestampMs: min(durationMs, sample.timestampMs + Self.denseWindowRadiusMs),
            confidence: min(1.0, max(0.0, evidence.confidence * proximityFactor))
          )
        )
      }
    }

    return ContactCandidateSet(
      windows: selectContactCandidateWindows(candidates),
      groundLine: groundLine
    )
  }

  private func fallbackContactCandidateWindows(
    from samples: [FrameSample],
    durationMs: Int
  ) -> ContactCandidateSet {
    let footObservations = samples.flatMap { sample in
      FootSide.allCases.compactMap { side in
        sample.footBottom(side).map { evidence in
          FootObservation(sample: sample, side: side, footEvidence: evidence)
        }
      }
    }
    guard let groundLine = groundLineForFootEvidence(footObservations) else {
      return ContactCandidateSet(
        windows: [],
        groundLine: GroundLine(slope: 0, intercept: 0)
      )
    }

    let averageScale = max(
      samples.map(\.bodyScale).reduce(0, +) / Double(samples.count),
      1
    )
    let localTolerance = averageScale * Self.kinematicContactMotionToleranceRatio
    var candidates: [ContactCandidate] = []
    for side in FootSide.allCases {
      let sideEvidence = samples.compactMap { sample in
        sample.footBottom(side).map { evidence in (sample, evidence) }
      }.sorted { $0.0.timestampMs < $1.0.timestampMs }
      guard let lowerEnvelopeY = percentile(
        sideEvidence.map { Double($0.1.bottomPoint.y) },
        fraction: Self.kinematicContactLowerPercentile
      ) else {
        continue
      }
      for index in sideEvidence.indices {
        let sample = sideEvidence[index].0
        let evidence = sideEvidence[index].1
        let currentY = Double(evidence.bottomPoint.y)
        let previous = index > 0 ? sideEvidence[index - 1] : nil
        let next = index + 1 < sideEvidence.count ? sideEvidence[index + 1] : nil
        let closeToPrevious = previous.map {
          sample.timestampMs - $0.0.timestampMs <= Self.coarseFrameIntervalMs * 2
        } ?? false
        let closeToNext = next.map {
          $0.0.timestampMs - sample.timestampMs <= Self.coarseFrameIntervalMs * 2
        } ?? false
        let locallyLow =
          (!closeToPrevious || currentY >= Double(previous!.1.bottomPoint.y) - localTolerance) &&
          (!closeToNext || currentY >= Double(next!.1.bottomPoint.y) - localTolerance)
        guard currentY >= lowerEnvelopeY, locallyLow else {
          continue
        }
        candidates.append(
          ContactCandidate(
            side: side,
            centerTimestampMs: sample.timestampMs,
            startTimestampMs: max(0, sample.timestampMs - Self.denseWindowRadiusMs),
            endTimestampMs: min(durationMs, sample.timestampMs + Self.denseWindowRadiusMs),
            confidence: min(1.0, max(0.0, evidence.confidence))
          )
        )
      }
    }

    return ContactCandidateSet(
      windows: selectContactCandidateWindows(candidates),
      groundLine: groundLine
    )
  }

  private func mergeContactCandidateSets(
    detected: ContactCandidateSet,
    fallback: ContactCandidateSet
  ) -> ContactCandidateSet {
    ContactCandidateSet(
      windows: selectContactCandidateWindows(detected.windows + fallback.windows),
      groundLine: detected.windows.isEmpty ? fallback.groundLine : detected.groundLine
    )
  }

  private func denseTimestampsForContactWindows(
    _ windows: [ContactCandidate],
    durationMs: Int
  ) -> [Int] {
    let selectedWindows = Array(windows.prefix(Self.maxContactWindows))
    guard !selectedWindows.isEmpty else {
      return []
    }
    // Reserve an even budget for every candidate window. A global sort by
    // distance to the coarse centres can starve the real contact near a
    // window edge when several steps overlap.
    let perWindowBudget = max(3, Self.maxDenseFrameBudget / selectedWindows.count)
    var timestamps = Set<Int>()
    for window in selectedWindows {
      var frameTimes: [Int] = []
      var timestampMs = window.startTimestampMs
      while timestampMs <= window.endTimestampMs {
        frameTimes.append(min(durationMs, max(0, timestampMs)))
        timestampMs += Self.denseFrameIntervalMs
      }
      if frameTimes.isEmpty || frameTimes.last != window.endTimestampMs {
        frameTimes.append(min(durationMs, max(0, window.endTimestampMs)))
      }
      var selected = Set<Int>()
      let nearestToCenter = frameTimes.sorted { first, second in
        let firstDistance = abs(first - window.centerTimestampMs)
        let secondDistance = abs(second - window.centerTimestampMs)
        return firstDistance == secondDistance ? first < second : firstDistance < secondDistance
      }
      selected.formUnion(nearestToCenter.prefix(min(3, perWindowBudget)))
      let remaining = perWindowBudget - selected.count
      if remaining > 0 {
        for index in 0..<remaining {
          let fraction = remaining <= 1
            ? 0.5
            : Double(index) / Double(remaining - 1)
          let frameIndex = Int((Double(frameTimes.count - 1) * fraction).rounded())
          selected.insert(frameTimes[frameIndex])
        }
      }
      for timestamp in nearestToCenter where selected.count < perWindowBudget {
        selected.insert(timestamp)
      }
      timestamps.formUnion(selected)
    }
    return timestamps.sorted().prefix(Self.maxDenseFrameBudget).map { $0 }
  }

  private func validateDenseContactFrames(
    _ samples: [FrameSample],
    windows: [ContactCandidate],
    groundLine: GroundLine,
    direction: AnalysisDirection
  ) -> [ContactWindowValidation] {
    let orderedSamples = samples.sorted { $0.timestampMs < $1.timestampMs }
    let validations = windows
      .sorted { $0.centerTimestampMs < $1.centerTimestampMs }
      .map { window in
        let selection = selectDenseContactFrame(
          for: window,
          orderedSamples: orderedSamples,
          groundLine: groundLine,
          direction: direction
        )
        return ContactWindowValidation(
          window: window,
          contact: selection.contact,
          candidateFrameCount: selection.candidateFrameCount,
          rejectedFrameCounts: selection.rejectedFrameCounts
        )
      }
    var selectedIndexes: [Int] = []
    let rankedIndexes = validations.indices
      .filter { validations[$0].contact != nil }
      .sorted { first, second in
        let firstContact = validations[first].contact!
        let secondContact = validations[second].contact!
        if firstContact.confidence == secondContact.confidence {
          return firstContact.timestampMs < secondContact.timestampMs
        }
        return firstContact.confidence > secondContact.confidence
      }
    for index in rankedIndexes {
      let timestampMs = validations[index].contact!.timestampMs
      let isSameEvent = selectedIndexes.contains { selectedIndex in
        abs(validations[selectedIndex].contact!.timestampMs - timestampMs) <
          Self.minimumDistinctContactSeparationMs
      }
      if !isSameEvent {
        selectedIndexes.append(index)
      }
    }
    let selectedIndexSet = Set(selectedIndexes)
    return validations.enumerated().map { index, validation in
      if validation.contact == nil || selectedIndexSet.contains(index) {
        return validation
      }
      return ContactWindowValidation(
        window: validation.window,
        contact: nil,
        candidateFrameCount: validation.candidateFrameCount,
        rejectedFrameCounts: validation.rejectedFrameCounts
      )
    }
  }

  private func contactProxyFrames(
    from samples: [FrameSample],
    windows: [ContactCandidate],
    direction: AnalysisDirection,
    confidencePenalty: Double
  ) -> [ContactFrameAnalysis] {
    var proxies: [ContactFrameAnalysis] = []
    for window in windows.sorted(by: { $0.centerTimestampMs < $1.centerTimestampMs }) {
      let candidate = samples
        .filter { sample in
          sample.timestampMs >= window.startTimestampMs &&
            sample.timestampMs <= window.endTimestampMs
        }
        .flatMap { sample in
          FootSide.allCases.compactMap { side -> ContactProxyCandidate? in
            guard let evidence = sample.footBottom(side),
              let landmarkConfidence = sample.contactLandmarkConfidence(
                side,
                footEvidence: evidence
              )
            else {
              return nil
            }
            return ContactProxyCandidate(
              sample: sample,
              side: side,
              landmarkConfidence: landmarkConfidence
            )
          }
        }
        .sorted { first, second in
          let firstDistance = abs(first.sample.timestampMs - window.centerTimestampMs)
          let secondDistance = abs(second.sample.timestampMs - window.centerTimestampMs)
          if firstDistance != secondDistance {
            return firstDistance < secondDistance
          }
          if first.landmarkConfidence != second.landmarkConfidence {
            return first.landmarkConfidence > second.landmarkConfidence
          }
          return first.sample.timestampMs < second.sample.timestampMs
        }
        .first
      guard let candidate else {
        continue
      }
      guard let kneeAngleDegrees = candidate.sample.contactKneeAngleDegrees(candidate.side) else {
        continue
      }
      let confidence = min(
        1.0,
        max(
          0.0,
          min(
            window.confidence,
            candidate.landmarkConfidence
          ) * confidencePenalty
        )
      )
      let proxy = ContactFrameAnalysis(
        timestampMs: candidate.sample.timestampMs,
        windowCenterTimestampMs: window.centerTimestampMs,
        side: candidate.side,
        footStrikeRatio: candidate.sample.contactFootStrikeRatio(
          candidate.side,
          direction: direction
        ),
        kneeAngleDegrees: kneeAngleDegrees,
        confidence: confidence,
        isKinematicEstimate: false
      )
      proxies.append(proxy)
    }
    var selected: [ContactFrameAnalysis] = []
    let ranked = proxies.sorted {
      if $0.confidence == $1.confidence {
        return $0.timestampMs < $1.timestampMs
      }
      return $0.confidence > $1.confidence
    }
    for proxy in ranked {
      let isSameEvent = selected.contains { existing in
        abs(existing.timestampMs - proxy.timestampMs) <
          Self.minimumDistinctContactSeparationMs
      }
      if !isSameEvent {
        selected.append(proxy)
      }
    }
    return selected.sorted { $0.timestampMs < $1.timestampMs }
  }

  private func selectDenseContactFrame(
    for window: ContactCandidate,
    orderedSamples: [FrameSample],
    groundLine: GroundLine,
    direction: AnalysisDirection
  ) -> ContactFrameSelection {
    let alternateSide: FootSide = window.side == .left ? .right : .left
    let preferred = selectDenseContactFrameForSide(
      for: window,
      side: window.side,
      orderedSamples: orderedSamples,
      groundLine: groundLine,
      direction: direction
    )
    let alternate = selectDenseContactFrameForSide(
      for: window,
      side: alternateSide,
      orderedSamples: orderedSamples,
      groundLine: groundLine,
      direction: direction
    )
    let selectedContact = [preferred.contact, alternate.contact]
      .compactMap { $0 }
      .max { first, second in
        let firstBias = first.side == window.side ? 1.03 : 1
        let secondBias = second.side == window.side ? 1.03 : 1
        return contactSelectionScore(
          timestampMs: first.timestampMs,
          confidence: first.confidence,
          window: window
        ) * firstBias < contactSelectionScore(
          timestampMs: second.timestampMs,
          confidence: second.confidence,
          window: window
        ) * secondBias
      }
    var rejectedFrameCounts = preferred.rejectedFrameCounts
    for (reason, count) in alternate.rejectedFrameCounts {
      rejectedFrameCounts[reason, default: 0] += count
    }
    return ContactFrameSelection(
      contact: selectedContact,
      candidateFrameCount: max(
        preferred.candidateFrameCount,
        alternate.candidateFrameCount
      ),
      rejectedFrameCounts: rejectedFrameCounts
    )
  }

  private func contactSelectionScore(
    timestampMs: Int,
    confidence: Double,
    window: ContactCandidate
  ) -> Double {
    let distanceRatio = min(
      1,
      Double(abs(timestampMs - window.centerTimestampMs)) /
        Double(max(1, Self.denseWindowRadiusMs))
    )
    return confidence * (1 - (distanceRatio * 0.65))
  }

  private func selectDenseContactFrameForSide(
    for window: ContactCandidate,
    side: FootSide,
    orderedSamples: [FrameSample],
    groundLine: GroundLine,
    direction: AnalysisDirection
  ) -> ContactFrameSelection {
    var rejectedFrameCounts: [String: Int] = [:]
    let candidates: [ContactFrameCandidate] = orderedSamples
      .filter { sample in
        sample.timestampMs >= window.startTimestampMs &&
        sample.timestampMs <= window.endTimestampMs
      }
      .compactMap { sample -> ContactFrameCandidate? in
        guard let evidence = sample.footBottom(side) else {
          incrementContactRejection(&rejectedFrameCounts, reason: "missing_foot_landmark")
          return nil
        }
        guard sample.contactLandmarkConfidence(
          side,
          footEvidence: evidence
        ) != nil else {
          incrementContactRejection(&rejectedFrameCounts, reason: "missing_contact_joint_chain")
          return nil
        }
        let candidate = denseContactCandidate(sample, side: side, groundLine: groundLine)
        if candidate == nil {
          incrementContactRejection(&rejectedFrameCounts, reason: "missing_foot_landmark")
        }
        return candidate
      }
    var temporalCandidates: [ContactFrameCandidate] = []
    var persistentCandidates: [ContactFrameCandidate] = []
    for index in candidates.indices {
      let current = candidates[index]
      guard current.inGroundBand else {
        incrementContactRejection(&rejectedFrameCounts, reason: "outside_ground_band")
        continue
      }
      guard isEligibleContact(current) else {
        incrementContactRejection(&rejectedFrameCounts, reason: "low_contact_confidence")
        continue
      }
      let previous = index > 0 ? candidates[index - 1] : nil
      let next = index + 1 < candidates.count ? candidates[index + 1] : nil
      guard
        hasTemporalNeighbor(current, previous: previous) ||
          hasTemporalNeighbor(current, next: next)
      else {
        incrementContactRejection(&rejectedFrameCounts, reason: "insufficient_motion_window")
        continue
      }
      guard hasGroundBandPersistence(current, previous: previous, next: next) else {
        incrementContactRejection(
          &rejectedFrameCounts,
          reason: "insufficient_contact_persistence"
        )
        continue
      }
      guard isFootAtLocalBottom(current, previous: previous, next: next) else {
        incrementContactRejection(&rejectedFrameCounts, reason: "unstable_foot_motion")
        continue
      }
      if enteredGroundBand(current, previous: previous) {
        temporalCandidates.append(current)
      } else {
        persistentCandidates.append(current)
      }
    }
    // Never fall back to an isolated near-ground frame. It remains a phase
    // candidate only, rather than being promoted to initial contact.
    let candidatesForSelection = temporalCandidates.isEmpty
      ? persistentCandidates
      : temporalCandidates
    let selected = candidatesForSelection.sorted(by: { first, second in
        let firstScore = contactSelectionScore(
          timestampMs: first.sample.timestampMs,
          confidence: first.confidence,
          window: window
        )
        let secondScore = contactSelectionScore(
          timestampMs: second.sample.timestampMs,
          confidence: second.confidence,
          window: window
        )
        if firstScore != secondScore {
          return firstScore > secondScore
        }
        if first.confidence != second.confidence {
          return first.confidence > second.confidence
        }
        let firstDistance = abs(first.sample.timestampMs - window.centerTimestampMs)
        let secondDistance = abs(second.sample.timestampMs - window.centerTimestampMs)
        if firstDistance != secondDistance {
          return firstDistance < secondDistance
        }
        return first.sample.timestampMs < second.sample.timestampMs
      }).first
    let kinematicCandidates: [ContactFrameCandidate]
    if let lowerEnvelopeY = percentile(
      candidates.map { Double($0.footEvidence.bottomPoint.y) },
      fraction: Self.kinematicContactLowerPercentile
    ) {
      kinematicCandidates = candidates.enumerated().compactMap { index, candidate in
        isKinematicContactCandidate(
          candidates,
          index: index,
          lowerEnvelopeY: lowerEnvelopeY
        ) ? candidate : nil
      }
    } else {
      kinematicCandidates = []
    }
    let kinematicSelection = kinematicCandidates.sorted(by: { first, second in
      let firstScore = contactSelectionScore(
        timestampMs: first.sample.timestampMs,
        confidence: first.confidence,
        window: window
      )
      let secondScore = contactSelectionScore(
        timestampMs: second.sample.timestampMs,
        confidence: second.confidence,
        window: window
      )
      if firstScore != secondScore {
        return firstScore > secondScore
      }
      if first.confidence != second.confidence {
        return first.confidence > second.confidence
      }
      let firstDistance = abs(first.sample.timestampMs - window.centerTimestampMs)
      let secondDistance = abs(second.sample.timestampMs - window.centerTimestampMs)
      if firstDistance != secondDistance {
        return firstDistance < secondDistance
      }
      return first.sample.timestampMs < second.sample.timestampMs
    }).first
    let strictContact = selected.flatMap {
      contactFrame(
        from: $0,
        window: window,
        direction: direction,
        isKinematicEstimate: false
      )
    }
    let kinematicContact = strictContact == nil
      ? kinematicSelection.flatMap {
        contactFrame(
          from: $0,
          window: window,
          direction: direction,
          isKinematicEstimate: true,
          confidence: $0.confidence * Self.kinematicContactConfidencePenalty
        )
      }
      : nil
    return ContactFrameSelection(
      contact: strictContact ?? kinematicContact,
      candidateFrameCount: max(
        candidates.filter { $0.inGroundBand }.count,
        kinematicCandidates.count
      ),
      rejectedFrameCounts: rejectedFrameCounts
    )
  }

  private func incrementContactRejection(
    _ rejectedFrameCounts: inout [String: Int],
    reason: String
  ) {
    rejectedFrameCounts[reason, default: 0] += 1
  }

  private func hasTemporalNeighbor(
    _ current: ContactFrameCandidate,
    previous: ContactFrameCandidate? = nil,
    next: ContactFrameCandidate? = nil
  ) -> Bool {
    [previous, next].compactMap { $0 }.contains { neighbor in
      abs(neighbor.sample.timestampMs - current.sample.timestampMs) <=
        Self.contactMotionNeighborGapMs
    }
  }

  private func denseContactCandidate(
    _ sample: FrameSample,
    side: FootSide,
    groundLine: GroundLine
  ) -> ContactFrameCandidate? {
    guard let evidence = sample.footBottom(side) else {
      return nil
    }
    guard let landmarkConfidence = sample.contactLandmarkConfidence(
      side,
      footEvidence: evidence
    ) else {
      return nil
    }
    let tolerance = max(1.0, sample.bodyScale * Self.denseContactGroundToleranceRatio)
    let proximity = groundGap(groundLine, footEvidence: evidence)
    let inGroundBand = proximity >= -tolerance * 0.55 && proximity <= tolerance * 1.1
    let proximityFactor = min(1.0, max(0.0, 1.0 - (max(0.0, proximity) / tolerance)))
    let confidence = min(
      1.0,
      max(
        0.0,
        landmarkConfidence *
          (0.75 + (0.25 * proximityFactor))
      )
    )
    return ContactFrameCandidate(
      sample: sample,
      side: side,
      footEvidence: evidence,
      proximity: proximity,
      tolerance: tolerance,
      confidence: confidence,
      inGroundBand: inGroundBand
    )
  }

  private func isEligibleContact(_ candidate: ContactFrameCandidate) -> Bool {
    candidate.inGroundBand && candidate.confidence >= Self.minimumContactFrameConfidence
  }

  private func enteredGroundBand(
    _ current: ContactFrameCandidate,
    previous: ContactFrameCandidate?
  ) -> Bool {
    guard let previous else {
      return false
    }
    return previous.proximity > current.tolerance &&
      abs(previous.sample.timestampMs - current.sample.timestampMs) <=
      Self.contactMotionNeighborGapMs
  }

  private func hasGroundBandPersistence(
    _ current: ContactFrameCandidate,
    previous: ContactFrameCandidate?,
    next: ContactFrameCandidate?
  ) -> Bool {
    [previous, next].compactMap { $0 }.contains { neighbor in
      isEligibleContact(neighbor) &&
        abs(neighbor.sample.timestampMs - current.sample.timestampMs) <=
        Self.contactMotionNeighborGapMs
    }
  }

  private func isFootAtLocalBottom(
    _ current: ContactFrameCandidate,
    previous: ContactFrameCandidate?,
    next: ContactFrameCandidate?
  ) -> Bool {
    let tolerance = max(1.0, current.sample.bodyScale * Self.contactMotionToleranceRatio)
    let currentY = Double(current.footEvidence.bottomPoint.y)
    if let previous,
       abs(current.sample.timestampMs - previous.sample.timestampMs) <=
         Self.contactMotionNeighborGapMs,
       currentY < Double(previous.footEvidence.bottomPoint.y) - tolerance
    {
      return false
    }
    if let next,
       abs(next.sample.timestampMs - current.sample.timestampMs) <=
         Self.contactMotionNeighborGapMs,
       currentY < Double(next.footEvidence.bottomPoint.y) - tolerance
    {
      return false
    }
    return true
  }

  private func isKinematicContactCandidate(
    _ candidates: [ContactFrameCandidate],
    index: Int,
    lowerEnvelopeY: Double
  ) -> Bool {
    let current = candidates[index]
    guard current.confidence >= Self.minimumContactFrameConfidence,
      Double(current.footEvidence.bottomPoint.y) >= lowerEnvelopeY
    else {
      return false
    }
    let previous = index > 0 ? candidates[index - 1] : nil
    let next = index + 1 < candidates.count ? candidates[index + 1] : nil
    let hasPrevious = hasTemporalNeighbor(current, previous: previous)
    let hasNext = hasTemporalNeighbor(current, next: next)
    guard hasPrevious || hasNext else {
      return false
    }
    let tolerance = max(
      1.0,
      current.sample.bodyScale * Self.kinematicContactMotionToleranceRatio
    )
    let currentY = Double(current.footEvidence.bottomPoint.y)
    if hasPrevious,
       let previous,
       currentY < Double(previous.footEvidence.bottomPoint.y) - tolerance
    {
      return false
    }
    if hasNext,
       let next,
       currentY < Double(next.footEvidence.bottomPoint.y) - tolerance
    {
      return false
    }
    return true
  }

  private func contactFrame(
    from candidate: ContactFrameCandidate,
    window: ContactCandidate,
    direction: AnalysisDirection,
    isKinematicEstimate: Bool,
    confidence: Double? = nil
  ) -> ContactFrameAnalysis? {
    guard let kneeAngleDegrees = candidate.sample.contactKneeAngleDegrees(candidate.side) else {
      return nil
    }
    return ContactFrameAnalysis(
      timestampMs: candidate.sample.timestampMs,
      windowCenterTimestampMs: window.centerTimestampMs,
      side: candidate.side,
      footStrikeRatio: candidate.sample.contactFootStrikeRatio(
        candidate.side,
        direction: direction
      ),
      kneeAngleDegrees: kneeAngleDegrees,
      confidence: confidence ?? candidate.confidence,
      isKinematicEstimate: isKinematicEstimate
    )
  }

  private func sampleSummaryPayload(
    attemptedFrames: Int,
    validFrames: Int,
    poseFrameCount: Int,
    maxFrameBudget: Int? = nil,
    targetFps: Int? = nil
  ) -> [String: Any] {
    var payload: [String: Any] = [
      "attemptedFrames": attemptedFrames,
      "validFrames": validFrames,
      "poseFrameCount": poseFrameCount,
    ]
    if let maxFrameBudget = maxFrameBudget {
      payload["maxFrameBudget"] = maxFrameBudget
    }
    if let targetFps = targetFps {
      payload["targetFps"] = targetFps
    }
    return payload
  }

  private func metricQualityPayload(
    confidence: Double,
    sampleCount: Int,
    reason: String? = nil
  ) -> [String: Any] {
    var payload: [String: Any] = [
      "confidence": roundTo3(min(1.0, max(0.0, confidence))),
      "sampleCount": sampleCount,
    ]
    if let reason {
      payload["reason"] = reason
    }
    return payload
  }

  private func perspectiveQualityPayload(from samples: [FrameSample]) -> PerspectiveQuality {
    guard !samples.isEmpty else {
      return PerspectiveQuality(
        evaluatedFrameCount: 0,
        medianBodyScaleRatio: 0,
        minBodyScaleRatio: 0,
        visibilityCoverage: 0,
        sideViewScore: 0,
        scaleDriftRatio: 0,
        cutOffFrameRatio: 0,
        issues: []
      )
    }
    let bodyScaleRatios = samples.map { sample in
      sample.bodyScale / Double(max(1, min(sample.imageWidth, sample.imageHeight)))
    }
    let medianBodyScaleRatio = median(bodyScaleRatios) ?? 0
    let minBodyScaleRatio = bodyScaleRatios.min() ?? 0
    let scales = samples.map(\.bodyScale).filter { $0 > 0 }
    let lowerScale = percentile(scales, fraction: 0.10) ?? 0
    let upperScale = percentile(scales, fraction: 0.90) ?? lowerScale
    let scaleDriftRatio = lowerScale <= 0 ? 0 : (upperScale - lowerScale) / lowerScale
    let visibilityCoverage = samples.map { sample in
      Double([
        sample.leftShoulder,
        sample.rightShoulder,
        sample.leftHip,
        sample.rightHip,
        sample.leftKnee,
        sample.rightKnee,
        sample.leftAnkle,
        sample.rightAnkle,
      ].compactMap { $0 }.count) / 8.0
    }.reduce(0, +) / Double(samples.count)
    let sideRatios = samples.compactMap { $0.sideViewWidthRatio }
    let sideWidthRatio = median(sideRatios) ?? 1
    let sideViewScore = min(1.0, max(0.0, 1.0 - ((sideWidthRatio - 0.18) / 0.34)))
    let cutOffFrameRatio = Double(samples.filter(\.touchesFrameEdge).count) /
      Double(samples.count)
    var issues: [String] = []
    if medianBodyScaleRatio < Self.minimumBodyScaleRatio ||
      minBodyScaleRatio < Self.minimumBodyScaleRatio * 0.72
    {
      issues.append("tooSmall")
    }
    if sideViewScore < Self.minimumSideViewScore {
      issues.append("notSideOn")
    }
    if cutOffFrameRatio > Self.maximumCutOffFrameRatio ||
      visibilityCoverage < Self.minimumVisibilityCoverage
    {
      issues.append("bodyCutOff")
    }
    if scaleDriftRatio > Self.maximumScaleDriftRatio {
      issues.append("scaleDrift")
    }
    return PerspectiveQuality(
      evaluatedFrameCount: samples.count,
      medianBodyScaleRatio: roundTo3(medianBodyScaleRatio),
      minBodyScaleRatio: roundTo3(minBodyScaleRatio),
      visibilityCoverage: roundTo3(visibilityCoverage),
      sideViewScore: roundTo3(sideViewScore),
      scaleDriftRatio: roundTo3(scaleDriftRatio),
      cutOffFrameRatio: roundTo3(cutOffFrameRatio),
      issues: issues
    )
  }

  private func perspectiveReasonForMetric(
    _ quality: PerspectiveQuality,
    metric: String
  ) -> String? {
    if quality.issues.contains("tooSmall") {
      return "too_small_runner"
    }
    if quality.issues.contains("bodyCutOff") {
      return "body_cut_off"
    }
    let isLowerBody = metric == "footStrike" || metric == "kneeFlexion"
    if isLowerBody, quality.issues.contains("notSideOn") {
      return "not_side_on"
    }
    if (isLowerBody || metric == "bounce"), quality.issues.contains("scaleDrift") {
      return "scale_drift"
    }
    return nil
  }

  private func applyPerspectiveQuality(
    metric: String,
    baseQuality: [String: Any],
    perspectiveQuality: PerspectiveQuality
  ) -> [String: Any] {
    guard let reason = perspectiveReasonForMetric(perspectiveQuality, metric: metric) else {
      return baseQuality
    }
    let confidence = (baseQuality["confidence"] as? NSNumber)?.doubleValue ??
      (baseQuality["confidence"] as? Double ?? 0)
    let sampleCount = (baseQuality["sampleCount"] as? NSNumber)?.intValue ??
      (baseQuality["sampleCount"] as? Int ?? 0)
    return metricQualityPayload(
      confidence: min(confidence, reason == "too_small_runner" ? 0 : 0.55),
      sampleCount: sampleCount,
      reason: reason
    )
  }

  private func contactWindowPayloads(
    windows: [ContactCandidate],
    denseTimestamps: [Int],
    contactValidations: [ContactWindowValidation]
  ) -> [[String: Any]] {
    windows.map { window in
      let validation = contactValidations.first { candidate in
        candidate.window.side == window.side &&
          candidate.window.centerTimestampMs == window.centerTimestampMs
      }
      let validated: [ContactFrameAnalysis] = validation?.contact.map { [$0] } ?? []
      let confidence = validated.isEmpty
        ? 0.0
        : validated.map(\.confidence).reduce(0, +) / Double(validated.count)
      return [
        "side": (validation?.contact?.side ?? window.side).rawValue,
        "startTimestampMs": window.startTimestampMs,
        "centerTimestampMs": window.centerTimestampMs,
        "endTimestampMs": window.endTimestampMs,
        "coarseConfidence": roundTo3(window.confidence),
        "denseSampleCount": denseTimestamps.filter { timestampMs in
          timestampMs >= window.startTimestampMs &&
            timestampMs <= window.endTimestampMs
        }.count,
        "candidateFrameCount": validation?.candidateFrameCount ?? 0,
        "rejectedFrameCounts": validation?.rejectedFrameCounts ?? [:],
        "validatedContactFrameTimestampsMs": Array(
          Set(validated.map(\.timestampMs))
        ).sorted(),
        "confidence": roundTo3(confidence),
      ]
    }
  }

  private func mergePoseFrames(
    coarsePoseFrames: [[String: Any]],
    densePoseFrames: [[String: Any]]
  ) -> [[String: Any]] {
    var byTimestamp: [Int: [String: Any]] = [:]
    for poseFrame in coarsePoseFrames + densePoseFrames {
      guard let timestampMs = poseFrame["timestampMs"] as? Int else {
        continue
      }
      byTimestamp[timestampMs] = poseFrame
    }
    return byTimestamp.keys.sorted().compactMap { byTimestamp[$0] }
  }

  private func poseFrame(
    from result: PoseLandmarkerResult,
    timestampMs: Int,
    imageSize: CGSize
  ) -> [String: Any]? {
    guard let landmarks = result.landmarks.first,
          landmarks.count >= Self.mediaPipePoseLandmarkCount else {
      return nil
    }
    let worldLandmarks = result.worldLandmarks.first

    let landmarkPayloads = landmarks
      .prefix(Self.mediaPipePoseLandmarkCount)
      .enumerated()
      .map { index, landmark -> [String: Any] in
        var payload: [String: Any] = [
          "index": index,
          "x": Double(landmark.x),
          "y": Double(landmark.y),
          "z": Double(landmark.z),
          "visibility": nullableNumber(landmark.visibility),
          "presence": nullableNumber(landmark.presence),
          "confidence": Double(landmarkConfidence(landmark)),
        ]
        if let worldLandmarks, index < worldLandmarks.count {
          let world = worldLandmarks[index]
          let imageConfidence = Double(landmarkConfidence(landmark))
          let worldConfidence = Double(landmarkConfidence(world))
          payload["worldX"] = Double(world.x)
          payload["worldY"] = Double(world.y)
          payload["worldZ"] = Double(world.z)
          payload["worldVisibility"] = nullableNumber(world.visibility)
          payload["worldPresence"] = nullableNumber(world.presence)
          payload["worldConfidence"] = worldConfidence > 0 ? worldConfidence : imageConfidence
        }
        return payload
      }

    return [
      "timestampMs": timestampMs,
      "imageWidth": Int(imageSize.width.rounded()),
      "imageHeight": Int(imageSize.height.rounded()),
      "landmarks": landmarkPayloads,
    ]
  }

  private func nullableNumber(_ value: NSNumber?) -> Any {
    value?.doubleValue ?? NSNull()
  }

  private func extractFrameSample(
    from result: PoseLandmarkerResult,
    timestampMs: Int,
    imageSize: CGSize
  ) -> FrameSample? {
    guard let landmarks = result.landmarks.first, landmarks.count > Self.rightFootIndex else {
      return nil
    }

    let leftShoulder = confidentLandmarkPoint(Self.leftShoulderIndex, in: landmarks, imageSize: imageSize)
    let rightShoulder = confidentLandmarkPoint(Self.rightShoulderIndex, in: landmarks, imageSize: imageSize)
    let leftHip = confidentLandmarkPoint(Self.leftHipIndex, in: landmarks, imageSize: imageSize)
    let rightHip = confidentLandmarkPoint(Self.rightHipIndex, in: landmarks, imageSize: imageSize)
    let leftKnee = confidentLandmarkPoint(Self.leftKneeIndex, in: landmarks, imageSize: imageSize)
    let rightKnee = confidentLandmarkPoint(Self.rightKneeIndex, in: landmarks, imageSize: imageSize)
    let leftAnkle = confidentLandmarkPoint(Self.leftAnkleIndex, in: landmarks, imageSize: imageSize)
    let rightAnkle = confidentLandmarkPoint(Self.rightAnkleIndex, in: landmarks, imageSize: imageSize)
    let shoulderPoints = [leftShoulder?.point, rightShoulder?.point].compactMap { $0 }
    let hipPoints = [leftHip?.point, rightHip?.point].compactMap { $0 }
    // The far-side leg is often briefly hidden at landing in a side-view
    // recording. Keep a usable torso frame, and later require a full
    // hip-knee-ankle chain only on the side actually being measured.
    guard !shoulderPoints.isEmpty, !hipPoints.isEmpty else {
      return nil
    }
    let shoulderCenter = centerOfPoints(shoulderPoints)
    let hipCenter = centerOfPoints(hipPoints)
    let anklePoints = [leftAnkle?.point, rightAnkle?.point].compactMap { $0 }
    let torsoScale = distance(shoulderCenter, hipCenter)
    let legScale = anklePoints.isEmpty
      ? 0
      : distance(hipCenter, centerOfPoints(anklePoints))
    let bodyScale = max(torsoScale, legScale)
    guard bodyScale >= Self.minimumBodyScalePx else {
      return nil
    }

    let leftHeel = confidentLandmarkPoint(Self.leftHeelIndex, in: landmarks, imageSize: imageSize)
    let rightHeel = confidentLandmarkPoint(Self.rightHeelIndex, in: landmarks, imageSize: imageSize)
    let leftToe = confidentLandmarkPoint(Self.leftFootIndex, in: landmarks, imageSize: imageSize)
    let rightToe = confidentLandmarkPoint(Self.rightFootIndex, in: landmarks, imageSize: imageSize)
    let leftElbow = confidentLandmarkPoint(Self.leftElbowIndex, in: landmarks, imageSize: imageSize)
    let rightElbow = confidentLandmarkPoint(Self.rightElbowIndex, in: landmarks, imageSize: imageSize)
    let leftWrist = confidentLandmarkPoint(Self.leftWristIndex, in: landmarks, imageSize: imageSize)
    let rightWrist = confidentLandmarkPoint(Self.rightWristIndex, in: landmarks, imageSize: imageSize)

    return FrameSample(
      timestampMs: timestampMs,
      imageWidth: Int(imageSize.width.rounded()),
      imageHeight: Int(imageSize.height.rounded()),
      leftShoulder: leftShoulder?.point,
      rightShoulder: rightShoulder?.point,
      leftHip: leftHip?.point,
      rightHip: rightHip?.point,
      leftKnee: leftKnee?.point,
      rightKnee: rightKnee?.point,
      shoulderCenter: shoulderCenter,
      hipCenter: hipCenter,
      leftAnkle: leftAnkle?.point,
      rightAnkle: rightAnkle?.point,
      leftHeel: leftHeel?.point,
      rightHeel: rightHeel?.point,
      leftToe: leftToe?.point,
      rightToe: rightToe?.point,
      leftElbow: leftElbow?.point,
      rightElbow: rightElbow?.point,
      leftWrist: leftWrist?.point,
      rightWrist: rightWrist?.point,
      leftShoulderConfidence: leftShoulder?.confidence,
      rightShoulderConfidence: rightShoulder?.confidence,
      leftHipConfidence: leftHip?.confidence,
      rightHipConfidence: rightHip?.confidence,
      leftKneeConfidence: leftKnee?.confidence,
      rightKneeConfidence: rightKnee?.confidence,
      leftAnkleConfidence: leftAnkle?.confidence,
      rightAnkleConfidence: rightAnkle?.confidence,
      leftHeelConfidence: leftHeel?.confidence,
      rightHeelConfidence: rightHeel?.confidence,
      leftToeConfidence: leftToe?.confidence,
      rightToeConfidence: rightToe?.confidence,
      leftElbowConfidence: leftElbow?.confidence,
      rightElbowConfidence: rightElbow?.confidence,
      leftWristConfidence: leftWrist?.confidence,
      rightWristConfidence: rightWrist?.confidence,
      bodyScale: bodyScale
    )
  }

  private func confidentLandmarkPoint(
    _ index: Int,
    in landmarks: [NormalizedLandmark],
    imageSize: CGSize
  ) -> ConfidentPoint? {
    guard index >= 0, index < landmarks.count else {
      return nil
    }
    let landmark = landmarks[index]
    let confidence = landmarkConfidence(landmark)
    guard confidence >= Self.minimumLikelihood else {
      return nil
    }
    return ConfidentPoint(
      point: CGPoint(
        x: Double(landmark.x) * Double(imageSize.width),
        y: Double(landmark.y) * Double(imageSize.height)
      ),
      confidence: Double(confidence)
    )
  }

  private func landmarkConfidence(_ landmark: NormalizedLandmark) -> Float {
    let visibility = landmark.visibility?.floatValue
    let presence = landmark.presence?.floatValue
    let confidence: Float
    switch (visibility, presence) {
    case let (visibility?, presence?):
      confidence = min(visibility, presence)
    case let (visibility?, nil):
      confidence = visibility
    case let (nil, presence?):
      confidence = presence
    default:
      confidence = 0
    }
    return min(1, max(0, confidence))
  }

  private func landmarkConfidence(_ landmark: Landmark) -> Float {
    let visibility = landmark.visibility?.floatValue
    let presence = landmark.presence?.floatValue
    let confidence: Float
    switch (visibility, presence) {
    case let (visibility?, presence?):
      confidence = min(visibility, presence)
    case let (visibility?, nil):
      confidence = visibility
    case let (nil, presence?):
      confidence = presence
    default:
      confidence = 0
    }
    return min(1, max(0, confidence))
  }

  private func resolveDirection(from samples: [FrameSample]) -> AnalysisDirection {
    guard let first = samples.first, let last = samples.last else {
      return .stationary
    }
    let hipMovement = Double(last.hipCenter.x - first.hipCenter.x)
    let averageScale = max(samples.map(\.bodyScale).reduce(0, +) / Double(samples.count), 1.0)
    if abs(hipMovement) >= averageScale * Self.stationaryThresholdRatio {
      return hipMovement > 0 ? .leftToRight : .rightToLeft
    }

    // On a treadmill the hips stay in one image location. Heel-toe
    // orientation still establishes a facing side, which lets the evidence
    // layer pair posture and landing values to their measured frames.
    let footDirections = samples.flatMap { sample in
      FootSide.allCases.compactMap { side -> Double? in
        guard let foot = sample.footBottom(side) else {
          return nil
        }
        let normalizedDirection =
          Double(foot.toe.x - foot.heel.x) / max(sample.bodyScale, 1.0)
        return abs(normalizedDirection) >= Self.minimumFacingDirectionRatio
          ? normalizedDirection
          : nil
      }
    }
    guard let facingDirection = percentile(footDirections, fraction: 0.5),
      abs(facingDirection) >= Self.minimumFacingDirectionRatio
    else {
      return .stationary
    }
    return facingDirection > 0 ? .leftToRight : .rightToLeft
  }

  private func midpoint(_ first: CGPoint, _ second: CGPoint) -> CGPoint {
    CGPoint(x: (first.x + second.x) / 2, y: (first.y + second.y) / 2)
  }

  private func centerOfPoints(_ points: [CGPoint]) -> CGPoint {
    CGPoint(
      x: points.map(\.x).reduce(0, +) / CGFloat(points.count),
      y: points.map(\.y).reduce(0, +) / CGFloat(points.count)
    )
  }

  private func distance(_ first: CGPoint, _ second: CGPoint) -> Double {
    let dx = Double(first.x - second.x)
    let dy = Double(first.y - second.y)
    return hypot(dx, dy)
  }

  private func roundTo3(_ value: Double) -> Double {
    (value * 1000).rounded(.towardZero) / 1000
  }

  private struct PosePassResult {
    let samples: [FrameSample]
    let poseFrames: [[String: Any]]
    let sharpnessValues: [Double]
  }

  private struct ConfidentPoint {
    let point: CGPoint
    let confidence: Double
  }

  private struct ContactCandidateSet {
    let windows: [ContactCandidate]
    let groundLine: GroundLine
  }

  private struct GroundLine {
    let slope: Double
    let intercept: Double

    func y(at x: Double) -> Double {
      slope * x + intercept
    }
  }

  private struct GroundPoint {
    let x: Double
    let y: Double
    let bodyScale: Double
  }

  private struct FootObservation {
    let sample: FrameSample
    let side: FootSide
    let footEvidence: FootBottomEvidence
  }

  private struct ContactCandidate {
    let side: FootSide
    let centerTimestampMs: Int
    let startTimestampMs: Int
    let endTimestampMs: Int
    let confidence: Double
  }

  private struct ContactFrameAnalysis {
    let timestampMs: Int
    let windowCenterTimestampMs: Int
    let side: FootSide
    let footStrikeRatio: Double
    let kneeAngleDegrees: Double
    let confidence: Double
    let isKinematicEstimate: Bool
  }

  private struct ContactProxyCandidate {
    let sample: FrameSample
    let side: FootSide
    let landmarkConfidence: Double
  }

  private struct ContactFrameSelection {
    let contact: ContactFrameAnalysis?
    let candidateFrameCount: Int
    let rejectedFrameCounts: [String: Int]
  }

  private struct ContactWindowValidation {
    let window: ContactCandidate
    let contact: ContactFrameAnalysis?
    let candidateFrameCount: Int
    let rejectedFrameCounts: [String: Int]
  }

  private struct ContactFrameCandidate {
    let sample: FrameSample
    let side: FootSide
    let footEvidence: FootBottomEvidence
    let proximity: Double
    let tolerance: Double
    let confidence: Double
    let inGroundBand: Bool
  }

  private struct FootBottomEvidence {
    let bottomPoint: CGPoint
    let ankle: CGPoint
    let heel: CGPoint
    let toe: CGPoint
    let confidence: Double
  }

  private struct PerspectiveQuality {
    let evaluatedFrameCount: Int
    let medianBodyScaleRatio: Double
    let minBodyScaleRatio: Double
    let visibilityCoverage: Double
    let sideViewScore: Double
    let scaleDriftRatio: Double
    let cutOffFrameRatio: Double
    let issues: [String]

    var payload: [String: Any] {
      [
        "evaluatedFrameCount": evaluatedFrameCount,
        "medianBodyScaleRatio": medianBodyScaleRatio,
        "minBodyScaleRatio": minBodyScaleRatio,
        "visibilityCoverage": visibilityCoverage,
        "sideViewScore": sideViewScore,
        "scaleDriftRatio": scaleDriftRatio,
        "cutOffFrameRatio": cutOffFrameRatio,
        "issues": issues,
      ]
    }
  }

  private struct FrameSample {
    let timestampMs: Int
    let imageWidth: Int
    let imageHeight: Int
    let leftShoulder: CGPoint?
    let rightShoulder: CGPoint?
    let leftHip: CGPoint?
    let rightHip: CGPoint?
    let leftKnee: CGPoint?
    let rightKnee: CGPoint?
    let shoulderCenter: CGPoint
    let hipCenter: CGPoint
    let leftAnkle: CGPoint?
    let rightAnkle: CGPoint?
    let leftHeel: CGPoint?
    let rightHeel: CGPoint?
    let leftToe: CGPoint?
    let rightToe: CGPoint?
    let leftElbow: CGPoint?
    let rightElbow: CGPoint?
    let leftWrist: CGPoint?
    let rightWrist: CGPoint?
    let leftShoulderConfidence: Double?
    let rightShoulderConfidence: Double?
    let leftHipConfidence: Double?
    let rightHipConfidence: Double?
    let leftKneeConfidence: Double?
    let rightKneeConfidence: Double?
    let leftAnkleConfidence: Double?
    let rightAnkleConfidence: Double?
    let leftHeelConfidence: Double?
    let rightHeelConfidence: Double?
    let leftToeConfidence: Double?
    let rightToeConfidence: Double?
    let leftElbowConfidence: Double?
    let rightElbowConfidence: Double?
    let leftWristConfidence: Double?
    let rightWristConfidence: Double?
    let bodyScale: Double

    var sideViewWidthRatio: Double? {
      func pointDistance(_ first: CGPoint, _ second: CGPoint) -> Double {
        hypot(Double(first.x - second.x), Double(first.y - second.y))
      }
      var widths: [Double] = []
      if let leftShoulder, let rightShoulder {
        widths.append(pointDistance(leftShoulder, rightShoulder) / max(bodyScale, 1.0))
      }
      if let leftHip, let rightHip {
        widths.append(pointDistance(leftHip, rightHip) / max(bodyScale, 1.0))
      }
      guard !widths.isEmpty else {
        return nil
      }
      return widths.reduce(0, +) / Double(widths.count)
    }

    var touchesFrameEdge: Bool {
      let marginX = Double(imageWidth) * RunningPoseAnalysisChannel.edgeCutOffMarginRatio
      let marginY = Double(imageHeight) * RunningPoseAnalysisChannel.edgeCutOffMarginRatio
      return [
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
      ].compactMap { $0 }.contains { point in
        Double(point.x) <= marginX ||
          Double(point.x) >= Double(imageWidth) - marginX ||
          Double(point.y) <= marginY ||
          Double(point.y) >= Double(imageHeight) - marginY
      }
    }

    var coreLandmarkConfidence: Double {
      let values = [
        leftShoulderConfidence,
        rightShoulderConfidence,
        leftHipConfidence,
        rightHipConfidence,
        leftKneeConfidence,
        rightKneeConfidence,
        leftAnkleConfidence,
        rightAnkleConfidence,
      ].compactMap { $0 }
      guard !values.isEmpty else {
        return 0
      }
      return values.reduce(0, +) / Double(values.count)
    }

    var armLandmarkConfidence: Double? {
      var values: [Double] = []
      if let leftShoulderConfidence, let leftElbowConfidence, let leftWristConfidence {
        values.append((leftShoulderConfidence + leftElbowConfidence + leftWristConfidence) / 3)
      }
      if let rightShoulderConfidence, let rightElbowConfidence, let rightWristConfidence {
        values.append((rightShoulderConfidence + rightElbowConfidence + rightWristConfidence) / 3)
      }
      guard !values.isEmpty else {
        return nil
      }
      return values.reduce(0, +) / Double(values.count)
    }

    func forwardLeanDegrees(direction: AnalysisDirection) -> Double {
      let verticalTravel = max(1.0, Double(hipCenter.y - shoulderCenter.y))
      let forwardOffset: Double
      switch direction {
      case .leftToRight:
        forwardOffset = Double(shoulderCenter.x - hipCenter.x)
      case .rightToLeft:
        forwardOffset = Double(hipCenter.x - shoulderCenter.x)
      case .stationary:
        forwardOffset = abs(Double(shoulderCenter.x - hipCenter.x))
      }

      if direction != .stationary && forwardOffset <= 0 {
        return 0
      }
      return atan2(abs(forwardOffset), verticalTravel) * 180 / .pi
    }

    func leadFootStrikeRatio(direction: AnalysisDirection) -> Double {
      let leftFoot = leftHeel ?? leftAnkle
      let rightFoot = rightHeel ?? rightAnkle
      guard leftFoot != nil || rightFoot != nil else {
        return 0
      }
      let forwardReachPx: Double
      switch direction {
      case .leftToRight:
        forwardReachPx = Double(
          max(leftFoot?.x ?? -CGFloat.infinity, rightFoot?.x ?? -CGFloat.infinity) - hipCenter.x
        )
      case .rightToLeft:
        forwardReachPx = Double(
          hipCenter.x - min(leftFoot?.x ?? CGFloat.infinity, rightFoot?.x ?? CGFloat.infinity)
        )
      case .stationary:
        forwardReachPx = max(
          leftFoot.map { abs(Double($0.x - hipCenter.x)) } ?? 0,
          rightFoot.map { abs(Double($0.x - hipCenter.x)) } ?? 0
        )
      }
      return forwardReachPx / max(bodyScale, 1.0)
    }

    func footBottom(_ side: FootSide) -> FootBottomEvidence? {
      guard let ankle = side == .left ? leftAnkle : rightAnkle else {
        return nil
      }
      let heel = side == .left ? leftHeel : rightHeel
      let toe = side == .left ? leftToe : rightToe
      let ankleConfidence = side == .left
        ? leftAnkleConfidence
        : rightAnkleConfidence
      let heelConfidence = side == .left ? leftHeelConfidence : rightHeelConfidence
      let toeConfidence = side == .left ? leftToeConfidence : rightToeConfidence
      let bottomPoint = ([ankle] + [heel, toe].compactMap { $0 }).max { first, second in
        first.y < second.y
      } ?? ankle
      guard let confidence = [ankleConfidence, heelConfidence, toeConfidence]
        .compactMap({ $0 })
        .min()
      else {
        return nil
      }
      return FootBottomEvidence(
        bottomPoint: bottomPoint,
        ankle: ankle,
        heel: heel ?? ankle,
        toe: toe ?? ankle,
        confidence: confidence
      )
    }

    func contactFootStrikeRatio(
      _ side: FootSide,
      direction: AnalysisDirection
    ) -> Double {
      guard let foot = footBottom(side) else {
        return 0
      }
      let footX = Double(foot.ankle.x)
      let forwardReachPx: Double
      switch direction {
      case .leftToRight:
        forwardReachPx = footX - Double(hipCenter.x)
      case .rightToLeft:
        forwardReachPx = Double(hipCenter.x) - footX
      case .stationary:
        forwardReachPx = abs(footX - Double(hipCenter.x))
      }
      return max(0, forwardReachPx) / max(bodyScale, 1.0)
    }

    func contactKneeAngleDegrees(_ side: FootSide) -> Double? {
      let hip = side == .left ? leftHip : rightHip
      let knee = side == .left ? leftKnee : rightKnee
      let ankle = side == .left ? leftAnkle : rightAnkle
      guard let hip, let knee, let ankle else {
        return nil
      }
      return jointAngle(hip, knee, ankle)
    }

    func contactLandmarkConfidence(
      _ side: FootSide,
      footEvidence: FootBottomEvidence
    ) -> Double? {
      let hipConfidence = side == .left ? leftHipConfidence : rightHipConfidence
      let kneeConfidence = side == .left ? leftKneeConfidence : rightKneeConfidence
      let hip = side == .left ? leftHip : rightHip
      let knee = side == .left ? leftKnee : rightKnee
      guard hip != nil, knee != nil,
        let hipConfidence,
        let kneeConfidence
      else {
        return nil
      }
      return min(footEvidence.confidence, min(hipConfidence, kneeConfidence))
    }

    var averageElbowAngleDegrees: Double? {
      var angles: [Double] = []
      if let leftShoulder, let leftElbow, let leftWrist {
        angles.append(jointAngle(leftShoulder, leftElbow, leftWrist))
      }
      if let rightShoulder, let rightElbow, let rightWrist {
        angles.append(jointAngle(rightShoulder, rightElbow, rightWrist))
      }
      guard !angles.isEmpty else {
        return nil
      }
      return angles.reduce(0, +) / Double(angles.count)
    }

    func leadKneeAngleDegrees(direction: AnalysisDirection) -> Double? {
      let leftFoot = leftHeel ?? leftAnkle
      let rightFoot = rightHeel ?? rightAnkle
      guard leftFoot != nil || rightFoot != nil else {
        return nil
      }
      let useLeft: Bool
      switch direction {
      case .leftToRight:
        useLeft = (leftFoot?.x ?? -CGFloat.infinity) >= (rightFoot?.x ?? -CGFloat.infinity)
      case .rightToLeft:
        useLeft = (leftFoot?.x ?? CGFloat.infinity) <= (rightFoot?.x ?? CGFloat.infinity)
      case .stationary:
        useLeft =
          (leftFoot.map { abs(Double($0.x - hipCenter.x)) } ?? 0) >=
          (rightFoot.map { abs(Double($0.x - hipCenter.x)) } ?? 0)
      }
      let hip = useLeft ? leftHip : rightHip
      let knee = useLeft ? leftKnee : rightKnee
      let ankle = useLeft ? leftAnkle : rightAnkle
      guard let hip, let knee, let ankle else {
        return nil
      }
      return jointAngle(hip, knee, ankle)
    }

    private func jointAngle(_ first: CGPoint, _ vertex: CGPoint, _ third: CGPoint) -> Double {
      let firstDx = Double(first.x - vertex.x)
      let firstDy = Double(first.y - vertex.y)
      let secondDx = Double(third.x - vertex.x)
      let secondDy = Double(third.y - vertex.y)
      let firstLength = hypot(firstDx, firstDy)
      let secondLength = hypot(secondDx, secondDy)
      guard firstLength > 0, secondLength > 0 else {
        return 180
      }
      let cosine =
        ((firstDx * secondDx) + (firstDy * secondDy)) / (firstLength * secondLength)
      return acos(max(-1, min(1, cosine))) * 180 / .pi
    }
  }

  private enum AnalysisDirection: String {
    case leftToRight
    case rightToLeft
    case stationary
  }

  private enum FootSide: String, CaseIterable {
    case left
    case right
  }

  private struct AnalysisError: Error {
    let code: String
    let message: String
  }

  private static let channelName = "football_note/running_pose_analysis"
  private static let methodName = "analyzeRunningVideo"
  private static let evidenceFramesMethodName = "extractRunningEvidenceFrames"
  private static let liveFrameMethodName = "analyzeRunningLiveFrame"
  private static let coarseTargetFps = 8
  private static let coarseFrameIntervalMs = 125
  private static let maxCoarseFrameBudget = 481
  private static let minimumValidFrames = 6
  private static let minimumSharpnessSampleCount = 6
  private static let minimumMedianSharpness = 0.018
  private static let sharpnessHorizontalInsetFraction = 0.10
  private static let sharpnessTopFraction = 0.32
  private static let sharpnessBottomFraction = 0.68
  private static let sharpnessSampleWidth = 96
  private static let sharpnessSampleHeight = 64
  private static let minVideoDurationMs = 1500
  private static let maxVideoDurationMs = 60000
  private static let minimumLikelihood: Float = 0.35
  private static let minimumBodyScalePx = 40.0
  private static let mediaPipePoseLandmarkCount = 33
  private static let stationaryThresholdRatio = 0.12
  private static let denseTargetFps = 30
  private static let denseFrameIntervalMs = 33
  private static let denseWindowRadiusMs = 500
  private static let maxDenseFrameBudget = 240
  private static let maxContactWindows = 8
  private static let minimumContactCenterSeparationMs = 320
  private static let minimumDistinctContactSeparationMs = 120
  private static let minimumFacingDirectionRatio = 0.02
  private static let minimumValidatedContactFrames = 3
  private static let minimumContactFrameConfidence = 0.34
  private static let kinematicContactConfidencePenalty = 0.82
  private static let kinematicContactLowerPercentile = 0.65
  private static let kinematicContactMotionToleranceRatio = 0.025
  private static let contactProxyConfidencePenalty = 0.60
  private static let coarseContactProxyConfidencePenalty = 0.42
  private static let coarseContactGroundToleranceRatio = 0.15
  private static let denseContactGroundToleranceRatio = 0.16
  private static let localFootExtremumToleranceRatio = 0.035
  private static let contactMotionToleranceRatio = 0.035
  private static let contactMotionNeighborGapMs = 100
  private static let groundLineSampleFraction = 0.45
  private static let groundLineMinimumSamples = 3
  private static let minimumBodyScaleRatio = 0.12
  private static let minimumSideViewScore = 0.46
  private static let maximumScaleDriftRatio = 0.34
  private static let maximumCutOffFrameRatio = 0.18
  private static let minimumVisibilityCoverage = 0.62
  private static let edgeCutOffMarginRatio = 0.025
  private static let modelResourceName = "pose_landmarker_full"
  private static let modelResourceExtension = "task"
  private static let leftShoulderIndex = 11
  private static let rightShoulderIndex = 12
  private static let leftElbowIndex = 13
  private static let rightElbowIndex = 14
  private static let leftWristIndex = 15
  private static let rightWristIndex = 16
  private static let leftHipIndex = 23
  private static let rightHipIndex = 24
  private static let leftKneeIndex = 25
  private static let rightKneeIndex = 26
  private static let leftAnkleIndex = 27
  private static let rightAnkleIndex = 28
  private static let leftHeelIndex = 29
  private static let rightHeelIndex = 30
  private static let leftFootIndex = 31
  private static let rightFootIndex = 32
}
