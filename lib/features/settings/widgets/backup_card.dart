import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/backup/backup_providers.dart';
import '../../../core/backup/backup_service.dart';
import '../../../core/backup/snapshot_providers.dart';
import '../../../core/ui/share_origin.dart';
import '../../../shared/widgets/glass_surface.dart';
import 'auto_backup_card.dart';

class BackupCard extends ConsumerWidget {
  const BackupCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Backup', style: theme.textTheme.titleMedium),
          const SizedBox(height: 14),
          Text('Save to a file', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            'Export an encrypted copy of everything to save or move to another device, protected by a passphrase only you know.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _exportBackup(context, ref),
            icon: const Icon(Icons.upload_outlined),
            label: const Text('Export backup'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _importBackup(context, ref),
            icon: const Icon(Icons.download_outlined),
            label: const Text('Import backup'),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          const AutoBackupSection(),
        ],
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final passphrase = await _promptPassphrase(context, confirm: true);
    if (passphrase == null) return;

    try {
      final file = await ref
          .read(backupServiceProvider)
          .exportEncrypted(passphrase);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'NativeSpend backup',
          sharePositionOrigin: shareOrigin(),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['llbackup'],
    );
    if (files.isEmpty || files.first.path == null) return;

    if (!context.mounted) return;
    final passphrase = await _promptPassphrase(context, confirm: false);
    if (passphrase == null) return;

    try {
      // Importing merges a lot of rows in: keep a copy to go back to.
      await ref.read(snapshotServiceProvider).snapshot('before-import');
      await ref
          .read(backupServiceProvider)
          .importEncrypted(File(files.first.path!), passphrase);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Backup restored')));
      }
    } on BackupPassphraseException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect passphrase for this backup')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }

  Future<String?> _promptPassphrase(
    BuildContext context, {
    required bool confirm,
  }) async {
    final controller = TextEditingController();
    final confirmController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          confirm ? 'Choose a backup passphrase' : 'Enter backup passphrase',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Passphrase',
                border: OutlineInputBorder(),
              ),
            ),
            if (confirm) ...[
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm passphrase',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            if (confirm) ...[
              const SizedBox(height: 8),
              Text(
                "Remember this — there's no way to recover a backup without it.",
                style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                  color: Theme.of(dialogContext).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text;
              if (value.length < 4) return;
              if (confirm && value != confirmController.text) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text("Passphrases don't match")),
                );
                return;
              }
              Navigator.of(dialogContext).pop(value);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
