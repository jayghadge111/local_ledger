import '../../shared/widgets/text_button_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/settings_repository.dart';
import '../../core/email/bank_email_matcher.dart';
import '../../shared/widgets/glass_background.dart';
import '../../shared/widgets/glass_surface.dart';

/// Extra sender domains for banks the built-in list doesn't know — mostly
/// small and co-operative banks. Gmail import treats mail from these as
/// bank alerts.
class BankEmailDomainsScreen extends ConsumerStatefulWidget {
  const BankEmailDomainsScreen({super.key});

  @override
  ConsumerState<BankEmailDomainsScreen> createState() =>
      _BankEmailDomainsScreenState();
}

class _BankEmailDomainsScreenState
    extends ConsumerState<BankEmailDomainsScreen> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save(List<String> domains) => ref
      .read(settingsRepositoryProvider)
      .set(SettingsKeys.customBankEmailDomains, domains.join(','));

  Future<void> _add(List<String> current) async {
    final domain = normalizeSenderDomain(_controller.text);
    if (domain == null) {
      setState(
        () => _error =
            'Enter a sender address or domain, like alerts@mybank.co.in',
      );
      return;
    }
    if (!current.contains(domain)) await _save([...current, domain]);
    _controller.clear();
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final domains =
        ref.watch(customBankEmailDomainsProvider).value ?? const <String>[];

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Bank email senders')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add your bank\'s email address',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gmail import already recognises ${knownBankEmailDomains.length}+ Indian banks and '
                    'every .bank.in address. If your bank\'s alerts are skipped, open one in Gmail, '
                    'copy the sender\'s address (e.g. alerts@mybank.co.in) and add it here.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          keyboardType: TextInputType.emailAddress,
                          onSubmitted: (_) => _add(domains),
                          decoration: InputDecoration(
                            hintText: 'alerts@mybank.co.in',
                            errorText: _error,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => _add(domains),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  for (final d in domains)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.alternate_email_rounded,
                        size: 18,
                      ),
                      title: Text(d),
                      trailing: IconButton(
                        tooltip: 'Remove',
                        color: dangerColor(context),
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () =>
                            _save(domains.where((x) => x != d).toList()),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
