import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraPreviewWrapper extends StatelessWidget {
  const CameraPreviewWrapper({
    required CameraController cameraController,
    super.key,
  }) : _cameraController = cameraController;

  final CameraController _cameraController;

  @override
  Widget build(BuildContext context) => CameraPreview(_cameraController);
}
