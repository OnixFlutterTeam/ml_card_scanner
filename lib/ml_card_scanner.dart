import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ml_card_scanner/src/screen/camera_screen.dart';

import 'src/model/card_info.dart';
import 'src/model/card_orientation.dart';
import 'src/model/routes.dart';

export 'src/model/card_info.dart';
export 'src/model/card_orientation.dart';
export 'src/model/routes.dart';

class MlCardScanner {
  static Future<CardInfo?> scanCard(
    BuildContext context, {
    CardOrientation cardOrientation = CardOrientation.portrait,
    double overlayBorderRadius = 25,
    Color overlayColorFilter = Colors.black54,
    String overlayText = "Scan the font side",
    TextStyle overlayTextStyle = const TextStyle(
      color: Colors.white,
      fontSize: 14,
    ),
    int scannerDelay = 400,
    Routes routes = Routes.materialPageRoute,
  }) async {
    if (routes == Routes.materialPageRoute) {
      return Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraScreen(
            cardOrientation: cardOrientation,
            overlayBorderRadius: overlayBorderRadius,
            overlayColorFilter: overlayColorFilter,
            overlayText: overlayText,
            overlayTextStyle: overlayTextStyle,
            scannerDelay: scannerDelay,
          ),
        ),
      );
    } else {
      return Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => CameraScreen(
            cardOrientation: cardOrientation,
            overlayBorderRadius: overlayBorderRadius,
            overlayColorFilter: overlayColorFilter,
            overlayText: overlayText,
            overlayTextStyle: overlayTextStyle,
            scannerDelay: scannerDelay,
          ),
        ),
      );
    }
  }
}
