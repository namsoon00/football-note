import AVFoundation
import CoreMedia
import Flutter
import MLKitPoseDetection
import MLKitVision
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

    let options = PoseDetectorOptions()
    options.detectorMode = .stream
    let detector = PoseDetector.poseDetector(options: options)

    var frameSamples: [FrameSample] = []
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
        let visionImage = VisionImage(image: image)
        visionImage.orientation = image.imageOrientation

        let poses = try detector.results(in: visionImage)
        guard let pose = poses.first, let sample = extractFrameSample(from: pose) else {
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

  private func extractFrameSample(from pose: Pose) -> FrameSample? {
    guard
      let leftShoulder = confidentLandmark(.leftShoulder, in: pose),
      let rightShoulder = confidentLandmark(.rightShoulder, in: pose),
      let leftHip = confidentLandmark(.leftHip, in: pose),
      let rightHip = confidentLandmark(.rightHip, in: pose),
      let leftKnee = confidentLandmark(.leftKnee, in: pose),
      let rightKnee = confidentLandmark(.rightKnee, in: pose),
      let leftAnkle = confidentLandmark(.leftAnkle, in: pose),
      let rightAnkle = confidentLandmark(.rightAnkle, in: pose)
    else {
      return nil
    }

    let shoulderCenter = midpoint(point(leftShoulder.position), point(rightShoulder.position))
    let hipCenter = midpoint(point(leftHip.position), point(rightHip.position))
    let ankleCenter = midpoint(point(leftAnkle.position), point(rightAnkle.position))
    let torsoScale = distance(shoulderCenter, hipCenter)
    let legScale = distance(hipCenter, ankleCenter)
    let bodyScale = max(torsoScale, legScale)
    guard bodyScale >= Self.minimumBodyScalePx else {
      return nil
    }

    return FrameSample(
      leftShoulder: point(leftShoulder.position),
      rightShoulder: point(rightShoulder.position),
      leftHip: point(leftHip.position),
      rightHip: point(rightHip.position),
      leftKnee: point(leftKnee.position),
      rightKnee: point(rightKnee.position),
      shoulderCenter: shoulderCenter,
      hipCenter: hipCenter,
      leftAnkle: point(leftAnkle.position),
      rightAnkle: point(rightAnkle.position),
      leftHeel: confidentLandmark(.leftHeel, in: pose).map { point($0.position) },
      rightHeel: confidentLandmark(.rightHeel, in: pose).map { point($0.position) },
      leftElbow: confidentLandmark(.leftElbow, in: pose).map { point($0.position) },
      rightElbow: confidentLandmark(.rightElbow, in: pose).map { point($0.position) },
      leftWrist: confidentLandmark(.leftWrist, in: pose).map { point($0.position) },
      rightWrist: confidentLandmark(.rightWrist, in: pose).map { point($0.position) },
      bodyScale: bodyScale
    )
  }

  private func confidentLandmark(_ type: PoseLandmarkType, in pose: Pose) -> PoseLandmark? {
    let landmark = pose.landmark(ofType: type)
    guard landmark.inFrameLikelihood >= Self.minimumLikelihood else {
      return nil
    }
    return landmark
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

  private func point(_ source: Vision3DPoint) -> CGPoint {
    CGPoint(x: source.x, y: source.y)
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
}
