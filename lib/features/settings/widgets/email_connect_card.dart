import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/email/email_providers.dart';
import '../../../core/email/gmail_import_service.dart';
import '../../../core/import_progress.dart';
import '../../../shared/widgets/glass_surface.dart';
import '../../../shared/widgets/import_progress_view.dart';

class EmailConnectCard extends ConsumerStatefulWidget {
  const EmailConnectCard({super.key});

  @override
  ConsumerState<EmailConnectCard> createState() => _EmailConnectCardState();
}

class _EmailConnectCardState extends ConsumerState<EmailConnectCard> {
  bool _working = false;
  ImportProgress? _progress;
  String? _email;
  String? _note;
  bool _noteOk = true;

  @override
  void initState() {
    super.initState();
    _restoreConnectedAccount();
  }

  /// Shows "Connected as …" if Google still has a session from before.
  /// Purely informational — nothing is imported until the user taps a button.
  Future<void> _restoreConnectedAccount() async {
    try {
      final account = await ref.read(gmailAuthServiceProvider).currentAccount();
      if (mounted && account != null) setState(() => _email = account.email);
    } catch (_) {}
  }

  String _summary(EmailImportResult r) {
    if (r.imported > 0) {
      return 'Done — added ${r.imported} transaction${r.imported == 1 ? '' : 's'} '
          'from ${r.scanned} bank email${r.scanned == 1 ? '' : 's'}.'
          '${r.queued > 0 ? ' ${r.queued} need your review (Manage tab).' : ''}';
    }
    if (r.scanned == 0) {
      return 'Connected. No bank emails found in the last year.';
    }
    final reasons = [
      if (r.duplicates > 0) '${r.duplicates} already in the app',
      if (r.queued > 0) '${r.queued} need your review (Manage tab)',
      if (r.notRecognised > 0) '${r.notRecognised} weren\'t transaction alerts',
      if (r.unreadable > 0) '${r.unreadable} couldn\'t be read',
    ];
    return 'Connected. Checked ${r.scanned} emails, added none'
        '${reasons.isEmpty ? '.' : ': ${reasons.join(', ')}.'}';
  }

  /// [fresh] = the user asked to connect / switch account, so Google must
  /// show its account chooser rather than silently reusing the last one.
  Future<void> _run({required bool fresh}) async {
    setState(() {
      _working = true;
      _note = null;
      _progress = const ImportProgress('Signing in to Google…');
    });
    try {
      final auth = ref.read(gmailAuthServiceProvider);
      final account = fresh
          ? await auth.signInFresh()
          : (await auth.currentAccount() ?? await auth.signInFresh());
      if (mounted) setState(() => _email = account.email);

      final result = await ref
          .read(gmailImportServiceProvider)
          .importRecent(
            account: account,
            onProgress: (p) {
              if (mounted) setState(() => _progress = p);
            },
          );
      if (mounted) {
        setState(() {
          _note = _summary(result);
          _noteOk = true;
        });
      }
    } catch (e) {
      final cancelled =
          e is GoogleSignInException &&
          e.code == GoogleSignInExceptionCode.canceled;
      if (mounted) {
        setState(() {
          _note = cancelled
              ? 'Sign-in was cancelled.'
              : 'Gmail import failed: $e';
          _noteOk = cancelled;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
          _progress = null;
        });
      }
    }
  }

  Future<void> _disconnect() async {
    try {
      await ref.read(gmailAuthServiceProvider).disconnect();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _email = null;
        _note =
            'Disconnected. LocalLedger can no longer read this Gmail account.';
        _noteOk = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final connected = _email != null;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gmail import', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Reads recent bank alert emails directly from your Gmail account — nothing '
            'passes through a server of ours. Read-only: your mail is never changed.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (connected) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.mark_email_read_rounded,
                  size: 18,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Connected as $_email',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          if (!connected)
            FilledButton.icon(
              onPressed: _working ? null : () => _run(fresh: true),
              icon: _working
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.mail_outline),
              label: Text(_working ? 'Working…' : 'Connect Gmail'),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _working ? null : () => _run(fresh: false),
                  icon: _working
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync_rounded),
                  label: Text(_working ? 'Working…' : 'Scan now'),
                ),
                OutlinedButton.icon(
                  onPressed: _working ? null : () => _run(fresh: true),
                  icon: const Icon(Icons.switch_account_rounded),
                  label: const Text('Switch account'),
                ),
                TextButton(
                  onPressed: _working ? null : _disconnect,
                  child: const Text('Disconnect'),
                ),
              ],
            ),
          if (_working && _progress != null) ...[
            const SizedBox(height: 14),
            ImportProgressView(progress: _progress!),
          ],
          if (_note != null && !_working) ...[
            const SizedBox(height: 14),
            ImportResultNote(ok: _noteOk, text: _note!),
          ],
        ],
      ),
    );
  }
}
