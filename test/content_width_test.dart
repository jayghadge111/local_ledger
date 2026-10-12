import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/shared/widgets/glass_background.dart';

void main() {
  Future<void> show(WidgetTester tester, double width, Widget child) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: child));
  }

  testWidgets('a phone is untouched', (tester) async {
    await show(
      tester,
      390,
      const GlassBackground(child: SizedBox.expand(key: Key('page'))),
    );
    expect(tester.getSize(find.byKey(const Key('page'))).width, 390);
  });

  testWidgets('a tablet gets a centred column, full height', (tester) async {
    await show(
      tester,
      1032,
      const GlassBackground(child: SizedBox.expand(key: Key('page'))),
    );
    final page = tester.getRect(find.byKey(const Key('page')));
    expect(page.width, kContentMaxWidth);
    expect(page.height, 900);
    expect(page.center.dx, 1032 / 2);
  });

  testWidgets('focused screens get the narrower column', (tester) async {
    await show(
      tester,
      1032,
      const GlassBackground(
        maxContentWidth: kFocusedMaxWidth,
        child: SizedBox.expand(key: Key('page')),
      ),
    );
    expect(
      tester.getSize(find.byKey(const Key('page'))).width,
      kFocusedMaxWidth,
    );
  });

  testWidgets('the shell can opt out and stay full width', (tester) async {
    await show(
      tester,
      1032,
      const GlassBackground(
        maxContentWidth: null,
        child: SizedBox.expand(key: Key('page')),
      ),
    );
    expect(tester.getSize(find.byKey(const Key('page'))).width, 1032);
  });

  testWidgets('what sizes itself from MediaQuery sees the column', (
    tester,
  ) async {
    double? seen;
    await show(
      tester,
      1032,
      GlassBackground(
        child: Builder(
          builder: (context) {
            seen = MediaQuery.sizeOf(context).width;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    expect(seen, kContentMaxWidth);
  });

  testWidgets('the page still scrolls and lays out normally inside it', (
    tester,
  ) async {
    await show(
      tester,
      1032,
      GlassBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: const Text('Budgets')),
          body: ListView(
            children: [
              for (var i = 0; i < 30; i++) ListTile(title: Text('Row $i')),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(ListView)).width, kContentMaxWidth);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();
    expect(find.text('Row 0'), findsNothing);
  });
}
