import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/import_progress.dart';
import 'package:local_ledger/shared/widgets/import_progress_view.dart';

void main() {
  test('fraction and remaining', () {
    const p = ImportProgress('Reading', done: 120, total: 340);
    expect(p.fraction, closeTo(0.353, 0.001));
    expect(p.remaining, 220);
    expect(const ImportProgress('Searching…').fraction, isNull);
    expect(const ImportProgress('x', done: 5, total: 3).remaining, 0);
  });

  testWidgets('shows done, left, percent and transactions found', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ImportProgressView(
          progress: ImportProgress('Reading bank emails', done: 120, total: 340, found: 12),
        ),
      ),
    ));
    expect(find.text('Reading bank emails'), findsOneWidget);
    expect(find.text('35%'), findsOneWidget);
    expect(find.text('120 of 340 checked · 220 left'), findsOneWidget);
    expect(find.text('12 transactions added so far'), findsOneWidget);
    expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value,
        closeTo(0.353, 0.001));
  });

  testWidgets('unknown total shows an indeterminate bar and no counts', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: ImportProgressView(progress: ImportProgress('Signing in…'))),
    ));
    expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, isNull);
    expect(find.textContaining('left'), findsNothing);
  });
}
