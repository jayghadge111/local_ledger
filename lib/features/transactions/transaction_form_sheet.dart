import 'package:flutter/material.dart';

import '../../shared/widgets/centered_dialog_card.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/db/app_database.dart';
import '../../core/db/providers.dart';
import '../../core/db/rules_repository.dart';
import '../../core/intelligence/default_category_rules.dart';
import '../../core/lending/lending_math.dart';
import '../../core/lending/lending_repository.dart';
import '../../shared/widgets/text_button_styles.dart';
import '../../core/intelligence/rule_matcher.dart';
import '../../shared/widgets/glass_surface.dart';
import '../../shared/widgets/glass_switch_row.dart';
import '../splits/splits_ui.dart';
import '../../core/security/encryption_providers.dart';
import '../../core/sms/parser_templates.dart';
import 'transactions_repository.dart';

/// Starting values for a new transaction (e.g. from an unreadable SMS).
class TransactionPrefill {
  const TransactionPrefill({
    this.amountMinor,
    this.merchant,
    this.type,
    this.date,
    this.learnFromBody,
    this.senderCode,
  });
  final int? amountMinor;
  final String? merchant;
  final String? type;
  final DateTime? date;

  /// The message the values came from. When the user saves, the app learns
  /// this message's layout so the next one like it is read automatically.
  final String? learnFromBody;
  final String? senderCode;
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

  /// When the loan is due — asked for (and required) when the category is
  /// Lending money / Borrowing money. Same field as on the Lend & borrow page.
  DateTime? _dueDate;

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

    // Editing a transaction that already made a Lend & borrow entry: start
    // from that entry's due date.
    if (existing != null) {
      ref.read(lendingRepositoryProvider).entryForTransaction(existing.id).then(
        (entry) {
          if (mounted && entry?.dueDate != null && _dueDate == null) {
            setState(() => _dueDate = entry!.dueDate);
          }
        },
      );
    }
  }

  /// 'lent' / 'borrowed' when this transaction is a loan, else null.
  String? get _loanDirection => lendingDirectionFor(_categoryId, _type);

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _pickDueDate() async {
    final first = _day(_date);
    final start = _dueDate ?? first.add(const Duration(days: 7));
    final picked = await showDatePicker(
      context: context,
      initialDate: start.isBefore(first) ? first : start,
      firstDate: first,
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  String? _validateDueDate() {
    final due = _dueDate;
    if (due == null) return 'Due date is required for lending and borrowing';
    if (_day(due).isBefore(_day(_date))) {
      return "Due date can't be before the transaction date";
    }
    return null;
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

    final merchantText = _merchantController.text.trim();
    final lending = ref.read(lendingRepositoryProvider);
    final direction = _loanDirection;
    LendingSync loan = LendingSync.none;
    if (widget.existing == null) {
      final newId = await repo.addManualTransaction(
        amountMinor: amountMinor,
        merchant: _merchantController.text.trim(),
        categoryId: _categoryId!,
        type: _type,
        date: _date,
        isInternational: _isInternational,
        accountId: accountId,
        isTransfer: _isTransfer,
      );
      loan = await lending.syncFromTransaction(
        transactionId: newId,
        direction: direction,
        person: merchantText,
        amountMinor: amountMinor,
        date: _date,
        dueDate: _dueDate,
      );
      final body = widget.prefill?.learnFromBody;
      if (body != null) {
        await _learn(
          body: body,
          amountMinor: amountMinor,
          merchant: merchantText,
          senderCode: widget.prefill?.senderCode,
        );
      }
    } else {
      await _learnFromCorrection(
        amountMinor: amountMinor,
        merchant: merchantText,
      );
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
      loan = await lending.syncFromTransaction(
        transactionId: widget.existing!.id,
        direction: direction,
        person: merchantText,
        amountMinor: amountMinor,
        date: _date,
        dueDate: _dueDate,
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
    final loanNote = switch (loan) {
      LendingSync.created =>
        'Added to Lend & borrow — you will be reminded on the due date',
      LendingSync.keptWithPayments => 'Kept the Lend & borrow entry, since repayments are recorded against it',
      _ => null,
    };
    if (loanNote != null) {
      messenger.showSnackBar(SnackBar(content: Text(loanNote)));
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  /// Teaches the parser this message's layout. Never blocks saving.
  Future<void> _learn({
    required String body,
    required int amountMinor,
    required String merchant,
    String? senderCode,
    bool requireMerchant = false,
  }) async {
    try {
      final learned = await ref
          .read(parserTemplateStoreProvider)
          .learn(
            body: body,
            type: _type,
            amountMinor: amountMinor,
            merchant: merchant,
            senderCode: senderCode,
            requireMerchant: requireMerchant,
          );
      if (learned && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Learned this message layout — similar messages will be read automatically',
            ),
          ),
        );
      }
    } catch (_) {
      // Learning is a bonus; the edit itself must go through.
    }
  }

  /// Editing an imported transaction fixes something the parser got wrong:
  /// the payee, the direction or the amount. If so, learn from the original
  /// message.
  Future<void> _learnFromCorrection({
    required int amountMinor,
    required String merchant,
  }) async {
    final existing = widget.existing!;
    final encrypted = existing.rawTextEncrypted;
    if (encrypted == null) return;
    final changedType = _type != existing.type;
    final changedAmount = amountMinor != existing.amountMinor;
    final changedMerchant = merchant != existing.merchant;
    if (!changedType && !changedAmount && !changedMerchant) return;
    try {
      final body = await ref
          .read(encryptionServiceProvider)
          .decryptString(encrypted);
      await _learn(
        body: body,
        amountMinor: amountMinor,
        merchant: changedMerchant ? merchant : '',
        // A rename alone only teaches us something if the new name is in the message.
        requireMerchant: changedMerchant && !changedType && !changedAmount,
      );
    } catch (_) {}
  }

  Future<void> _delete() async {
    final repo = ref.read(transactionsRepositoryProvider);
    // A loan entry made from this transaction goes with it (unless
    // repayments were recorded against it).
    await ref
        .read(lendingRepositoryProvider)
        .syncFromTransaction(
          transactionId: widget.existing!.id,
          direction: null,
          person: '',
          amountMinor: 0,
          date: DateTime.now(),
        );
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
                      decoration: InputDecoration(
                        labelText: switch (_loanDirection) {
                          'lent' => 'Lent to',
                          'borrowed' => 'Borrowed from',
                          _ => 'Merchant / description',
                        },
                        border: const OutlineInputBorder(),
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
                    if (_loanDirection != null) ...[
                      const SizedBox(height: 12),
                      FormField<DateTime>(
                        validator: (_) => _validateDueDate(),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        builder: (field) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () async {
                                await _pickDueDate();
                                field.didChange(_dueDate);
                              },
                              icon: const Icon(Icons.alarm_rounded, size: 18),
                              label: Text(
                                _dueDate == null
                                    ? 'Set due date (reminder) *'
                                    : 'Due ${DateFormat('d MMM yyyy').format(_dueDate!)}',
                              ),
                              style: field.hasError
                                  ? OutlinedButton.styleFrom(
                                      foregroundColor: Theme.of(context)
                                          .colorScheme
                                          .error,
                                      side: BorderSide(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error,
                                      ),
                                    )
                                  : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 12, top: 6),
                              child: Text(
                                field.errorText ?? 'Also added to Lend & borrow, with a reminder on this date.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: field.hasError
                                          ? Theme.of(context).colorScheme.error
                                          : Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
