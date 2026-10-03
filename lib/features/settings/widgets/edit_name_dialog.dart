import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/settings_repository.dart';
import '../../../core/ingest/ingest_providers.dart';
import '../../../core/profile/greeting.dart';
import '../../../core/ui/root_messenger.dart';
import '../../../shared/widgets/centered_dialog_card.dart';
import '../../../shared/widgets/glass_surface.dart';

/// Why we ask for the name — shown wherever it's collected.
const nameExplanation =
    'Used only on this device to tell payments you make to or receive from '
    'yourself (moving money between your own accounts, UPI to yourself) from '
    'real spending and income. They appear as Self Transfer and are left out '
    'of your totals.';

/// Saves [name] and re-checks existing transactions against it, so Self
/// Transfers already imported are recognised straight away.
Future<void> saveUserName(WidgetRef ref, String name) async {
  final settings = ref.read(settingsRepositoryProvider);
  final cleaned = prettyName(name);
  if (cleaned.isEmpty) {
    await settings.remove(SettingsKeys.userName);
  } else {
    await settings.set(SettingsKeys.userName, cleaned);
  }
  await ref.read(reconcilerProvider).run();
}

Future<void> showEditNameDialog(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    builder: (_) => const CenteredDialogCard(child: _EditNameCard()),
  );
}

class _EditNameCard extends ConsumerStatefulWidget {
  const _EditNameCard();

  @override
  ConsumerState<_EditNameCard> createState() => _EditNameCardState();
}

class _EditNameCardState extends ConsumerState<_EditNameCard> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(userNameProvider).value ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await saveUserName(ref, _controller.text);
    if (!mounted) return;
    Navigator.of(context).pop();
    showRootSnackBar('Name saved');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Align(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: GlassCard(
            borderRadius: 28,
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your full name', style: theme.textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  nameExplanation,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _save(),
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    hintText: 'As it appears on your bank account',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
