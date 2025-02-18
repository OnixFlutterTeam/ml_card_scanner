import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

/// Example processor that converts [CameraImage] to [InputImage].
/// Handles NV21, YUV_420_888, and BGRA with boundary checks.
class ImageProcessor {
  // Optional callback if you want to debug the raw bytes
  Function(Uint8List bytes)? debugCallback;

  ImageProcessor();

  /// Creates an [InputImage] for ML Kit from the given [CameraImage].
  ///  - Converts image to 3-channel RGB
  ///  - Grayscale + contrast
  ///  - Converts to BGRA for ML Kit
  InputImage createInputImage(CameraImage image, InputImageRotation rotation) {
    try {
      final formatValue = InputImageFormatValue.fromRawValue(image.format.raw);
      debugPrint('createInputImage\n'
          ' image.format.raw: ${image.format.raw}\n'
          ' formatValue: $formatValue\n'
          'rotation: $rotation\n'
          '');

      final width = image.width;
      final height = image.height;
      final rawBites = image.planes[0].bytes;

      // 1) Convert to 3-channel RGB (with plane-count check)
      final rgbBytes = yuv420NV12ToRgba8888(rawBites, width, height);

      // (Optional) debug callback
      if (debugCallback != null) {
        debugPrint('debugCallback !');
        img.Image rgbImage = img.Image.fromBytes(
          width: width,
          height: height,
          bytes: rgbBytes.buffer,
          format: img.Format.uint8,
          numChannels: 4,
          order: img.ChannelOrder.rgba,
        );
        Uint8List pngBytes = Uint8List.fromList(img.encodePng(rgbImage));
        debugCallback!(pngBytes);
      }

      // 2) Use image package to apply grayscale + contrast
      img.Image baseImage = img.Image.fromBytes(
        width: image.width,
        height: image.height,
        bytes: rgbBytes.buffer,
        format: img.Format.uint8,
        numChannels: 4,
        order: img.ChannelOrder.rgba,
      );

      baseImage = img.grayscale(baseImage);
      baseImage = img.adjustColor(baseImage, contrast: 2.0);

      // 3) Convert final RGB → BGRA (4 bytes/pixel) for ML Kit
      final Uint8List finalRGB = Uint8List.fromList(baseImage.getBytes());
      final Uint8List bgraBytes =
          _convertRGBtoBGRA(finalRGB, image.width, image.height);

      // 4) Build InputImage with BGRA data
      return InputImage.fromBytes(
        bytes: bgraBytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.bgra8888, // 4-ch BGRA
          bytesPerRow: image.width * 4, // 4 bytes per pixel
        ),
      );
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }
}

Uint8List yuv420NV12ToRgba8888(Uint8List src, int width, int height) {
  final rgba = Uint8List(width * height * 4);
  final uvStart = width * height;
  int index = 0, rgbaIndex = 0;
  int y, u, v;
  int r, g, b, a;
  int uvIndex = 0;

  for (int i = 0; i < height; i++) {
    for (int j = 0; j < width; j++) {
      uvIndex = (i ~/ 2 * width + j - j % 2).toInt();

      y = src[rgbaIndex];
      u = src[uvStart + uvIndex];
      v = src[uvStart + uvIndex + 1];

// 调整系数以改善颜色质量
      r = y + (1.164 * (v - 128)).toInt(); // r
      g = y - (0.392 * (u - 128)).toInt() - (0.813 * (v - 128)).toInt(); // g
      b = y + (2.017 * (u - 128)).toInt(); // b
      a = 255; // 设置透明度为255（不透明）

// 颜色通道值限制在0到255之间
      r = r.clamp(0, 255);
      g = g.clamp(0, 255);
      b = b.clamp(0, 255);

// 计算索引并填充RGBA通道值
      index = rgbaIndex % width + i * width;
      rgba[index * 4 + 0] = r;
      rgba[index * 4 + 1] = g;
      rgba[index * 4 + 2] = b;
      rgba[index * 4 + 3] = a;
      rgbaIndex++;
    }
  }

  return rgba;
}

/// Decides how to extract 3-channel RGB based on plane count & format.
Uint8List _convertImageToRGB(CameraImage image) {
  final planes = image.planes;

  // Some devices incorrectly report nv21 but have 3 planes.
  // It's safer to rely on plane count primarily:
  if (planes.length == 1) {
    // Usually iOS BGRA
    return _convertBGRAtoRGB(image);
  } else if (planes.length == 2) {
    // Potentially NV21 (plane[0]=Y, plane[1]=VU)
    // Check if plane[1] has enough data to be real NV21
    final needed = (image.width ~/ 2) * (image.height ~/ 2) * 2;
    if (planes[1].bytes.length >= needed) {
      return _convertNV21ToRGB(image);
    } else {
      // Fallback: treat as 3-plane YUV
      return _convertYUV420ToRGB_Fallback(planes);
    }
  } else if (planes.length == 3) {
    // Standard YUV_420_888
    return _convert3PlaneYUVToRGB(image);
  } else {
    throw UnsupportedError(
      'Unsupported plane count: ${planes.length}. Cannot convert to RGB.',
    );
  }
}

