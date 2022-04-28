import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:ml_card_scanner/src/model/card_orientation.dart';
import 'package:ml_card_scanner/src/utils/camera_lifecycle.dart';
import 'package:ml_card_scanner/src/utils/card_parser_util.dart';
import 'package:ml_card_scanner/src/utils/logger.dart';
import 'package:ml_card_scanner/src/widgets/camera_overlay_widget.dart';
import 'package:ml_card_scanner/src/widgets/camera_widget.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraScreen extends StatefulWidget {
  final CardOrientation cardOrientation;

  const CameraScreen({Key? key, required this.cardOrientation})
      : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  final CardParserUtil _cardParser = CardParserUtil();

  bool _isCameraInitialized = false;
  late CameraDescription _camera;
  late CameraController _controller;
  late CameraLifecycle _cameraLifecycle;

  @override
  void initState() {
    _initialize();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    WidgetsBinding.instance?.removeObserver(_cameraLifecycle);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return Scaffold(
      body: Stack(
        children: <Widget>[
          _isCameraInitialized
              ? CameraWidget(
                  cameraController: _controller,
                  cameraDescription: _camera,
                  onImage: _detect,
                )
              : const Center(
                  child: CircularProgressIndicator(),
                ),
          CameraOverlayWidget(
            cardOrientation: widget.cardOrientation,
          ),
        ],
      ),
    );
  }

  void _initialize() async {
    var initializeResult = await _initializeCamera();
    if (initializeResult) {
      _initLifecycle();
      setState(() {
        _isCameraInitialized = initializeResult;
      });
    } else {
      //TODO show error?
    }
  }

  Future<bool> _initializeCamera() async {
    var status = await Permission.camera.request();
    if (!status.isGranted) {
      return false;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      return false;
    }
    if ((cameras.where((cam) => cam.lensDirection == CameraLensDirection.back))
        .isEmpty) {
      return false;
    }
    _camera = cameras
        .firstWhere((cam) => cam.lensDirection == CameraLensDirection.back);

    _controller = CameraController(_camera, ResolutionPreset.veryHigh,
        enableAudio: false);
    await _controller.initialize();
    return true;
  }

  void _initLifecycle() {
    _cameraLifecycle = CameraLifecycle(cameraController: _controller);
    WidgetsBinding.instance?.addObserver(_cameraLifecycle);
  }

  void _detect(InputImage image) async {
    var resultCard = await _cardParser.detectCardContent(image);
    Logger.log('Detect Card Details', resultCard.toString());
    if (resultCard?.isValid() ?? false) {
      Navigator.of(context).pop(resultCard);
    }
  }
}
