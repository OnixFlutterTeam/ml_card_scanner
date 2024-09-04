import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ml_card_scanner/src/model/typedefs.dart';
import 'package:ml_card_scanner/src/widget/camera_preview_wrapper.dart';

class CameraWidget extends StatefulWidget {
  final CameraController cameraController;
  final CameraDescription cameraDescription;
  final int scannerDelay;
  final CameraPreviewBuilder? cameraPreviewBuilder;
  final InputImageCallback onImage;

  const CameraWidget({
    required this.cameraController,
    required this.cameraDescription,
    required this.onImage,
    required this.scannerDelay,
    this.cameraPreviewBuilder,
    super.key,
  });

  @override
  CameraViewState createState() => CameraViewState();
}

class CameraViewState extends State<CameraWidget> {
  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };
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

    return Transform.scale(
      scale: 1 / mediaSize.aspectRatio,
      child: Center(
        child: AspectRatio(
          aspectRatio: mediaSize.aspectRatio,
          child: CameraPreview(widget.cameraController),
        ),
      ),
    );
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if ((DateTime.now().millisecondsSinceEpoch - _lastFrameDecode) <
        widget.scannerDelay) {
      return;
    }
    _lastFrameDecode = DateTime.now().millisecondsSinceEpoch;

    final sensorOrientation = widget.cameraDescription.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[widget.cameraController.value.deviceOrientation];
      if (rotationCompensation == null) return;
      if (widget.cameraDescription.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }

    if (rotation == null) return;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);

    if (image.planes.isEmpty) return;
    final plane = image.planes.first;
    final inputImage = InputImage.fromBytes(
      bytes: Uint8List.fromList(
        image.planes.fold(
            <int>[],
            (List<int> previousValue, element) =>
                previousValue..addAll(element.bytes)),
      ),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format ?? InputImageFormat.yuv420,
        bytesPerRow: plane.bytesPerRow,
      ),
    );

    widget.onImage(inputImage);
  }
}
