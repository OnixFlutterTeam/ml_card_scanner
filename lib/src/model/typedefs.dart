import 'package:flutter/widgets.dart';
import 'package:ml_card_scanner/ml_card_scanner.dart';
import 'package:ml_card_scanner/src/widget/camera_preview_wrapper.dart';

typedef CameraPreviewBuilder = Widget Function(
  BuildContext context,
  CameraPreviewWrapper preview,
  Size? previewSize,
);

typedef OverlayTextBuilder = Widget Function(BuildContext context);

typedef OverlayBuilder = Widget Function(BuildContext context);

typedef CardInfoCallback = void Function(CardInfo? card);

typedef ScannerWorkerResult = Map<String, dynamic>;
