import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/db/settings_repository.dart';
import 'package:local_ledger/features/settings/widgets/profile_card.dart';
import 'package:local_ledger/shared/widgets/greeting_header.dart';

/// While the app shell animates in, its body is briefly laid out far narrower
/// than the screen. Nothing on Home or Settings may overflow at those widths.
void main() {
  for (final name in [null, 'Jayesh Bhika Ghadge']) {
    for (final width in [
      20.0,
      60.0,
      100.0,
      140.0,
      200.0,
      229.0,
      231.0,
      260.0,
      280.0,
      340.0,
      390.0,
    ]) {
      testWidgets(
        'greeting and profile card survive ${width.toInt()}px wide (name: $name)',
        (tester) async {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                userNameProvider.overrideWith((ref) => Stream.value(name)),
              ],
              child: MaterialApp(
                home: Scaffold(
                  body: Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: width,
                      child: const SingleChildScrollView(
                        child: Column(
                          children: [GreetingHeader(), ProfileCard()],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 100));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
