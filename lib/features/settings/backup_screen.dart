import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/backup/snapshot_providers.dart';
import '../../shared/widgets/glass_background.dart';
import '../manage/manage_card.dart';
import 'widgets/backup_card.dart';

/// Everything about backing up, on its own screen: save to a file, move to
/// another phone, and the copy the app keeps by itself.
class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Backup')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: const [BackupCard()],
        ),
      ),
    );
  }
}

/// The Settings entry for [BackupScreen], in the same style as the other
/// tools: one card, with the date of the last copy as its summary.
class BackupEntryCard extends ConsumerWidget {
  const BackupEntryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final last = ref.watch(snapshotListProvider).value?.firstOrNull;
    return ManageCard(
      item: ManageItem(
        icon: Icons.backup_rounded,
        title: 'Backup',
        subtitle: last == null
            ? 'Save your data to a file, and keep a copy on this phone'
            : 'Last copy ${DateFormat.yMMMd().add_jm().format(last.at)} · export, import, restore',
        screen: const BackupScreen(),
      ),
    );
  }
}
