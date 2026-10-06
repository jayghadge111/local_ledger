import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/db/providers.dart';
import '../../shared/widgets/fade_slide_in.dart';
import '../../shared/widgets/glass_surface.dart';
import '../../shared/widgets/placeholder_body.dart';
import '../../shared/widgets/shimmer.dart';
import '../calendar/calendar_screen.dart';
import 'transaction_detail_sheet.dart';
import 'transaction_filters.dart';
import 'transaction_form_sheet.dart';
import 'widgets/transaction_tile.dart';

/// How many rows are built up front, and how many more each time the user
/// reaches the end of what's loaded.
const kFirstPage = 40;
const kNextPage = 30;

/// How long the placeholder rows show before the next page appears, so a
/// fast scroll lands on shimmer instead of a blank gap.
const kPageDelay = Duration(milliseconds: 280);

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchController = TextEditingController();
  final _scroll = ScrollController();
  String _query = '';
  TransactionFilters _filters = const TransactionFilters();

  int _visible = kFirstPage;
  bool _loadingMore = false;
  Timer? _pageTimer;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _pageTimer?.cancel();
    _scroll.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final nearEnd = _scroll.position.extentAfter < 900;
    if (nearEnd && !_loadingMore) _loadMore();
  }

  void _loadMore() {
    setState(() => _loadingMore = true);
    _pageTimer?.cancel();
    _pageTimer = Timer(kPageDelay, () {
      if (!mounted) return;
      setState(() {
        _visible += kNextPage;
        _loadingMore = false;
      });
    });
  }

  void _resetPaging() {
    _pageTimer?.cancel();
    _visible = kFirstPage;
    _loadingMore = false;
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _openFilters(List<Category> categories) async {
    final result = await showTransactionFilterSheet(
      context,
      current: _filters,
      categories: categories,
    );
    if (result != null && mounted) {
      setState(() {
        _filters = result;
        _resetPaging();
      });
    }
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

          final query = _query.trim().toLowerCase();
          final filtered = allTransactions.where((t) {
            if (query.isNotEmpty && !t.merchant.toLowerCase().contains(query)) {
              return false;
            }
            return _filters.matches(t);
          }).toList();

          final shown = filtered.length < _visible ? filtered.length : _visible;
          final hasMore = shown < filtered.length;
          // While more rows exist, a few shimmering placeholders sit at the
          // end — the user sees them as soon as they outrun the loaded rows.
          final skeletons = hasMore ? 3 : 0;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: _SearchBar(
                  controller: _searchController,
                  filters: _filters,
                  categoriesById: categoriesById,
                  onQueryChanged: (v) => setState(() {
                    _query = v;
                    _resetPaging();
                  }),
                  onOpenFilters: () => _openFilters(categories),
                  onClearCategory: () => setState(() {
                    _filters = _filters.copyWith(clearCategory: true);
                    _resetPaging();
                  }),
                  onClearType: () => setState(() {
                    _filters = _filters.copyWith(clearType: true);
                    _resetPaging();
                  }),
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
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                        itemCount: shown + skeletons,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          if (index >= shown) {
                            return TransactionTileSkeleton(variant: index);
                          }
                          final transaction = filtered[index];
                          final tile = TransactionTile(
                            transaction: transaction,
                            category: categoriesById[transaction.categoryId],
                            onTap: () =>
                                showTransactionDetail(context, transaction),
                          );
                          // Only the first screenful animates in; rows built
                          // while scrolling must be visible straight away.
                          return index < 12
                              ? FadeSlideIn(
                                  delay: Duration(milliseconds: 35 * index),
                                  child: tile,
                                )
                              : tile;
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: _SearchBarSkeleton(),
            ),
            Expanded(child: TransactionListSkeleton()),
          ],
        ),
        error: (error, _) =>
            Center(child: Text('Could not load transactions: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add transaction',
        onPressed: () => showTransactionFormSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SearchBarSkeleton extends StatelessWidget {
  const _SearchBarSkeleton();

  @override
  Widget build(BuildContext context) {
    return const GlassCard(
      borderRadius: 20,
      padding: EdgeInsets.all(14),
      child: Shimmer(
        child: SizedBox(
          height: 26,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Search box with a filter button beside it; active filters show below as
/// removable chips.
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.filters,
    required this.categoriesById,
    required this.onQueryChanged,
    required this.onOpenFilters,
    required this.onClearCategory,
    required this.onClearType,
  });

  final TextEditingController controller;
  final TransactionFilters filters;
  final Map<String, Category> categoriesById;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onOpenFilters;
  final VoidCallback onClearCategory;
  final VoidCallback onClearType;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      borderRadius: 20,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onQueryChanged,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search merchant',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: controller.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
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
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Calendar',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CalendarScreen()),
                ),
                icon: const Icon(Icons.calendar_month_outlined),
              ),
              Badge(
                isLabelVisible: filters.isActive,
                label: Text('${filters.activeCount}'),
                backgroundColor: scheme.primary,
                textColor: scheme.onPrimary,
                child: IconButton(
                  tooltip: 'Filters',
                  onPressed: onOpenFilters,
                  icon: Icon(
                    filters.isActive
                        ? Icons.filter_alt_rounded
                        : Icons.filter_alt_outlined,
                  ),
                ),
              ),
            ],
          ),
          if (filters.isActive) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (filters.type != null)
                    InputChip(
                      label: Text(
                        filters.type == 'debit' ? 'Spent' : 'Received',
                      ),
                      onDeleted: onClearType,
                      visualDensity: VisualDensity.compact,
                    ),
                  if (filters.categoryId != null)
                    InputChip(
                      label: Text(
                        categoriesById[filters.categoryId]?.name ?? 'Category',
                      ),
                      onDeleted: onClearCategory,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
