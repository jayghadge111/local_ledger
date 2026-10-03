import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/settings_repository.dart';
import 'app_update_service.dart';

enum UpdateStage {
  none,
  available,
  downloading,
  downloaded,
  installing,
  installed,
  failed,
}

class UpdateState {
  const UpdateState({
    this.stage = UpdateStage.none,
    this.offer,
    this.progress,
    this.message,
    this.dismissed = false,
  });

  final UpdateStage stage;
  final UpdateOffer? offer;

  /// 0–1 while downloading; null when the platform doesn't report it.
  final double? progress;

  /// An error, or the outcome of a simulated install.
  final String? message;

  /// The user chose "Later" for this version.
  final bool dismissed;

  /// Whether the Home banner should be on screen.
  bool get visible =>
      stage != UpdateStage.none &&
      !(dismissed && stage == UpdateStage.available);

  UpdateState copyWith({
    UpdateStage? stage,
    UpdateOffer? offer,
    double? progress,
    bool clearProgress = false,
    String? message,
    bool? dismissed,
  }) {
    return UpdateState(
      stage: stage ?? this.stage,
      offer: offer ?? this.offer,
      progress: clearProgress ? null : (progress ?? this.progress),
      message: message,
      dismissed: dismissed ?? this.dismissed,
    );
  }
}

/// The service used for real: Google Play on an Android release build.
/// Elsewhere there is nothing to ask — iOS updates through the App Store —
/// and debug builds use the simulator (see [UpdateController.simulate]).
final appUpdateServiceProvider = Provider<AppUpdateService?>((ref) {
  if (kDebugMode) return null;
  return Platform.isAndroid ? PlayAppUpdateService() : null;
});

final updateControllerProvider =
    NotifierProvider<UpdateController, UpdateState>(UpdateController.new);

/// Looks for a newer version, downloads it while showing progress, and
/// installs it — all driven from a banner on Home.
class UpdateController extends Notifier<UpdateState> {
  static const _checkEvery = Duration(hours: 6);

  AppUpdateService? _override;
  StreamSubscription<UpdateEvent>? _download;
  DateTime? _lastCheck;

  @override
  UpdateState build() {
    ref.onDispose(() => _download?.cancel());
    return const UpdateState();
  }

  AppUpdateService? get _service =>
      _override ?? ref.read(appUpdateServiceProvider);

  bool get _busy =>
      state.stage == UpdateStage.downloading ||
      state.stage == UpdateStage.installing;

  /// Asks the store whether a newer version exists. Cheap and quiet; called
  /// when the app opens or returns to the foreground, at most every few hours.
  Future<void> check({bool force = false}) async {
    final service = _service;
    if (service == null || _busy) return;
    final now = DateTime.now();
    if (!force &&
        _lastCheck != null &&
        now.difference(_lastCheck!) < _checkEvery) {
      return;
    }
    _lastCheck = now;

    final offer = await service.check();
    if (offer == null) {
      if (state.stage == UpdateStage.available) state = const UpdateState();
      return;
    }
    // Keep a download/ready state; only (re)announce when idle.
    if (state.stage != UpdateStage.none &&
        state.stage != UpdateStage.available &&
        state.stage != UpdateStage.failed) {
      return;
    }

    final dismissed = await ref
        .read(settingsRepositoryProvider)
        .get(SettingsKeys.updateDismissedVersion);
    state = UpdateState(
      stage: UpdateStage.available,
      offer: offer,
      dismissed: dismissed == offer.label && !offer.isImportant,
    );
  }

  /// "Later": hides the banner for this version.
  Future<void> dismiss() async {
    final offer = state.offer;
    if (offer == null || offer.isImportant) return;
    await ref
        .read(settingsRepositoryProvider)
        .set(SettingsKeys.updateDismissedVersion, offer.label);
    state = state.copyWith(dismissed: true);
  }

  /// "Update": downloads inside the app, reporting progress.
  void start() {
    final service = _service;
    if (service == null || _busy || state.offer == null) return;
    state = state.copyWith(
      stage: UpdateStage.downloading,
      clearProgress: true,
      dismissed: false,
    );
    _download?.cancel();
    _download = service.download().listen(
      (event) {
        switch (event) {
          case UpdateProgress(:final fraction):
            state = state.copyWith(
              stage: UpdateStage.downloading,
              progress: fraction,
              clearProgress: fraction == null,
            );
          case UpdateDownloaded():
            state = state.copyWith(stage: UpdateStage.downloaded, progress: 1);
          case UpdateFailed(:final message):
            state = state.copyWith(
              stage: UpdateStage.failed,
              message: message,
              clearProgress: true,
            );
          case UpdateCancelled():
            state = state.copyWith(
              stage: UpdateStage.available,
              clearProgress: true,
            );
        }
      },
      onError: (Object e) => state = state.copyWith(
        stage: UpdateStage.failed,
        message: '$e',
        clearProgress: true,
      ),
    );
  }

  /// "Restart to install". On a real update the app restarts here.
  Future<void> install() async {
    final service = _service;
    if (service == null || state.stage != UpdateStage.downloaded) return;
    state = state.copyWith(stage: UpdateStage.installing);
    try {
      await service.install();
      if (state.offer?.simulated ?? false) {
        // A real install restarts the app and never gets here.
        state = state.copyWith(
          stage: UpdateStage.installed,
          message: 'Simulated: a real update would restart the app now.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        stage: UpdateStage.failed,
        message: 'Could not install the update: $e',
      );
    }
  }

  /// Retry after a failure.
  void retry() {
    if (state.stage == UpdateStage.failed) start();
  }

  /// Clears the banner (used after a simulated install).
  void clear() {
    _download?.cancel();
    state = const UpdateState();
  }

  // ---- debug-only testing ----

  /// Pretends a new version is available so the whole flow — banner, download
  /// progress, restart prompt — can be tried without a Google Play release.
  /// Does nothing outside debug builds.
  void simulate({
    bool withProgress = true,
    double? failAtFraction,
    Duration duration = const Duration(seconds: 6),
  }) {
    if (!kDebugMode) return;
    _download?.cancel();
    _override = SimulatedAppUpdateService(
      withProgress: withProgress,
      failAtFraction: failAtFraction,
      duration: duration,
    );
    state = const UpdateState(
      stage: UpdateStage.available,
      offer: UpdateOffer(label: 'Version 9.9.9 (test)', simulated: true),
    );
  }

  /// Back to the real service.
  void stopSimulating() {
    if (!kDebugMode) return;
    _override = null;
    clear();
  }
}
