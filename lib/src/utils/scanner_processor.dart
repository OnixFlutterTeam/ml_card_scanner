import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ml_card_scanner/src/model/card_info.dart';
import 'package:ml_card_scanner/src/parser/parser_algorithm.dart';
import 'package:ml_card_scanner/src/utils/image_processor.dart';
import 'package:ml_card_scanner/src/utils/stream_debouncer.dart';

class ScannerProcessor {
  final bool _useFilters;
  final bool _debugMode;
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  late final StreamController<Uint8List>? _debugImageStreamController;

  ScannerProcessor({
    bool useFilters = false,
    bool debugMode = false,
  })  : _useFilters = useFilters,
        _debugMode = debugMode {
    if (debugMode) {
      _debugImageStreamController = StreamController<Uint8List>.broadcast();
    }
  }

  Stream<Uint8List>? get imageStream =>
      _debugImageStreamController?.stream.transform(
        debounceTransformer(
          const Duration(milliseconds: 5000),
        ),
      );

  Future<CardInfo?> computeImage(
    ParserAlgorithm parseAlgorithm,
    CameraImage image,
    InputImageRotation rotation,
  ) async {
    late InputImage inputImage;
    if (!_useFilters) {
      final format = InputImageFormatValue.fromRawValue(
        image.format.raw,
      );
      final plane = image.planes.first;
      final bytes = image.planes.map((e) => e.bytes).toList();
      inputImage = await compute<List<Uint8List>, InputImage>(
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
    } else {
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

      ReceivePort? receivePort;
      if (_debugMode) {
        receivePort = ReceivePort();
        receivePort.listen(
          (message) {
            if (message is Uint8List) {
              if (_debugImageStreamController != null &&
                  !_debugImageStreamController!.isClosed) {
                _debugImageStreamController?.add(message);
              }
            }
          },
        );
      }
      inputImage = await createInputImageInIsolate(
        rawBytes: bytes,
        width: width,
        height: height,
        rawRotation: rawRotation,
        rawFormat: rawFormat,
        bytesPerRow: bytesPerRow,
        debugSendPort: receivePort?.sendPort,
      );
      receivePort?.close();
    }

    final recognizedText = await _recognizer.processImage(inputImage);

    /*if (kDebugMode) {
      debugPrint('\nrecognizedText: ${recognizedText.text}\n');
      for (var e in recognizedText.blocks) {
        debugPrint('block: -> ${e.text} ');
      }
      debugPrint('\n');
    }*/
    final parsedCard = await parseAlgorithm.parse(recognizedText);
    return parsedCard;
  }

  void dispose() {
    if (_debugImageStreamController != null &&
        !_debugImageStreamController!.isClosed) {
      _debugImageStreamController?.close();
    }
    unawaited(_recognizer.close());
  }
}
