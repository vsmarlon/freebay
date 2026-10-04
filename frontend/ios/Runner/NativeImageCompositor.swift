import CoreImage
import CoreText
import Flutter
import ImageIO
import UIKit

enum NativeImageCompositor {
  private static let channelName = "com.freebay.app/image_compositor"
  private static let maxBytes = 32 * 1024 * 1024
  private static let maxDimension = 2048
  private static let bundledFontAvailable: Bool = {
    guard let frameworks = Bundle.main.privateFrameworksURL else { return false }
    let fontURL = frameworks.appendingPathComponent(
      "App.framework/flutter_assets/assets/fonts/SpaceGrotesk[wght].ttf"
    )
    guard FileManager.default.fileExists(atPath: fontURL.path) else { return false }
    let registered = CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
    return registered || UIFont(name: "SpaceGrotesk", size: 16) != nil
      || UIFont(name: "Space Grotesk", size: 16) != nil
  }()

  private struct Stroke {
    let points: [CGPoint]
    let color: UIColor
    let width: CGFloat
    let style: String
  }

  private struct TextItem {
    let text: String
    let point: CGPoint
    let fontSize: CGFloat
    let color: UIColor
  }

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "compose" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "invalid_arguments", message: "Invalid image composition arguments", details: nil))
        return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          let bytes = try compose(args)
          DispatchQueue.main.async { result(FlutterStandardTypedData(bytes: bytes)) }
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(code: "composition_failed", message: "Image composition failed", details: nil))
          }
        }
      }
    }
  }

  private static func compose(_ args: [String: Any]) throws -> Data {
    guard let typedBytes = args["bytes"] as? FlutterStandardTypedData else { throw CompositionError.invalid }
    let bytes = typedBytes.data
    guard !bytes.isEmpty, bytes.count <= maxBytes,
      let imageSource = CGImageSourceCreateWithData(bytes as CFData, nil),
      let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: maxDimension,
      ] as CFDictionary),
      let requestedWidth = number(args["imageWidth"]),
      let requestedHeight = number(args["imageHeight"]),
      requestedWidth > 0, requestedWidth <= 100000, requestedHeight > 0, requestedHeight <= 100000,
      let canvasWidth = number(args["canvasWidth"]), canvasWidth > 0,
      let canvasHeight = number(args["canvasHeight"]), canvasHeight > 0,
      let rotation = number(args["rotationRadians"]), rotation.isFinite,
      let maxDimensionValue = number(args["maxDimension"]), maxDimensionValue >= 1,
      maxDimensionValue <= Double(maxDimension),
      let matrix = args["colorMatrix"] as? [NSNumber], matrix.count == 20,
      let strokes = args["strokes"] as? [[String: Any]], strokes.count <= 1000,
      let textItems = args["text"] as? [[String: Any]], textItems.count <= 100
    else { throw CompositionError.invalid }

    let inputImage = UIImage(cgImage: thumbnail)
    let rawWidth = inputImage.size.width * inputImage.scale
    let rawHeight = inputImage.size.height * inputImage.scale
    guard rawWidth.isFinite, rawHeight.isFinite, rawWidth > 0, rawHeight > 0 else {
      throw CompositionError.invalid
    }
    let width = max(1, Int(rawWidth.rounded()))
    let height = max(1, Int(rawHeight.rounded()))
    let size = CGSize(width: width, height: height)
    let renderer = UIGraphicsImageRenderer(size: size, format: rendererFormat())
    let source = renderer.image { _ in
      inputImage.draw(in: CGRect(origin: .zero, size: size))
    }
    guard let sourceCG = source.cgImage else { throw CompositionError.invalid }

    let matrixValues = matrix.map { CGFloat(truncating: $0) }
    guard matrixValues.allSatisfy({ $0.isFinite }) else { throw CompositionError.invalid }
    guard let filter = CIFilter(name: "CIColorMatrix") else { throw CompositionError.invalid }
    filter.setValue(CIImage(cgImage: sourceCG), forKey: kCIInputImageKey)
    filter.setValue(CIVector(x: matrixValues[0], y: matrixValues[1], z: matrixValues[2], w: matrixValues[3]), forKey: "inputRVector")
    filter.setValue(CIVector(x: matrixValues[5], y: matrixValues[6], z: matrixValues[7], w: matrixValues[8]), forKey: "inputGVector")
    filter.setValue(CIVector(x: matrixValues[10], y: matrixValues[11], z: matrixValues[12], w: matrixValues[13]), forKey: "inputBVector")
    filter.setValue(CIVector(x: matrixValues[15], y: matrixValues[16], z: matrixValues[17], w: matrixValues[18]), forKey: "inputAVector")
    filter.setValue(CIVector(x: matrixValues[4] / 255, y: matrixValues[9] / 255, z: matrixValues[14] / 255, w: matrixValues[19]), forKey: "inputBiasVector")
    guard let filtered = filter.outputImage,
      let filteredCG = CIContext(options: nil).createCGImage(filtered, from: filtered.extent)
    else { throw CompositionError.invalid }

    let previewScale = min(canvasWidth / Double(width), canvasHeight / Double(height))
    guard previewScale.isFinite, previewScale > 0 else { throw CompositionError.invalid }
    let originX = (canvasWidth - Double(width) * previewScale) / 2
    let originY = (canvasHeight - Double(height) * previewScale) / 2
    var totalPoints = 0
    let parsedStrokes: [Stroke] = try strokes.map { stroke in
      guard let points = stroke["points"] as? [[NSNumber]], points.count <= 10000,
        let argb = (stroke["argb"] as? NSNumber)?.uint32Value,
        let lineWidth = number(stroke["width"]), lineWidth > 0, lineWidth <= 1000,
        let style = stroke["style"] as? String,
        ["marker", "highlighter", "eraser"].contains(style)
      else { throw CompositionError.invalid }
      totalPoints += points.count
      guard totalPoints <= 200000 else { throw CompositionError.invalid }
      let mapped = try points.map { pair -> CGPoint in
        guard pair.count == 2 else { throw CompositionError.invalid }
        let x = Double(truncating: pair[0]), y = Double(truncating: pair[1])
        guard x.isFinite, y.isFinite else { throw CompositionError.invalid }
        return CGPoint(x: (x - originX) / previewScale, y: (y - originY) / previewScale)
      }
      let alpha: CGFloat = style == "highlighter" ? 80 / 255 : CGFloat((argb >> 24) & 0xff) / 255
      let color = UIColor(red: CGFloat((argb >> 16) & 0xff) / 255, green: CGFloat((argb >> 8) & 0xff) / 255, blue: CGFloat(argb & 0xff) / 255, alpha: alpha)
      return Stroke(points: mapped, color: color, width: CGFloat(lineWidth / previewScale), style: style)
    }
    let parsedTexts: [TextItem] = try textItems.map { item in
      guard let text = item["text"] as? String, text.count <= 2000,
        let x = number(item["x"]), let y = number(item["y"]),
        let fontSize = number(item["fontSize"]), fontSize > 0, fontSize <= 4096,
        let argb = (item["argb"] as? NSNumber)?.uint32Value
      else { throw CompositionError.invalid }
      let color = UIColor(red: CGFloat((argb >> 16) & 0xff) / 255, green: CGFloat((argb >> 8) & 0xff) / 255, blue: CGFloat(argb & 0xff) / 255, alpha: CGFloat((argb >> 24) & 0xff) / 255)
      return TextItem(text: text, point: CGPoint(x: ((x - originX) / previewScale), y: ((y - originY) / previewScale)), fontSize: CGFloat(fontSize), color: color)
    }

    let overlayRenderer = UIGraphicsImageRenderer(size: size, format: rendererFormat())
    let overlay = overlayRenderer.image { context in
      for stroke in parsedStrokes {
        let cg = context.cgContext
        cg.saveGState()
        cg.setBlendMode(stroke.style == "eraser" ? .clear : .normal)
        cg.setStrokeColor(stroke.color.cgColor)
        cg.setFillColor(stroke.color.cgColor)
        cg.setLineWidth(stroke.width)
        cg.setLineCap(stroke.style == "marker" ? .round : .butt)
        cg.setLineJoin(.round)
        if stroke.points.count == 1 {
          cg.fillEllipse(in: CGRect(x: stroke.points[0].x - stroke.width / 2, y: stroke.points[0].y - stroke.width / 2, width: stroke.width, height: stroke.width))
        } else if let first = stroke.points.first {
          cg.beginPath()
          cg.move(to: first)
          stroke.points.dropFirst().forEach { cg.addLine(to: $0) }
          cg.strokePath()
        }
        cg.restoreGState()
      }
    }
    guard let overlayCG = overlay.cgImage else { throw CompositionError.invalid }

    let radians = CGFloat(rotation)
    let rotatedWidth = abs(CGFloat(width) * cos(radians)) + abs(CGFloat(height) * sin(radians))
    let rotatedHeight = abs(CGFloat(width) * sin(radians)) + abs(CGFloat(height) * cos(radians))
    let outputScale = min(1, CGFloat(max(1, min(maxDimension, Int(maxDimensionValue)))) / max(rotatedWidth, rotatedHeight))
    let outputSize = CGSize(width: max(1, (rotatedWidth * outputScale).rounded()), height: max(1, (rotatedHeight * outputScale).rounded()))
    let outputRenderer = UIGraphicsImageRenderer(size: outputSize, format: rendererFormat())
    let outputImage = outputRenderer.image { context in
      let cg = context.cgContext
      cg.saveGState()
      cg.translateBy(x: outputSize.width / (2 * outputScale), y: outputSize.height / (2 * outputScale))
      cg.rotate(by: radians)
      cg.scaleBy(x: outputScale, y: outputScale)
      cg.translateBy(x: -CGFloat(width) / 2, y: -CGFloat(height) / 2)
      cg.draw(filteredCG, in: CGRect(origin: .zero, size: size))
      cg.draw(overlayCG, in: CGRect(origin: .zero, size: size))
      cg.restoreGState()

      for item in parsedTexts {
        let point = CGPoint(
          x: outputSize.width / 2 + (item.point.x - CGFloat(width) / 2) * outputScale,
          y: outputSize.height / 2 + (item.point.y - CGFloat(height) / 2) * outputScale
        )
        let size = item.fontSize * outputScale
        (item.text as NSString).draw(at: point, withAttributes: [
          .font: editorFont(size: size),
          .foregroundColor: item.color,
        ])
      }
    }
    guard let png = outputImage.pngData() else { throw CompositionError.invalid }
    return png
  }

  private static func number(_ value: Any?) -> Double? {
    guard let number = value as? NSNumber else { return nil }
    let result = number.doubleValue
    return result.isFinite ? result : nil
  }

  private static func rendererFormat() -> UIGraphicsImageRendererFormat {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    format.opaque = false
    return format
  }

  private static func editorFont(size: CGFloat) -> UIFont {
    let bundled = bundledFontAvailable
      ? (UIFont(name: "SpaceGrotesk", size: size) ?? UIFont(name: "Space Grotesk", size: size))
      : nil
    guard let bundled,
      let boldDescriptor = bundled.fontDescriptor.withSymbolicTraits(.traitBold)
    else { return UIFont.systemFont(ofSize: size, weight: .bold) }
    return UIFont(descriptor: boldDescriptor, size: size)
  }

  private enum CompositionError: Error { case invalid }
}
