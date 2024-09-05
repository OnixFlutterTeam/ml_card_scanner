import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ml_card_scanner/src/model/typedefs.dart';
import 'package:ml_card_scanner/src/parser/card_parser.dart';

typedef _WorkerMessageType = (
  int,
  List<Uint8List>,
  int,
  int,
  InputImageRotation,
  InputImageFormat?,
  int,
);

class ScannerWorker {
  final SendPort _commands;
  final ReceivePort _responses;
  final Map<int, Completer<ScannerWorkerResult?>> _activeRequests = {};
  int _idCounter = 0;
  bool _closed = false;

  Future<ScannerWorkerResult?> processImage(
    List<Uint8List> bytes,
    int width,
    int height,
    InputImageRotation rotation,
    InputImageFormat? format,
    int bytesPerRow,
  ) async {
    if (_closed) throw StateError('Closed');
    final completer = Completer<ScannerWorkerResult?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    _commands.send(
      (id, bytes, width, height, rotation, format, bytesPerRow),
    );
    return await completer.future;
  }

  static Future<ScannerWorker> spawn({
    required int cardScanTries,
  }) async {
    final token = RootIsolateToken.instance;

    if (token == null) {
      throw Exception('RootIsolateToken is null');
    }

    final initPort = RawReceivePort();
    final connection = Completer<(ReceivePort, SendPort)>.sync();
    initPort.handler = (initialMessage) {
      final commandPort = initialMessage as SendPort;
      connection
          .complete((ReceivePort.fromRawReceivePort(initPort), commandPort));
    };

    try {
      await Isolate.spawn(
        _startRemoteIsolate,
        _IsolateData(
          token: token,
          sendPort: initPort.sendPort,
          cardScanTries: cardScanTries,
        ),
      );
    } on Object {
      initPort.close();
      rethrow;
    }

    final (ReceivePort receivePort, SendPort sendPort) =
        await connection.future;

    return ScannerWorker._(
      receivePort,
      sendPort,
    );
  }

  ScannerWorker._(this._responses, this._commands) {
    _responses.listen(_handleResponsesFromIsolate);
  }

  void _handleResponsesFromIsolate(dynamic message) {
    final (int id, Object? response) = message as (int, Object?);
    final completer = _activeRequests.remove(id)!;

    if (response is RemoteError) {
      completer.completeError(message);
    } else {
      completer.complete(response as ScannerWorkerResult?);
    }

    if (_closed && _activeRequests.isEmpty) _responses.close();
  }

  static void _handleCommandsToIsolate(
    ReceivePort receivePort,
    SendPort sendPort,
    int cardScanTries,
  ) {
    final parser = CardParser(cardScanTries: cardScanTries);
    receivePort.listen((message) async {
      if (message == 'shutdown') {
        receivePort.close();
        return;
      }

      final (
        int id,
        List<Uint8List> bytes,
        int width,
        int height,
        InputImageRotation rotation,
        InputImageFormat? format,
        int bytesPerRow,
      ) = message as _WorkerMessageType;

      try {
        final inputImage = InputImage.fromBytes(
          bytes: Uint8List.fromList(
            bytes.fold(
                <int>[],
                (List<int> previousValue, element) =>
                    previousValue..addAll(element)),
          ),
          metadata: InputImageMetadata(
            size: Size(width.toDouble(), height.toDouble()),
            rotation: rotation,
            format: format ?? InputImageFormat.yuv420,
            bytesPerRow: bytesPerRow,
          ),
        );

        final result = await parser.detectCardContent(inputImage);
        sendPort.send((id, result?.toJson()));
      } catch (e) {
        sendPort.send((id, RemoteError(e.toString(), '')));
      }
    });
  }

  static void _startRemoteIsolate(_IsolateData data) {
    BackgroundIsolateBinaryMessenger.ensureInitialized(data.token);
    final receivePort = ReceivePort();
    data.sendPort.send(receivePort.sendPort);
    _handleCommandsToIsolate(receivePort, data.sendPort, data.cardScanTries);
  }

  void close() {
    if (!_closed) {
      _closed = true;
      _commands.send('shutdown');
      if (_activeRequests.isEmpty) _responses.close();
      if (kDebugMode) {
        print('--- port closed --- ');
      }
    }
  }
}

class _IsolateData {
  final RootIsolateToken token;
  final SendPort sendPort;
  final int cardScanTries;

  _IsolateData({
    required this.token,
    required this.sendPort,
    required this.cardScanTries,
  });
}
