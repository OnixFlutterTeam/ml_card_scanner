import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraPreviewWrapper extends StatelessWidget {
  final CameraController _cameraController;

  const CameraPreviewWrapper({
    required CameraController cameraController,
    super.key,
  }) : _cameraController = cameraController;

  @override
  Widget build(BuildContext context) => CameraPreview(_cameraController);
}
