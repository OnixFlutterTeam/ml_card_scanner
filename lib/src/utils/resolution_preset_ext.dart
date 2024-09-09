import 'package:camera/camera.dart';
import 'package:ml_card_scanner/ml_card_scanner.dart';

extension ResolutionPresetExt on CameraResolution {
  ResolutionPreset convertToResolutionPreset() {
    return switch (this) {
      CameraResolution.high => ResolutionPreset.veryHigh,
      CameraResolution.ultra => ResolutionPreset.ultraHigh,
      CameraResolution.max => ResolutionPreset.max,
    };
  }
}
