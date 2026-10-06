import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether Google can be reached right now. A DNS lookup is enough to tell
/// "no connection" from everything else, and it fails in a second or two
/// instead of leaving a spinner running for the full request timeout.
Future<bool> canReachGoogle() async {
  try {
    final found = await InternetAddress.lookup('gmail.googleapis.com')
        .timeout(const Duration(seconds: 4));
    return found.isNotEmpty && found.first.rawAddress.isNotEmpty;
  } on SocketException {
    return false;
  } on TimeoutException {
    return false;
  } catch (_) {
    // Not being able to check is not the same as being offline.
    return true;
  }
}

/// Replaceable in tests.
final internetCheckProvider = Provider<Future<bool> Function()>(
  (ref) => canReachGoogle,
);
