import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/settings_repository.dart';
import 'rules_manager.dart';

/// What the Settings card shows.
class RulesUiState {
  const RulesUiState({
    required this.status,
    this.checking = false,
    this.message,
    this.lastChecked,
  });

  final RulesStatus status;
  final bool checking;

  /// How the last check or action ended, in a sentence.
  final String? message;
  final DateTime? lastChecked;

  RulesUiState copyWith({
    RulesStatus? status,
    bool? checking,
    String? message,
    DateTime? lastChecked,
    bool clearMessage = false,
  }) => RulesUiState(
    status: status ?? this.status,
    checking: checking ?? this.checking,
    message: clearMessage ? null : (message ?? this.message),
    lastChecked: lastChecked ?? this.lastChecked,
  );
}

const _autoCheckEvery = Duration(hours: 24);

final rulesControllerProvider = NotifierProvider<RulesController, RulesUiState>(
  RulesController.new,
);

class RulesController extends Notifier<RulesUiState> {
  RulesManager? get _manager => RulesManager.instance;

  @override
  RulesUiState build() {
    final manager = _manager;
    return RulesUiState(
      status:
          manager?.status() ??
          const RulesStatus(packVersion: 0, updated: false, canRollBack: false),
    );
  }

  SettingsRepository get _settings => ref.read(settingsRepositoryProvider);

  /// Checks now, whatever the schedule.
  Future<void> checkNow() async {
    final manager = _manager;
    if (manager == null || state.checking) return;
    state = state.copyWith(checking: true, clearMessage: true);
    final result = await manager.checkForUpdate();
    final now = DateTime.now();
    if (result is! RulesOffline) {
      await _settings.set(SettingsKeys.rulesLastChecked, now.toIso8601String());
    }
    if (!ref.mounted) return;
    state = state.copyWith(
      checking: false,
      status: manager.status(),
      lastChecked: now,
      message: switch (result) {
        RulesUpdated(:final packVersion) =>
          'Updated to version $packVersion.',
        RulesUpToDate() => 'You have the latest rules.',
        RulesOffline() => 'No internet connection. Try again later.',
        RulesRejected(:final reason) =>
          "An update was found but wasn't used ($reason). Nothing changed.",
      },
    );
  }

  /// The quiet daily check, if the user allows it.
  Future<void> maybeCheck() async {
    final manager = _manager;
    if (manager == null || state.checking) return;
    final raw = await _settings.get(SettingsKeys.rulesLastChecked);
    final last = raw == null ? null : DateTime.tryParse(raw);
    if (last != null && DateTime.now().difference(last) < _autoCheckEvery) {
      return;
    }
    await checkNow();
  }

  Future<void> rollBack() async {
    final manager = _manager;
    if (manager == null) return;
    final status = await manager.rollBack();
    if (!ref.mounted) return;
    state = state.copyWith(
      status: status,
      message: 'Went back to version ${status.packVersion}.',
    );
  }

  void useBuiltIn() {
    final manager = _manager;
    if (manager == null) return;
    state = state.copyWith(
      status: manager.useBuiltIn(),
      message: 'Using the rules built into the app.',
    );
  }
}
