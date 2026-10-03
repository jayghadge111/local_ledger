import 'package:flutter/material.dart';

/// The app-wide [ScaffoldMessenger], so a snackbar can be shown from
/// anywhere — including background work that outlives the screen that
/// started it (see `SyncController`).
final rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

void showRootSnackBar(String text) {
  final messenger = rootMessengerKey.currentState;
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
}
