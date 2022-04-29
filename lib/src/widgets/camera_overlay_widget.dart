import 'package:flutter/material.dart';
import 'package:ml_card_scanner/src/model/card_orientation.dart';

class CameraOverlayWidget extends StatelessWidget {
  final CardOrientation cardOrientation;
  final double overlayBorderRadius;
  final Color overlayColorFilter;
  const CameraOverlayWidget(
      {Key? key,
      required this.cardOrientation,
      required this.overlayBorderRadius,
      required this.overlayColorFilter})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(overlayColorFilter, BlendMode.srcOut),
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: Align(
              alignment: Alignment.bottomRight,
              child: Center(
                child: _getContainer(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getContainer(context) {
    if (cardOrientation == CardOrientation.portrait) {
      return Container(
        height: (MediaQuery.of(context).size.width * 0.75) * 1.6,
        width: (MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(overlayBorderRadius)),
      );
    }
    return Container(
        height: (MediaQuery.of(context).size.width * 0.95) / 1.6,
        width: (MediaQuery.of(context).size.width * 0.95),
        decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(overlayBorderRadius)));
  }
}
