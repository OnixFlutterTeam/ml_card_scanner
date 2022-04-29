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
  final double overlayBorderRadius;
  final Color overlayColorFilter;
  final String overlayText;
  final TextStyle overlayTextStyle;
  final int scannerDelay;

  const CameraScreen({
    Key? key,
    required this.cardOrientation,
    required this.overlayBorderRadius,
    required this.overlayColorFilter,
    required this.overlayText,
    required this.scannerDelay,
    required this.overlayTextStyle,
  }) : super(key: key);

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
    if (mounted) {
      WidgetsBinding.instance?.removeObserver(_cameraLifecycle);
      _controller.dispose();
    }
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
                  scannerDelay: widget.scannerDelay,
                )
              : const Center(
                  child: CircularProgressIndicator(),
                ),
          CameraOverlayWidget(
            cardOrientation: widget.cardOrientation,
            overlayBorderRadius: widget.overlayBorderRadius,
            overlayColorFilter: widget.overlayColorFilter,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: (MediaQuery.of(context).size.height / 5),
            child: Text(
              widget.overlayText,
              style: widget.overlayTextStyle,
              textAlign: TextAlign.center,
            ),
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
      Navigator.pop(context, resultCard);
    }
  }
}
