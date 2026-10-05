import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/providers.dart';
import '../security/encryption_providers.dart';
import 'reconciler.dart';
import 'transaction_ingestor.dart';

final ingestorProvider = Provider<TransactionIngestor>((ref) {
  return TransactionIngestor(
    ref.watch(databaseProvider),
    ref.watch(encryptionServiceProvider),
  );
});

final reconcilerProvider = Provider<Reconciler>(
  (ref) => Reconciler(ref.watch(databaseProvider)),
);
