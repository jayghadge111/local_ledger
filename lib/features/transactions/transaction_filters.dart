import 'package:flutter/material.dart';

import '../../core/db/app_database.dart';
import '../../shared/widgets/glass_surface.dart';

/// What the Transactions list is narrowed to besides the search text.
class TransactionFilters {
  const TransactionFilters({this.categoryId, this.type});

  final String? categoryId;

  /// 'debit' | 'credit' | null for both.
  final String? type;

  int get activeCount => (categoryId == null ? 0 : 1) + (type == null ? 0 : 1);
  bool get isActive => activeCount > 0;

  TransactionFilters copyWith({
    String? categoryId,
    String? type,
    bool clearCategory = false,
    bool clearType = false,
  }) {
    return TransactionFilters(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      type: clearType ? null : (type ?? this.type),
    );
  }

  bool matches(Transaction t) {
    if (categoryId != null && t.categoryId != categoryId) return false;
    if (type != null && t.type != type) return false;
    return true;
  }
}

/// Opens the filter panel, sliding down from the top of the screen. Returns
/// the chosen filters, or null if it was closed without applying.
Future<TransactionFilters?> showTransactionFilterSheet(
  BuildContext context, {
  required TransactionFilters current,
  required List<Category> categories,
}) {
  return showGeneralDialog<TransactionFilters>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close filters',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, _, _) =>
        _FilterPanel(current: current, categories: categories),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
}

class _FilterPanel extends StatefulWidget {
  const _FilterPanel({required this.current, required this.categories});

  final TransactionFilters current;
  final List<Category> categories;

  @override
  State<_FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<_FilterPanel> {
  late TransactionFilters _draft = widget.current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.topCenter,
      child: Material(
        type: MaterialType.transparency,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: GlassCard(
                borderRadius: 28,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Filters',
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Only the choices scroll; Reset / Apply stay in view.
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Type', style: theme.textTheme.labelLarge),
                            const SizedBox(height: 8),
                            SegmentedButton<String?>(
                              showSelectedIcon: false,
                              segments: const [
                                ButtonSegment(value: null, label: Text('All')),
                                ButtonSegment(
                                  value: 'debit',
                                  label: Text('Spent'),
                                ),
                                ButtonSegment(
                                  value: 'credit',
                                  label: Text('Received'),
                                ),
                              ],
                              selected: {_draft.type},
                              onSelectionChanged: (s) => setState(
                                () => _draft = s.first == null
                                    ? _draft.copyWith(clearType: true)
                                    : _draft.copyWith(type: s.first),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text('Category', style: theme.textTheme.labelLarge),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ChoiceChip(
                                  label: const Text('All'),
                                  selected: _draft.categoryId == null,
                                  onSelected: (_) => setState(
                                    () => _draft = _draft.copyWith(
                                      clearCategory: true,
                                    ),
                                  ),
                                ),
                                for (final c in widget.categories)
                                  ChoiceChip(
                                    label: Text(c.name),
                                    selected: _draft.categoryId == c.id,
                                    onSelected: (_) => setState(
                                      () => _draft = _draft.copyWith(
                                        categoryId: c.id,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _draft.isActive
                                ? () => setState(
                                    () => _draft = const TransactionFilters(),
                                  )
                                : null,
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: () => Navigator.of(context).pop(_draft),
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
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
