import Flutter
import MediaPipeTasksVision
import UIKit

final class MediaPipePoseLandmarkerChannel {
  private let channel: FlutterMethodChannel
  private let queue = DispatchQueue(
    label: "com.namsoon.footballnote.mediapipe-pose-landmarker",
    qos: .userInitiated
  )
  private var poseLandmarker: PoseLandmarker?
  private var lastTimestampMs = 0

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
    case Self.detectBgraMethodName:
      detectPoseFromBgra8888(call: call, result: result)
    case Self.closeMethodName:
      close(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func detectPoseFromBgra8888(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard
      let arguments = call.arguments as? [String: Any],
      let typedData = arguments["bytes"] as? FlutterStandardTypedData,
      let width = arguments["width"] as? Int,
      let height = arguments["height"] as? Int,
      let bytesPerRow = arguments["bytesPerRow"] as? Int,
      width > 0,
      height > 0,
      bytesPerRow >= width * Self.bytesPerPixel
    else {
      result(
        FlutterError(
          code: "invalid_frame",
          message: "MediaPipe pose detection requires BGRA bytes with width, height, and bytesPerRow.",
          details: nil
        )
      )
      return
    }

    let rotationDegrees = arguments["rotationDegrees"] as? Int ?? 0
    let timestampMs = (arguments["timestampMs"] as? NSNumber)?.intValue ?? 0
    let frameData = typedData.data

    queue.async {
      do {
        let detection = try self.detectPose(
          data: frameData,
          width: width,
          height: height,
          bytesPerRow: bytesPerRow,
          rotationDegrees: rotationDegrees,
          timestampMs: timestampMs
        )
        DispatchQueue.main.async {
          result(detection)
        }
      } catch {
        DispatchQueue.main.async {
          result(
            FlutterError(
              code: "mediapipe_pose_failed",
              message: error.localizedDescription,
              details: nil
            )
          )
        }
      }
    }
  }

  private func close(result: @escaping FlutterResult) {
    queue.async {
      self.poseLandmarker = nil
      self.lastTimestampMs = 0
      DispatchQueue.main.async {
        result(nil)
      }
    }
  }

  private func detectPose(
    data: Data,
    width: Int,
    height: Int,
    bytesPerRow: Int,
    rotationDegrees: Int,
    timestampMs: Int
  ) throws -> [String: Any] {
    let image = try makeImage(
      data: data,
      width: width,
      height: height,
      bytesPerRow: bytesPerRow,
      rotationDegrees: rotationDegrees
    )
    let mpImage = try MPImage(uiImage: image)
    let result = try landmarker().detect(
      videoFrame: mpImage,
      timestampInMilliseconds: nextTimestamp(timestampMs)
    )

    return encode(result: result, imageSize: image.size)
  }

  private func landmarker() throws -> PoseLandmarker {
    if let poseLandmarker {
      return poseLandmarker
    }

    guard let modelPath = Bundle.main.path(
      forResource: Self.modelResourceName,
      ofType: Self.modelResourceExtension
    ) else {
      throw MediaPipePoseLandmarkerError.modelMissing
    }

    let options = PoseLandmarkerOptions()
    options.baseOptions.modelAssetPath = modelPath
    options.runningMode = .video
    options.numPoses = 1
    options.minPoseDetectionConfidence = Self.minimumPoseDetectionConfidence
    options.minPosePresenceConfidence = Self.minimumPosePresenceConfidence
    options.minTrackingConfidence = Self.minimumTrackingConfidence

    let createdLandmarker = try PoseLandmarker(options: options)
    poseLandmarker = createdLandmarker
    return createdLandmarker
  }

  private func makeImage(
    data: Data,
    width: Int,
    height: Int,
    bytesPerRow: Int,
    rotationDegrees: Int
  ) throws -> UIImage {
    guard data.count >= bytesPerRow * height else {
      throw MediaPipePoseLandmarkerError.invalidFrame
    }

    guard let provider = CGDataProvider(data: data as CFData) else {
      throw MediaPipePoseLandmarkerError.invalidFrame
    }

    let bitmapInfo = CGBitmapInfo.byteOrder32Little.union(
      CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
    )
    guard let cgImage = CGImage(
      width: width,
      height: height,
      bitsPerComponent: 8,
      bitsPerPixel: 32,
      bytesPerRow: bytesPerRow,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: bitmapInfo,
      provider: provider,
      decode: nil,
      shouldInterpolate: false,
      intent: .defaultIntent
    ) else {
      throw MediaPipePoseLandmarkerError.invalidFrame
    }

    return resizedImageIfNeeded(
      rotatedImage(from: cgImage, rotationDegrees: rotationDegrees)
    )
  }

  private func rotatedImage(from cgImage: CGImage, rotationDegrees: Int) -> UIImage {
    let normalizedRotation = ((rotationDegrees % 360) + 360) % 360
    let sourceSize = CGSize(width: cgImage.width, height: cgImage.height)
    guard normalizedRotation != 0 else {
      return UIImage(cgImage: cgImage)
    }

    let outputSize = normalizedRotation == 90 || normalizedRotation == 270
      ? CGSize(width: sourceSize.height, height: sourceSize.width)
      : sourceSize
    let renderer = UIGraphicsImageRenderer(size: outputSize)
    return renderer.image { context in
      let cgContext = context.cgContext
      cgContext.translateBy(x: outputSize.width / 2, y: outputSize.height / 2)
      cgContext.rotate(by: CGFloat(normalizedRotation) * .pi / 180)
      UIImage(cgImage: cgImage).draw(
        in: CGRect(
          x: -sourceSize.width / 2,
          y: -sourceSize.height / 2,
          width: sourceSize.width,
          height: sourceSize.height
        )
      )
    }
  }

  private func resizedImageIfNeeded(_ image: UIImage) -> UIImage {
    let longEdge = max(image.size.width, image.size.height)
    guard longEdge > Self.maxAnalysisLongEdge else {
      return image
    }

    let scale = Self.maxAnalysisLongEdge / longEdge
    let targetSize = CGSize(
      width: max(1, image.size.width * scale),
      height: max(1, image.size.height * scale)
    )
    let renderer = UIGraphicsImageRenderer(size: targetSize)
    return renderer.image { _ in
      image.draw(in: CGRect(origin: .zero, size: targetSize))
    }
  }

  private func nextTimestamp(_ timestampMs: Int) -> Int {
    let safeTimestampMs = max(timestampMs, lastTimestampMs + 1)
    lastTimestampMs = safeTimestampMs
    return safeTimestampMs
  }

  private func encode(result: PoseLandmarkerResult, imageSize: CGSize) -> [String: Any] {
    let landmarks = result.landmarks.first ?? []
    let worldLandmarks = result.worldLandmarks.first ?? []
    let encodedLandmarks = landmarks.enumerated().map { index, landmark in
      let worldLandmark = index < worldLandmarks.count ? worldLandmarks[index] : nil
      var encoded: [String: Any] = [
        "index": index,
        "x": Double(landmark.x) * Double(imageSize.width),
        "y": Double(landmark.y) * Double(imageSize.height),
        "z": Double(landmark.z),
      ]
      if let visibility = optionalDouble(landmark.visibility) {
        encoded["visibility"] = visibility
      }
      if let presence = optionalDouble(landmark.presence) {
        encoded["presence"] = presence
      }
      if let worldLandmark {
        encoded["worldX"] = Double(worldLandmark.x)
        encoded["worldY"] = Double(worldLandmark.y)
        encoded["worldZ"] = Double(worldLandmark.z)
        if let worldVisibility = optionalDouble(worldLandmark.visibility) {
          encoded["worldVisibility"] = worldVisibility
        }
      }
      return encoded
    }

    return [
      "imageWidth": imageSize.width,
      "imageHeight": imageSize.height,
      "landmarks": encodedLandmarks,
    ]
  }

  private func optionalDouble(_ value: NSNumber?) -> Double? {
    value?.doubleValue
  }

  private enum MediaPipePoseLandmarkerError: LocalizedError {
    case invalidFrame
    case modelMissing

    var errorDescription: String? {
      switch self {
      case .invalidFrame:
        return "Could not decode the camera frame."
      case .modelMissing:
        return "MediaPipe pose model is missing from the iOS bundle."
      }
    }
  }

  private static let channelName = "football_note/mediapipe_pose_landmarker"
  private static let detectBgraMethodName = "detectPoseFromBgra8888"
  private static let closeMethodName = "close"
  private static let modelResourceName = "pose_landmarker_lite"
  private static let modelResourceExtension = "task"
  private static let minimumPoseDetectionConfidence: Float = 0.35
  private static let minimumPosePresenceConfidence: Float = 0.35
  private static let minimumTrackingConfidence: Float = 0.35
  private static let bytesPerPixel = 4
  private static let maxAnalysisLongEdge: CGFloat = 720
}
