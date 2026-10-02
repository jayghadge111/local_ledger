import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/providers.dart';
import '../security/encryption_providers.dart';
import 'gmail_auth_service.dart';
import 'gmail_import_service.dart';

final gmailAuthServiceProvider = Provider<GmailAuthService>((ref) => GmailAuthService());

final gmailImportServiceProvider = Provider<GmailImportService>((ref) {
  return GmailImportService(
    ref.watch(databaseProvider),
    ref.watch(encryptionServiceProvider),
    ref.watch(gmailAuthServiceProvider),
  );
});
