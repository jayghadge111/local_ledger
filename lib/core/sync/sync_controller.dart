import 'dart:async' show TimeoutException;
import 'dart:io' show SocketException;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' show ClientException;

import '../backup/snapshot_providers.dart';
import '../diagnostics/diagnostic_log.dart';
import '../email/email_providers.dart';
import '../email/gmail_auth_service.dart' show GmailAccessException;
import '../email/gmail_import_service.dart';
import '../db/settings_repository.dart';
import '../import_progress.dart';
import '../permissions/app_permissions.dart';
import 'connectivity.dart';
import 'import_checkpoints.dart';
import '../sms/sms_import_service.dart';
import '../sms/sms_providers.dart';
import '../ui/root_messenger.dart';

enum SyncStatus { idle, running, paused, succeeded, failed }

/// One import (Gmail or SMS): what it's doing now, or how the last run ended.
class SyncJob {
  const SyncJob({
    this.status = SyncStatus.idle,
    this.progress,
    this.message,
    this.resumable = false,
    this.stopping = false,
    this.needsSettings = false,
    this.needsReconnect = false,
  });

  final SyncStatus status;
  final ImportProgress? progress;

  /// A checkpoint exists, so [SyncController.resumeGmail] / `resumeSms` can
  /// carry on instead of starting over.
  final bool resumable;

  /// The user asked to stop; waiting for the import to reach a safe point.
  final bool stopping;

  /// The outcome of the last run, shown on the settings card.
  final String? message;

  /// It failed because Google no longer accepts the saved sign-in (access
  /// removed or expired): the card offers "Reconnect Gmail".
  final bool needsReconnect;

  /// It failed because a permission is switched off for good, so the card
  /// should offer "Open settings" — asking again would do nothing.
  final bool needsSettings;

  bool get running => status == SyncStatus.running;
  bool get failed => status == SyncStatus.failed;
  bool get paused => status == SyncStatus.paused;

  /// Worth showing a "Resume" on: stopped, interrupted, or failed part-way.
  bool get canResume => resumable && !running;
}

class SyncState {
  const SyncState({
    this.gmail = const SyncJob(),
    this.sms = const SyncJob(),
    this.gmailAccount,
  });

  final SyncJob gmail;
  final SyncJob sms;

  /// The Google account Gmail import is connected as, if any.
  final String? gmailAccount;

  bool get anyRunning => gmail.running || sms.running;
  bool get anyResumable => gmail.canResume || sms.canResume;

  SyncState copyWith({
    SyncJob? gmail,
    SyncJob? sms,
    String? gmailAccount,
    bool clearAccount = false,
  }) {
    return SyncState(
      gmail: gmail ?? this.gmail,
      sms: sms ?? this.sms,
      gmailAccount: clearAccount ? null : (gmailAccount ?? this.gmailAccount),
    );
  }
}

/// During onboarding, the user may move on once running imports pass this.
const kOnboardingContinueAtPercent = 25;

/// True when nothing is running, or every running import is far enough along
/// that the rest can safely finish in the background.
bool canLeaveOnboarding(SyncState s) {
  for (final job in [s.gmail, s.sms]) {
    if (!job.running) continue;
    final f = job.progress?.fraction;
    if (f == null || f * 100 < kOnboardingContinueAtPercent) return false;
  }
  return true;
}

/// Overall progress of the slowest running import, as a whole percent.
int? syncPercent(SyncState s) {
  final fractions = [
    for (final job in [s.gmail, s.sms])
      if (job.running) job.progress?.fraction,
  ];
  if (fractions.isEmpty || fractions.contains(null)) return null;
  final lowest = fractions.whereType<double>().reduce((a, b) => a < b ? a : b);
  return (lowest * 100).floor();
}

final syncControllerProvider = NotifierProvider<SyncController, SyncState>(
  SyncController.new,
);

String _stoppedText(int added) =>
    'Stopped — ${added == 0 ? 'nothing added yet' : 'added $added so far'}. '
    'Tap Resume to carry on where it left off.';

