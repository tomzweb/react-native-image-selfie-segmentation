package com.reactnativeimageselfiesegmentation;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.util.Base64;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.module.annotations.ReactModule;
import com.google.android.gms.tasks.Task;
import com.google.android.gms.tasks.Tasks;
import com.google.mlkit.vision.common.InputImage;
import com.google.mlkit.vision.segmentation.Segmentation;
import com.google.mlkit.vision.segmentation.SegmentationMask;
import com.google.mlkit.vision.segmentation.Segmenter;
import com.google.mlkit.vision.segmentation.selfie.SelfieSegmenterOptions;

import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.util.concurrent.ExecutionException;

@ReactModule(name = ImageSelfieSegmentationModule.NAME)
public class ImageSelfieSegmentationModule extends ReactContextBaseJavaModule {
    public static final String NAME = "ImageSelfieSegmentation";

    public ImageSelfieSegmentationModule(ReactApplicationContext reactContext) {
        super(reactContext);
    }

    @Override
    @NonNull
    public String getName() {
        return NAME;
    }


    // Example method
    // See https://reactnative.dev/docs/native-modules-android
    @ReactMethod
    public void replaceBackground(String inputStr, String backgroundStr, Promise promise) {

      // setup the segmentation options
      SelfieSegmenterOptions options =
        new SelfieSegmenterOptions.Builder()
          .setDetectorMode(SelfieSegmenterOptions.SINGLE_IMAGE_MODE)
          .build();

      Segmenter segmenter = Segmentation.getClient(options);

      String base64Image = "";
      Bitmap inputBitmap = toBitmap(inputStr);
      Bitmap backgroundBitmap = toBitmap(backgroundStr);
      InputImage inputImage = InputImage.fromBitmap(inputBitmap, 0);

      // process the mask
      Task<SegmentationMask> result = segmenter.process(inputImage);

      try {
        SegmentationMask mask = Tasks.await(result);
        // convert mask
        base64Image = generateBase64MaskImage(mask, inputBitmap, backgroundBitmap);
      } catch (ExecutionException e) {
        // The Task failed, this is the same exception you'd get in a non-blocking
        // failure handler.
      } catch (InterruptedException e) {
        // An interrupt occurred while waiting for the task to complete.
      }


      promise.resolve(base64Image);
    }

  private String generateBase64MaskImage (SegmentationMask mask, Bitmap inputBitmap, Bitmap backgroundBitmap) {
    // create a blank bitmap to put our new mask/image
    Bitmap combinedBitmap = Bitmap.createBitmap(inputBitmap.getWidth(), inputBitmap.getHeight(), inputBitmap.getConfig());
    int maskWidth = mask.getWidth();
    int maskHeight = mask.getHeight();
    ByteBuffer bufferMask = mask.getBuffer();

    for (int y = 0; y < maskHeight; y++) {
      for (int x = 0; x < maskWidth; x++) {
        // gets the likely hood of the background for this pixel
        double backgroundLikelihood = 1 - bufferMask.getFloat();
        // sets the color of the pixel, depending if background or not
        int bgPixel = backgroundLikelihood > 0.2 ? backgroundBitmap.getPixel(x, y) : inputBitmap.getPixel(x, y) ;
        combinedBitmap.setPixel(x, y, bgPixel);
      }
    }

    // converts and returns base64 image
    return toBase64(combinedBitmap);
  }

  /** Converts NV21 format byte buffer to bitmap. */
  @Nullable
  public static Bitmap toBitmap(String input) {
    byte[] decodedString = Base64.decode(input, Base64.DEFAULT);
    Bitmap decodedByte = BitmapFactory.decodeByteArray(decodedString, 0, decodedString.length);
    return decodedByte;
  }

  /** Converts NV21 format byte buffer to bitmap. */
  @Nullable
  public static String toBase64(Bitmap bitmap) {
    ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
    bitmap.compress(Bitmap.CompressFormat.JPEG, 100, byteArrayOutputStream);
    byte[] byteArray = byteArrayOutputStream .toByteArray();
    return "data:image/jpeg;base64," + Base64.encodeToString(byteArray, Base64.NO_WRAP);
  }

  public static native String nativeReplaceBackground(String inputImage, String backgroundImage);
}
