import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/db/providers.dart';
import '../../shared/widgets/fade_slide_in.dart';
import '../../shared/widgets/glass_surface.dart';
import '../../shared/widgets/placeholder_body.dart';
import 'transaction_detail_sheet.dart';
import 'transaction_form_sheet.dart';
import 'widgets/transaction_tile.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _categoryFilter;
  String? _typeFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.value ?? <Category>[];
    final categoriesById = {for (final c in categories) c.id: c};

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: transactionsAsync.when(
        data: (allTransactions) {
          if (allTransactions.isEmpty) {
            return const PlaceholderBody(
              icon: Icons.receipt_long_outlined,
              title: 'No transactions yet',
              subtitle: 'Tap the + button to add your first one manually.',
            );
          }

          final filtered = allTransactions.where((t) {
            if (_query.isNotEmpty &&
                !t.merchant.toLowerCase().contains(_query.toLowerCase())) {
              return false;
            }
            if (_categoryFilter != null && t.categoryId != _categoryFilter) {
              return false;
            }
            if (_typeFilter != null && t.type != _typeFilter) {
              return false;
            }
            return true;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: _FilterBar(
                  controller: _searchController,
                  onQueryChanged: (v) => setState(() => _query = v),
                  categories: categories,
                  categoryFilter: _categoryFilter,
                  onCategoryChanged: (v) => setState(() => _categoryFilter = v),
                  typeFilter: _typeFilter,
                  onTypeChanged: (v) => setState(() => _typeFilter = v),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const PlaceholderBody(
                        icon: Icons.search_off,
                        title: 'No matches',
                        subtitle:
                            'Try a different search or clear the filters.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final transaction = filtered[index];
                          return FadeSlideIn(
                            delay: Duration(
                              milliseconds: 35 * index.clamp(0, 12),
                            ),
                            child: TransactionTile(
                              transaction: transaction,
                              category: categoriesById[transaction.categoryId],
                              onTap: () =>
                                  showTransactionDetail(context, transaction),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load transactions: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showTransactionFormSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.controller,
    required this.onQueryChanged,
    required this.categories,
    required this.categoryFilter,
    required this.onCategoryChanged,
    required this.typeFilter,
    required this.onTypeChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onQueryChanged;
  final List<Category> categories;
  final String? categoryFilter;
  final ValueChanged<String?> onCategoryChanged;
  final String? typeFilter;
  final ValueChanged<String?> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      borderRadius: 20,
      child: Column(
        children: [
          TextField(
            controller: controller,
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search merchant',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        controller.clear();
                        onQueryChanged('');
                      },
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: categoryFilter,
                  isExpanded: true,
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    for (final c in categories)
                      DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: onCategoryChanged,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: typeFilter,
                  isExpanded: true,
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: 'Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(value: 'debit', child: Text('Spent')),
                    DropdownMenuItem(value: 'credit', child: Text('Received')),
                  ],
                  onChanged: onTypeChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
