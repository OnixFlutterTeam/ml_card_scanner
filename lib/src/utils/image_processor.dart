import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

Future<InputImage> createInputImageInIsolate({
  required Uint8List rawBytes,
  required int width,
  required int height,
  required int rawRotation,
  required int rawFormat,
  required int bytesPerRow,
}) async {
  return await compute(_processImage, {
    "rawBytes": rawBytes,
    "width": width,
    "height": height,
    "rawRotation": rawRotation,
    "rawFormat": rawFormat,
    "bytesPerRow": bytesPerRow,
  });
}

InputImage _processImage(Map<String, dynamic> data) {
  final Uint8List rawBytes = data["rawBytes"];
  final int width = data["width"];
  final int height = data["height"];
  final int rawRotation = data["rawRotation"];
  final int rawFormat = data["rawFormat"];
  final int bytesPerRow = data["bytesPerRow"];

  final ImageProcessor imageProcessor = ImageProcessor();
  return imageProcessor.createInputImage(
    rawBytes: rawBytes,
    width: width,
    height: height,
    rawRotation: rawRotation,
    rawFormat: rawFormat,
    bytesPerRow: bytesPerRow,
  );
}

///////////////////////

class ImageProcessor {
  Function(Uint8List bytes)? debugCallback;

  ImageProcessor();

  InputImage createInputImage({
    required Uint8List rawBytes,
    required int bytesPerRow,
    required int width,
    required int height,
    required int rawRotation,
    required int rawFormat,
  }) {
    try {
      var baseImage = Platform.isAndroid
          ? _convertNV21toImage(rawBytes, width, height)
          : _convertBGRA8888toImage(rawBytes, width, height);

      baseImage = img.grayscale(baseImage, amount: 1.0);
      baseImage = img.adjustColor(
        baseImage,
        contrast: 4.0,
        brightness: 1.2,
      );
      // baseImage = applySharpening(baseImage);
      // baseImage = applyThreshold(baseImage, threshold: 60,);
      //_debugCallback(baseImage);

      final Uint8List finalRGBA = Uint8List.fromList(baseImage.getBytes());
      final Uint8List bgraBytes = convertRgbaToNv21(finalRGBA, width, height);

      return InputImage.fromBytes(
        bytes: bgraBytes,
        metadata: InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: InputImageRotationValue.fromRawValue(rawRotation)!,
          format: InputImageFormat.nv21,
          bytesPerRow: width * 4,
        ),
      );
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  void _debugCallback(img.Image baseImage) {
    if (debugCallback != null) {
      debugPrint('debugCallback !');
      Uint8List pngBytes = Uint8List.fromList(img.encodePng(baseImage));
      debugCallback!(pngBytes);
    }
  }
}

img.Image applySharpening(img.Image image) {
  // 3x3 Sharpening Kernel
  final List<List<int>> kernel = [
    [-1, -1, -1],
    [-1, 9, -1],
    [-1, -1, -1],
  ];

  final img.Image newImage = img.Image.from(image);
  final int width = image.width;
  final int height = image.height;

  for (int y = 1; y < height - 1; y++) {
    for (int x = 1; x < width - 1; x++) {
      double sumR = 0, sumG = 0, sumB = 0;

      for (int ky = -1; ky <= 1; ky++) {
        for (int kx = -1; kx <= 1; kx++) {
          img.Pixel pixel = image.getPixel(x + kx, y + ky);
          int kernelValue = kernel[ky + 1][kx + 1];

          sumR += pixel.r * kernelValue;
          sumG += pixel.g * kernelValue;
          sumB += pixel.b * kernelValue;
        }
      }

      // Clamp values to [0, 255]
      int newR = sumR.clamp(0, 255).toInt();
      int newG = sumG.clamp(0, 255).toInt();
      int newB = sumB.clamp(0, 255).toInt();

      newImage.setPixelRgba(x, y, newR, newG, newB, 255);
    }
  }

  return newImage;
}

img.Image applyThreshold(img.Image image, {int threshold = 128}) {
  img.Image newImage = img.Image.from(image);

  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      img.Pixel pixel = image.getPixel(x, y);

      int luminance =
          ((pixel.r * 0.3) + (pixel.g * 0.59) + (pixel.b * 0.11)).toInt();
      int binary = (luminance > threshold) ? 255 : 0;

      newImage.setPixelRgba(x, y, binary, binary, binary, 255);
    }
  }

  return newImage;
}

