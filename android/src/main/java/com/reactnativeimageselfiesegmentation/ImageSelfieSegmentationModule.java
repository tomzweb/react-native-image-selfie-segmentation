package com.reactnativeimageselfiesegmentation;

import android.content.Context;
import android.content.ContextWrapper;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.media.ExifInterface;
import android.net.Uri;
import android.provider.MediaStore;
import android.util.Base64;
import android.util.Log;

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
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.UUID;
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

      String finalImage = "";
      Bitmap inputBitmap = toBitmap(inputStr);
      Bitmap backgroundBitmap = toBitmap(backgroundStr);

      int rotation = 0;
      Uri myUri = Uri.parse(inputStr);
      try {
        ExifInterface exif = new ExifInterface(myUri.getPath());
        rotation = exif.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL);
      } catch (IOException e) {
        e.printStackTrace();
      }

      InputImage inputImage = InputImage.fromBitmap(inputBitmap, exifToDegrees(rotation));

      if (inputBitmap.getWidth() > backgroundBitmap.getWidth() || inputBitmap.getHeight() > backgroundBitmap.getHeight()) {
        // "Input image \(inputWidth)x\(inputHeight) is smaller than background image \(backgroundWidth)x\(backgroundHeight)"
        String iWidth = String.valueOf(inputBitmap.getWidth());
        String iHeight = String.valueOf(inputBitmap.getHeight());
        String bWidth = String.valueOf(backgroundBitmap.getWidth());
        String bHeight = String.valueOf(backgroundBitmap.getHeight());
        promise.reject("images", "Input image " + iWidth + "x" + iHeight
          + " is smaller than background image " + bWidth + "x" + bHeight);

        return;
      }

      // setup the segmentation options
      SelfieSegmenterOptions options =
        new SelfieSegmenterOptions.Builder()
          .setDetectorMode(SelfieSegmenterOptions.SINGLE_IMAGE_MODE)
          .build();

      Segmenter segmenter = Segmentation.getClient(options);

      // process the mask
      Task<SegmentationMask> result = segmenter.process(inputImage);

      ;

      try {
        SegmentationMask mask = Tasks.await(result);
        // convert mask
        finalImage = generateMaskImage(mask, inputBitmap, backgroundBitmap);
        promise.resolve(finalImage);
      } catch (ExecutionException e) {
        // The Task failed, this is the same exception you'd get in a non-blocking
        // failure handler.
        promise.reject("mask", e.getLocalizedMessage());
      } catch (InterruptedException e) {
        // An interrupt occurred while waiting for the task to complete.
        promise.reject("mask", e.getLocalizedMessage());
      }

    }

  private String generateMaskImage (SegmentationMask mask, Bitmap inputBitmap, Bitmap backgroundBitmap) {
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
    return saveToInternalStorage(combinedBitmap);
  }

  private String saveToInternalStorage(Bitmap bitmapImage){
    ContextWrapper cw = new ContextWrapper(this.getCurrentActivity().getApplicationContext());
    File directory = cw.getDir("imageDir", Context.MODE_PRIVATE);
    File filePath = new File(directory, UUID.randomUUID().toString() + ".jpeg");

    FileOutputStream fos = null;
    try {
      fos = new FileOutputStream(filePath);
      bitmapImage.compress(Bitmap.CompressFormat.JPEG, 100, fos);
    } catch (Exception e) {
      e.printStackTrace();
    } finally {
      try {
        fos.close();
      } catch (IOException e) {
        e.printStackTrace();
      }
    }
    return "file://" + filePath.getAbsolutePath();
  }

  /** Converts NV21 format byte buffer to bitmap. */
  @Nullable
  public Bitmap toBitmap(String input) {
    Uri myUri = Uri.parse(input);
    Log.i("INPUT", input  + " " + myUri);

    Bitmap bitmap = null;
    try {
      bitmap = MediaStore.Images.Media.getBitmap(this.getCurrentActivity().getContentResolver(), myUri);
    } catch (IOException e) {
      e.printStackTrace();
    }
    return bitmap;
  }

  /** Converts NV21 format byte buffer to bitmap. */
  @Nullable
  public String toBase64(Bitmap bitmap) {
    ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
    bitmap.compress(Bitmap.CompressFormat.JPEG, 100, byteArrayOutputStream);
    byte[] byteArray = byteArrayOutputStream .toByteArray();
    return "data:image/jpeg;base64," + Base64.encodeToString(byteArray, Base64.NO_WRAP);
  }

  public int exifToDegrees(int exifOrientation) {
    if (exifOrientation == ExifInterface.ORIENTATION_ROTATE_90) { return 90; }
    else if (exifOrientation == ExifInterface.ORIENTATION_ROTATE_180) {  return 180; }
    else if (exifOrientation == ExifInterface.ORIENTATION_ROTATE_270) {  return 270; }
    return 0;
  }

  public static native String nativeReplaceBackground(String inputImage, String backgroundImage);
}
