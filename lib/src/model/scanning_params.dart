import 'package:flutter/material.dart';

import 'card_info.dart';
import 'scanner_exception.dart';

class ScanningParams {
  final bool scanningEnabled;
  final bool cameraPreviewEnabled;
  final ValueChanged<CardInfo>? onCardScanned;
  final ValueChanged<ScannerException>? onError;

  ScanningParams({
    required this.scanningEnabled,
    required this.cameraPreviewEnabled,
    required this.onCardScanned,
    required this.onError,
  });

  factory ScanningParams.defaultParams() => ScanningParams(
        scanningEnabled: true,
        cameraPreviewEnabled: true,
        onCardScanned: null,
        onError: null,
      );

  ScanningParams copyWith({
    bool? scanningEnabled,
    bool? cameraPreviewEnabled,
    ValueChanged<CardInfo?>? onCardScanned,
    ValueChanged<ScannerException>? onError,
  }) =>
      ScanningParams(
        scanningEnabled: scanningEnabled ?? this.scanningEnabled,
        onCardScanned: onCardScanned ?? this.onCardScanned,
        cameraPreviewEnabled: cameraPreviewEnabled ?? this.cameraPreviewEnabled,
        onError: onError ?? this.onError,
      );
}
