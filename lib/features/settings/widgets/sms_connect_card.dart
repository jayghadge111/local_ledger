import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/intl.dart';

import '../../../core/db/settings_repository.dart';
import '../../../core/sms/sms_providers.dart';
import '../../../shared/widgets/glass_switch_row.dart';
import '../../../shared/widgets/glass_surface.dart';

class SmsConnectCard extends ConsumerStatefulWidget {
  const SmsConnectCard({super.key});

  @override
  ConsumerState<SmsConnectCard> createState() => _SmsConnectCardState();
}

class _SmsConnectCardState extends ConsumerState<SmsConnectCard> {
  bool _scanning = false;

  Future<void> _connect() async {
    final service = ref.read(smsImportServiceProvider);
    final granted = await service.requestPermission();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SMS permission was not granted')),
        );
      }
      return;
    }

    setState(() => _scanning = true);
    try {
      final result = await service.importFromInbox();
      await service.listenForNewMessages((_) {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Scanned ${result.scanned} messages, imported ${result.imported} transactions'
              '${result.queued > 0 ? ', ${result.queued} to review' : ''}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = ref.read(smsImportServiceProvider);

    if (!service.isSupported) return const SizedBox.shrink();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SMS import (Android)', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Scans your SMS inbox for bank transaction alerts and adds any new ones. '
            'Parsing happens entirely on this device — the original message is stored '
            'encrypted, never sent anywhere.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          StreamBuilder<String?>(
            stream: ref.read(settingsRepositoryProvider).watch(SettingsKeys.smsLastSyncedAt),
            builder: (context, snapshot) {
              final last = snapshot.data == null ? null : DateTime.tryParse(snapshot.data!);
              if (last == null) return const SizedBox.shrink();
              final stale = DateTime.now().difference(last) > const Duration(days: 3);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  stale
                      ? 'Last synced ${DateFormat.yMMMd().add_jm().format(last)} — opening the app catches up on anything missed.'
                      : 'Last synced ${DateFormat.yMMMd().add_jm().format(last)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: stale ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            },
          ),
          StreamBuilder<String?>(
            stream: ref.read(settingsRepositoryProvider).watch(SettingsKeys.smsAutoSync),
            builder: (context, snapshot) => GlassSwitchRow(
              label: 'Sync automatically when the app opens',
              value: snapshot.data != 'false',
              onChanged: (v) => ref
                  .read(settingsRepositoryProvider)
                  .set(SettingsKeys.smsAutoSync, v.toString()),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _scanning ? null : _connect,
            icon: _scanning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sms_outlined),
            label: Text(_scanning ? 'Scanning…' : 'Scan SMS inbox'),
          ),
        ],
      ),
    );
  }
}
