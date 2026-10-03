import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/intl.dart';

import '../../../core/db/settings_repository.dart';
import '../../../core/import_progress.dart';
import '../../../shared/widgets/import_progress_view.dart';
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
  ImportProgress? _progress;
  String? _note;
  bool _noteOk = true;

  Future<void> _connect() async {
    final service = ref.read(smsImportServiceProvider);
    final granted = await service.requestPermission();
    if (!granted) {
      if (mounted) {
        setState(() {
          _note = 'SMS permission was not granted, so nothing was scanned. You can allow it later in Settings.';
          _noteOk = false;
        });
      }
      return;
    }

    setState(() {
      _scanning = true;
      _note = null;
    });
    try {
      final result = await service.importFromInbox(
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      await service.listenForNewMessages((_) {});
      if (mounted) {
        setState(() {
          _note = result.imported > 0
              ? 'Done — added ${result.imported} transaction${result.imported == 1 ? '' : 's'} '
                    'from ${result.scanned} messages.'
                    '${result.queued > 0 ? ' ${result.queued} need your review (Manage tab).' : ''}'
              : 'Done — scanned ${result.scanned} messages, no new bank transactions found.'
                    '${result.queued > 0 ? ' ${result.queued} need your review (Manage tab).' : ''}';
          _noteOk = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _note = 'SMS scan failed: $e';
          _noteOk = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _scanning = false;
          _progress = null;
        });
      }
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
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<String?>(
            stream: ref
                .read(settingsRepositoryProvider)
                .watch(SettingsKeys.smsLastSyncedAt),
            builder: (context, snapshot) {
              final last = snapshot.data == null
                  ? null
                  : DateTime.tryParse(snapshot.data!);
              if (last == null) return const SizedBox.shrink();
              final stale =
                  DateTime.now().difference(last) > const Duration(days: 3);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  stale
                      ? 'Last synced ${DateFormat.yMMMd().add_jm().format(last)} — opening the app catches up on anything missed.'
                      : 'Last synced ${DateFormat.yMMMd().add_jm().format(last)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: stale
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            },
          ),
          StreamBuilder<String?>(
            stream: ref
                .read(settingsRepositoryProvider)
                .watch(SettingsKeys.smsAutoSync),
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
          if (_scanning && _progress != null) ...[
            const SizedBox(height: 14),
            ImportProgressView(progress: _progress!),
          ],
          if (_note != null && !_scanning) ...[
            const SizedBox(height: 14),
            ImportResultNote(ok: _noteOk, text: _note!),
          ],
        ],
      ),
    );
  }
}
