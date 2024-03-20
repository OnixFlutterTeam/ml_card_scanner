class ScannerException implements Exception {
  final String _message;

  String get message => _message;

  const ScannerException(this._message);
}

class ScannerNoCamerasAvailableException extends ScannerException {
  const ScannerNoCamerasAvailableException() : super('No cameras available.');
}

class ScannerNoBackCameraAvailableException extends ScannerException {
  const ScannerNoBackCameraAvailableException()
      : super('No back camera available.');
}

class ScannerPermissionIsNotGrantedException extends ScannerException {
  const ScannerPermissionIsNotGrantedException()
      : super('Camera permission not granted.');
}
