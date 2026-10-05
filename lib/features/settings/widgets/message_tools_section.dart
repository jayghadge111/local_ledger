import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/settings_repository.dart';
import '../../../core/db/small_repositories.dart';
import '../../../core/sms/parser_templates.dart';
import '../../import_review/bank_email_domains_screen.dart';
import '../../import_review/learned_layouts_screen.dart';
import '../../import_review/own_identifiers_screen.dart';
import '../../import_review/unparsed_messages_screen.dart';
import '../../manage/manage_card.dart';

/// The tools that sit behind message import — what couldn't be read, what the
/// app has learned, your other names and UPI IDs, and extra bank email
/// senders — listed right under the SMS and Gmail import cards.
class MessageToolsSection extends ConsumerWidget {
  const MessageToolsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unparsed =
        ref.watch(unparsedMessagesProvider).value ?? const <UnparsedMessage>[];
    final learned = ref.watch(parserTemplateCountProvider).value ?? 0;
    final own =
        ref.watch(ownIdentifiersProvider).value ?? const <OwnIdentifier>[];
    final senders =
        ref.watch(customBankEmailDomainsProvider).value ?? const <String>[];

    final items = <ManageItem>[
      ManageItem(
        icon: Icons.mark_email_unread_rounded,
        title: 'Messages to review',
        subtitle: unparsed.isEmpty
            ? "Bank messages we couldn't read will appear here"
            : '${unparsed.length} need${unparsed.length == 1 ? 's' : ''} your attention',
        badge: unparsed.isEmpty ? null : unparsed.length,
        screen: const UnparsedMessagesScreen(),
      ),
      ManageItem(
        icon: Icons.auto_fix_high_rounded,
        title: 'Learned message layouts',
        subtitle: learned == 0
            ? 'Fix a transaction and the app learns to read messages like it'
            : '$learned learned from your corrections',
        screen: const LearnedLayoutsScreen(),
      ),
      ManageItem(
        icon: Icons.swap_horiz_rounded,
        title: 'My other names & UPI IDs',
        subtitle: own.isEmpty
            ? "Extra UPI IDs or spellings of your name, so transfers between your accounts aren't counted as spending"
            : '${own.length} saved · also used to spot Self Transfers',
        screen: const OwnIdentifiersScreen(),
      ),
      ManageItem(
        icon: Icons.alternate_email_rounded,
        title: 'Bank email senders',
        subtitle: senders.isEmpty
            ? 'Gmail alerts from your bank skipped? Add its sender address'
            : '${senders.length} extra sender${senders.length == 1 ? '' : 's'} added',
        screen: const BankEmailDomainsScreen(),
      ),
    ];

    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          ManageCard(item: items[i]),
        ],
      ],
    );
  }
}
