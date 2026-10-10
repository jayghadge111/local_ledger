import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/diagnostics/app_guard.dart';

Future<void> main() => runGuarded(
  () => const ProviderScope(child: TrueLedgerApp()),
);
