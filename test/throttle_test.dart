import 'package:fake_async/fake_async.dart';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/db/throttle.dart';

void main() {
  test('first event goes straight through, a burst collapses to the latest', () {
    fakeAsync((async) {
      final source = StreamController<int>();
      final seen = <int>[];
      throttleLatest(source.stream, const Duration(milliseconds: 250)).listen(
        seen.add,
      );

      source.add(1);
      async.flushMicrotasks();
      expect(seen, [1]); // no waiting for the first change

      for (var i = 2; i <= 100; i++) {
        source.add(i);
      }
      async.flushMicrotasks();
      expect(seen, [1]); // the burst is held back…

      async.elapse(const Duration(milliseconds: 250));
      expect(seen, [1, 100]); // …and arrives once, as its last value

      async.elapse(const Duration(seconds: 1));
      expect(seen, [1, 100]); // nothing invented while quiet

      source.add(101);
      async.flushMicrotasks();
      expect(seen, [1, 100, 101]); // quiet again: immediate
    });
  });

  test('a change that arrives just before the stream ends is not lost', () async {
    final source = StreamController<int>();
    final seen = <int>[];
    var done = false;
    throttleLatest(
      source.stream,
      const Duration(milliseconds: 40),
    ).listen(seen.add, onDone: () => done = true);

    source
      ..add(1)
      ..add(2);
    await source.close();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(seen, [1, 2]);
    expect(done, isTrue);
  });

  test('cancelling stops the timer and the source', () {
    fakeAsync((async) {
      final source = StreamController<int>();
      final sub = throttleLatest(
        source.stream,
        const Duration(milliseconds: 250),
      ).listen((_) {});
      source.add(1);
      async.flushMicrotasks();
      sub.cancel();
      async.flushMicrotasks();
      expect(source.hasListener, isFalse);
      expect(async.pendingTimers.length, 0);
    });
  });
}
