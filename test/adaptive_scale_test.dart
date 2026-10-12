import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/responsive/adaptive_scale.dart';
import 'package:local_ledger/shared/widgets/glass_background.dart';
import 'package:local_ledger/shared/widgets/pin_pad.dart';

void main() {
  group('uiScaleFor', () {
    test('phones are left alone, in either orientation', () {
      expect(uiScaleFor(const Size(390, 844)), 1.0);
      expect(uiScaleFor(const Size(844, 390)), 1.0);
      expect(uiScaleFor(const Size(430, 932)), 1.0);
      expect(uiScaleFor(const Size(932, 430)), 1.0);
    });

    test('tablets grow with their size, more on a bigger screen', () {
      final mini = uiScaleFor(const Size(744, 1133));
      final eleven = uiScaleFor(const Size(834, 1194));
      final thirteen = uiScaleFor(const Size(1032, 1376));
      expect(mini, inInclusiveRange(1.1, 1.25));
      expect(eleven, inInclusiveRange(1.25, 1.35));
      expect(thirteen, 1.5);
      expect(mini, lessThan(eleven));
      expect(eleven, lessThan(thirteen));
    });

    test('turning the tablet does not change the scale', () {
      expect(
        uiScaleFor(const Size(1133, 744)),
        uiScaleFor(const Size(744, 1133)),
      );
    });
  });

  Future<void> show(WidgetTester tester, Size window, Widget child) async {
    tester.view.physicalSize = window;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, c) => AdaptiveScale(child: c!),
        home: child,
      ),
    );
  }

  testWidgets('on a phone nothing is scaled', (tester) async {
    double? seen;
    await show(
      tester,
      const Size(390, 844),
      Builder(
        builder: (context) {
          seen = MediaQuery.sizeOf(context).width;
          return const SizedBox.expand(key: Key('page'));
        },
      ),
    );
    expect(seen, 390);
    expect(tester.getSize(find.byKey(const Key('page'))).width, 390);
  });

  testWidgets('on a tablet the page fills the screen, laid out smaller', (
    tester,
  ) async {
    Size? seen;
    await show(
      tester,
      const Size(1032, 1376),
      Builder(
        builder: (context) {
          seen = MediaQuery.sizeOf(context);
          return const SizedBox.expand(key: Key('page'));
        },
      ),
    );
    // Laid out at 1/1.5 of the window...
    expect(seen!.width, closeTo(1032 / 1.5, 0.01));
    expect(seen!.height, closeTo(1376 / 1.5, 0.01));
    // ...and drawn over all of it.
    final rect = tester.getRect(find.byKey(const Key('page')));
    expect(rect.width, closeTo(1032, 0.5));
    expect(rect.height, closeTo(1376, 0.5));
    expect(rect.topLeft, Offset.zero);
  });

  testWidgets('taps land where they are drawn', (tester) async {
    var taps = 0;
    await show(
      tester,
      const Size(1032, 1376),
      Scaffold(
        body: Align(
          alignment: Alignment.bottomRight,
          child: ElevatedButton(
            onPressed: () => taps++,
            child: const Text('Tap me'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Tap me'));
    expect(taps, 1);
  });

  testWidgets('insets such as the keyboard are scaled with it', (tester) async {
    EdgeInsets? insets;
    tester.view.physicalSize = const Size(1032, 1376);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, c) => AdaptiveScale(child: c!),
        home: Builder(
          builder: (context) {
            insets = MediaQuery.viewInsetsOf(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(insets!.bottom, closeTo(300 / 1.5, 0.01));
  });

  testWidgets('focused screens get bigger text on a tablet only', (
    tester,
  ) async {
    double? phone;
    double? tablet;
    Future<void> measure(Size window, void Function(double) save) async {
      tester.view.physicalSize = window;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, c) => AdaptiveScale(child: c!),
          home: FocusedBoost(
            child: Builder(
              builder: (context) {
                save(MediaQuery.textScalerOf(context).scale(10));
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    }

    await measure(const Size(390, 844), (v) => phone = v);
    await measure(const Size(1032, 1376), (v) => tablet = v);
    addTearDown(tester.view.reset);
    expect(phone, 10);
    expect(tablet, closeTo(13.5, 0.01));
  });

  testWidgets('the keypad is bigger on a tablet, inside the narrow column', (
    tester,
  ) async {
    Future<double> keyWidth(Size window) async {
      tester.view.physicalSize = window;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, c) => AdaptiveScale(child: c!),
          home: Scaffold(
            body: GlassBackground(
              maxContentWidth: kFocusedMaxWidth,
              child: FocusedBoost(
                child: Center(child: PinPad(length: 4, onSubmitted: (_) {})),
              ),
            ),
          ),
        ),
      );
      return tester.getRect(find.byType(InkWell).first).width;
    }

    final phone = await keyWidth(const Size(390, 844));
    final mini = await keyWidth(const Size(744, 1133));
    final big = await keyWidth(const Size(1032, 1376));
    addTearDown(tester.view.reset);

    expect(phone, 76);
    // 76 x the focused boost (1.35) x the app scale (1.16 and 1.5).
    expect(mini, closeTo(76 * 1.35 * (744 / 640), 1));
    expect(big, closeTo(76 * 1.35 * 1.5, 1));
  });
}
