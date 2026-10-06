import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

/// One stop of the tour: which navigation item it is about and what to say.
class IntroStep {
  const IntroStep({required this.title, required this.body});
  final String title;
  final String body;
}

/// The five main sections, in the order they sit in the navigation bar.
const introSteps = [
  IntroStep(
    title: 'Home',
    body: 'Your month at a glance: what came in, what went out, where it went, and how your budgets are doing.',
  ),
  IntroStep(
    title: 'Transactions',
    body: 'Every payment in one list. Search or filter it, and tap one to see its details or fix it.',
  ),
  IntroStep(
    title: 'Manage',
    body: 'Budgets, shared expenses, money you lent or borrowed, and auto-pay dues — kept together.',
  ),
  IntroStep(
    title: 'Alerts',
    body: 'Bills coming up, budgets running out and unusual payments show up here.',
  ),
  IntroStep(
    title: 'Settings',
    body: 'Bring in your bank messages, lock the app with a PIN, back up your data and change how it looks.',
  ),
];

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
    tooltipPosition: wide ? TooltipPosition.right : TooltipPosition.top,
    tooltipPadding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
    tooltipBorderRadius: BorderRadius.circular(20),
    targetShapeBorder: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
    ),
    // The icon plus its label and the pill behind it.
    targetPadding: const EdgeInsets.fromLTRB(22, 10, 22, 26),
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