img.Image _convertBGRA8888toImage(Uint8List bgraBytes, int width, int height) {
  Uint8List rgbaBytes = Uint8List(bgraBytes.length);
  for (int i = 0; i < bgraBytes.length; i += 4) {
    rgbaBytes[i] = bgraBytes[i + 2];
    rgbaBytes[i + 1] = bgraBytes[i + 1];
    rgbaBytes[i + 2] = bgraBytes[i];
    rgbaBytes[i + 3] = bgraBytes[i + 3];
  }
  return img.Image.fromBytes(
    width: width,
    height: height,
    bytes: rgbaBytes.buffer,
    format: img.Format.uint8,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );
}

img.Image _convertNV21toImage(Uint8List nv21Bytes, int width, int height) {
  Uint8List rgbaBytes = _yuv420NV21ToRgba8888(nv21Bytes, width, height);
  return img.Image.fromBytes(
    width: width,
    height: height,
    bytes: rgbaBytes.buffer,
    format: img.Format.uint8,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );
}

Uint8List _yuv420NV21ToRgba8888(Uint8List src, int width, int height) {
  final rgba = Uint8List(width * height * 4);
  final nvStart = width * height;
  int index = 0, rgbaIndex = 0;
  int y, u, v;
  int r, g, b, a;
  int nvIndex = 0;

  for (int i = 0; i < height; i++) {
    for (int j = 0; j < width; j++) {
      nvIndex = (i ~/ 2 * width + j - j % 2).toInt();
      y = src[rgbaIndex];
      u = src[nvStart + nvIndex];
      v = src[nvStart + nvIndex + 1];
      r = y + (1.13983 * (v - 128)).toInt();
      g = y - (0.39465 * (u - 128)).toInt() - (0.58060 * (v - 128)).toInt();
      b = y + (2.03211 * (u - 128)).toInt();
      a = 255;
      r = r.clamp(0, 255);
      g = g.clamp(0, 255);
      b = b.clamp(0, 255);
      index = rgbaIndex % width + i * width;
      rgba[index * 4 + 0] = b;
      rgba[index * 4 + 1] = g;
      rgba[index * 4 + 2] = r;
      rgba[index * 4 + 3] = a;
      rgbaIndex++;
    }
  }

  return rgba;
}

Uint8List convertRgbaToNv21(Uint8List rgbaBytes, int width, int height) {
  int frameSize = width * height;
  Uint8List nv21 = Uint8List(frameSize + (frameSize ~/ 2));

  int yIndex = 0;
  int uvIndex = frameSize;

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      int rgbaIndex = (y * width + x) * 4;

      int r = rgbaBytes[rgbaIndex];
      int g = rgbaBytes[rgbaIndex + 1];
      int b = rgbaBytes[rgbaIndex + 2];

      // Compute Y value (Luma)
      int yValue = ((0.299 * r) + (0.587 * g) + (0.114 * b)).toInt();
      nv21[yIndex++] = yValue.clamp(0, 255);

      // Compute UV values (Chroma) for every 2x2 block
      if (y % 2 == 0 && x % 2 == 0) {
        int uValue = (((b - yValue) * 0.565) + 128).toInt();
        int vValue = (((r - yValue) * 0.713) + 128).toInt();

        // NV21 format interleaves V and U
        nv21[uvIndex++] = vValue.clamp(0, 255); // V first
        nv21[uvIndex++] = uValue.clamp(0, 255); // U second
      }
    }
  }

  return nv21;
}
