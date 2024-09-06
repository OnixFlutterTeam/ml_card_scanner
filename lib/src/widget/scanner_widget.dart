import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ml_card_scanner/ml_card_scanner.dart';
import 'package:ml_card_scanner/src/model/typedefs.dart';
import 'package:ml_card_scanner/src/parser/default_parser_algorithm.dart';
import 'package:ml_card_scanner/src/utils/camera_image_util.dart';
import 'package:ml_card_scanner/src/utils/logger.dart';
import 'package:ml_card_scanner/src/utils/scanner_worker.dart';
import 'package:ml_card_scanner/src/widget/camera_overlay_widget.dart';
import 'package:ml_card_scanner/src/widget/camera_widget.dart';
import 'package:ml_card_scanner/src/widget/text_overlay_widget.dart';
import 'package:permission_handler/permission_handler.dart';

class ScannerWidget extends StatefulWidget {
  final CardOrientation overlayOrientation;
  final OverlayBuilder? overlayBuilder;
  final int scannerDelay;
  final bool oneShotScanning;
  final CameraResolution cameraResolution;
  final ScannerWidgetController? controller;
  final CameraPreviewBuilder? cameraPreviewBuilder;
  final OverlayTextBuilder? overlayTextBuilder;
  final int cardScanTries;

  const ScannerWidget({
    this.overlayBuilder,
    this.controller,
    this.scannerDelay = 400,
    this.cardScanTries = 5,
    this.oneShotScanning = true,
    this.overlayOrientation = CardOrientation.portrait,
    this.cameraResolution = CameraResolution.high,
    this.cameraPreviewBuilder,
    this.overlayTextBuilder,
    super.key,
  });

  @override
  State<ScannerWidget> createState() => _ScannerWidgetState();
}

