import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class CameraWidget extends StatefulWidget {
  final CameraController cameraController;
  final CameraDescription cameraDescription;
  final int scannerDelay;

  const CameraWidget(
      {Key? key,
      required this.cameraController,
      required this.cameraDescription,
      required this.onImage,
      required this.scannerDelay})
      : super(key: key);

  final Function(InputImage inputImage) onImage;

  @override
  CameraViewState createState() => CameraViewState();
}

class CameraViewState extends State<CameraWidget> {
  int _lastFrameDecode = 0;

  Future<void> stopCameraStream() async =>
      widget.cameraController.stopImageStream();

  Future<void> startCameraStream() async =>
      widget.cameraController.startImageStream(_processCameraImage);

  @override
  void initState() {
    startCameraStream();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.of(context).size;
    final scale =
        1 / (widget.cameraController.value.aspectRatio * mediaSize.aspectRatio);
    return ClipRect(
      clipper: _MediaSizeClipper(mediaSize),
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.topCenter,
        child: CameraPreview(widget.cameraController),
      ),
    );
  }

  Future _processCameraImage(CameraImage image) async {
    if ((DateTime.now().millisecondsSinceEpoch - _lastFrameDecode) <
        widget.scannerDelay) {
      return;
    }
    _lastFrameDecode = DateTime.now().millisecondsSinceEpoch;
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize =
        Size(image.width.toDouble(), image.height.toDouble());

    final imageRotation = InputImageRotationMethods.fromRawValue(
            widget.cameraDescription.sensorOrientation) ??
        InputImageRotation.Rotation_0deg;

    final inputImageFormat =
        InputImageFormatMethods.fromRawValue(image.format.raw) ??
            InputImageFormat.NV21;

    final planeData = image.planes.map(
      (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();

    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: imageRotation,
      inputImageFormat: inputImageFormat,
      planeData: planeData,
    );

    final inputImage =
        InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

    widget.onImage(inputImage);
  }
}

class _MediaSizeClipper extends CustomClipper<Rect> {
  final Size mediaSize;

  const _MediaSizeClipper(this.mediaSize);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, mediaSize.width, mediaSize.height);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return true;
  }
}
