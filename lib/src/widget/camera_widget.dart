import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:ml_card_scanner/ml_card_scanner.dart';
import 'package:ml_card_scanner/src/model/typedefs.dart';
import 'package:ml_card_scanner/src/widget/camera_preview_wrapper.dart';

class CameraWidget extends StatefulWidget {
  final CameraController cameraController;
  final CameraDescription cameraDescription;
  final CameraPreviewBuilder? cameraPreviewBuilder;
  final ScannerWidgetController scannerController;

  const CameraWidget({
    required this.cameraController,
    required this.cameraDescription,
    required this.scannerController,
    this.cameraPreviewBuilder,
    super.key,
  });

  @override
  CameraViewState createState() => CameraViewState();
}

class CameraViewState extends State<CameraWidget> {

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


}