class _ScannerWidgetState extends State<ScannerWidget>
    with WidgetsBindingObserver {
  final ValueNotifier<CameraController?> _isInitialized = ValueNotifier(null);
  late CameraDescription _camera;
  late ScannerWidgetController _scannerController;
  CameraController? _cameraController;
  ScannerWorker? _worker;
  bool _isBusy = false;
  bool _canProcess = true;
  int _lastFrameDecode = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerController = widget.controller ?? ScannerWidgetController();
    _scannerController.addListener(_scanParamsListener);
    _initialize();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        ValueListenableBuilder<CameraController?>(
          valueListenable: _isInitialized,
          builder: (context, cc, _) {
            print('cc');
            if (cc == null) return const SizedBox.shrink();
            _cameraController = cc;
            return CameraWidget(
              cameraController: cc,
              cameraPreviewBuilder: widget.cameraPreviewBuilder,
            );
          },
        ),
        widget.overlayBuilder?.call(context) ??
            CameraOverlayWidget(
              cardOrientation: widget.overlayOrientation,
              overlayBorderRadius: 25,
              overlayColorFilter: Colors.black54,
            ),
        widget.overlayTextBuilder?.call(context) ??
            Positioned(
              left: 0,
              right: 0,
              bottom: (MediaQuery.sizeOf(context).height / 5),
              child: const TextOverlayWidget(),
            ),
      ],
    );
  }

  @override
  void dispose() {
    _canProcess = false;
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.removeListener(_scanParamsListener);
    _cameraController?.dispose();
    _worker?.close();
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    final isCameraInitialized = _cameraController?.value.isInitialized ?? false;

    if (state == AppLifecycleState.inactive) {
      final isStreaming = _cameraController?.value.isStreamingImages ?? false;
      _isInitialized.value = null;
      if (isStreaming) {
        _cameraController?.stopImageStream();
      }
      _cameraController?.dispose();
      _cameraController = null;
    } else if (state == AppLifecycleState.resumed) {
      if (isCameraInitialized) {
        return;
      }
      _initializeCamera();
    }
  }

  void _initialize() async {
    try {
      var cameraController = await _initializeCamera();
      if (cameraController != null) {
        _worker = await ScannerWorker.spawn(
          algorithm: DefaultParserAlgorithm(widget.cardScanTries),
        );
      }
    } catch (e) {
      _handleError(ScannerException(e.toString()));
    }
  }

  Future<CameraController?> _initializeCamera() async {
    var status = await Permission.camera.request();
    if (!status.isGranted) {
      _handleError(const ScannerPermissionIsNotGrantedException());
      return null;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      _handleError(const ScannerNoCamerasAvailableException());
      return null;
    }
    if ((cameras.where((cam) => cam.lensDirection == CameraLensDirection.back))
        .isEmpty) {
      _handleError(const ScannerNoBackCameraAvailableException());
      return null;
    }
    _camera = cameras
        .firstWhere((cam) => cam.lensDirection == CameraLensDirection.back);
    final cameraController = CameraController(
      _camera,
      _getResolutionPreset(),
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    await cameraController.initialize();
    final isStreaming = _cameraController?.value.isStreamingImages ?? false;
    if (_scannerController.scanningEnabled && !isStreaming) {
      cameraController.startImageStream(_onFrame);
    }
    _isInitialized.value = cameraController;
    return cameraController;
  }

  ResolutionPreset _getResolutionPreset() {
    switch (widget.cameraResolution) {
      case CameraResolution.max:
        return ResolutionPreset.max;
      case CameraResolution.high:
        return ResolutionPreset.veryHigh;
      case CameraResolution.ultra:
        return ResolutionPreset.ultraHigh;
    }
  }

  Future<void> _onFrame(CameraImage image) async {
    final cc = _cameraController;
    if (cc == null) return;
    if (!cc.value.isInitialized) return;
    if (!_scannerController.scanningEnabled) return;

    if ((DateTime.now().millisecondsSinceEpoch - _lastFrameDecode) <
        widget.scannerDelay) {
      return;
    }
    _lastFrameDecode = DateTime.now().millisecondsSinceEpoch;

    try {
      final sensorOrientation = _camera.sensorOrientation;
      final rotation = CameraImageUtil.getImageRotation(
        sensorOrientation,
        cc.value.deviceOrientation,
        _camera.lensDirection,
      );

      if (rotation == null) {
        return;
      }
      final format = InputImageFormatValue.fromRawValue(
        image.format.raw,
      );

      if (image.planes.isEmpty) {
        return;
      }
      final plane = image.planes.first;
      final bytes = image.planes.map((e) => e.bytes).toList();

      _handleInputImage(
        bytes,
        InputImageMetadata(
          size: Size(
            image.width.toDouble(),
            image.height.toDouble(),
          ),
          rotation: rotation,
          format: format ?? InputImageFormat.yuv420,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } catch (_) {}
  }

  void _handleInputImage(
    List<Uint8List> imageBytes,
    InputImageMetadata metadata,
  ) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;

    final cardJson = await _worker?.processImage(
      imageBytes,
      metadata.size.width.toInt(),
      metadata.size.height.toInt(),
      metadata.rotation,
      metadata.format,
      metadata.bytesPerRow,
    );
    final cardInfo = (cardJson != null) ? CardInfo.fromJson(cardJson) : null;
    if (cardInfo == null) {
      _isBusy = false;
      return;
    }
    Logger.log('Detect Card Details', cardInfo.toString());
    if (widget.oneShotScanning) {
      _scannerController.disableScanning();
    }
    _handleData(cardInfo);
    _isBusy = false;
  }

  void _scanParamsListener() {
    final isStreaming = _cameraController?.value.isStreamingImages ?? false;
    if (_scannerController.scanningEnabled) {
      if (!isStreaming) {
        _cameraController?.startImageStream(_onFrame);
      }
    } else {
      if (isStreaming) {
        _cameraController?.stopImageStream();
      }
    }
    if (_scannerController.cameraPreviewEnabled) {
      _cameraController?.resumePreview();
    } else {
      _cameraController?.pausePreview();
    }
  }

  void _handleData(CardInfo cardInfo) {
    final cardScannedCallback = _scannerController.onCardScanned;
    cardScannedCallback?.call(cardInfo);
  }

  void _handleError(ScannerException exception) {
    final errorCallback = _scannerController.onError;
    errorCallback?.call(exception);
  }
}
