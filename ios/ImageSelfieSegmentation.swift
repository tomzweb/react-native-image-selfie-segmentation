@objc(ImageSelfieSegmentation)
class ImageSelfieSegmentation: NSObject {

    @objc(replaceBackground:withB:withResolver:withRejecter:)
    func replaceBackground(inputImage: NSString, backgroundImage: NSString, resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
        print(inputImage)
        print(backgroundImage)
        resolve("Hello")
    }
}
