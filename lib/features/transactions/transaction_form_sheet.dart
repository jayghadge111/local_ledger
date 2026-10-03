import 'package:flutter/material.dart';

import '../../shared/widgets/centered_dialog_card.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/db/app_database.dart';
import '../../core/db/providers.dart';
import '../../core/db/rules_repository.dart';
import '../../core/intelligence/default_category_rules.dart';
import '../../shared/widgets/text_button_styles.dart';
import '../../core/intelligence/rule_matcher.dart';
import '../../shared/widgets/glass_surface.dart';
import '../../shared/widgets/glass_switch_row.dart';
import '../splits/splits_ui.dart';
import 'transactions_repository.dart';

/// Starting values for a new transaction (e.g. from an unreadable SMS).
class TransactionPrefill {
  const TransactionPrefill({
    this.amountMinor,
    this.merchant,
    this.type,
    this.date,
  });
  final int? amountMinor;
  final String? merchant;
  final String? type;
  final DateTime? date;
}

/// Opens the add/edit transaction form as a modal sheet. Pass [existing] to
/// edit a transaction, or omit it to add a new one. Completes with true if
/// the user saved.
Future<bool?> showTransactionFormSheet(
  BuildContext context, {
  Transaction? existing,
  TransactionPrefill? prefill,
}) {
  // A centered dialog (not a bottom sheet); the card inside supplies the
  // styling, so the dialog itself is transparent.
  return showDialog<bool>(
    context: context,
    builder: (_) => CenteredDialogCard(
      child: TransactionFormSheet(existing: existing, prefill: prefill),
    ),
  );
}

class TransactionFormSheet extends ConsumerStatefulWidget {
  const TransactionFormSheet({super.key, this.existing, this.prefill});

  final Transaction? existing;
  final TransactionPrefill? prefill;

  @override
  ConsumerState<TransactionFormSheet> createState() =>
      _TransactionFormSheetState();
}

class _TransactionFormSheetState extends ConsumerState<TransactionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _merchantController;
  String? _categoryId;
  // True until the user explicitly picks a category themselves — while
  // true, a matching rule is free to keep updating the auto-picked category
  // as they keep typing the merchant name.
  bool _categoryIsAutoPicked = true;
  String _type = 'debit';
  late DateTime _date;
  late bool _isInternational;
  late bool _isTransfer;
  bool _paidInCash = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final prefill = widget.prefill;
    final startAmount = existing?.amountMinor ?? prefill?.amountMinor;
    _amountController = TextEditingController(
      text: startAmount == null ? '' : (startAmount / 100).toStringAsFixed(2),
    );
    _merchantController = TextEditingController(
      text: existing?.merchant ?? prefill?.merchant ?? '',
    )..addListener(_tryAutoCategorize);
    _categoryId = existing?.categoryId;
    _categoryIsAutoPicked = existing == null;
    _type = existing?.type ?? prefill?.type ?? 'debit';
    _date = existing?.date ?? prefill?.date ?? DateTime.now();
    _isInternational = existing?.isInternational ?? false;
    _isTransfer = existing?.kind == 'transfer';
  }

  void _tryAutoCategorize() {
    if (!_categoryIsAutoPicked) return;
    final rules = ref.read(rulesProvider).value ?? const [];
    final merchant = _merchantController.text.trim();
    if (merchant.isEmpty) return;
    final match =
        matchCategoryForMerchant(merchant, rules) ??
        defaultCategoryFor(merchant, isCredit: _type == 'credit');
    if (match != null && match != _categoryId) {
      setState(() => _categoryId = match);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pick a category first')));
      return;
    }

    final amountMinor = (double.parse(_amountController.text.trim()) * 100)
        .round();
    final repo = ref.read(transactionsRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final accountId = _paidInCash ? await repo.cashAccountId() : null;

    if (widget.existing == null) {
      await repo.addManualTransaction(
        amountMinor: amountMinor,
        merchant: _merchantController.text.trim(),
        categoryId: _categoryId!,
        type: _type,
        date: _date,
        isInternational: _isInternational,
        accountId: accountId,
        isTransfer: _isTransfer,
      );
    } else {
      final renamed = await repo.updateTransaction(
        widget.existing!.id,
        amountMinor: amountMinor,
        merchant: _merchantController.text.trim(),
        categoryId: _categoryId!,
        type: _type,
        date: _date,
        isInternational: _isInternational,
        accountId: accountId,
        isTransfer: _isTransfer,
      );
      if (renamed > 0) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Also updated $renamed similar transaction${renamed == 1 ? '' : 's'}',
            ),
          ),
        );
      }
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final repo = ref.read(transactionsRepositoryProvider);
    await repo.softDelete(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final isEditing = widget.existing != null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          // Keeps the dialog from stretching edge-to-edge on wide/foldable screens.
          constraints: const BoxConstraints(maxWidth: 480),
          child: GlassCard(
            borderRadius: 28,
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isEditing ? 'Edit transaction' : 'Add transaction',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'debit', label: Text('Spent')),
                        ButtonSegment(value: 'credit', label: Text('Received')),
                      ],
                      selected: {_type},
                      onSelectionChanged: (s) =>
                          setState(() => _type = s.first),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Amount (₹)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final parsed = double.tryParse((value ?? '').trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _merchantController,
                      decoration: const InputDecoration(
                        labelText: 'Merchant / description',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    categoriesAsync.when(
                      data: (categories) => DropdownButtonFormField<String>(
                        initialValue: _categoryId,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final c in categories)
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                        ],
                        onChanged: (value) => setState(() {
                          _categoryId = value;
                          _categoryIsAutoPicked = false;
                        }),
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Could not load categories: $e'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(DateFormat.yMMMd().format(_date)),
                    ),
                    GlassSwitchRow(
                      label: 'International transaction',
                      value: _isInternational,
                      onChanged: (v) => setState(() => _isInternational = v),
                    ),
                    GlassSwitchRow(
                      label: 'Transfer between my own accounts',
                      value: _isTransfer,
                      onChanged: (v) => setState(() => _isTransfer = v),
                    ),
                    if (!isEditing && _type == 'debit')
                      GlassSwitchRow(
                        label: 'Paid in cash',
                        value: _paidInCash,
                        onChanged: (v) => setState(() => _paidInCash = v),
                      ),
                    if (isEditing && _type == 'debit')
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () =>
                              showSplitSheet(context, widget.existing!),
                          icon: const Icon(Icons.call_split_rounded),
                          label: const Text('Split with others'),
                        ),
                      ),
                    const SizedBox(height: 20),
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
                          flex: 2,
                          child: FilledButton(
                            onPressed: _submit,
                            child: Text(
                              isEditing ? 'Save changes' : 'Add transaction',
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isEditing) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _delete,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                        style: dangerTextButtonStyle(context),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
