import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ml_card_scanner/ml_card_scanner.dart';
import 'package:ml_card_scanner/src/model/scanning_params.dart';

class ScannerWidgetController extends ValueNotifier<ScanningParams> {
  ScannerWidgetController() : super(ScanningParams.defaultParams());

  bool get scanningEnabled => value.scanningEnabled;

  bool get cameraPreviewEnabled => value.cameraPreviewEnabled;

  ValueChanged<CardInfo>? get onCardScanned => value.onCardScanned;

  ValueChanged<ScannerException>? get onError => value.onError;

  void enableScanning() {
    if (scanningEnabled) {
      return;
    }
    value = value.copyWith(scanningEnabled: true);
    notifyListeners();
  }

  void disableScanning() {
    if (!scanningEnabled) {
      return;
    }
    value = value.copyWith(scanningEnabled: false);
    notifyListeners();
  }

  void enableCameraPreview() {
    if (cameraPreviewEnabled) {
      return;
    }
    value = value.copyWith(cameraPreviewEnabled: true);
    notifyListeners();
  }

  void disableCameraPreview() {
    if (!cameraPreviewEnabled) {
      return;
    }
    value = value.copyWith(cameraPreviewEnabled: false);
    notifyListeners();
  }

  void setCardListener(ValueChanged<CardInfo?> onCardScanned) {
    value = value.copyWith(onCardScanned: onCardScanned);
    notifyListeners();
  }

  void removeCardListeners(ValueChanged<CardInfo?>? onCardScanned) {
    if (onCardScanned != null) {
      return;
    }
    value = value.copyWith(onCardScanned: null);
    notifyListeners();
  }

  void setErrorListener(ValueChanged<ScannerException>? onError) {
    value = value.copyWith(onError: onError);
    notifyListeners();
  }

  void removeErrorListener(ValueChanged<ScannerException>? onError) {
    if (onError != null) {
      return;
    }
    value = value.copyWith(onError: null);
    notifyListeners();
  }

}
