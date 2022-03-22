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

        // load the image file uris
        let inputUiImage = UIUtilities.loadFileToUiImage(filePath: inputImage as String, maxSize: maxSize, isBackground: false);
        let backgroundUiImage = UIUtilities.loadFileToUiImage(filePath: backgroundImage as String, maxSize: maxSize, isBackground: true);

        // return an error back to js
        if (inputUiImage == nil || backgroundUiImage == nil) {
            return reject("images", "Failed to load images", NSError(domain:"", code:500, userInfo:nil))
        }

        // crop background
        let bgWidth = inputUiImage!.size.width
        let bgHeight = inputUiImage!.size.height
        let croppedBackgroundUiImage = UIUtilities.cropToBounds(image: backgroundUiImage!, width: bgWidth, height: bgHeight)
        
        // now we need to convert the UI Image to an image buffer
        let inputImageBuffer = UIUtilities.createImageBuffer(from: inputUiImage!)
        let backgroundImageBuffer = UIUtilities.createImageBuffer(from: croppedBackgroundUiImage)

        if (inputImageBuffer == nil || backgroundImageBuffer == nil) {
            return reject("images", "Failed to create buffer from image", NSError(domain:"", code:500, userInfo:nil))
        }

        // check height and widths of images to ensure background > input
        let inputWidth = CVPixelBufferGetWidth(inputImageBuffer!)
        let backgroundWidth = CVPixelBufferGetWidth(backgroundImageBuffer!)
        let inputHeight = CVPixelBufferGetHeight(inputImageBuffer!)
        let backgroundHeight = CVPixelBufferGetHeight(backgroundImageBuffer!)
                
        if (inputWidth > backgroundWidth || inputHeight > backgroundHeight) {
            return reject("images", "Input image \(inputWidth)x\(inputHeight) is smaller than background image \(backgroundWidth)x\(backgroundHeight)", NSError(domain:"", code:500, userInfo:nil))
        }
        
        // create the vision image from the buffer and set orientation
        let visionImage = VisionImage(image: inputUiImage!)
        if let orientation = inputUiImage?.imageOrientation {
            visionImage.orientation = orientation
        }

        // set up the segmenter
        let options = SelfieSegmenterOptions()
        options.segmenterMode = .singleImage
        let segmenter = Segmenter.segmenter(options: options)

        // get the mask for the input image
        var mask: SegmentationMask
        do {
          mask = try segmenter.results(in: visionImage)
        } catch let error {
          return reject("segmenter", "Failed to perform segmentation with error: \(error.localizedDescription).", error)
        }
        
        // apply background to input using the mask
        UIUtilities.applySegmentationMask(mask: mask , inputImage: inputImageBuffer!, backgroundImage: backgroundImageBuffer!)

        // now convert back to a UI image and return the base64 image
        if let newUiImage = UIUtilities.createUIImage(from: inputImageBuffer!, orientation: visionImage.orientation) {
            let newUiImageFilePath = UIUtilities.saveUiImageToFilePath(uiImage: newUiImage);
            return newUiImageFilePath != nil ? resolve(newUiImageFilePath) :
                    reject("images", "Failed to save image to file path", NSError(domain:"", code:500, userInfo:nil))
        }

        return reject("images", "Failed to create image from input", NSError(domain:"", code:500, userInfo:nil))
    }
}
