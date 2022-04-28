import 'package:flutter/material.dart';
import 'package:ml_card_scanner/src/model/card_orientation.dart';

class CameraOverlayWidget extends StatelessWidget {
  final CardOrientation cardOrientation;
  const CameraOverlayWidget({Key? key, required this.cardOrientation})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcOut),
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: Align(
              alignment: Alignment.bottomRight,
              child: Center(
                child: getContainer(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Container getContainer(context) {
    if (cardOrientation == CardOrientation.portrait) {
      return Container(
        height: (MediaQuery.of(context).size.width * 0.7) * 1.6,
        width: (MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
            color: Colors.black, borderRadius: BorderRadius.circular(25)),
      );
    }
    return Container(
        height: (MediaQuery.of(context).size.width * 0.7),
        width: (MediaQuery.of(context).size.width * 0.7) * 1.35,
        decoration: BoxDecoration(
            color: Colors.black, borderRadius: BorderRadius.circular(25)));
  }
}
