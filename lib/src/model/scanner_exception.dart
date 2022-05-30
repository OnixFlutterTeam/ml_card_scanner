class ScannerException implements Exception {
  final String _message;

  String get message => _message;

  ScannerException(this._message);
}
