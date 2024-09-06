import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ml_card_scanner/ml_card_scanner.dart';
import 'package:ml_card_scanner/src/model/typedefs.dart';
import 'package:ml_card_scanner/src/utils/camera_image_util.dart';
import 'package:ml_card_scanner/src/widget/camera_preview_wrapper.dart';

class CameraWidget extends StatefulWidget {
  final CameraController cameraController;
  final CameraDescription cameraDescription;
  final int scannerDelay;
  final CameraPreviewBuilder? cameraPreviewBuilder;
  final InputImageCallback onInputImage;
  final ScannerWidgetController scannerController;

  const CameraWidget({
    required this.cameraController,
    required this.cameraDescription,
    required this.onInputImage,
    required this.scannerDelay,
    required this.scannerController,
    this.cameraPreviewBuilder,
    super.key,
  });

  @override
  CameraViewState createState() => CameraViewState();
}

class CameraViewState extends State<CameraWidget> {
  int _lastFrameDecode = 0;

  Future<void> stopCameraStream() async {
    if (!widget.cameraController.value.isStreamingImages) {
      return;
    }
    return widget.cameraController.stopImageStream();
  }

  Future<void> startCameraStream() async {
    if (widget.cameraController.value.isStreamingImages) {
      return;
    }
    return widget.cameraController.startImageStream(_processCameraImage);
  }

  @override
  void initState() {
    super.initState();
    startCameraStream();
  }

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);

    if (widget.cameraPreviewBuilder != null) {
      return widget.cameraPreviewBuilder?.call(
            context,
            CameraPreviewWrapper(cameraController: widget.cameraController),
            widget.cameraController.value.previewSize,
          ) ??
          const SizedBox.shrink();
    }

    return Center(
      child: AspectRatio(
        aspectRatio: mediaSize.aspectRatio,
        child: CameraPreview(widget.cameraController),
      ),
    );
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (!widget.scannerController.scanningEnabled) return;

    if ((DateTime.now().millisecondsSinceEpoch - _lastFrameDecode) <
        widget.scannerDelay) {
      return;
    }
    _lastFrameDecode = DateTime.now().millisecondsSinceEpoch;

    try {
      final sensorOrientation = widget.cameraDescription.sensorOrientation;
      final rotation = CameraImageUtil.getImageRotation(
        sensorOrientation,
        widget.cameraController.value.deviceOrientation,
        widget.cameraDescription.lensDirection,
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

      widget.onInputImage(
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
}
