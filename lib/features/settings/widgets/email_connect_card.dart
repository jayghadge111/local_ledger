import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/email/email_providers.dart';
import '../../../shared/widgets/glass_surface.dart';

class EmailConnectCard extends ConsumerStatefulWidget {
  const EmailConnectCard({super.key});

  @override
  ConsumerState<EmailConnectCard> createState() => _EmailConnectCardState();
}

class _EmailConnectCardState extends ConsumerState<EmailConnectCard> {
  bool _working = false;

  Future<void> _connect() async {
    setState(() => _working = true);
    try {
      final result = await ref.read(gmailImportServiceProvider).importRecent();
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
              'Gmail sign-in isn\'t set up yet for this build — needs an OAuth client configured in Google Cloud Console. ($e)',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
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
        ],
      ),
    );
  }
}
