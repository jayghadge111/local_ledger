import '../../../shared/widgets/text_button_styles.dart';

import 'dart:io';

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/db/providers.dart';
import '../../../core/diagnostics/diagnostic_log.dart';
import '../../../core/diagnostics/support_contact.dart';
import '../../../core/ui/share_origin.dart';
import '../../../shared/widgets/glass_surface.dart';

/// "Something went wrong" help: shows how many problems the app has noted on
/// this phone and lets the user send them on purpose. The log stays on the
/// device until they press Share, and holds no transactions or messages.
class DiagnosticsCard extends ConsumerStatefulWidget {
  const DiagnosticsCard({super.key, this.log});

  /// Defaults to the app's own log; tests pass their own.
  final DiagnosticLog? log;

  @override
  ConsumerState<DiagnosticsCard> createState() => _DiagnosticsCardState();
}

class _DiagnosticsCardState extends ConsumerState<DiagnosticsCard> {
  late Future<int> _count = _load();
  bool _busy = false;

  DiagnosticLog get _log => widget.log ?? DiagnosticLog.instance;

  Future<int> _load() async => (await _log.entries()).length;

  void _reload() {
    final next = _load();
    setState(() {
      _count = next;
    });
  }

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final text = await _log.report(
        extra: {
          'Build': kReleaseMode ? 'release' : 'debug',
          'Database version': '${ref.read(databaseProvider).schemaVersion}',
        },
      );
      final dir = await getTemporaryDirectory();
      final file = File(p.join(dir.path, 'nativespend-diagnostics.txt'));
      await file.writeAsString(text);
      await _send(file.path, messenger);
    } catch (error, stack) {
      _log.record('diagnostics', error, stack, 'sharing the log');
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't prepare the log to share.")),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Opens a new email to [kSupportEmail] with the log attached. Where no mail
  /// app can take an attachment (no account set up, a simulator), falls back to
  /// the share sheet so the log can still go out some other way.
  Future<void> _send(String path, ScaffoldMessengerState messenger) async {
    try {
      await FlutterEmailSender.send(
        Email(
          recipients: const [kSupportEmail],
          subject: 'NativeSpend diagnostic log',
          body:
              'Hi,\n\nThe diagnostic log from NativeSpend is attached. '
              'It has error details only — no transactions, messages or '
              'account numbers.\n\n(Add anything you were doing when it '
              'went wrong here.)\n',
          attachmentPaths: [path],
        ),
      );
    } on FlutterEmailSenderNotAvailableException {
      await _shareInstead(path, messenger);
    } on FlutterEmailSenderUnsupportedFeatureException {
      await _shareInstead(path, messenger);
    }
  }

  Future<void> _shareInstead(
    String path,
    ScaffoldMessengerState messenger,
  ) async {
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'No email app is set up here. Send the log to $kSupportEmail some other way.',
        ),
      ),
    );
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: 'text/plain')],
        subject: 'NativeSpend diagnostic log',
        text: 'NativeSpend diagnostic log',
        sharePositionOrigin: shareOrigin(),
      ),
    );
  }

  Future<void> _clear() async {
    await _log.clear();
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Diagnostics', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'If something goes wrong, the app notes it here on your phone. '
            'Nothing is sent anywhere unless you tap Email. The log has error '
            'details only — no transactions, messages or account numbers.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<int>(
            future: _count,
            builder: (context, snapshot) {
              final n = snapshot.data ?? 0;
              return Row(
                children: [
                  Expanded(
                    child: Text(
                      n == 0
                          ? 'No problems noted.'
                          : '$n problem${n == 1 ? '' : 's'} noted.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  if (n > 0)
                    TextButton(
                      onPressed: _clear,
                      style: dangerTextButtonStyle(context),
                      child: const Text('Clear'),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _share,
            icon: const Icon(Icons.mail_outline_rounded),
            label: const Text('Email diagnostic log'),
          ),
        ],
      ),
    );
  }
}
