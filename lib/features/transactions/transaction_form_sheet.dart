import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/db/app_database.dart';
import '../../core/db/providers.dart';
import '../../core/db/rules_repository.dart';
import '../../core/intelligence/rule_matcher.dart';
import '../../shared/widgets/glass_surface.dart';
import '../../shared/widgets/glass_switch_row.dart';
import 'transactions_repository.dart';

/// Opens the add/edit transaction form as a modal sheet. Pass [existing] to
/// edit a transaction, or omit it to add a new one.
Future<void> showTransactionFormSheet(
  BuildContext context, {
  Transaction? existing,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => TransactionFormSheet(existing: existing),
  );
}

class TransactionFormSheet extends ConsumerStatefulWidget {
  const TransactionFormSheet({super.key, this.existing});

  final Transaction? existing;

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

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _amountController = TextEditingController(
      text: existing == null
          ? ''
          : (existing.amountMinor / 100).toStringAsFixed(2),
    );
    _merchantController = TextEditingController(text: existing?.merchant ?? '')
      ..addListener(_tryAutoCategorize);
    _categoryId = existing?.categoryId;
    _categoryIsAutoPicked = existing == null;
    _type = existing?.type ?? 'debit';
    _date = existing?.date ?? DateTime.now();
    _isInternational = existing?.isInternational ?? false;
  }

  void _tryAutoCategorize() {
    if (!_categoryIsAutoPicked) return;
    final rules = ref.read(rulesProvider).value ?? const [];
    final merchant = _merchantController.text.trim();
    if (merchant.isEmpty || rules.isEmpty) return;
    final match = matchCategoryForMerchant(merchant, rules);
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

    if (widget.existing == null) {
      await repo.addManualTransaction(
        amountMinor: amountMinor,
        merchant: _merchantController.text.trim(),
        categoryId: _categoryId!,
        type: _type,
        date: _date,
        isInternational: _isInternational,
      );
    } else {
      await repo.updateTransaction(
        widget.existing!.id,
        amountMinor: amountMinor,
        merchant: _merchantController.text.trim(),
        categoryId: _categoryId!,
        type: _type,
        date: _date,
        isInternational: _isInternational,
      );
    }

    if (mounted) Navigator.of(context).pop();
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
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          // Keeps the sheet from stretching edge-to-edge on wide/foldable screens.
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
                    Text(
                      isEditing ? 'Edit transaction' : 'Add transaction',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _submit,
                      child: Text(
                        isEditing ? 'Save changes' : 'Add transaction',
                      ),
                    ),
                    if (isEditing) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _delete,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
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
