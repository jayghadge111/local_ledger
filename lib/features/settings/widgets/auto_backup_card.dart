import '../../../shared/widgets/text_button_styles.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/backup/local_snapshots.dart';
import '../../../core/backup/snapshot_providers.dart';

/// The copy NativeSpend keeps by itself: when it was made, and a one-tap way
/// back to it. Shown inside the Backup card.
class AutoBackupSection extends ConsumerStatefulWidget {
  const AutoBackupSection({super.key});

  @override
  ConsumerState<AutoBackupSection> createState() => _AutoBackupSectionState();
}

class _AutoBackupSectionState extends ConsumerState<AutoBackupSection> {
  bool _busy = false;

  Future<void> _backupNow() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final made = await ref.read(snapshotServiceProvider).snapshot('manual');
    if (!mounted) return;
    setState(() => _busy = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          made == null ? "Couldn't make a copy right now." : 'Backed up.',
        ),
      ),
    );
  }

  Future<void> _restore(SnapshotInfo s) async {
    final when = DateFormat.yMMMd().add_jm().format(s.at);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore this copy?'),
        content: Text(
          'Everything in the app goes back to how it was on $when '
          '(${s.label.toLowerCase()}). Anything added since then will be '
          'gone, and this can\'t be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final done = await ref.read(snapshotServiceProvider).restore(s);
    if (mounted) setState(() => _busy = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          done
              ? 'Restored the copy from $when.'
              : "That copy couldn't be restored. Nothing was changed.",
        ),
      ),
    );
  }

  Future<void> _delete(SnapshotInfo s) async {
    final when = DateFormat.yMMMd().add_jm().format(s.at);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this backup?'),
        content: Text(
          'The copy from $when will be deleted. Your current data is not '
          'affected. A new copy is made before the next update or big import.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: dangerTextButtonStyle(context),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final done = ref.read(snapshotServiceProvider).delete(s);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          done ? 'Backup deleted.' : "Couldn't delete that backup.",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final snapshots = ref.watch(snapshotListProvider).value ?? const [];
    final fmt = DateFormat.yMMMd().add_jm();
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kept on this phone', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          'NativeSpend saves a copy of your data on this phone before app '
          'updates and big imports. Each new copy replaces the last. If '
          'something goes wrong, restore it.',
          style: muted,
        ),
        const SizedBox(height: 12),
        Text(
          snapshots.isEmpty
              ? 'Last backup: none yet'
              : 'Last backup: ${fmt.format(snapshots.first.at)}',
          style: theme.textTheme.bodyMedium,
        ),
        for (final s in snapshots) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.label, style: theme.textTheme.bodyMedium),
                    Text(
                      '${fmt.format(s.at)} · ${_size(s.bytes)}',
                      style: muted,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _busy ? null : () => _restore(s),
                child: const Text('Restore'),
              ),
              IconButton(
                tooltip: 'Delete backup',
                color: dangerColor(context),
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: _busy ? null : () => _delete(s),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _busy ? null : _backupNow,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Back up now'),
        ),
      ],
    );
  }

  String _size(int bytes) => bytes < 1024 * 1024
      ? '${(bytes / 1024).ceil()} KB'
      : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