String _dueNotices(int n) => n > 0
    ? ' $n auto-debit notice${n == 1 ? '' : 's'} saved under Auto-pay & dues.'
    : '';

String describeGmailResult(EmailImportResult r) {
  if (r.cancelled) return _stoppedText(r.imported);
  if (r.imported > 0) {
    return 'Done — added ${r.imported} transaction${r.imported == 1 ? '' : 's'} '
        'from ${r.scanned} bank email${r.scanned == 1 ? '' : 's'}.'
        '${_dueNotices(r.obligations)}'
        '${r.queued > 0 ? ' ${r.queued} need your review (Manage tab).' : ''}';
  }
  if (r.scanned == 0) {
    return 'Connected. No bank emails found in the last year.';
  }
  final reasons = [
    if (r.obligations > 0)
      '${r.obligations} auto-debit notice${r.obligations == 1 ? '' : 's'} saved under Auto-pay & dues',
    if (r.duplicates > 0) '${r.duplicates} already in the app',
    if (r.queued > 0) '${r.queued} need your review (Manage tab)',
    if (r.notRecognised > 0) "${r.notRecognised} weren't transaction alerts",
    if (r.unreadable > 0) "${r.unreadable} couldn't be read",
  ];
  return 'Connected. Checked ${r.scanned} emails, added none'
      '${reasons.isEmpty ? '.' : ': ${reasons.join(', ')}.'}';
}

String describeSmsResult(SmsImportResult r) {
  if (r.cancelled) return _stoppedText(r.imported);
  final review =
      '${_dueNotices(r.obligations)}'
      '${r.queued > 0 ? ' ${r.queued} need your review (Manage tab).' : ''}';
  return r.imported > 0
      ? 'Done — added ${r.imported} transaction${r.imported == 1 ? '' : 's'} from ${r.scanned} messages.$review'
      : 'Done — scanned ${r.scanned} messages, no new bank transactions found.$review';
}

/// Runs the Gmail and SMS imports for the whole app.
///
/// The work lives here, not in the settings cards that start it, so leaving
/// the Settings page doesn't cancel anything: the import carries on, the
/// home screen shows a live banner, the transaction lists fill in as rows
/// are stored (they watch the database), and a snackbar announces the end
/// wherever the user happens to be.
///
/// An import can be stopped, and one that was stopped — or killed with the
/// app — leaves a checkpoint, so it can be resumed rather than redone.
class SyncController extends Notifier<SyncState> {
  bool _smsBusy = false;
  ImportCancelToken? _gmailCancel;
  ImportCancelToken? _smsCancel;

  @override
  SyncState build() => const SyncState();

  CheckpointStore get _store =>
      CheckpointStore(ref.read(settingsRepositoryProvider));

  void _setGmail(SyncJob job) => state = state.copyWith(gmail: job);
  void _setSms(SyncJob job) => state = state.copyWith(sms: job);

  /// Progress update that keeps the "stopping" flag the user set.
  void _gmailProgress(ImportProgress p) => _setGmail(
    SyncJob(
      status: SyncStatus.running,
      progress: p,
      stopping: state.gmail.stopping,
    ),
  );
  void _smsProgress(ImportProgress p) => _setSms(
    SyncJob(
      status: SyncStatus.running,
      progress: p,
      stopping: state.sms.stopping,
    ),
  );

  /// On app start: if an import was cut short (stopped, or the app was
  /// killed), offer to resume it. Never resumes by itself — Gmail in
  /// particular only reads mail when the user says so.
  Future<void> checkInterrupted() async {
    if (!state.gmail.running && !state.gmail.paused) {
      final c = await _store.gmail();
      if (c != null) {
        _setGmail(
          SyncJob(
            status: SyncStatus.paused,
            resumable: true,
            progress: ImportProgress(
              'Paused',
              done: c.doneIds.length,
              total: c.total,
              found: c.found,
            ),
            message: 'Gmail sync was interrupted. Resume to carry on where it left off.',
          ),
        );
      }
    }
    if (!state.sms.running && !state.sms.paused) {
      final c = await _store.sms();
      if (c != null) {
        _setSms(
          SyncJob(
            status: SyncStatus.paused,
            resumable: true,
            progress: ImportProgress(
              'Paused',
              done: c.done,
              total: c.total,
              found: c.found,
            ),
            message: 'SMS scan was interrupted. Resume to carry on where it left off.',
          ),
        );
      }
    }
  }

