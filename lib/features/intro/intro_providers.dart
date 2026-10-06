import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/settings_repository.dart';

/// True for a fresh install that hasn't yet been shown the walkthrough of the
/// five sections (set when onboarding finishes, cleared once the tour ends).
final introTourPendingProvider = StreamProvider<bool>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watch(SettingsKeys.introTourPending)
      .map((v) => v == 'true'),
);

/// Marks the tour as seen so it never comes back.
Future<void> markIntroTourSeen(WidgetRef ref) => ref
    .read(settingsRepositoryProvider)
    .set(SettingsKeys.introTourPending, 'false');
