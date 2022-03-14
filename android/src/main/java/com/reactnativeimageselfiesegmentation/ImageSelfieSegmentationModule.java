package com.reactnativeimageselfiesegmentation;

import android.content.Context;
import android.content.ContextWrapper;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.graphics.Matrix;
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
  public void replaceBackground(String inputStr, String backgroundStr, int maxSize, Promise promise) {

    String finalImage = "";
    int inputRotation =  getRotationFromPath(inputStr);
    int backgroundRotation = getRotationFromPath(backgroundStr);
    Bitmap inputBitmap = resize(toBitmap(inputStr), maxSize, maxSize, 0,false);
    Bitmap backgroundBitmap = resize(toBitmap(backgroundStr), maxSize, maxSize, backgroundRotation, true);

    Log.i("PRE INPUT SIZES", "Input image " + inputBitmap.getWidth() + "x" + inputBitmap.getHeight()
      + " - Background image " + backgroundBitmap.getWidth() + "x" + backgroundBitmap.getHeight());


    InputImage inputImage = InputImage.fromBitmap(inputBitmap, inputRotation);
    InputImage backgroundImage = InputImage.fromBitmap(backgroundBitmap, backgroundRotation);

    Log.i("ROTATIONS", inputRotation + " " + backgroundRotation);
    Log.i("INPUT ROTATIONS", inputImage.getRotationDegrees() + " " + backgroundImage.getRotationDegrees());


    int iWidth = inputImage.getWidth();
    int iHeight = inputImage.getHeight();
    int bWidth = backgroundImage.getWidth();
    int bHeight = backgroundImage.getHeight();

    Log.i("SIZES", "Input image " + iWidth + "x" + iHeight
      + " - Background image " + bWidth + "x" + bHeight);

    if (iWidth > bWidth || iHeight > bHeight) {
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

    try {
      SegmentationMask mask = Tasks.await(result);
      // convert mask
      Log.i("SIZES MASK", mask.getWidth() + " " + mask.getHeight());
      finalImage = generateMaskImage(mask, inputImage.getBitmapInternal(), backgroundImage.getBitmapInternal(), inputRotation, backgroundRotation);
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


  private String generateMaskImage (SegmentationMask mask, Bitmap inputBitmap, Bitmap backgroundBitmap, int inputRotation, int backgroundRotation) {
    // create a blank bitmap to put our new mask/image
    // if an image is rotated, we need to use height for width and visa versa
    int newWidth = isRotated(inputRotation) ? inputBitmap.getHeight() : inputBitmap.getWidth();
    int newHeight = isRotated(inputRotation) ? inputBitmap.getWidth() : inputBitmap.getHeight();
    Bitmap combinedBitmap = Bitmap.createBitmap(newWidth, newHeight, inputBitmap.getConfig());
    Log.i("PRE FINAL IMAGE", combinedBitmap.getWidth() + " "  + combinedBitmap.getHeight());

    inputBitmap = isRotated(inputRotation) ? rotateBitmap(inputBitmap, inputRotation) : inputBitmap;
    backgroundBitmap = isRotated(backgroundRotation) ? rotateBitmap(backgroundBitmap, backgroundRotation) : backgroundBitmap;

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
    Bitmap bitmap = null;
    try {
      bitmap = MediaStore.Images.Media.getBitmap(this.getCurrentActivity().getContentResolver(), myUri);
    } catch (IOException e) {
      e.printStackTrace();
    }
    Log.i("DEFAULT SIZE", bitmap.getWidth() + " " + bitmap.getHeight());
    return bitmap;
  }

  public Bitmap rotateBitmap(Bitmap source, int angle)
  {
    Matrix matrix = new Matrix();
    matrix.postRotate(angle);
    return Bitmap.createBitmap(source, 0, 0, source.getWidth(), source.getHeight(), matrix, true);
  }

  public int getRotationFromPath(String filePath) {
    int rotation = 0;
    Uri myUri = Uri.parse(filePath);
    try {
      ExifInterface exif = new ExifInterface(myUri.getPath());
      rotation = exif.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL);
    } catch (IOException e) {
      e.printStackTrace();
    }
    if (rotation == ExifInterface.ORIENTATION_ROTATE_90) { return 90; }
    else if (rotation == ExifInterface.ORIENTATION_ROTATE_180) {  return 180; }
    else if (rotation == ExifInterface.ORIENTATION_ROTATE_270) {  return 270; }
    return 0;
  }


  /**
   * Resize the bitmap
   * @param image
   * @param maxWidth
   * @param maxHeight
   * @param rotation used to determine final height
   * @param isBackground used to determine final height for backgrounds,
   *                     where they need to be larger than the input image
   * @return
   */
  private Bitmap resize(Bitmap image, int maxWidth, int maxHeight, int rotation, boolean isBackground) {
    int width = image.getWidth();
    int height = image.getHeight();

    // handles images where rotation is 0, but is portrait
    float aspectRatio = image.getWidth() > image.getHeight() ? (float) width / (float) height : (float) height / (float) width;

    // handles rotated images
    int finalWidth = maxWidth;
    int finalHeight = isRotated(rotation) || isBackground ? Math.round(maxHeight * aspectRatio) : Math.round(maxHeight / aspectRatio);

    Bitmap resizedImage = Bitmap.createScaledBitmap(image, finalWidth, finalHeight, true);

    image.recycle();
    return resizedImage;
  }

  private Boolean isRotated(int rotation) {
    return rotation == 90 || rotation == 270;
  }

    public static native String nativeReplaceBackground(String inputImage, String backgroundImage);
}