  /// Gives up on a paused import: forgets the checkpoint.
  Future<void> dismissGmail() async {
    await _store.clearGmail();
    _setGmail(const SyncJob());
  }

  Future<void> dismissSms() async {
    await _store.clearSms();
    _setSms(const SyncJob());
  }

  // ---- Gmail ----

  /// Shows "Connected as …" for an account the user connected earlier. Reads
  /// only what this app saved on the device: it never contacts Google, opens
  /// an account picker, or imports anything. Connecting happens only when the
  /// user taps Connect Gmail or Scan now.
  Future<void> restoreGmailAccount() async {
    if (state.gmailAccount != null) return;
    final saved = await ref
        .read(settingsRepositoryProvider)
        .get(SettingsKeys.gmailAccount);
    if (saved != null && saved.isNotEmpty && state.gmailAccount == null) {
      state = state.copyWith(gmailAccount: saved);
    }
  }

  void stopGmail() {
    if (!state.gmail.running) return;
    _gmailCancel?.cancel();
    _setGmail(
      SyncJob(
        status: SyncStatus.running,
        progress: state.gmail.progress,
        stopping: true,
      ),
    );
  }

  Future<void> resumeGmail() => startGmail(fresh: false, resume: true);

  /// [fresh]: the user asked to connect / switch account, so Google must show
  /// its account chooser instead of silently reusing the last account.
  /// [resume]: carry on from the saved checkpoint instead of starting over.
  Future<void> startGmail({required bool fresh, bool resume = false}) async {
    if (state.gmail.running) return;
    final token = _gmailCancel = ImportCancelToken();
    _setGmail(
      SyncJob(
        status: SyncStatus.running,
        progress: state.gmail.progress != null && resume
            ? state.gmail.progress
            : const ImportProgress('Signing in to Google…'),
      ),
    );
    try {
      // Say so at once when there is no connection, instead of a spinner.
      if (!await ref.read(internetCheckProvider)()) {
        _setGmail(
          SyncJob(
            status: SyncStatus.failed,
            message: _offlineText,
            resumable: await _store.gmail() != null,
          ),
        );
        return;
      }
      if (!resume) {
        await ref.read(snapshotServiceProvider).snapshot('before-gmail-scan');
      }
      final auth = ref.read(gmailAuthServiceProvider);
      final account = fresh
          ? await auth.signInFresh()
          : (await auth.currentAccount() ?? await auth.signInFresh());
      state = state.copyWith(gmailAccount: account.email);
      await ref
          .read(settingsRepositoryProvider)
          .set(SettingsKeys.gmailAccount, account.email);

      final result = await ref
          .read(gmailImportServiceProvider)
          .importRecent(
            account: account,
            onProgress: _gmailProgress,
            cancel: token,
            resume: resume,
          );
      if (result.cancelled) {
        final c = await _store.gmail();
        _setGmail(
          SyncJob(
            status: SyncStatus.paused,
            resumable: c != null,
            progress: c == null
                ? null
                : ImportProgress(
                    'Paused',
                    done: c.doneIds.length,
                    total: c.total,
                    found: c.found,
                  ),
            message: describeGmailResult(result),
          ),
        );
        showRootSnackBar('Gmail sync stopped — you can resume it anytime');
        return;
      }
      _setGmail(
        SyncJob(
          status: SyncStatus.succeeded,
          message: describeGmailResult(result),
        ),
      );
      showRootSnackBar(
        result.imported > 0
            ? 'Gmail sync complete — added ${result.imported} transaction${result.imported == 1 ? '' : 's'}'
            : 'Gmail sync complete — nothing new to add',
      );
    } catch (e, stack) {
      if (e is GoogleSignInException &&
          e.code == GoogleSignInExceptionCode.canceled) {
        _setGmail(
          SyncJob(
            message: _signInCancelledText(e),
            resumable: await _store.gmail() != null,
          ),
        );
        return;
      }
      DiagnosticLog.instance.record('gmail', e, stack, 'importing from Gmail');
      _setGmail(
        SyncJob(
          status: SyncStatus.failed,
          message: describeGmailFailure(e),
          needsReconnect: e is GmailAccessException,
          resumable: await _store.gmail() != null,
        ),
      );
      showRootSnackBar('Gmail sync failed — open Settings for details');
    }
  }

