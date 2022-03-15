import CoreVideo
import UIKit
import CoreMedia

@objc(ImageSelfieSegmentation)
class ImageSelfieSegmentation: NSObject {
    @objc static func requiresMainQueueSetup() -> Bool {
        return false
    }

    @objc(replaceBackground:withB:withC:withResolver:withRejecter:)
    func replaceBackground(inputImage: NSString, backgroundImage: NSString, maxSize: NSNumber, resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
        
        // set up the segmenter
        let options = SelfieSegmenterOptions()
        options.segmenterMode = .singleImage

        let segmenter = Segmenter.segmenter(options: options)
        
        let inputUiImage = UIUtilities.loadFileToUiImage(filePath: inputImage as String, maxSize: maxSize, isBackground: false);
        let backgroundUiImage = UIUtilities.loadFileToUiImage(filePath: backgroundImage as String, maxSize: maxSize, isBackground: true);
        let bgWidth = inputUiImage!.size.width
        let bgHeight = inputUiImage!.size.height
        let croppedBackgroundUiImage = UIUtilities.cropToBounds(image: backgroundUiImage!, width: bgWidth, height: bgHeight)
        
        if (inputUiImage == nil || backgroundUiImage == nil) {
            return reject("images", "Failed to load images", NSError(domain:"", code:500, userInfo:nil))
        }
        
        // now we need to convert the UI Image to an image buffer
        let inputImageBuffer = UIUtilities.createImageBuffer(from: inputUiImage!)!
        let backgroundImageBuffer = UIUtilities.createImageBuffer(from: croppedBackgroundUiImage)!
        
        
        let inputWidth = CVPixelBufferGetWidth(inputImageBuffer)
        let backgroundWidth = CVPixelBufferGetWidth(backgroundImageBuffer)
        let inputHeight = CVPixelBufferGetHeight(inputImageBuffer)
        let backgroundHeight = CVPixelBufferGetHeight(backgroundImageBuffer)
                
        if (inputWidth > backgroundWidth || inputHeight > backgroundHeight) {
            return reject("images", "Input image \(inputWidth)x\(inputHeight) is smaller than background image \(backgroundWidth)x\(backgroundHeight)", NSError(domain:"", code:500, userInfo:nil))
        }
            
        
        // create the vision image from the buffer
        let visionImage = VisionImage(image: inputUiImage!)
        if let orientation = inputUiImage?.imageOrientation {
            visionImage.orientation = orientation
        }


        var mask: SegmentationMask
        do {
          mask = try segmenter.results(in: visionImage)
        } catch let error {
          print("Failed to perform segmentation with error: \(error.localizedDescription).")
          return reject("segmenter", "Failed to perform segmentation with error: \(error.localizedDescription).", error)
        }
        
           
        UIUtilities.applySegmentationMask(mask: mask , inputImage: inputImageBuffer, backgroundImage: backgroundImageBuffer)

        // now convert back to a UI image and return the base64 image
        let newUiImage = UIUtilities.createUIImage(from: inputImageBuffer, orientation: visionImage.orientation)!;
        let newUiImageFilePath = UIUtilities.saveUiImageToFilePath(uiImage: newUiImage);
        
        return resolve(newUiImageFilePath)
        
    }
}
