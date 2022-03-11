import AVFoundation
import CoreVideo
import UIKit

public class UIUtilities {

  // MARK: - Public

    
    public static func convertUiImageToBase64String (img: UIImage) -> String {
      return img.jpegData(compressionQuality: 1)?.base64EncodedString() ?? ""
    }
    
    public static func loadFileToUiImage(filePath: String) -> UIImage? {
        do {
            let url = URL(string: filePath)
            let imageData = try Data(contentsOf: url!)
            return UIImage(data: imageData)
        } catch {
            print("Error loading image : \(error)")
        }
        return nil
    }
    
    public static func saveUiImageToFilePath(uiImage: UIImage) -> String? {
        var cacheUrl: URL {
            return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        }
        let newPhotoFileName = UUID().uuidString + ".jpeg"
        let imagePath = cacheUrl.path + "/" + newPhotoFileName
        let fileSuccess = FileManager.default.createFile(atPath: imagePath, contents: uiImage.jpegData(compressionQuality: 1), attributes: nil)
        return fileSuccess ? imagePath : nil
    }
            
        
    public static func convertBase64ToUiImage (strBase64: String) -> UIImage {
        let dataDecoded : Data = Data(base64Encoded: strBase64, options: .ignoreUnknownCharacters)!
        let decodedimage = UIImage(data: dataDecoded)
        return decodedimage!
    }
    
    /// Converts a `UIImage` to an image buffer.
    ///
    /// @param image The `UIImage` which should be converted.
    /// @return The image buffer. Callers own the returned buffer and are responsible for releasing it
    ///     when it is no longer needed. Additionally, the image orientation will not be accounted for
    ///     in the returned buffer, so callers must keep track of the orientation separately.
    public static func createImageBuffer(from image: UIImage) -> CVImageBuffer? {
      guard let cgImage = image.cgImage else { return nil }
      let width = cgImage.width
      let height = cgImage.height

      var buffer: CVPixelBuffer? = nil
      CVPixelBufferCreate(
        kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, nil,
        &buffer)
      guard let imageBuffer = buffer else { return nil }

      let flags = CVPixelBufferLockFlags(rawValue: 0)
      CVPixelBufferLockBaseAddress(imageBuffer, flags)
      let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
      let colorSpace = CGColorSpaceCreateDeviceRGB()
      let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
      let context = CGContext(
        data: baseAddress, width: width, height: height, bitsPerComponent: 8,
        bytesPerRow: bytesPerRow, space: colorSpace,
        bitmapInfo: (CGImageAlphaInfo.premultipliedFirst.rawValue
          | CGBitmapInfo.byteOrder32Little.rawValue))

      if let context = context {
        let rect = CGRect.init(x: 0, y: 0, width: width, height: height)
        context.draw(cgImage, in: rect)
        CVPixelBufferUnlockBaseAddress(imageBuffer, flags)
        return imageBuffer
      } else {
        CVPixelBufferUnlockBaseAddress(imageBuffer, flags)
        return nil
      }
    }
    
