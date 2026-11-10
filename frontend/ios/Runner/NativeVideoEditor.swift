import AVFoundation
import CoreImage
import Flutter
import ImageIO
import UIKit

final class NativeVideoEditor {
  private var activeExport: AVAssetExportSession?
  private let ciContext = CIContext(options: nil)

  func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "com.freebay.app/video_editor", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "export" else { result(FlutterMethodNotImplemented); return }
      guard let self, self.activeExport == nil, let args = call.arguments as? [String: Any],
        let input = args["input"] as? String, let output = args["output"] as? String,
        let overlay = args["overlay"] as? String,
        let crop = args["crop"] as? [Double], crop.count == 4,
        let start = args["startMs"] as? Int, let end = args["endMs"] as? Int,
        let duration = args["durationMs"] as? Int,
        start >= 0, end > start, duration > 0, end <= duration,
        crop.allSatisfy({ $0.isFinite && $0 >= 0 && $0 <= 1 }),
        crop[2] > crop[0], crop[3] > crop[1],
        FileManager.default.isReadableFile(atPath: input),
        FileManager.default.isReadableFile(atPath: overlay),
        input != output, output != overlay
      else {
        result(FlutterError(code: "invalid_arguments", message: "Invalid video export arguments", details: nil))
        return
      }
      let matrix: [Double]
      if args["colorMatrix"] == nil {
        matrix = Self.identityMatrix
      } else if let supplied = args["colorMatrix"] as? [Double], supplied.count == 20,
        supplied.allSatisfy(\.isFinite)
      {
        matrix = supplied
      } else {
        result(FlutterError(code: "invalid_arguments", message: "Invalid video export arguments", details: nil))
        return
      }
      let rotation = args["rotationDegrees"] as? Int ?? 0
      guard [0, 90, 180, 270].contains(rotation), Self.hasIdentityAlpha(matrix),
        let overlayData = try? Data(contentsOf: URL(fileURLWithPath: overlay)),
        overlayData.starts(with: Self.pngSignature),
        let overlaySource = CGImageSourceCreateWithData(overlayData as CFData, nil),
        let overlayImage = CGImageSourceCreateImageAtIndex(overlaySource, 0, nil)
      else {
        result(FlutterError(code: "invalid_arguments", message: "Invalid video export arguments", details: nil))
        return
      }
      self.export(input: input, output: output, overlay: overlayImage, crop: crop,
        matrix: matrix, rotation: rotation, start: start, end: end,
        maxDimension: args["maxDimension"] as? Int ?? 2048,
        mute: args["mute"] as? Bool ?? false, result: result)
    }
  }

  private func export(
    input: String, output: String, overlay: CGImage, crop: [Double], matrix: [Double],
    rotation: Int, start: Int, end: Int, maxDimension: Int, mute: Bool, result: @escaping FlutterResult
  ) {
    let asset = AVURLAsset(url: URL(fileURLWithPath: input))
    guard let source = asset.tracks(withMediaType: .video).first,
      let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
    else {
      result(FlutterError(code: "export_failed", message: "Video could not be opened", details: nil))
      return
    }
    let preferred = source.preferredTransform
    let rawBounds = CGRect(origin: .zero, size: source.naturalSize).applying(preferred).standardized
    let orientedWidth = rawBounds.width
    let orientedHeight = rawBounds.height
    guard orientedWidth.isFinite, orientedHeight.isFinite, orientedWidth > 0, orientedHeight > 0 else {
      result(FlutterError(code: "invalid_arguments", message: "Invalid video dimensions", details: nil))
      return
    }
    let cropWidth = CGFloat(crop[2] - crop[0]) * orientedWidth
    let cropHeight = CGFloat(crop[3] - crop[1]) * orientedHeight
    let rotatedWidth = rotation % 180 == 0 ? cropWidth : cropHeight
    let rotatedHeight = rotation % 180 == 0 ? cropHeight : cropWidth
    guard (2...2048).contains(maxDimension) else {
      result(FlutterError(code: "invalid_arguments", message: "Invalid video dimensions", details: nil))
      return
    }
    let scale = min(1, CGFloat(maxDimension) / max(rotatedWidth, rotatedHeight))
    let outputWidth = Self.evenDimension(rotatedWidth * scale)
    let outputHeight = Self.evenDimension(rotatedHeight * scale)
    guard overlay.width == outputWidth, overlay.height == outputHeight else {
      result(FlutterError(code: "invalid_arguments", message: "Overlay dimensions do not match video output", details: nil))
      return
    }
    let cropRect = CGRect(
      x: CGFloat(crop[0]) * orientedWidth,
      y: CGFloat(1 - crop[3]) * orientedHeight,
      width: cropWidth,
      height: cropHeight
    )
    let radians = -CGFloat(rotation) * .pi / 180
    let colorMatrix = matrix
    let matrixValues = matrix.map(CGFloat.init)
    let outputSize = CGSize(width: outputWidth, height: outputHeight)
    let overlayCI = CIImage(cgImage: overlay)
    let composition = AVMutableVideoComposition(asset: asset) { [ciContext] request in
      var image = request.sourceImage
      let transformedExtent = image.extent.standardized
      image = image.transformed(by: CGAffineTransform(
        translationX: -transformedExtent.minX, y: -transformedExtent.minY
      ))
      guard let colorFilter = CIFilter(name: "CIColorMatrix") else {
        request.finish(with: NSError(domain: "FreeBayMediaExport", code: 1))
        return
      }
      colorFilter.setValue(image, forKey: kCIInputImageKey)
      colorFilter.setValue(CIVector(x: matrixValues[0], y: matrixValues[1], z: matrixValues[2], w: matrixValues[3]), forKey: "inputRVector")
      colorFilter.setValue(CIVector(x: matrixValues[5], y: matrixValues[6], z: matrixValues[7], w: matrixValues[8]), forKey: "inputGVector")
      colorFilter.setValue(CIVector(x: matrixValues[10], y: matrixValues[11], z: matrixValues[12], w: matrixValues[13]), forKey: "inputBVector")
      colorFilter.setValue(CIVector(x: matrixValues[15], y: matrixValues[16], z: matrixValues[17], w: matrixValues[18]), forKey: "inputAVector")
      colorFilter.setValue(CIVector(x: matrixValues[4] / 255, y: matrixValues[9] / 255,
        z: matrixValues[14] / 255, w: matrixValues[19] / 255), forKey: "inputBiasVector")
      guard let filtered = colorFilter.outputImage else {
        request.finish(with: NSError(domain: "FreeBayMediaExport", code: 2))
        return
      }
      let cropped = filtered.cropped(to: cropRect)
      let rotated = cropped.transformed(by: CGAffineTransform(rotationAngle: radians))
      let rotatedExtent = rotated.extent.standardized
      let normalized = rotated.transformed(by: CGAffineTransform(
        translationX: -rotatedExtent.minX, y: -rotatedExtent.minY
      ))
      let fitted = normalized.transformed(by: CGAffineTransform(
        scaleX: outputSize.width / rotatedExtent.width,
        y: outputSize.height / rotatedExtent.height
      ))
      let outputFrame = fitted.cropped(to: CGRect(origin: .zero, size: outputSize))
      let overlayFrame = overlayCI.cropped(to: CGRect(origin: .zero, size: outputSize))
      let final = overlayFrame.composited(over: outputFrame)
      request.finish(with: final, context: ciContext)
    }
    composition.renderSize = outputSize
    composition.frameDuration = CMTime(value: 1, timescale: 30)
    session.timeRange = CMTimeRange(
      start: CMTime(value: Int64(start), timescale: 1000),
      duration: CMTime(value: Int64(end - start), timescale: 1000)
    )
    session.videoComposition = composition
    session.outputURL = URL(fileURLWithPath: output)
    session.outputFileType = .mp4
    if mute, let audio = asset.tracks(withMediaType: .audio).first {
      let parameters = AVMutableAudioMixInputParameters(track: audio)
      parameters.setVolumeRamp(fromStartVolume: 0, toEndVolume: 0, timeRange: session.timeRange)
      let mix = AVMutableAudioMix()
      mix.inputParameters = [parameters]
      session.audioMix = mix
    }
    try? FileManager.default.removeItem(atPath: output)
    activeExport = session
    session.exportAsynchronously { [weak self] in
      DispatchQueue.main.async {
        self?.activeExport = nil
        if session.status == .completed { result(nil) }
        else {
          try? FileManager.default.removeItem(atPath: output)
          result(FlutterError(code: "export_failed", message: "Video export failed", details: nil))
        }
      }
    }
  }

  private static func evenDimension(_ value: Double) -> Int {
    min(2048, max(2, (Int(value.rounded(.toNearestOrAwayFromZero)) + 1) & ~1))
  }

  private static func hasIdentityAlpha(_ matrix: [Double]) -> Bool {
    matrix[15] == 0 && matrix[16] == 0 && matrix[17] == 0 && matrix[18] == 1 && matrix[19] == 0
  }

  private static let identityMatrix: [Double] = [
    1, 0, 0, 0, 0, 0, 1, 0, 0, 0,
    0, 0, 1, 0, 0, 0, 0, 0, 1, 0,
  ]
  private static let pngSignature = Data([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])
}
