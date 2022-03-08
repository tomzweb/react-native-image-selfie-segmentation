import { NativeModules, Platform } from 'react-native';

const LINKING_ERROR =
  `The package 'react-native-image-selfie-segmentation' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo managed workflow\n';

const ImageSelfieSegmentation = NativeModules.ImageSelfieSegmentation
  ? NativeModules.ImageSelfieSegmentation
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

export function replaceBackground(
  inputImage: string,
  backgroundImage: string
): Promise<string> {
  return ImageSelfieSegmentation.replaceBackground(inputImage, backgroundImage);
}
