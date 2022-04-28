import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ml_card_scanner/src/screen/camera_screen.dart';

import 'src/model/card_info.dart';
import 'src/model/card_orientation.dart';

class MlCardScanner {
  Future<CardInfo?> scanCard(BuildContext context,
      {CardOrientation cardorientation = CardOrientation.portrait}) async {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          cardOrientation: cardorientation,
        ),
      ),
    );
  }
}
