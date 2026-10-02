import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/providers.dart';
import '../security/encryption_providers.dart';
import 'sms_import_service.dart';

final smsImportServiceProvider = Provider<SmsImportService>((ref) {
  return SmsImportService(ref.watch(databaseProvider), ref.watch(encryptionServiceProvider));
});
