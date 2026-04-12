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
    let strideRatio = topAverage(frameSamples.map { $0.strideReachRatio(direction: direction) })

    return [
      "durationMs": durationMs,
      "sampledFrames": Self.sampleCount,
      "validFrames": frameSamples.count,
      "direction": direction.rawValue,
      "forwardLeanDegrees": roundTo3(leanDegrees),
      "verticalBounceRatio": roundTo3(max(0, bounceRatio)),
      "strideReachRatio": roundTo3(max(0, strideRatio)),
    ]
  }

  private func extractFrameSample(from pose: Pose) -> FrameSample? {
    guard
      let leftShoulder = confidentLandmark(.leftShoulder, in: pose),
      let rightShoulder = confidentLandmark(.rightShoulder, in: pose),
      let leftHip = confidentLandmark(.leftHip, in: pose),
      let rightHip = confidentLandmark(.rightHip, in: pose),
      let leftAnkle = confidentLandmark(.leftAnkle, in: pose),
      let rightAnkle = confidentLandmark(.rightAnkle, in: pose)
    else {
      return nil
    }

    let shoulderCenter = midpoint(leftShoulder.position, rightShoulder.position)
    let hipCenter = midpoint(leftHip.position, rightHip.position)
    let ankleCenter = midpoint(leftAnkle.position, rightAnkle.position)
    let torsoScale = distance(shoulderCenter, hipCenter)
    let legScale = distance(hipCenter, ankleCenter)
    let bodyScale = max(torsoScale, legScale)
    guard bodyScale >= Self.minimumBodyScalePx else {
      return nil
    }

    return FrameSample(
      shoulderCenter: shoulderCenter,
      hipCenter: hipCenter,
      leftAnkle: leftAnkle.position,
      rightAnkle: rightAnkle.position,
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

  private func midpoint(_ first: Vision3DPoint, _ second: Vision3DPoint) -> CGPoint {
    CGPoint(x: (first.x + second.x) / 2, y: (first.y + second.y) / 2)
  }

  private func distance(_ first: CGPoint, _ second: CGPoint) -> Double {
    let dx = Double(first.x - second.x)
    let dy = Double(first.y - second.y)
    return hypot(dx, dy)
  }

  private func topAverage(_ values: [Double]) -> Double {
    guard !values.isEmpty else {
      return 0
    }
    let clipped = values.map { max(0, $0) }.sorted()
    let windowSize = max(1, clipped.count / 3)
    let slice = clipped.suffix(windowSize)
    return slice.reduce(0, +) / Double(slice.count)
  }

  private func roundTo3(_ value: Double) -> Double {
    (value * 1000).rounded(.towardZero) / 1000
  }

  private struct FrameSample {
    let shoulderCenter: CGPoint
    let hipCenter: CGPoint
    let leftAnkle: Vision3DPoint
    let rightAnkle: Vision3DPoint
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

    func strideReachRatio(direction: AnalysisDirection) -> Double {
      let forwardReachPx: Double
      switch direction {
      case .leftToRight:
        forwardReachPx = Double(max(leftAnkle.x, rightAnkle.x) - hipCenter.x)
      case .rightToLeft:
        forwardReachPx = Double(hipCenter.x - min(leftAnkle.x, rightAnkle.x))
      case .stationary:
        forwardReachPx = max(
          abs(Double(leftAnkle.x - hipCenter.x)),
          abs(Double(rightAnkle.x - hipCenter.x))
        )
      }
      return max(0, forwardReachPx) / max(bodyScale, 1.0)
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
  private static let sampleCount = 10
  private static let minimumValidFrames = 3
  private static let minVideoDurationMs = 1500
  private static let sampleStartFraction = 0.15
  private static let sampleEndFraction = 0.85
  private static let minimumLikelihood: Float = 0.45
  private static let minimumBodyScalePx = 40.0
  private static let stationaryThresholdRatio = 0.12
}
