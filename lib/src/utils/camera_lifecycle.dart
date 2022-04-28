import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraLifecycle extends WidgetsBindingObserver {
  final CameraController cameraController;

  CameraLifecycle({required this.cameraController});

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        await cameraController.resumePreview();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        await cameraController.pausePreview();
        break;
    }
  }
}
