#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(ImageSelfieSegmentation, NSObject)

RCT_EXTERN_METHOD(
                  replaceBackground:(NSString)inputImage
                  withB:(NSString)backgroundImage
                  withC:(NSNumber* _Nonnull)maxSize
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)

@end
