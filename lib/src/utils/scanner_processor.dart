import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ml_card_scanner/src/model/card_info.dart';
import 'package:ml_card_scanner/src/parser/parser_algorithm.dart';
import 'package:ml_card_scanner/src/utils/image_processor.dart';

class ScannerProcessor {
  late ImageProcessor imgProcessor = ImageProcessor();
  final TextRecognizer _recognizer =
  TextRecognizer(script: TextRecognitionScript.latin);
  ScannerProcessor() : imgProcessor = ImageProcessor();

  Future<CardInfo?> computeImage(
    ParserAlgorithm parseAlgorithm,
    CameraImage image,
    InputImageRotation rotation,
  ) async {

    // final format = InputImageFormatValue.fromRawValue(
    //   image.format.raw,
    // );
    //
    // final plane = image.planes.first;
    //
    // final bytes = image.planes.map((e) => e.bytes).toList();
    //
    // final inputImage = await compute<List<Uint8List>, InputImage>(
    //   (message) async {
    //     final bytesAll = Uint8List.fromList(
    //       bytes.fold(
    //           <int>[],
    //           (List<int> previousValue, element) =>
    //               previousValue..addAll(element)),
    //     );
    //     final input = InputImage.fromBytes(
    //       bytes: bytesAll,
    //       metadata: InputImageMetadata(
    //         size: Size(image.width.toDouble(), image.height.toDouble()),
    //         rotation: rotation,
    //         format: format ?? InputImageFormat.yuv420,
    //         bytesPerRow: plane.bytesPerRow,
    //       ),
    //     );
    //     return input;
    //   },
    //   bytes,
    // );


    print('image.planes: ${image.planes.length}');

    final rawFormat = image.format.raw;
    final rawRotation = rotation.rawValue;
    final Uint8List bytes = Uint8List.fromList(
      image.planes.fold(
        <int>[],
            (List<int> previousValue, element) =>
        previousValue..addAll(element.bytes),
      ),
    );
    final width = image.width;
    final height = image.height;
    final bytesPerRow = image.planes.first.bytesPerRow;



    final inputImage = await createInputImageInIsolate(
      rawBytes: bytes,
      width: width,
      height: height,
      rawRotation: rawRotation,
      rawFormat: rawFormat,
      bytesPerRow: bytesPerRow,
    );

    // final inputImage = imgProcessor.createInputImage(
    //   rawBytes: bytes,
    //   width: width,
    //   height: height,
    //   rawRotation: rawRotation,
    //   rawFormat: rawFormat,
    //   bytesPerRow: bytesPerRow,
    // );










    final recognizedText = await _recognizer.processImage(inputImage);

    if (kDebugMode) {
      debugPrint('\n\nrecognizedText: ${recognizedText.text}\n');
      for (var e in recognizedText.blocks) {
        debugPrint('blocks: ${e.text} -> ');
      }
    }

    final parsedCard = await parseAlgorithm.parse(recognizedText);

    return parsedCard;
  }

  void dispose() {
    imgProcessor.debugCallback = null;
    unawaited(_recognizer.close());
  }
}
