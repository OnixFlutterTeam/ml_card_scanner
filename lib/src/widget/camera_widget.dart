import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:ml_card_scanner/src/model/typedefs.dart';
import 'package:ml_card_scanner/src/widget/camera_preview_wrapper.dart';

class CameraWidget extends StatelessWidget {
  final CameraController cameraController;
  final CameraPreviewBuilder? cameraPreviewBuilder;

  const CameraWidget({
    required this.cameraController,
    this.cameraPreviewBuilder,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    if (cameraPreviewBuilder != null) {
      return cameraPreviewBuilder?.call(
            context,
            CameraPreviewWrapper(cameraController: cameraController),
            cameraController.value.previewSize,
          ) ??
          const SizedBox.shrink();
    }

    return Center(
      child: SizedBox(
        width: mediaSize.width,
        child: AspectRatio(
          aspectRatio: mediaSize.aspectRatio,
          child: CameraPreview(cameraController),
        ),
      ),
    );
  }
}
