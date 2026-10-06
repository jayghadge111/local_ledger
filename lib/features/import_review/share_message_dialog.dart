import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/sms/anonymize.dart';
import '../../core/sms/bank_sms_parser.dart';

/// "Share for fixing": copies an anonymised version of a message the app
/// couldn't read, with what the right answer is, so it can be sent to the
/// developer and become a permanent test (see `tool/add_canaries.dart`).
///
/// Nothing is sent from here — the person copies the text and chooses where to
/// paste it. They see, and can edit, exactly what will be copied.
Future<void> showShareMessageDialog(BuildContext context, String body) {
  return showDialog<void>(
    context: context,
    builder: (context) => _ShareMessageDialog(body: body),
  );
}

class _ShareMessageDialog extends StatefulWidget {
  const _ShareMessageDialog({required this.body});
  final String body;

  @override
  State<_ShareMessageDialog> createState() => _ShareMessageDialogState();
}

class _ShareMessageDialogState extends State<_ShareMessageDialog> {
  late final TextEditingController _text = TextEditingController(
    text: anonymizeMessage(widget.body),
  );
  late final TextEditingController _amount = TextEditingController(
    text: _initialAmount(),
  );
  final _merchant = TextEditingController();
  String? _type = 'debit';
  bool _notTransaction = false;

  String _initialAmount() {
    final minor = extractAmountMinor(widget.body);
    return minor == null ? '' : (minor / 100).toStringAsFixed(2);
  }

  @override
  void dispose() {
    _text.dispose();
    _amount.dispose();
    _merchant.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    final rupees = double.tryParse(_amount.text.replaceAll(',', '').trim());
    final json = canaryJson(
      text: _text.text,
      type: _notTransaction ? null : _type,
      amountMinor: _notTransaction || rupees == null
          ? null
          : (rupees * 100).round(),
      merchantContains: _notTransaction ? null : _merchant.text,
    );
    await Clipboard.setData(ClipboardData(text: json));
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied. Paste it into a message to send.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Share for fixing'),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This copies the message with numbers and account details '
            "changed, so it can be used to teach the app. Names can't be "
            'spotted automatically — please remove any you see. Nothing is '
            'sent until you paste it somewhere yourself.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _text,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Message (edit if needed)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Text('What is it?', style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Money spent'),
                selected: !_notTransaction && _type == 'debit',
                onSelected: (_) => setState(() {
                  _notTransaction = false;
                  _type = 'debit';
                }),
              ),
              ChoiceChip(
                label: const Text('Money received'),
                selected: !_notTransaction && _type == 'credit',
                onSelected: (_) => setState(() {
                  _notTransaction = false;
                  _type = 'credit';
                }),
              ),
              ChoiceChip(
                label: const Text('Not a transaction'),
                selected: _notTransaction,
                onSelected: (_) => setState(() => _notTransaction = true),
              ),
            ],
          ),
          if (!_notTransaction) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _merchant,
              decoration: const InputDecoration(
                labelText: 'Paid to / received from (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _copy,
          icon: const Icon(Icons.copy_rounded),
          label: const Text('Copy'),
        ),
      ],
    );
  }
}
