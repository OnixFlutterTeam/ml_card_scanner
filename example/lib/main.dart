import 'package:flutter/material.dart';
import 'package:ml_card_scanner/ml_card_scanner.dart';

void main() {
  runApp(const MaterialApp(home: MainScreen()));
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Scanner Example'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            _parseCard(context);
          },
          child: const Text('Parse Card'),
        ),
      ),
    );
  }

  void _parseCard(BuildContext context) async {
    CardInfo? cardInfo = await MlCardScanner.scanCard(context,
        cardOrientation: CardOrientation.landscape,
        overlayBorderRadius: 50,
        overlayColorFilter: Colors.cyan.withOpacity(0.4),
        overlayText: "Scanner card",
        scannerDelay: 600,
        routes: Routes.cupertinoPageRoute);
    print('Card Parsed: ${cardInfo.toString()}');
  }
}
