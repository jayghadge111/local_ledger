import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../diagnostics/diagnostic_log.dart';

/// Where a permission stands, in the terms the UI needs to react to.
enum PermissionState {
  granted,

  /// Not allowed yet, or refused once: asking again shows the system dialog.
  denied,

  /// Refused for good (or revoked in system settings): the system won't ask
  /// again, so the only way back is the app's page in system settings.
  blocked,

  /// This device can't grant it (a parental or enterprise policy), or the
  /// platform has no such permission.
  unavailable,
}

/// The permissions the app uses.
enum AppPermission {
  sms(Permission.sms, 'SMS access'),
  notifications(Permission.notification, 'Notifications');

  const AppPermission(this.permission, this.label);
  final Permission permission;
  final String label;
}

PermissionState mapPermissionStatus(PermissionStatus status) {
  if (status.isGranted || status.isLimited || status.isProvisional) {
    return PermissionState.granted;
  }
  if (status.isPermanentlyDenied) return PermissionState.blocked;
  if (status.isRestricted) return PermissionState.unavailable;
  return PermissionState.denied;
}

/// Asks the system about permissions. Whatever the plugin does — throws, is
/// missing on this platform, returns something odd — comes back as a
/// [PermissionState] and never as an exception.
class PermissionService {
  const PermissionService();

  Future<PermissionState> status(AppPermission p) async {
    try {
      return mapPermissionStatus(await p.permission.status);
    } catch (error, stack) {
      DiagnosticLog.instance.record(
        'permission',
        error,
        stack,
        'reading ${p.name}',
      );
      return PermissionState.unavailable;
    }
  }

  /// Shows the system dialog if the system is still willing to. If the
  /// permission is already blocked this returns [PermissionState.blocked]
  /// without showing anything, so the caller can offer "Open settings".
  Future<PermissionState> request(AppPermission p) async {
    try {
      final current = await status(p);
      if (current == PermissionState.granted ||
          current == PermissionState.blocked ||
          current == PermissionState.unavailable) {
        return current;
      }
      return mapPermissionStatus(await p.permission.request());
    } catch (error, stack) {
      DiagnosticLog.instance.record(
        'permission',
        error,
        stack,
        'requesting ${p.name}',
      );
      return PermissionState.unavailable;
    }
  }

  /// Opens this app's page in system settings. False if that wasn't possible.
  Future<bool> openSettings() async {
    try {
      return await openAppSettings();
    } catch (error, stack) {
      DiagnosticLog.instance.record('permission', error, stack, 'settings');
      return false;
    }
  }
}

final permissionServiceProvider = Provider<PermissionService>(
  (ref) => const PermissionService(),
);

/// The current state of each permission, kept fresh: re-read whenever the app
/// comes back to the foreground, which is when a permission changed in system
/// settings (granted after "Open settings", or revoked) becomes visible.
final permissionsProvider =
    NotifierProvider<
      PermissionsController,
      Map<AppPermission, PermissionState>
    >(PermissionsController.new);

class PermissionsController
    extends Notifier<Map<AppPermission, PermissionState>>
    with WidgetsBindingObserver {
  @override
  Map<AppPermission, PermissionState> build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(this));
    refresh();
    return const {};
  }

  PermissionService get _service => ref.read(permissionServiceProvider);

  @override
  // ignore: avoid_renaming_method_parameters
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.resumed) refresh();
  }

  Future<void> refresh() async {
    final service = _service;
    final next = <AppPermission, PermissionState>{};
    for (final p in AppPermission.values) {
      next[p] = await service.status(p);
    }
    if (!ref.mounted) return;
    state = next;
  }

  /// Asks for [p] (system dialog if still possible) and updates [state].
  Future<PermissionState> request(AppPermission p) async {
    final service = _service;
    final result = await service.request(p);
    if (ref.mounted) state = {...state, p: result};
    return result;
  }

  Future<bool> openSettings() => _service.openSettings();
}
