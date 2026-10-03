import 'package:flutter/material.dart';

/// Places [child] (normally a card) in the middle of the screen over a
/// dialog barrier, lifted above the keyboard. Deliberately not a [Dialog]:
/// that draws its own full-screen themed surface behind the card.
class CenteredDialogCard extends StatelessWidget {
  const CenteredDialogCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: child,
        ),
      ),
    );
  }
}
