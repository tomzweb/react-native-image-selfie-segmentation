import CoreVideo
import UIKit
import CoreMedia

@objc(ImageSelfieSegmentation)
class ImageSelfieSegmentation: NSObject {

    @objc(replaceBackground:withB:withResolver:withRejecter:)
    func replaceBackground(inputImage: NSString, backgroundImage: NSString, resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
        
        // set up the segmenter
        let options = SelfieSegmenterOptions()
        options.segmenterMode = .singleImage

        let segmenter = Segmenter.segmenter(options: options)
        
        let inputUiImage = UIUtilities.convertBase64ToUiImage(strBase64: inputImage as String)
        let backgroundUiImage = UIUtilities.convertBase64ToUiImage(strBase64: backgroundImage as String)
        
        // create the vision image from the buffer
        let visionImage = VisionImage(image: inputUiImage)

        var mask: SegmentationMask
        do {
          mask = try segmenter.results(in: visionImage)
        } catch let error {
          print("Failed to perform segmentation with error: \(error.localizedDescription).")
          return
        }
        
      
        // now we need to convert the UI Image to an image buffer
        let inputImageBuffer = UIUtilities.createImageBuffer(from: inputUiImage)!
        let backgroundImageBuffer = UIUtilities.createImageBuffer(from: backgroundUiImage)!

        UIUtilities.applySegmentationMask(mask: mask , inputImage: inputImageBuffer, backgroundImage: backgroundImageBuffer)

        // now convert back to a UI image and return the base64 image
        let newUiImage = UIUtilities.createUIImage(from: inputImageBuffer, orientation: visionImage.orientation)!;
        let base64Image = UIUtilities.convertUiImageToBase64String(img: newUiImage)
        
        resolve("data:image/jpeg;base64," + base64Image)
        
    }
    
}
