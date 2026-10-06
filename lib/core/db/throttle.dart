import 'dart:async';

/// Passes the first event straight through, then at most one more per
/// [window] (the latest that arrived meanwhile, sent when the window ends).
///
/// Used so a screenful of data is re-read a few times a second while an
/// import writes hundreds of rows, instead of once per row — each re-read
/// hands thousands of rows to the UI isolate, which is what made a big scan
/// feel sluggish.
Stream<T> throttleLatest<T>(Stream<T> source, Duration window) {
  late StreamController<T> controller;
  StreamSubscription<T>? subscription;
  Timer? timer;
  T? pending;
  var hasPending = false;

  void flushOrRest() {
    timer = null;
    if (!hasPending) return;
    final value = pending as T;
    pending = null;
    hasPending = false;
    controller.add(value);
    timer = Timer(window, flushOrRest);
  }

  controller = StreamController<T>(
    onListen: () {
      subscription = source.listen(
        (event) {
          if (timer == null) {
            controller.add(event);
            timer = Timer(window, flushOrRest);
          } else {
            pending = event;
            hasPending = true;
          }
        },
        onError: controller.addError,
        onDone: () {
          timer?.cancel();
          if (hasPending) controller.add(pending as T);
          controller.close();
        },
      );
    },
    onCancel: () {
      timer?.cancel();
      return subscription?.cancel();
    },
  );
  return controller.stream;
}
