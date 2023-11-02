import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class CameraWidget extends StatefulWidget {
  final CameraController cameraController;
  final CameraDescription cameraDescription;
  final int scannerDelay;

  const CameraWidget({
    required this.cameraController,
    required this.cameraDescription,
    required this.onImage,
    required this.scannerDelay,
    super.key,
  });

  final Function(InputImage inputImage) onImage;

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
    startCameraStream();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.of(context).size;
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

  Future _processCameraImage(CameraImage image) async {
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
      if (rotationCompensation == null) return null;
      if (widget.cameraDescription.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }

    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);

    if (image.planes.isEmpty) return null;
    final plane = image.planes.first;
    final inputImage = InputImage.fromBytes(
      bytes: image.planes.first.bytes,
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