  Future<void> disconnectGmail() async {
    try {
      await ref.read(gmailAuthServiceProvider).disconnect();
    } catch (_) {}
    await _store.clearGmail();
    await ref
        .read(settingsRepositoryProvider)
        .set(SettingsKeys.gmailAccount, '');
    state = state.copyWith(
      clearAccount: true,
      gmail: const SyncJob(
        message:
            'Disconnected. NativeSpend can no longer read this Gmail account.',
      ),
    );
  }

  // ---- SMS ----

  void stopSms() {
    if (!state.sms.running) return;
    _smsCancel?.cancel();
    _setSms(
      SyncJob(
        status: SyncStatus.running,
        progress: state.sms.progress,
        stopping: true,
      ),
    );
  }

  Future<void> resumeSms() => startSms(resume: true);

  /// The "Scan SMS inbox" button: asks for permission, then reads the whole
  /// 1-year window. [resume] continues a stopped or interrupted scan.
  Future<void> startSms({bool resume = false}) async {
    if (_smsBusy) return;
    final service = ref.read(smsImportServiceProvider);
    final permission = await service.requestPermission();
    if (permission != PermissionState.granted) {
      _setSms(_smsPermissionJob(permission));
      ref.read(permissionsProvider.notifier).refresh();
      return;
    }
    _smsBusy = true;
    final token = _smsCancel = ImportCancelToken();
    _setSms(
      SyncJob(
        status: SyncStatus.running,
        progress: resume && state.sms.progress != null
            ? state.sms.progress
            : const ImportProgress('Reading your messages…'),
      ),
    );
    try {
      // A full scan can touch thousands of rows: keep a copy to go back to.
      if (!resume) {
        await ref.read(snapshotServiceProvider).snapshot('before-sms-scan');
      }
      final result = await service.importFromInbox(
        onProgress: _smsProgress,
        cancel: token,
        resume: resume,
      );
      if (result.cancelled) {
        final c = await _store.sms();
        _setSms(
          SyncJob(
            status: SyncStatus.paused,
            resumable: c != null,
            progress: c == null
                ? null
                : ImportProgress(
                    'Paused',
                    done: c.done,
                    total: c.total,
                    found: c.found,
                  ),
            message: describeSmsResult(result),
          ),
        );
        showRootSnackBar('SMS scan stopped — you can resume it anytime');
        return;
      }
      _setSms(
        SyncJob(
          status: SyncStatus.succeeded,
          message: describeSmsResult(result),
        ),
      );
      showRootSnackBar(
        result.imported > 0
            ? 'SMS sync complete — added ${result.imported} transaction${result.imported == 1 ? '' : 's'}'
            : 'SMS sync complete — nothing new to add',
      );
      await service.listenForNewMessages(_onLiveSms);
    } catch (e, stack) {
      DiagnosticLog.instance.record('sms', e, stack, 'scanning the inbox');
      _setSms(
        SyncJob(
          status: SyncStatus.failed,
          message: 'SMS scan failed: $e',
          resumable: await _store.sms() != null,
        ),
      );
      showRootSnackBar('SMS sync failed — open Settings for details');
    } finally {
      _smsBusy = false;
    }
  }

