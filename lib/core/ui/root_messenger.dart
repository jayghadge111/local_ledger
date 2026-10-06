import 'package:flutter/material.dart';

/// The app-wide [ScaffoldMessenger], so a snackbar can be shown from
/// anywhere — including background work that outlives the screen that
/// started it (see `SyncController`).
final rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

void showRootSnackBar(String text) {
  final messenger = rootMessengerKey.currentState;
  if (messenger == null) return;
  try {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
      );
  } on AssertionError {
    // A screen with no Scaffold (some onboarding steps) has nowhere to show
    // it. The message is a courtesy; losing it must not raise an error.
  }
}
