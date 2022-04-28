import 'package:flutter/foundation.dart';

class Logger {
  static void log(String tag, String message) {
    if (kDebugMode) {
      print('$tag: $message');
    }
  }
}
