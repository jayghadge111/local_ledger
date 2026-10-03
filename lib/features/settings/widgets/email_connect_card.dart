import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/email/email_providers.dart';
import '../../../core/import_progress.dart';
import '../../../shared/widgets/import_progress_view.dart';
import '../../../shared/widgets/glass_surface.dart';

class EmailConnectCard extends ConsumerStatefulWidget {
  const EmailConnectCard({super.key});

  @override
  ConsumerState<EmailConnectCard> createState() => _EmailConnectCardState();
}

class _EmailConnectCardState extends ConsumerState<EmailConnectCard> {
  bool _working = false;
  ImportProgress? _progress;

  Future<void> _connect() async {
    setState(() => _working = true);
    try {
      final result = await ref.read(gmailImportServiceProvider).importRecent(
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Scanned ${result.scanned} emails, imported ${result.imported} transactions',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gmail import failed: $e',
            ),
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gmail import', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Reads recent transaction emails directly from your Gmail account — nothing '
            'passes through a server of ours. Needs a one-time Google sign-in.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _working ? null : _connect,
            icon: _working
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.mail_outline),
            label: Text(_working ? 'Working…' : 'Connect Gmail'),
          ),
          if (_working && _progress != null) ...[
            const SizedBox(height: 14),
            ImportProgressView(progress: _progress!),
          ],
        ],
      ),
    );
  }
}