    /// Applies a segmentation mask to an image buffer by replacing colors in the segmented regions.
    ///
    /// @param The mask output from a segmentation operation.
    /// @param imageBuffer The image buffer on which segmentation was performed. Must have pixel
    ///     format type `kCVPixelFormatType_32BGRA`.
    /// @param backgroundColor Optional color to render into the background region (i.e. outside of
    ///    the segmented region of interest).
    /// @param foregroundColor Optional color to render into the foreground region (i.e. inside the
    ///     segmented region of interest).
    public static func applySegmentationMask(
      mask: SegmentationMask, inputImage inputImageBuffer: CVImageBuffer,
      backgroundImage backgroundImageBuffer: CVImageBuffer
    ) {
      assert(
        CVPixelBufferGetPixelFormatType(inputImageBuffer) == kCVPixelFormatType_32BGRA,
        "Input Image buffer must have 32BGRA pixel format type")

        assert(
          CVPixelBufferGetPixelFormatType(backgroundImageBuffer) == kCVPixelFormatType_32BGRA,
          "Background Image buffer must have 32BGRA pixel format type")
        
      let width = CVPixelBufferGetWidth(mask.buffer)
      let height = CVPixelBufferGetHeight(mask.buffer)
      assert(CVPixelBufferGetWidth(inputImageBuffer) == width, "Width must match")
      assert(CVPixelBufferGetHeight(inputImageBuffer) == height, "Height must match")
        
      assert(CVPixelBufferGetWidth(backgroundImageBuffer) >= CVPixelBufferGetWidth(inputImageBuffer), "Background width must be equal or larger than input")
      assert(CVPixelBufferGetHeight(backgroundImageBuffer) >= CVPixelBufferGetHeight(inputImageBuffer), "Background height must be equal or larger than input")


      let writeFlags = CVPixelBufferLockFlags(rawValue: 0)
      CVPixelBufferLockBaseAddress(inputImageBuffer, writeFlags)
      CVPixelBufferLockBaseAddress(backgroundImageBuffer, writeFlags)
      CVPixelBufferLockBaseAddress(mask.buffer, CVPixelBufferLockFlags.readOnly)

      let maskBytesPerRow = CVPixelBufferGetBytesPerRow(mask.buffer)
      var maskAddress =
        CVPixelBufferGetBaseAddress(mask.buffer)!.bindMemory(
          to: Float32.self, capacity: maskBytesPerRow * height)

      let imageBytesPerRow = CVPixelBufferGetBytesPerRow(inputImageBuffer)
      var imageAddress = CVPixelBufferGetBaseAddress(inputImageBuffer)!.bindMemory(
        to: UInt8.self, capacity: imageBytesPerRow * height)
        
      let backgroundImageBytesPerRow = CVPixelBufferGetBytesPerRow(backgroundImageBuffer)
      var backgroundImageAddress = CVPixelBufferGetBaseAddress(backgroundImageBuffer)!.bindMemory(
          to: UInt8.self, capacity: backgroundImageBytesPerRow * height)
        

      let redFG: CGFloat = 0.0
      let greenFG: CGFloat = 0.0
      let blueFG: CGFloat = 0.0
      let alphaFG: CGFloat = 0.0
      var redBG: CGFloat = 0.0
      var greenBG: CGFloat = 0.0
      var blueBG: CGFloat = 0.0
      var alphaBG: CGFloat = 0.0


      for _ in 0...(height - 1) {
        for col in 0...(width - 1) {
          let pixelOffset = col * Constants.bgraBytesPerPixel
          let blueOffset = pixelOffset
          let greenOffset = pixelOffset + 1
          let redOffset = pixelOffset + 2
          let alphaOffset = pixelOffset + 3

          let maskValue: CGFloat = CGFloat(maskAddress[col])
          let backgroundRegionRatio: CGFloat = 1.0 - maskValue
          let foregroundRegionRatio = maskValue

          let originalPixelRed: CGFloat =
            CGFloat(imageAddress[redOffset]) / Constants.maxColorComponentValue
          let originalPixelGreen: CGFloat =
            CGFloat(imageAddress[greenOffset]) / Constants.maxColorComponentValue
          let originalPixelBlue: CGFloat =
            CGFloat(imageAddress[blueOffset]) / Constants.maxColorComponentValue
          let originalPixelAlpha: CGFloat =
            CGFloat(imageAddress[alphaOffset]) / Constants.maxColorComponentValue
          
          // replace bg colors with those from background image
          redBG = CGFloat(backgroundImageAddress[redOffset]) / Constants.maxColorComponentValue
          greenBG = CGFloat(backgroundImageAddress[greenOffset]) / Constants.maxColorComponentValue
          blueBG = CGFloat(backgroundImageAddress[blueOffset]) / Constants.maxColorComponentValue
          alphaBG = CGFloat(backgroundImageAddress[alphaOffset]) / Constants.maxColorComponentValue
            

          let redOverlay = redBG * backgroundRegionRatio + redFG * foregroundRegionRatio
          let greenOverlay = greenBG * backgroundRegionRatio + greenFG * foregroundRegionRatio
          let blueOverlay = blueBG * backgroundRegionRatio + blueFG * foregroundRegionRatio
          let alphaOverlay = alphaBG * backgroundRegionRatio + alphaFG * foregroundRegionRatio

          // Calculate composite color component values.
          // Derived from https://en.wikipedia.org/wiki/Alpha_compositing#Alpha_blending
          let compositeAlpha: CGFloat = ((1.0 - alphaOverlay) * originalPixelAlpha) + alphaOverlay
          var compositeRed: CGFloat = 0.0
          var compositeGreen: CGFloat = 0.0
          var compositeBlue: CGFloat = 0.0
          // Only perform rgb blending calculations if the output alpha is > 0. A zero-value alpha
          // means none of the color channels actually matter, and would introduce division by 0.
          if abs(compositeAlpha) > CGFloat(Float.ulpOfOne) {
            compositeRed =
              (((1.0 - alphaOverlay) * originalPixelAlpha * originalPixelRed)
                + (alphaOverlay * redOverlay)) / compositeAlpha
            compositeGreen =
              (((1.0 - alphaOverlay) * originalPixelAlpha * originalPixelGreen)
                + (alphaOverlay * greenOverlay)) / compositeAlpha
            compositeBlue =
              (((1.0 - alphaOverlay) * originalPixelAlpha * originalPixelBlue)
                + (alphaOverlay * blueOverlay)) / compositeAlpha
          }

          imageAddress[redOffset] = UInt8(compositeRed * Constants.maxColorComponentValue)
          imageAddress[greenOffset] = UInt8(compositeGreen * Constants.maxColorComponentValue)
          imageAddress[blueOffset] = UInt8(compositeBlue * Constants.maxColorComponentValue)
        }

        imageAddress += imageBytesPerRow / MemoryLayout<UInt8>.size
        backgroundImageAddress += backgroundImageBytesPerRow / MemoryLayout<UInt8>.size
        maskAddress += maskBytesPerRow / MemoryLayout<Float32>.size
      }

      CVPixelBufferUnlockBaseAddress(inputImageBuffer, writeFlags)
      CVPixelBufferUnlockBaseAddress(backgroundImageBuffer, writeFlags)
      CVPixelBufferUnlockBaseAddress(mask.buffer, CVPixelBufferLockFlags.readOnly)
    }
    
