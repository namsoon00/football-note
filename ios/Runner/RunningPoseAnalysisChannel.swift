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
    guard call.method == Self.methodName else {
      result(FlutterMethodNotImplemented)
      return
    }

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

    let imageGenerator = AVAssetImageGenerator(asset: asset)
    imageGenerator.appliesPreferredTrackTransform = true
    imageGenerator.requestedTimeToleranceBefore = .zero
    imageGenerator.requestedTimeToleranceAfter = .zero

    let coarsePoseLandmarker = try makePoseLandmarker()
    let coarsePass = try runPosePass(
      poseLandmarker: coarsePoseLandmarker,
      imageGenerator: imageGenerator,
      timestampsMs: coarseSampleTimestamps(durationMs: durationMs),
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

    let direction = resolveDirection(from: frameSamples)
    let averageScale = max(frameSamples.map(\.bodyScale).reduce(0, +) / Double(frameSamples.count), 1.0)
    let leanDegrees =
      frameSamples.map { $0.forwardLeanDegrees(direction: direction) }.reduce(0, +) /
      Double(frameSamples.count)
    let shoulderYs = frameSamples.map { Double($0.shoulderCenter.y) }
    let bounceRatio =
      ((shoulderYs.max() ?? 0) - (shoulderYs.min() ?? 0)) / averageScale
    let detectedCandidateSet = deriveContactCandidateWindows(
      from: frameSamples,
      durationMs: durationMs
    )
    let candidateSet = detectedCandidateSet.windows.isEmpty
      ? fallbackContactCandidateWindows(
        from: frameSamples,
        durationMs: durationMs
      )
      : detectedCandidateSet
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
    let contactFrames = validateDenseContactFrames(
      densePass.samples,
      windows: candidateSet.windows,
      groundY: candidateSet.groundY,
      direction: direction
    )
    let uniqueContactFrameCount = Set(contactFrames.map(\.timestampMs)).count
    let usesContactProxy = uniqueContactFrameCount < Self.minimumValidatedContactFrames
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
    let contactQualityReason = usesContactProxy ? "contact_phase_proxy" : nil
    let coreConfidence = frameSamples.map(\.coreLandmarkConfidence).reduce(0, +) /
      Double(frameSamples.count)
    let armConfidenceValues = frameSamples.compactMap(\.armLandmarkConfidence)
    let armConfidence = armConfidenceValues.reduce(0, +) /
      Double(armConfidenceValues.count)

    return [
      "durationMs": durationMs,
      "sampledFrames": Self.sampleCount,
      "validFrames": frameSamples.count,
      "direction": direction.rawValue,
      "forwardLeanDegrees": roundTo3(leanDegrees),
      "verticalBounceRatio": roundTo3(max(0, bounceRatio)),
      "footStrikeDistanceRatio": roundTo3(footStrikeRatio),
      "stanceKneeAngleDegrees": roundTo3(stanceKneeAngle),
      "elbowAngleDegrees": roundTo3(elbowAngle),
      "metricQualities": [
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
      ],
      "coarseSamples": sampleSummaryPayload(
        attemptedFrames: Self.sampleCount,
        validFrames: coarsePass.samples.count,
        poseFrameCount: coarsePass.poseFrames.count
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
        contactFrames: contactFrames
      ),
      "validatedContactFrameTimestampsMs": Array(
        Set(contactFrames.map(\.timestampMs))
      ).sorted(),
      "contactConfidence": roundTo3(contactConfidence),
      "poseFrames": mergePoseFrames(
        coarsePoseFrames: coarsePass.poseFrames,
        densePoseFrames: densePass.poseFrames
      ),
    ]
  }

  private func makePoseLandmarker() throws -> PoseLandmarker {
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
    options.runningMode = .video
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
    (0..<Self.sampleCount).map { index in
      let fraction: Double
      if Self.sampleCount == 1 {
        fraction = 0.5
      } else {
        let progress = Double(index) / Double(Self.sampleCount - 1)
        fraction =
          Self.sampleStartFraction +
          ((Self.sampleEndFraction - Self.sampleStartFraction) * progress)
      }
      return min(durationMs, max(0, Int((Double(durationMs) * fraction).rounded())))
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

  private func deriveContactCandidateWindows(
    from samples: [FrameSample],
    durationMs: Int
  ) -> ContactCandidateSet {
    let footBottoms = samples.flatMap { sample in
      FootSide.allCases.compactMap { side in
        sample.footBottom(side).map { evidence in (sample, evidence) }
      }
    }
    guard let groundY = footBottoms.map({ Double($0.1.bottomPoint.y) }).max() else {
      return ContactCandidateSet(windows: [], groundY: 0)
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
        let nearGround = groundY - bottomY <= groundTolerance
        let localExtremum =
          (previousY == nil || bottomY >= previousY! - localTolerance) &&
          (nextY == nil || bottomY >= nextY! - localTolerance)
        guard nearGround, localExtremum else {
          continue
        }
        let proximityFactor = min(
          1.0,
          max(0.0, 1.0 - (max(0.0, groundY - bottomY) / max(1.0, groundTolerance)))
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

    var selected: [ContactCandidate] = []
    let rankedCandidates = candidates.sorted {
      if $0.confidence == $1.confidence {
        return $0.centerTimestampMs < $1.centerTimestampMs
      }
      return $0.confidence > $1.confidence
    }
    for candidate in rankedCandidates {
      let overlapsExisting = selected.contains { selectedCandidate in
        selectedCandidate.side == candidate.side &&
        (
          abs(selectedCandidate.centerTimestampMs - candidate.centerTimestampMs) <
            Self.minimumContactCenterSeparationMs ||
            candidate.startTimestampMs <= selectedCandidate.endTimestampMs &&
            candidate.endTimestampMs >= selectedCandidate.startTimestampMs
        )
      }
      if !overlapsExisting {
        selected.append(candidate)
      }
      if selected.count >= Self.maxContactWindows {
        break
      }
    }

    return ContactCandidateSet(
      windows: selected.sorted { $0.centerTimestampMs < $1.centerTimestampMs },
      groundY: groundY
    )
  }

  private func fallbackContactCandidateWindows(
    from samples: [FrameSample],
    durationMs: Int
  ) -> ContactCandidateSet {
    let footBottoms = samples.flatMap { sample in
      FootSide.allCases.compactMap { side in
        sample.footBottom(side).map { evidence in (sample, evidence) }
      }
    }
    guard let groundY = footBottoms.map({ Double($0.1.bottomPoint.y) }).max() else {
      return ContactCandidateSet(windows: [], groundY: 0)
    }

    let windows = FootSide.allCases.compactMap { side -> ContactCandidate? in
      let sideEvidence = samples.compactMap { sample in
        sample.footBottom(side).map { evidence in (sample, evidence) }
      }
      guard let candidate = sideEvidence.max(by: {
        $0.1.bottomPoint.y < $1.1.bottomPoint.y
      }) else {
        return nil
      }
      return ContactCandidate(
        side: side,
        centerTimestampMs: candidate.0.timestampMs,
        startTimestampMs: max(0, candidate.0.timestampMs - Self.denseWindowRadiusMs),
        endTimestampMs: min(durationMs, candidate.0.timestampMs + Self.denseWindowRadiusMs),
        confidence: min(1.0, max(0.0, candidate.1.confidence))
      )
    }

    return ContactCandidateSet(
      windows: windows.sorted { $0.centerTimestampMs < $1.centerTimestampMs },
      groundY: groundY
    )
  }

  private func denseTimestampsForContactWindows(
    _ windows: [ContactCandidate],
    durationMs: Int
  ) -> [Int] {
    var timestampDistances: [Int: Int] = [:]
    for window in windows {
      var timestampMs = window.startTimestampMs
      while timestampMs <= window.endTimestampMs {
        recordDenseTimestamp(
          &timestampDistances,
          timestampMs: min(durationMs, max(0, timestampMs)),
          centerTimestampMs: window.centerTimestampMs
        )
        timestampMs += Self.denseFrameIntervalMs
      }
      recordDenseTimestamp(
        &timestampDistances,
        timestampMs: min(durationMs, max(0, window.centerTimestampMs)),
        centerTimestampMs: window.centerTimestampMs
      )
    }
    return timestampDistances
      .sorted {
        if $0.value == $1.value {
          return $0.key < $1.key
        }
        return $0.value < $1.value
      }
      .prefix(Self.maxDenseFrameBudget)
      .map(\.key)
      .sorted()
  }

  private func recordDenseTimestamp(
    _ timestampDistances: inout [Int: Int],
    timestampMs: Int,
    centerTimestampMs: Int
  ) {
    let distance = abs(timestampMs - centerTimestampMs)
    if let existing = timestampDistances[timestampMs], existing <= distance {
      return
    }
    timestampDistances[timestampMs] = distance
  }

  private func validateDenseContactFrames(
    _ samples: [FrameSample],
    windows: [ContactCandidate],
    groundY: Double,
    direction: AnalysisDirection
  ) -> [ContactFrameAnalysis] {
    let orderedSamples = samples.sorted { $0.timestampMs < $1.timestampMs }
    var selectedByTimestamp: [Int: ContactFrameAnalysis] = [:]
    for window in windows.sorted(by: { $0.centerTimestampMs < $1.centerTimestampMs }) {
      guard
        let contactFrame = selectDenseContactFrame(
          for: window,
          orderedSamples: orderedSamples,
          groundY: groundY,
          direction: direction
        )
      else {
        continue
      }
      if let existing = selectedByTimestamp[contactFrame.timestampMs],
         existing.confidence >= contactFrame.confidence {
        continue
      }
      selectedByTimestamp[contactFrame.timestampMs] = contactFrame
    }
    return selectedByTimestamp.keys.sorted().compactMap { selectedByTimestamp[$0] }
  }

  private func contactProxyFrames(
    from samples: [FrameSample],
    windows: [ContactCandidate],
    direction: AnalysisDirection,
    confidencePenalty: Double
  ) -> [ContactFrameAnalysis] {
    var selectedByTimestamp: [Int: ContactFrameAnalysis] = [:]
    for window in windows.sorted(by: { $0.centerTimestampMs < $1.centerTimestampMs }) {
      let candidate = samples
        .filter { sample in
          sample.timestampMs >= window.startTimestampMs &&
            sample.timestampMs <= window.endTimestampMs
        }
        .compactMap { sample -> (sample: FrameSample, evidence: FootBottomEvidence)? in
          guard let evidence = sample.footBottom(window.side) else {
            return nil
          }
          return (sample, evidence)
        }
        .sorted { first, second in
          let firstDistance = abs(first.sample.timestampMs - window.centerTimestampMs)
          let secondDistance = abs(second.sample.timestampMs - window.centerTimestampMs)
          if firstDistance != secondDistance {
            return firstDistance < secondDistance
          }
          return first.sample.timestampMs < second.sample.timestampMs
        }
        .first
      guard let candidate else {
        continue
      }
      let confidence = min(
        1.0,
        max(
          0.0,
          min(
            window.confidence,
            candidate.sample.contactLandmarkConfidence(
              window.side,
              footEvidence: candidate.evidence
            )
          ) * confidencePenalty
        )
      )
      let proxy = ContactFrameAnalysis(
        timestampMs: candidate.sample.timestampMs,
        windowCenterTimestampMs: window.centerTimestampMs,
        side: window.side,
        footStrikeRatio: candidate.sample.contactFootStrikeRatio(
          window.side,
          direction: direction
        ),
        kneeAngleDegrees: candidate.sample.contactKneeAngleDegrees(window.side),
        confidence: confidence
      )
      if let existing = selectedByTimestamp[proxy.timestampMs],
         existing.confidence >= proxy.confidence {
        continue
      }
      selectedByTimestamp[proxy.timestampMs] = proxy
    }
    return selectedByTimestamp.keys.sorted().compactMap { selectedByTimestamp[$0] }
  }

  private func selectDenseContactFrame(
    for window: ContactCandidate,
    orderedSamples: [FrameSample],
    groundY: Double,
    direction: AnalysisDirection
  ) -> ContactFrameAnalysis? {
    let candidates = orderedSamples
      .filter { sample in
        sample.timestampMs >= window.startTimestampMs &&
        sample.timestampMs <= window.endTimestampMs
      }
      .compactMap { sample in
        denseContactCandidate(sample, side: window.side, groundY: groundY)
      }
    var eligibleCandidates: [ContactFrameCandidate] = []
    var persistentCandidates: [ContactFrameCandidate] = []
    for index in candidates.indices {
      let current = candidates[index]
      guard isEligibleContact(current) else {
        continue
      }
      eligibleCandidates.append(current)
      let previous = index > 0 ? candidates[index - 1] : nil
      let next = index + 1 < candidates.count ? candidates[index + 1] : nil
      if enteredGroundBand(current, previous: previous) {
        return contactFrame(from: current, window: window, direction: direction)
      }
      if hasGroundBandPersistence(current, previous: previous, next: next) {
        persistentCandidates.append(current)
      }
    }
    let candidatesForSelection = persistentCandidates.isEmpty
      ? eligibleCandidates
      : persistentCandidates
    guard
      let selected = candidatesForSelection.sorted(by: { first, second in
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
    else {
      return nil
    }
    return contactFrame(from: selected, window: window, direction: direction)
  }

  private func denseContactCandidate(
    _ sample: FrameSample,
    side: FootSide,
    groundY: Double
  ) -> ContactFrameCandidate? {
    guard let evidence = sample.footBottom(side) else {
      return nil
    }
    let tolerance = max(1.0, sample.bodyScale * Self.denseContactGroundToleranceRatio)
    let proximity = groundY - Double(evidence.bottomPoint.y)
    let inGroundBand = proximity >= -tolerance * 0.35 && proximity <= tolerance
    let proximityFactor = min(1.0, max(0.0, 1.0 - (max(0.0, proximity) / tolerance)))
    let confidence = min(
      1.0,
      max(
        0.0,
        sample.contactLandmarkConfidence(side, footEvidence: evidence) *
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
      Self.denseFrameIntervalMs * 2
  }

  private func hasGroundBandPersistence(
    _ current: ContactFrameCandidate,
    previous: ContactFrameCandidate?,
    next: ContactFrameCandidate?
  ) -> Bool {
    [previous, next].compactMap { $0 }.contains { neighbor in
      isEligibleContact(neighbor) &&
        abs(neighbor.sample.timestampMs - current.sample.timestampMs) <=
        Self.denseFrameIntervalMs * 2
    }
  }

  private func contactFrame(
    from candidate: ContactFrameCandidate,
    window: ContactCandidate,
    direction: AnalysisDirection
  ) -> ContactFrameAnalysis {
    ContactFrameAnalysis(
      timestampMs: candidate.sample.timestampMs,
      windowCenterTimestampMs: window.centerTimestampMs,
      side: candidate.side,
      footStrikeRatio: candidate.sample.contactFootStrikeRatio(
        candidate.side,
        direction: direction
      ),
      kneeAngleDegrees: candidate.sample.contactKneeAngleDegrees(candidate.side),
      confidence: candidate.confidence
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

  private func contactWindowPayloads(
    windows: [ContactCandidate],
    denseTimestamps: [Int],
    contactFrames: [ContactFrameAnalysis]
  ) -> [[String: Any]] {
    windows.map { window in
      let validated = contactFrames.filter { frame in
        frame.side == window.side &&
        frame.windowCenterTimestampMs == window.centerTimestampMs &&
        frame.timestampMs >= window.startTimestampMs &&
        frame.timestampMs <= window.endTimestampMs
      }
      let confidence = validated.isEmpty
        ? 0.0
        : validated.map(\.confidence).reduce(0, +) / Double(validated.count)
      return [
        "side": window.side.rawValue,
        "startTimestampMs": window.startTimestampMs,
        "centerTimestampMs": window.centerTimestampMs,
        "endTimestampMs": window.endTimestampMs,
        "coarseConfidence": roundTo3(window.confidence),
        "denseSampleCount": denseTimestamps.filter { timestampMs in
          timestampMs >= window.startTimestampMs &&
          timestampMs <= window.endTimestampMs
        }.count,
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

    let landmarkPayloads = landmarks
      .prefix(Self.mediaPipePoseLandmarkCount)
      .enumerated()
      .map { index, landmark -> [String: Any] in
        [
          "index": index,
          "x": Double(landmark.x),
          "y": Double(landmark.y),
          "z": Double(landmark.z),
          "visibility": nullableNumber(landmark.visibility),
          "presence": nullableNumber(landmark.presence),
          "confidence": Double(landmarkConfidence(landmark)),
        ]
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

    guard
      let leftShoulder = confidentLandmarkPoint(Self.leftShoulderIndex, in: landmarks, imageSize: imageSize),
      let rightShoulder = confidentLandmarkPoint(Self.rightShoulderIndex, in: landmarks, imageSize: imageSize),
      let leftHip = confidentLandmarkPoint(Self.leftHipIndex, in: landmarks, imageSize: imageSize),
      let rightHip = confidentLandmarkPoint(Self.rightHipIndex, in: landmarks, imageSize: imageSize),
      let leftKnee = confidentLandmarkPoint(Self.leftKneeIndex, in: landmarks, imageSize: imageSize),
      let rightKnee = confidentLandmarkPoint(Self.rightKneeIndex, in: landmarks, imageSize: imageSize),
      let leftAnkle = confidentLandmarkPoint(Self.leftAnkleIndex, in: landmarks, imageSize: imageSize),
      let rightAnkle = confidentLandmarkPoint(Self.rightAnkleIndex, in: landmarks, imageSize: imageSize)
    else {
      return nil
    }

    let shoulderCenter = midpoint(leftShoulder.point, rightShoulder.point)
    let hipCenter = midpoint(leftHip.point, rightHip.point)
    let ankleCenter = midpoint(leftAnkle.point, rightAnkle.point)
    let torsoScale = distance(shoulderCenter, hipCenter)
    let legScale = distance(hipCenter, ankleCenter)
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
      leftShoulder: leftShoulder.point,
      rightShoulder: rightShoulder.point,
      leftHip: leftHip.point,
      rightHip: rightHip.point,
      leftKnee: leftKnee.point,
      rightKnee: rightKnee.point,
      shoulderCenter: shoulderCenter,
      hipCenter: hipCenter,
      leftAnkle: leftAnkle.point,
      rightAnkle: rightAnkle.point,
      leftHeel: leftHeel?.point,
      rightHeel: rightHeel?.point,
      leftToe: leftToe?.point,
      rightToe: rightToe?.point,
      leftElbow: leftElbow?.point,
      rightElbow: rightElbow?.point,
      leftWrist: leftWrist?.point,
      rightWrist: rightWrist?.point,
      leftShoulderConfidence: leftShoulder.confidence,
      rightShoulderConfidence: rightShoulder.confidence,
      leftHipConfidence: leftHip.confidence,
      rightHipConfidence: rightHip.confidence,
      leftKneeConfidence: leftKnee.confidence,
      rightKneeConfidence: rightKnee.confidence,
      leftAnkleConfidence: leftAnkle.confidence,
      rightAnkleConfidence: rightAnkle.confidence,
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

  private func resolveDirection(from samples: [FrameSample]) -> AnalysisDirection {
    guard let first = samples.first, let last = samples.last else {
      return .stationary
    }
    let hipMovement = Double(last.hipCenter.x - first.hipCenter.x)
    let averageScale = max(samples.map(\.bodyScale).reduce(0, +) / Double(samples.count), 1.0)
    if abs(hipMovement) < averageScale * Self.stationaryThresholdRatio {
      return .stationary
    }
    return hipMovement > 0 ? .leftToRight : .rightToLeft
  }

  private func midpoint(_ first: CGPoint, _ second: CGPoint) -> CGPoint {
    CGPoint(x: (first.x + second.x) / 2, y: (first.y + second.y) / 2)
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
    let groundY: Double
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

  private struct FrameSample {
    let timestampMs: Int
    let leftShoulder: CGPoint
    let rightShoulder: CGPoint
    let leftHip: CGPoint
    let rightHip: CGPoint
    let leftKnee: CGPoint
    let rightKnee: CGPoint
    let shoulderCenter: CGPoint
    let hipCenter: CGPoint
    let leftAnkle: CGPoint
    let rightAnkle: CGPoint
    let leftHeel: CGPoint?
    let rightHeel: CGPoint?
    let leftToe: CGPoint?
    let rightToe: CGPoint?
    let leftElbow: CGPoint?
    let rightElbow: CGPoint?
    let leftWrist: CGPoint?
    let rightWrist: CGPoint?
    let leftShoulderConfidence: Double
    let rightShoulderConfidence: Double
    let leftHipConfidence: Double
    let rightHipConfidence: Double
    let leftKneeConfidence: Double
    let rightKneeConfidence: Double
    let leftAnkleConfidence: Double
    let rightAnkleConfidence: Double
    let leftHeelConfidence: Double?
    let rightHeelConfidence: Double?
    let leftToeConfidence: Double?
    let rightToeConfidence: Double?
    let leftElbowConfidence: Double?
    let rightElbowConfidence: Double?
    let leftWristConfidence: Double?
    let rightWristConfidence: Double?
    let bodyScale: Double

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
      ]
      return values.reduce(0, +) / Double(values.count)
    }

    var armLandmarkConfidence: Double? {
      var values: [Double] = []
      if let leftElbowConfidence, let leftWristConfidence {
        values.append((leftShoulderConfidence + leftElbowConfidence + leftWristConfidence) / 3)
      }
      if let rightElbowConfidence, let rightWristConfidence {
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
      let forwardReachPx: Double
      switch direction {
      case .leftToRight:
        forwardReachPx = Double(max(leftFoot.x, rightFoot.x) - hipCenter.x)
      case .rightToLeft:
        forwardReachPx = Double(hipCenter.x - min(leftFoot.x, rightFoot.x))
      case .stationary:
        forwardReachPx = max(
          abs(Double(leftFoot.x - hipCenter.x)),
          abs(Double(rightFoot.x - hipCenter.x))
        )
      }
      return forwardReachPx / max(bodyScale, 1.0)
    }

    func footBottom(_ side: FootSide) -> FootBottomEvidence? {
      let ankle = side == .left ? leftAnkle : rightAnkle
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
      let confidence = ([ankleConfidence] + [heelConfidence, toeConfidence].compactMap { $0 })
        .min() ?? ankleConfidence
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

    func contactKneeAngleDegrees(_ side: FootSide) -> Double {
      side == .left
        ? jointAngle(leftHip, leftKnee, leftAnkle)
        : jointAngle(rightHip, rightKnee, rightAnkle)
    }

    func contactLandmarkConfidence(
      _ side: FootSide,
      footEvidence: FootBottomEvidence
    ) -> Double {
      let hipConfidence = side == .left ? leftHipConfidence : rightHipConfidence
      let kneeConfidence = side == .left ? leftKneeConfidence : rightKneeConfidence
      return min(footEvidence.confidence, min(hipConfidence, kneeConfidence))
    }

    var averageElbowAngleDegrees: Double? {
      var angles: [Double] = []
      if let leftElbow, let leftWrist {
        angles.append(jointAngle(leftShoulder, leftElbow, leftWrist))
      }
      if let rightElbow, let rightWrist {
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
      let useLeft: Bool
      switch direction {
      case .leftToRight:
        useLeft = leftFoot.x >= rightFoot.x
      case .rightToLeft:
        useLeft = leftFoot.x <= rightFoot.x
      case .stationary:
        useLeft =
          abs(Double(leftFoot.x - hipCenter.x)) >=
          abs(Double(rightFoot.x - hipCenter.x))
      }
      return useLeft
        ? jointAngle(leftHip, leftKnee, leftAnkle)
        : jointAngle(rightHip, rightKnee, rightAnkle)
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
  private static let sampleCount = 14
  private static let minimumValidFrames = 6
  private static let minimumSharpnessSampleCount = 6
  private static let minimumMedianSharpness = 0.018
  private static let sharpnessHorizontalInsetFraction = 0.10
  private static let sharpnessTopFraction = 0.32
  private static let sharpnessBottomFraction = 0.68
  private static let sharpnessSampleWidth = 96
  private static let sharpnessSampleHeight = 64
  private static let minVideoDurationMs = 1500
  private static let sampleStartFraction = 0.15
  private static let sampleEndFraction = 0.85
  private static let minimumLikelihood: Float = 0.35
  private static let minimumBodyScalePx = 40.0
  private static let mediaPipePoseLandmarkCount = 33
  private static let stationaryThresholdRatio = 0.12
  private static let denseTargetFps = 30
  private static let denseFrameIntervalMs = 33
  private static let denseWindowRadiusMs = 180
  private static let maxDenseFrameBudget = 48
  private static let maxContactWindows = 6
  private static let minimumContactCenterSeparationMs = 120
  private static let minimumValidatedContactFrames = 2
  private static let minimumContactFrameConfidence = 0.34
  private static let contactProxyConfidencePenalty = 0.60
  private static let coarseContactProxyConfidencePenalty = 0.42
  private static let coarseContactGroundToleranceRatio = 0.12
  private static let denseContactGroundToleranceRatio = 0.13
  private static let localFootExtremumToleranceRatio = 0.025
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
