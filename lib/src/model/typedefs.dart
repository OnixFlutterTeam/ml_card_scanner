import 'package:flutter/widgets.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ml_card_scanner/src/widget/camera_preview_wrapper.dart';

typedef CameraPreviewBuilder = Widget Function(
  BuildContext context,
  CameraPreviewWrapper preview,
  Size? previewSize,
);

typedef OverlayTextBuilder = Widget Function(BuildContext context);

typedef OverlayBuilder = Widget Function(BuildContext context);

typedef InputImageCallback = void Function(InputImage inputImage);
