import 'package:flutter/material.dart';

class TextOverlayWidget extends StatelessWidget {
  const TextOverlayWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Scan card front side',
      style: TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
      textAlign: TextAlign.center,
    );
  }
}
