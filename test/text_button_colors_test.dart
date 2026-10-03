import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/theme/app_theme.dart';
import 'package:local_ledger/shared/widgets/text_button_styles.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'text buttons are blue, danger ones red (${dark ? 'dark' : 'light'})',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark() : AppTheme.light(),
            home: Builder(
              builder: (context) => Column(
                children: [
                  TextButton(onPressed: () {}, child: const Text('Dismiss')),
                  TextButton(
                    onPressed: () {},
                    style: dangerTextButtonStyle(context),
                    child: const Text('Disconnect'),
                  ),
                ],
              ),
            ),
          ),
        );
        Color colorOf(String label) => tester
            .widget<DefaultTextStyle>(
              find
                  .descendant(
                    of: find.widgetWithText(TextButton, label),
                    matching: find.byType(DefaultTextStyle),
                  )
                  .first,
            )
            .style
            .color!;
        expect(
          colorOf('Dismiss'),
          dark ? AppPalette.linkDark : AppPalette.linkLight,
        );
        expect(
          colorOf('Disconnect'),
          dark ? AppPalette.dangerDark : AppPalette.dangerLight,
        );
      },
    );
  }
}
