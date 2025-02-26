import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

import 'image_converting_util.dart';

Future<InputImage> createInputImageInIsolate({
  required Uint8List rawBytes,
  required int width,
  required int height,
  required int rawRotation,
  required int rawFormat,
  required int bytesPerRow,
  SendPort? debugSendPort,
}) async {
  return await compute(_processImage, {
    "rawBytes": rawBytes,
    "width": width,
    "height": height,
    "rawRotation": rawRotation,
    "rawFormat": rawFormat,
    "bytesPerRow": bytesPerRow,
    "debugSendPort": debugSendPort,
  });
}

InputImage _processImage(Map<String, dynamic> data) {
  final Uint8List rawBytes = data["rawBytes"];
  final int width = data["width"];
  final int height = data["height"];
  final int rawRotation = data["rawRotation"];
  final int rawFormat = data["rawFormat"];
  final int bytesPerRow = data["bytesPerRow"];
  final SendPort? debugSendPort = data["debugSendPort"] as SendPort?;

  return createInputImage(
    rawBytes: rawBytes,
    width: width,
    height: height,
    rawRotation: rawRotation,
    rawFormat: rawFormat,
    bytesPerRow: bytesPerRow,
    debugSendPort: debugSendPort,
  );
}

///////////////////////

InputImage createInputImage({
  required Uint8List rawBytes,
  required int bytesPerRow,
  required int width,
  required int height,
  required int rawRotation,
  required int rawFormat,
  SendPort? debugSendPort,
}) {
  try {
    final format = InputImageFormatValue.fromRawValue(rawFormat);

    debugPrint(
      'createInputImage: '
      'format: $format, '
      'width: $width, '
      'height: $height'
      'bytesPerRow: $bytesPerRow',
    );

    var baseImage = Platform.isAndroid
        ? ImageConvertingUtil.convertNV21toImage(
            rawBytes,
            width,
            height,
          )
        : ImageConvertingUtil.convertBGRA8888toImage(
            rawBytes,
            width,
            height,
            bytesPerRow,
          );

    baseImage = img.grayscale(baseImage);
    baseImage = img.adjustColor(
      baseImage,
      contrast: 3.0, // High contrast for better edge detection
      //brightness: 1.5,  // Slight increase to lighten dark areas
    );

    width = 640;
    height = 480;
    baseImage = img.copyResize(baseImage, width: width, height: height);

    // baseImage = img.gaussianBlur(baseImage, radius: 1);
    // baseImage = img.sobel(baseImage, amount: 1);
    // baseImage = ImageFilterUtil.applySharpening(baseImage);
    // baseImage = ImageFilterUtil.applyThreshold(baseImage, threshold: 60,);

    if (debugSendPort != null) {
      debugSendPort.send(_convertToPngBytes(baseImage));
    }

    final Uint8List finalRGBA = Uint8List.fromList(baseImage.getBytes());
    final Uint8List bgraBytes = Platform.isAndroid
        ? ImageConvertingUtil.convertRgbaToNv21(finalRGBA, width, height)
        : ImageConvertingUtil.convertRgbaToBgra(finalRGBA);

    return InputImage.fromBytes(
      bytes: bgraBytes,
      metadata: InputImageMetadata(
        size: Size(width.toDouble(), height.toDouble()),
        rotation: InputImageRotationValue.fromRawValue(rawRotation) ??
            InputImageRotation.rotation90deg,
        format: Platform.isAndroid
            ? InputImageFormat.nv21
            : InputImageFormat.bgra8888,
        bytesPerRow: width * 4,
      ),
    );
  } catch (e) {
    debugPrint(e.toString());
    rethrow;
  }
}

Uint8List _convertToPngBytes(img.Image baseImage) => Uint8List.fromList(
      img.encodePng(
        baseImage,
      ),
    );
