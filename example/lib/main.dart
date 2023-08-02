import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ml_card_scanner/ml_card_scanner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
/*  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );*/
  runApp(const MaterialApp(home: MainScreen()));
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  CardInfo? _cardInfo;
  final ScannerWidgetController _controller = ScannerWidgetController();

  @override
  void initState() {
    _controller
      ..setCardListener((value) {
        setState(() {
          _cardInfo = value;
        });
      })
      ..setErrorListener((exception) {
        if (kDebugMode) {
          print('Error: ${exception.message}');
        }
      });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Scanner Example'),
      ),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: ScannerWidget(
                controller: _controller,
                overlayOrientation: CardOrientation.landscape,
              ),
            ),
            Container(
                width: MediaQuery.of(context).size.width,
                color: Colors.white,
                child: Column(
                  children: [
                    const SizedBox(
                      height: 20,
                    ),
                    Text(_cardInfo?.toString() ?? 'No Card Details'),
                    const SizedBox(
                      height: 20,
                    ),
                  ],
                )),
          ],
        ),
      ),
    );
  }
}