  /// Quiet catch-up on app open/resume. Shows the banner only if it actually
  /// runs, and only announces the end if it found something.
  Future<void> syncSmsIfDue() async {
    if (_smsBusy || state.sms.paused) return;
    final service = ref.read(smsImportServiceProvider);
    _smsBusy = true;
    final token = _smsCancel = ImportCancelToken();
    try {
      final result = await service.syncIfDue(
        onProgress: _smsProgress,
        cancel: token,
      );
      if (result == null || result.cancelled) {
        if (state.sms.running) _setSms(const SyncJob());
      } else {
        _setSms(
          SyncJob(
            status: SyncStatus.succeeded,
            message: describeSmsResult(result),
          ),
        );
        _announceNewSms(result);
      }
      await service.listenForNewMessages(_onLiveSms);
    } catch (e, stack) {
      DiagnosticLog.instance.record('sms', e, stack, 'catching up on SMS');
      _setSms(
        SyncJob(status: SyncStatus.failed, message: 'SMS sync failed: $e'),
      );
    } finally {
      _smsBusy = false;
    }
  }

  void _onLiveSms(SmsImportResult result) => _announceNewSms(result);

  void _announceNewSms(SmsImportResult result) {
    if (result.imported == 0 && result.queued == 0) return;
    final parts = [
      if (result.imported > 0)
        '${result.imported} new transaction${result.imported == 1 ? '' : 's'}',
      if (result.queued > 0)
        '${result.queued} message${result.queued == 1 ? '' : 's'} to review',
    ];
    showRootSnackBar(parts.join(' · '));
  }
}

/// What to tell the user when the SMS permission isn't there.
SyncJob _smsPermissionJob(PermissionState state) => switch (state) {
  PermissionState.blocked => const SyncJob(
    status: SyncStatus.failed,
    needsSettings: true,
    message:
        'SMS access is switched off for NativeSpend, so nothing was scanned. '
        'Turn on "SMS" under Permissions in the app\'s system settings, then '
        'come back and scan again.',
  ),
  PermissionState.unavailable => const SyncJob(
    status: SyncStatus.failed,
    message: "This phone doesn't allow SMS access for NativeSpend.",
  ),
  _ => const SyncJob(
    status: SyncStatus.failed,
    message:
        'SMS permission was not granted, so nothing was scanned. Tap Scan SMS '
        'inbox to try again.',
  ),
};

const _offlineText =
    "Couldn't reach Gmail. Check your internet connection and try again — "
    'it carries on from where it stopped.';

/// A plain-words reason for a failed Gmail import, whatever threw.
String describeGmailFailure(Object error) {
  if (error is GmailAccessException) {
    return 'Google stopped letting NativeSpend read this Gmail account — '
        'access was removed or has expired. Tap Connect Gmail to sign in '
        'again. What was already read is saved.';
  }
  if (error is SocketException ||
      error is TimeoutException ||
      error is ClientException) {
    return _offlineText;
  }
  if (error is GoogleSignInException) {
    return switch (error.code) {
      GoogleSignInExceptionCode.interrupted =>
        'Google sign-in was interrupted. Please try again.',
      GoogleSignInExceptionCode.uiUnavailable =>
        "Google sign-in can't be shown right now. Bring the app to the front "
            'and try again.',
      GoogleSignInExceptionCode.providerConfigurationError
          when (error.description ?? '').toLowerCase().contains('keychain') =>
        "Google signed you in, but this device wouldn't let the app save it "
            'securely (keychain error). Try again, or restart the app.',
      GoogleSignInExceptionCode.clientConfigurationError ||
      GoogleSignInExceptionCode.providerConfigurationError =>
        "Google sign-in isn't set up correctly for this build of the app.",
      GoogleSignInExceptionCode.userMismatch =>
        'That is a different Google account from the one connected. Use '
            'Connect Gmail to switch accounts.',
      _ => 'Google sign-in failed. Please try again.',
    };
  }
  return 'Gmail import failed: $error';
}

/// Android reports a misconfigured sign-in (e.g. this build's signing
/// certificate isn't registered in Google Cloud) as "cancelled" too, usually
/// a second after an account is picked — so say so, and show Google's own
/// description when it gave one.
String _signInCancelledText(GoogleSignInException e) {
  final detail = e.description?.trim();
  return 'Sign-in was cancelled'
      '${detail == null || detail.isEmpty ? '' : ' ($detail)'}. '
      "If you didn't cancel it, this build's signing key may not be "
      'registered for Google sign-in.';
}
