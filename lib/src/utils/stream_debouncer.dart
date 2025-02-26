import 'dart:async';

StreamTransformer<T, T> debounceTransformer<T>(Duration duration) {
  return StreamTransformer<T, T>.fromBind((stream) {
    StreamController<T>? controller;
    Timer? timer;

    controller = StreamController<T>(
      onCancel: () {
        timer?.cancel();
        controller?.close(); // Ensure proper cleanup
      },
    );

    stream.listen((data) {
      if (timer == null || !timer!.isActive) {
        if (!controller!.isClosed) {
          controller.add(data);
        }
        timer = Timer(duration, () {});
      }
    }, onDone: () {
      controller?.close();
    }, onError: (error, stackTrace) {
      controller?.addError(error, stackTrace);
    });

    return controller.stream;
  });
}
