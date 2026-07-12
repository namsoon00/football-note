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

    let poseLandmarker = try makePoseLandmarker()

    var frameSamples: [FrameSample] = []
    var lastTimestampMs = 0
    for index in 0..<Self.sampleCount {
      let fraction: Double
      if Self.sampleCount == 1 {
        fraction = 0.5
      } else {
        let progress = Double(index) / Double(Self.sampleCount - 1)
        fraction =
          Self.sampleStartFraction +
          ((Self.sampleEndFraction - Self.sampleStartFraction) * progress)
      }

      let captureTime = CMTime(seconds: durationSeconds * fraction, preferredTimescale: 600)
      try autoreleasepool {
        guard let cgImage = try? imageGenerator.copyCGImage(at: captureTime, actualTime: nil) else {
          return
        }
        let image = UIImage(cgImage: cgImage)
        let mpImage = try MPImage(uiImage: image)
        let timestampMs = max(
          Int((CMTimeGetSeconds(captureTime) * 1000.0).rounded()),
          lastTimestampMs + 1
        )
        lastTimestampMs = timestampMs

        let result = try poseLandmarker.detect(
          videoFrame: mpImage,
          timestampInMilliseconds: timestampMs
        )
        guard let sample = extractFrameSample(from: result, imageSize: image.size) else {
          return
        }
        frameSamples.append(sample)
      }
    }

    guard frameSamples.count >= Self.minimumValidFrames else {
      throw AnalysisError(
        code: "no_pose_detected",
        message: "We could not detect a clear running pose in this video."
      )
    }

    let direction = resolveDirection(from: frameSamples)
    let averageScale = max(frameSamples.map(\.bodyScale).reduce(0, +) / Double(frameSamples.count), 1.0)
    let leanDegrees =
      frameSamples.map { $0.forwardLeanDegrees(direction: direction) }.reduce(0, +) /
      Double(frameSamples.count)
    let shoulderYs = frameSamples.map { Double($0.shoulderCenter.y) }
    let bounceRatio =
      ((shoulderYs.max() ?? 0) - (shoulderYs.min() ?? 0)) / averageScale
    let loadingWindowSize = max(1, frameSamples.count / 3)
    let loadingSamples = frameSamples
      .sorted { $0.leadFootStrikeRatio(direction: direction) < $1.leadFootStrikeRatio(direction: direction) }
      .suffix(loadingWindowSize)
    let footStrikeRatio =
      loadingSamples.map { $0.leadFootStrikeRatio(direction: direction) }.reduce(0, +) /
      Double(loadingSamples.count)
    let kneeAngles = loadingSamples.compactMap { $0.leadKneeAngleDegrees(direction: direction) }
    let elbowAngles = frameSamples.compactMap { $0.averageElbowAngleDegrees }
    guard !kneeAngles.isEmpty, !elbowAngles.isEmpty else {
      throw AnalysisError(
        code: "no_pose_detected",
        message: "We could not detect a clear running pose in this video."
      )
    }
    let stanceKneeAngle = kneeAngles.reduce(0, +) / Double(kneeAngles.count)
    let elbowAngle = elbowAngles.reduce(0, +) / Double(elbowAngles.count)

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
    return try PoseLandmarker(options: options)
  }

  private func extractFrameSample(
    from result: PoseLandmarkerResult,
    imageSize: CGSize
  ) -> FrameSample? {
    guard let landmarks = result.landmarks.first, landmarks.count > Self.leftFootIndex else {
      return nil
    }

    guard
      let leftShoulder = confidentPoint(Self.leftShoulderIndex, in: landmarks, imageSize: imageSize),
      let rightShoulder = confidentPoint(Self.rightShoulderIndex, in: landmarks, imageSize: imageSize),
      let leftHip = confidentPoint(Self.leftHipIndex, in: landmarks, imageSize: imageSize),
      let rightHip = confidentPoint(Self.rightHipIndex, in: landmarks, imageSize: imageSize),
      let leftKnee = confidentPoint(Self.leftKneeIndex, in: landmarks, imageSize: imageSize),
      let rightKnee = confidentPoint(Self.rightKneeIndex, in: landmarks, imageSize: imageSize),
      let leftAnkle = confidentPoint(Self.leftAnkleIndex, in: landmarks, imageSize: imageSize),
      let rightAnkle = confidentPoint(Self.rightAnkleIndex, in: landmarks, imageSize: imageSize)
    else {
      return nil
    }

    let shoulderCenter = midpoint(leftShoulder, rightShoulder)
    let hipCenter = midpoint(leftHip, rightHip)
    let ankleCenter = midpoint(leftAnkle, rightAnkle)
    let torsoScale = distance(shoulderCenter, hipCenter)
    let legScale = distance(hipCenter, ankleCenter)
    let bodyScale = max(torsoScale, legScale)
    guard bodyScale >= Self.minimumBodyScalePx else {
      return nil
    }

    return FrameSample(
      leftShoulder: leftShoulder,
      rightShoulder: rightShoulder,
      leftHip: leftHip,
      rightHip: rightHip,
      leftKnee: leftKnee,
      rightKnee: rightKnee,
      shoulderCenter: shoulderCenter,
      hipCenter: hipCenter,
      leftAnkle: leftAnkle,
      rightAnkle: rightAnkle,
      leftHeel: confidentPoint(Self.leftHeelIndex, in: landmarks, imageSize: imageSize),
      rightHeel: confidentPoint(Self.rightHeelIndex, in: landmarks, imageSize: imageSize),
      leftElbow: confidentPoint(Self.leftElbowIndex, in: landmarks, imageSize: imageSize),
      rightElbow: confidentPoint(Self.rightElbowIndex, in: landmarks, imageSize: imageSize),
      leftWrist: confidentPoint(Self.leftWristIndex, in: landmarks, imageSize: imageSize),
      rightWrist: confidentPoint(Self.rightWristIndex, in: landmarks, imageSize: imageSize),
      bodyScale: bodyScale
    )
  }

  private func confidentPoint(
    _ index: Int,
    in landmarks: [NormalizedLandmark],
    imageSize: CGSize
  ) -> CGPoint? {
    guard index >= 0, index < landmarks.count else {
      return nil
    }
    let landmark = landmarks[index]
    let confidence = max(
      landmark.visibility?.floatValue ?? 0,
      landmark.presence?.floatValue ?? 0
    )
    guard confidence >= Self.minimumLikelihood else {
      return nil
    }
    return CGPoint(
      x: Double(landmark.x) * Double(imageSize.width),
      y: Double(landmark.y) * Double(imageSize.height)
    )
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

  private struct FrameSample {
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
    let leftElbow: CGPoint?
    let rightElbow: CGPoint?
    let leftWrist: CGPoint?
    let rightWrist: CGPoint?
    let bodyScale: Double

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

  private struct AnalysisError: Error {
    let code: String
    let message: String
  }

  private static let channelName = "football_note/running_pose_analysis"
  private static let methodName = "analyzeRunningVideo"
  private static let sampleCount = 14
  private static let minimumValidFrames = 6
  private static let minVideoDurationMs = 1500
  private static let sampleStartFraction = 0.15
  private static let sampleEndFraction = 0.85
  private static let minimumLikelihood: Float = 0.45
  private static let minimumBodyScalePx = 40.0
  private static let stationaryThresholdRatio = 0.12
  private static let modelResourceName = "pose_landmarker_lite"
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
}
