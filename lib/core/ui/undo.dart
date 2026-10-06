import 'package:flutter/material.dart';

import '../diagnostics/diagnostic_log.dart';
import 'haptics.dart';
import 'root_messenger.dart';

/// Puts things back the way they were. Repository methods that delete or
/// change many things at once return one of these.
typedef UndoAction = Future<void> Function();

/// A snackbar with an Undo button. Used instead of "are you sure?" dialogs for
/// deletes and bulk changes: one tap does the thing, one tap takes it back.
///
/// It goes on the app-wide messenger, so it survives the screen or sheet that
/// started the action closing.
void showUndoSnackBar(String message, UndoAction undo) {
  final messenger = rootMessengerKey.currentState;
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 7),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            Haptics.tap();
            try {
              await undo();
            } catch (error, stack) {
              DiagnosticLog.instance.record('undo', error, stack, message);
              showRootSnackBar("Couldn't undo that.");
            }
          },
        ),
      ),
    );
}
