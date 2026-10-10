import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../ui/share_origin.dart';

/// Hands a message — and optionally a picture — to the phone's share sheet:
/// WhatsApp, Telegram, SMS, email, whatever the user has. The app never sends
/// anything itself: the user chooses the app and the person, and presses send
/// there.
typedef ShareMessage = Future<void> Function({String? text, Uint8List? png});

final lendingShareProvider = Provider<ShareMessage>(
  (ref) => ({String? text, Uint8List? png}) async {
    final files = <XFile>[];
    if (png != null) {
      final file = File(
        '${Directory.systemTemp.path}/trueledger_status_'
        '${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(png, flush: true);
      files.add(XFile(file.path, mimeType: 'image/png'));
    }
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        files: files.isEmpty ? null : files,
        sharePositionOrigin: shareOrigin(),
      ),
    );
  },
);
