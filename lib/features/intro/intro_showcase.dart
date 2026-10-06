import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

/// One stop of the tour: which navigation item it is about and what to say.
class IntroStep {
  const IntroStep({required this.title, required this.body});
  final String title;
  final String body;
}

/// The six stops, in the order the tour visits them: Home, the alerts bell
/// beside the greeting on Home, then the bottom bar from left to right.
const introSteps = [
  IntroStep(
    title: 'Home',
    body: 'Your month at a glance: what came in, what went out, where it went, and how your budgets are doing.',
  ),
  IntroStep(
    title: 'Alerts',
    body: 'Tap the bell for bills coming up, budgets running out and unusual payments.',
  ),
  IntroStep(
    title: 'Transactions',
    body: 'Every payment in one list. Search or filter it, and tap one to see its details or fix it.',
  ),
  IntroStep(
    title: 'Split',
    body: 'A bill you paid for a group? Add your friends, split it, and see who still owes you.',
  ),
  IntroStep(
    title: 'Lend',
    body: 'Money you actually gave or took as a loan, with a reminder when it is due.',
  ),
  IntroStep(
    title: 'Settings',
    body: 'Bring in your bank messages, set budgets and rules, lock the app with a PIN and back up your data.',
  ),
];

/// The tour step of each bottom-bar item (Home, Transactions, Split, Lend,
/// Settings), and of the alerts bell on Home.
const introNavStep = [0, 2, 3, 4, 5];
const introBellStep = 1;

/// The bell on Home is one fixed widget, so its tour target is one fixed key.
final introBellKey = GlobalKey(debugLabel: 'introBell');

/// Registers the tour (the `showcaseview` package) for this screen. Call once;
/// [onEnd] runs when it is finished or skipped. Pair with [endIntroShowcase].
void registerIntroShowcase({required VoidCallback onEnd}) {
  ShowcaseView.register(
    onFinish: onEnd,
    onDismiss: (_) => onEnd(),
    // Taps outside the lit-up item do nothing: the tour only moves on with
    // its own buttons.
    disableBarrierInteraction: true,
    overlayColor: Colors.black,
    overlayOpacity: 0.72,
    semanticEnable: true,
  );
}

void endIntroShowcase() {
  try {
    ShowcaseView.get().unregister();
  } catch (_) {
    // Never registered, or already gone.
  }
}

/// Lights up navigation item [index] during the tour: wraps its [child] (the
/// icon) in a `Showcase` carrying that section's title and explanation.
///
/// [wide] puts the tooltip beside a side rail instead of above a bottom bar.
Widget introShowcase({
  required BuildContext context,
  required int index,
  required GlobalKey showcaseKey,
  required Widget child,
  required bool wide,

  /// Overrides where the tooltip sits (the bell on Home opens downwards).
  TooltipPosition? position,

  /// Overrides the glow around the target (a round bell needs less than a
  /// bottom-bar item with its label).
  EdgeInsets? targetPadding,
  ShapeBorder? targetShape,
}) {
  final theme = Theme.of(context);
  final step = introSteps[index];
  final last = index == introSteps.length - 1;
  final muted = theme.textTheme.bodySmall?.copyWith(
    color: theme.colorScheme.onSurfaceVariant,
  );
  final buttonText = TextStyle(
    color: theme.colorScheme.onPrimary,
    fontWeight: FontWeight.w700,
  );

  return Showcase(
    key: showcaseKey,
    title: step.title,
    description: step.body,
    titleTextStyle: theme.textTheme.titleLarge?.copyWith(
      color: theme.colorScheme.onSurface,
    ),
    descTextStyle: theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurface,
    ),
    tooltipBackgroundColor: theme.colorScheme.surface,
    textColor: theme.colorScheme.onSurface,
    tooltipPosition:
        position ?? (wide ? TooltipPosition.right : TooltipPosition.top),
    tooltipPadding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
    tooltipBorderRadius: BorderRadius.circular(20),
    targetShapeBorder:
        targetShape ??
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
    // The icon plus its label and the pill behind it.
    targetPadding: targetPadding ?? const EdgeInsets.fromLTRB(22, 10, 22, 26),
    disableDefaultTargetGestures: true,
    disableBarrierInteraction: true,
    tooltipActionConfig: const TooltipActionConfig(
      alignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
    ),
    tooltipActions: [
      TooltipActionButton.custom(
        button: Text('${index + 1} of ${introSteps.length}', style: muted),
      ),
      if (!last)
        TooltipActionButton(
          type: TooltipDefaultActionType.skip,
          name: 'Skip',
          backgroundColor: Colors.transparent,
          textStyle: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      TooltipActionButton(
        type: TooltipDefaultActionType.next,
        name: last ? 'Got it' : 'Next',
        backgroundColor: theme.colorScheme.primary,
        textStyle: buttonText,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      ),
    ],
    child: child,
  );
}
