import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'encryption_service.dart';

final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  return EncryptionService();
});
