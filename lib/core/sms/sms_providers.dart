import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/settings_repository.dart';
import '../ingest/ingest_providers.dart';
import 'sms_import_service.dart';

final smsImportServiceProvider = Provider<SmsImportService>((ref) {
  return SmsImportService(
    ref.watch(ingestorProvider),
    ref.watch(settingsRepositoryProvider),
  );
});