/// True NV21: plane[0] = Y, plane[1] = interleaved [V, U].
/// Adds boundary checks to avoid RangeError.
Uint8List _convertNV21ToRGB(CameraImage image) {
  final width = image.width;
  final height = image.height;

  final planeY = image.planes[0];
  final planeVU = image.planes[1];

  final yBuffer = planeY.bytes;
  final vuBuffer = planeVU.bytes;

  final yRowStride = planeY.bytesPerRow;
  final vuRowStride = planeVU.bytesPerRow;

  final rgb = Uint8List(width * height * 3);
  int rgbIndex = 0;

  for (int row = 0; row < height; row++) {
    // The row in the VU buffer for this Y row
    final int vuRow = (row ~/ 2) * vuRowStride;
    for (int col = 0; col < width; col++) {
      // Calculate Y index:
      final int yIndex = row * yRowStride + col;
      if (yIndex >= yBuffer.length) {
        // Out-of-bounds: fill with black/gray or break
        rgb[rgbIndex++] = 0;
        rgb[rgbIndex++] = 0;
        rgb[rgbIndex++] = 0;
        continue;
      }
      final int yVal = yBuffer[yIndex] & 0xFF;

      // For each pair of pixels, we read two bytes: [V, U]
      final int vuOffset = (col ~/ 2) * 2;
      final int vIndex = vuRow + vuOffset;
      final int uIndex = vIndex + 1;

      // Boundary checks for V/U
      if (uIndex >= vuBuffer.length) {
        // If the second plane is too short, fallback to grayscale
        rgb[rgbIndex++] = yVal;
        rgb[rgbIndex++] = yVal;
        rgb[rgbIndex++] = yVal;
        continue;
      }

      final int vVal = vuBuffer[vIndex] & 0xFF;
      final int uVal = vuBuffer[uIndex] & 0xFF;

      // YUV -> RGB
      double r = yVal + 1.370705 * (vVal - 128);
      double g = yVal - 0.698001 * (vVal - 128) - 0.337633 * (uVal - 128);
      double b = yVal + 1.732446 * (uVal - 128);

      rgb[rgbIndex++] = r.clamp(0, 255).toInt();
      rgb[rgbIndex++] = g.clamp(0, 255).toInt();
      rgb[rgbIndex++] = b.clamp(0, 255).toInt();
    }
  }

  return rgb;
}

/// 3-plane YUV (YUV_420_888 or similar) -> 3-channel RGB.
Uint8List _convert3PlaneYUVToRGB(CameraImage image) {
  final width = image.width;
  final height = image.height;

  final yPlane = image.planes[0];
  final uPlane = image.planes[1];
  final vPlane = image.planes[2];

  final yRowStride = yPlane.bytesPerRow;
  final uvRowStride = uPlane.bytesPerRow;
  final uvPixelStride = uPlane.bytesPerPixel ?? 1;

  final yBytes = yPlane.bytes;
  final uBytes = uPlane.bytes;
  final vBytes = vPlane.bytes;

  final rgb = Uint8List(width * height * 3);
  int rgbIndex = 0;

  for (int row = 0; row < height; row++) {
    final uvRow = (row ~/ 2) * uvRowStride;
    for (int col = 0; col < width; col++) {
      final int yIndex = row * yRowStride + col;
      if (yIndex >= yBytes.length) {
        // Out of range, fill with 0 or break
        rgb[rgbIndex++] = 0;
        rgb[rgbIndex++] = 0;
        rgb[rgbIndex++] = 0;
        continue;
      }
      final int yVal = yBytes[yIndex] & 0xFF;

      final uvCol = (col ~/ 2) * uvPixelStride;
      final int uIndex = uvRow + uvCol;
      final int vIndex = uvRow + uvCol;

      if (uIndex >= uBytes.length || vIndex >= vBytes.length) {
        // Fill with grayscale
        rgb[rgbIndex++] = yVal;
        rgb[rgbIndex++] = yVal;
        rgb[rgbIndex++] = yVal;
        continue;
      }

      final int uVal = uBytes[uIndex] & 0xFF;
      final int vVal = vBytes[vIndex] & 0xFF;

      double r = yVal + 1.370705 * (vVal - 128);
      double g = yVal - 0.698001 * (vVal - 128) - 0.337633 * (uVal - 128);
      double b = yVal + 1.732446 * (uVal - 128);

      rgb[rgbIndex++] = r.clamp(0, 255).toInt();
      rgb[rgbIndex++] = g.clamp(0, 255).toInt();
      rgb[rgbIndex++] = b.clamp(0, 255).toInt();
    }
  }

  return rgb;
}

