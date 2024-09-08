import 'dart:async';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ml_card_scanner/src/model/card_info.dart';
import 'package:ml_card_scanner/src/parser/parser_algorithm.dart';

class ScannerProcessor {
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  Future<CardInfo?> computeImage(
    ParserAlgorithm parseAlgorithm,
    CameraImage image,
    InputImageRotation rotation,
  ) async {
    final format = InputImageFormatValue.fromRawValue(
      image.format.raw,
    );

    final plane = image.planes.first;
    final bytes = image.planes.map((e) => e.bytes).toList();

    final inputImage = await compute<List<Uint8List>, InputImage>(
      (message) async {
        final bytesAll = Uint8List.fromList(
          bytes.fold(
              <int>[],
              (List<int> previousValue, element) =>
                  previousValue..addAll(element)),
        );
        final input = InputImage.fromBytes(
          bytes: bytesAll,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: rotation,
            format: format ?? InputImageFormat.yuv420,
            bytesPerRow: plane.bytesPerRow,
          ),
        );
        return input;
      },
      bytes,
    );
    final recognizedText = await _recognizer.processImage(inputImage);
    return parseAlgorithm.parse(recognizedText);
  }

  void dispose() {
    unawaited(_recognizer.close());
  }
}
