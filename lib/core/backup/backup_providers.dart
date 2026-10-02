import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/providers.dart';
import '../security/encryption_providers.dart';
import 'backup_service.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(databaseProvider), ref.watch(encryptionServiceProvider));
});