/// Fallback for devices labeled 'NV21' but not truly.
/// Just treat planes as if they are 3-plane YUV.
Uint8List _convertYUV420ToRGB_Fallback(List<Plane> planes) {
  if (planes.length < 3) {
    throw ArgumentError('Not enough planes for fallback YUV.');
  }
  final width = planes[0].width!;
  final height = planes[0].height!;

  final yBytes = planes[0].bytes;
  final uBytes = planes[1].bytes;
  final vBytes = planes[2].bytes;

  final yRowStride = planes[0].bytesPerRow;
  final uvRowStride = planes[1].bytesPerRow;
  final uvPixelStride = planes[1].bytesPerPixel ?? 1;

  final rgb = Uint8List(width * height * 3);
  int rgbIndex = 0;

  for (int row = 0; row < height; row++) {
    final uvRow = (row ~/ 2) * uvRowStride;
    for (int col = 0; col < width; col++) {
      final int yIndex = row * yRowStride + col;
      if (yIndex >= yBytes.length) {
        rgb[rgbIndex++] = 0;
        rgb[rgbIndex++] = 0;
        rgb[rgbIndex++] = 0;
        continue;
      }
      final int yVal = yBytes[yIndex] & 0xFF;

      final uvCol = (col ~/ 2) * uvPixelStride;
      final int uIndex = uvRow + uvCol;
      final int vIndex = uvRow + uvCol;

      if (uIndex >= uBytes.length || vIndex >= vBytes.length) {
        // fallback grayscale
        rgb[rgbIndex++] = yVal;
        rgb[rgbIndex++] = yVal;
        rgb[rgbIndex++] = yVal;
        continue;
      }

      final int uVal = uBytes[uIndex] & 0xFF;
      final int vVal = vBytes[vIndex] & 0xFF;

      double r = yVal + 1.370705 * (vVal - 128);
      double g = yVal - 0.698001 * (vVal - 128) - 0.337633 * (uVal - 128);
      double b = yVal + 1.732446 * (uVal - 128);

      rgb[rgbIndex++] = r.clamp(0, 255).toInt();
      rgb[rgbIndex++] = g.clamp(0, 255).toInt();
      rgb[rgbIndex++] = b.clamp(0, 255).toInt();
    }
  }
  return rgb;
}

/// Convert BGRA (planes[0]) -> 3-byte RGB
Uint8List _convertBGRAtoRGB(CameraImage image) {
  final int width = image.width;
  final int height = image.height;
  final Uint8List bgra = image.planes[0].bytes;
  final Uint8List rgb = Uint8List(width * height * 3);

  int iBGRA = 0;
  int iRGB = 0;
  final int totalPixels = width * height;

  for (int i = 0; i < totalPixels; i++) {
    if (iBGRA + 2 >= bgra.length) {
      // Out of range, fill with 0
      rgb[iRGB++] = 0;
      rgb[iRGB++] = 0;
      rgb[iRGB++] = 0;
      break;
    }
    final b = bgra[iBGRA];
    final g = bgra[iBGRA + 1];
    final r = bgra[iBGRA + 2];
    // final a = bgra[iBGRA + 3];

    rgb[iRGB++] = r;
    rgb[iRGB++] = g;
    rgb[iRGB++] = b;

    iBGRA += 4;
  }

  return rgb;
}

/// Convert 3-channel [rgbBytes] -> 4-channel BGRA8888
Uint8List _convertRGBtoBGRA(Uint8List rgbBytes, int width, int height) {
  final int totalPixels = width * height;
  final Uint8List bgraBytes = Uint8List(totalPixels * 4);

  int iRGB = 0;
  int iBGRA = 0;
  for (int i = 0; i < totalPixels; i++) {
    if (iRGB + 2 >= rgbBytes.length) {
      // Out of range
      bgraBytes[iBGRA] = 0;
      bgraBytes[iBGRA + 1] = 0;
      bgraBytes[iBGRA + 2] = 0;
      bgraBytes[iBGRA + 3] = 255;
      break;
    }
    final r = rgbBytes[iRGB];
    final g = rgbBytes[iRGB + 1];
    final b = rgbBytes[iRGB + 2];

    // BGRA order
    bgraBytes[iBGRA] = b;
    bgraBytes[iBGRA + 1] = g;
    bgraBytes[iBGRA + 2] = r;
    bgraBytes[iBGRA + 3] = 255; // alpha

    iRGB += 3;
    iBGRA += 4;
  }
  return bgraBytes;
}
