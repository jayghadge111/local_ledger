import 'dart:async';
import 'dart:io';

import 'package:in_app_update/in_app_update.dart';

/// A newer version of the app that can be installed.
class UpdateOffer {
  const UpdateOffer({
    required this.label,
    this.priority = 0,
    this.simulated = false,
  });

  /// Shown to the user, e.g. "Version 1.4.0" or "Build 42".
  final String label;

  /// 0–5, as set when the release is published. 4 and 5 are "important":
  /// the banner can't be dismissed.
  final int priority;

  /// A made-up offer used to test the flow in debug builds.
  final bool simulated;

  bool get isImportant => priority >= 4;
}

sealed class UpdateEvent {
  const UpdateEvent();
}

/// The download is under way. [fraction] is 0–1, or null when the platform
/// doesn't say how far along it is (Google Play's flexible updates don't).
class UpdateProgress extends UpdateEvent {
  const UpdateProgress(this.fraction);
  final double? fraction;
}

/// The download finished; installing restarts the app.
class UpdateDownloaded extends UpdateEvent {
  const UpdateDownloaded();
}

class UpdateFailed extends UpdateEvent {
  const UpdateFailed(this.message);
  final String message;
}

/// The user declined or cancelled in the system dialog.
class UpdateCancelled extends UpdateEvent {
  const UpdateCancelled();
}

/// Where updates come from. On Android that is Google Play's in-app update
/// API; a stand-in is used to try the flow in debug builds.
abstract class AppUpdateService {
  /// The available update, or null if the app is current (or this install
  /// can't be updated, e.g. a build that didn't come from Google Play).
  Future<UpdateOffer?> check();

  /// Downloads the update, reporting progress.
  Stream<UpdateEvent> download();

  /// Installs a downloaded update. The app restarts.
  Future<void> install();
}

/// Google Play flexible updates: the download happens in the background
/// inside Play, while TrueLedger shows its progress, then the user chooses
/// when to restart.
///
/// Only works for an install that came from Google Play, so it cannot be
/// exercised from a local build — see [SimulatedAppUpdateService].
class PlayAppUpdateService implements AppUpdateService {
  @override
  Future<UpdateOffer?> check() async {
    if (!Platform.isAndroid) return null;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable ||
          !info.flexibleUpdateAllowed) {
        return null;
      }
      final code = info.availableVersionCode;
      return UpdateOffer(
        label: code == null ? 'New version' : 'Build $code',
        priority: info.updatePriority,
      );
    } catch (_) {
      // Not installed from Play, no Play services, offline… nothing to offer.
      return null;
    }
  }

  @override
  Stream<UpdateEvent> download() {
    final controller = StreamController<UpdateEvent>();
    StreamSubscription<InstallStatus>? sub;

    Future<void> run() async {
      sub = InAppUpdate.installUpdateListener.listen((status) {
        switch (status) {
          case InstallStatus.pending:
          case InstallStatus.downloading:
            controller.add(
              const UpdateProgress(null),
            ); // Play reports no percentage
          case InstallStatus.downloaded:
            controller.add(const UpdateDownloaded());
            controller.close();
          case InstallStatus.failed:
            controller.add(
              const UpdateFailed(
                'The download failed. Check your connection and try again.',
              ),
            );
            controller.close();
          case InstallStatus.canceled:
            controller.add(const UpdateCancelled());
            controller.close();
          default:
            break;
        }
      });
      try {
        final result = await InAppUpdate.startFlexibleUpdate();
        if (result == AppUpdateResult.userDeniedUpdate) {
          controller.add(const UpdateCancelled());
          await controller.close();
        } else if (result == AppUpdateResult.inAppUpdateFailed) {
          controller.add(
            const UpdateFailed('Google Play could not start the update.'),
          );
          await controller.close();
        }
      } catch (e) {
        controller.add(UpdateFailed('Could not start the update: $e'));
        await controller.close();
      }
    }

    controller.onListen = run;
    controller.onCancel = () => sub?.cancel();
    return controller.stream;
  }

  @override
  Future<void> install() => InAppUpdate.completeFlexibleUpdate();
}

/// Debug-only stand-in: a made-up update that "downloads" over a few seconds,
/// so the banner can be tried without a Google Play release.
class SimulatedAppUpdateService implements AppUpdateService {
  SimulatedAppUpdateService({
    this.withProgress = true,
    this.failAtFraction,
    this.duration = const Duration(seconds: 6),
  });

  /// Report percentages (like a normal download) rather than only "downloading"
  /// (like Play's flexible updates).
  final bool withProgress;

  /// Fail once the download reaches this point (0–1); null = never.
  final double? failAtFraction;
  final Duration duration;

  @override
  Future<UpdateOffer?> check() async =>
      const UpdateOffer(label: 'Version 9.9.9 (test)', simulated: true);

  @override
  Stream<UpdateEvent> download() async* {
    const steps = 30;
    final tick = Duration(milliseconds: duration.inMilliseconds ~/ steps);
    for (var i = 1; i <= steps; i++) {
      await Future<void>.delayed(tick);
      final fraction = i / steps;
      if (failAtFraction != null && fraction >= failAtFraction!) {
        yield const UpdateFailed('Simulated failure — tap Retry.');
        return;
      }
      yield UpdateProgress(withProgress ? fraction : null);
    }
    yield const UpdateDownloaded();
  }

  @override
  Future<void> install() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
  }
}