    /// Converts an image buffer to a `UIImage`.
    ///
    /// @param imageBuffer The image buffer which should be converted.
    /// @param orientation The orientation already applied to the image.
    /// @return A new `UIImage` instance.
    public static func createUIImage(
      from imageBuffer: CVImageBuffer,
      orientation: UIImage.Orientation
    ) -> UIImage? {
      let ciImage = CIImage(cvPixelBuffer: imageBuffer)
      let context = CIContext(options: nil)
      guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
      return UIImage(cgImage: cgImage, scale: Constants.originalScale, orientation: orientation)
    }
    
    
    private enum Constants {
      static let circleViewAlpha: CGFloat = 0.7
      static let rectangleViewAlpha: CGFloat = 0.3
      static let shapeViewAlpha: CGFloat = 0.3
      static let rectangleViewCornerRadius: CGFloat = 10.0
      static let maxColorComponentValue: CGFloat = 255.0
      static let originalScale: CGFloat = 1.0
      static let bgraBytesPerPixel = 4
    }
}


extension UIColor {
    public convenience init?(hex: String) {
        let r, g, b, a: CGFloat

        if hex.hasPrefix("#") {
            print("HEX")
            print(hex)
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])
            
            if hexColor.count == 6 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xFF0000) >> 16) / 255.0
                    g = CGFloat((hexNumber & 0x00FF00) >> 8) / 255.0
                    b = CGFloat(hexNumber & 0x0000FF) / 255.0
                    a = CGFloat(1.0)

                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }

        return nil
    }
}
