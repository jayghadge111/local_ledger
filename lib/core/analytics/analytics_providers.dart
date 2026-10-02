import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';
import '../db/providers.dart';
import '../db/small_repositories.dart';
import 'spend_analytics.dart';

/// Transactions as totals, charts and budgets should see them: transfers
/// removed, refunds netted, splits reduced to the user's own share.
final analyticsTransactionsProvider = Provider<List<Transaction>>((ref) {
  final all = ref.watch(transactionsProvider).value ?? const <Transaction>[];
  final others = ref.watch(othersShareByTxnProvider);
  return spendingView(all, othersShareByTxn: others);
});
