import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';
import '../db/providers.dart';
import 'anomaly_detector.dart';
import 'recurring_detector.dart';

final recurringInsightsProvider = Provider<List<RecurringInsight>>((ref) {
  final transactions = ref.watch(transactionsProvider).value ?? <Transaction>[];
  return detectRecurring(transactions);
});

final unusualTransactionsProvider = Provider<List<Transaction>>((ref) {
  final transactions = ref.watch(transactionsProvider).value ?? <Transaction>[];
  return detectUnusual(transactions);
});

final internationalTransactionsProvider = Provider<List<Transaction>>((ref) {
  final transactions = ref.watch(transactionsProvider).value ?? <Transaction>[];
  return detectInternational(transactions);
});
