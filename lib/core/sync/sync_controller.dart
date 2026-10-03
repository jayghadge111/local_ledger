import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../email/email_providers.dart';
import '../email/gmail_import_service.dart';
import '../import_progress.dart';
import '../sms/sms_import_service.dart';
import '../sms/sms_providers.dart';
import '../ui/root_messenger.dart';

enum SyncStatus { idle, running, succeeded, failed }

/// One import (Gmail or SMS): what it's doing now, or how the last run ended.
class SyncJob {
  const SyncJob({this.status = SyncStatus.idle, this.progress, this.message});

  final SyncStatus status;
  final ImportProgress? progress;

  /// The outcome of the last run, shown on the settings card.
  final String? message;

  bool get running => status == SyncStatus.running;
  bool get failed => status == SyncStatus.failed;
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

String describeGmailResult(EmailImportResult r) {
  if (r.imported > 0) {
    return 'Done — added ${r.imported} transaction${r.imported == 1 ? '' : 's'} '
        'from ${r.scanned} bank email${r.scanned == 1 ? '' : 's'}.'
        '${r.queued > 0 ? ' ${r.queued} need your review (Manage tab).' : ''}';
  }
  if (r.scanned == 0) {
    return 'Connected. No bank emails found in the last year.';
  }
  final reasons = [
    if (r.duplicates > 0) '${r.duplicates} already in the app',
    if (r.queued > 0) '${r.queued} need your review (Manage tab)',
    if (r.notRecognised > 0) "${r.notRecognised} weren't transaction alerts",
    if (r.unreadable > 0) "${r.unreadable} couldn't be read",
  ];
  return 'Connected. Checked ${r.scanned} emails, added none'
      '${reasons.isEmpty ? '.' : ': ${reasons.join(', ')}.'}';
}

String describeSmsResult(SmsImportResult r) {
  final review = r.queued > 0
      ? ' ${r.queued} need your review (Manage tab).'
      : '';
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
class SyncController extends Notifier<SyncState> {
  bool _smsBusy = false;

  @override
  SyncState build() => const SyncState();

  void _setGmail(SyncJob job) => state = state.copyWith(gmail: job);
  void _setSms(SyncJob job) => state = state.copyWith(sms: job);

  // ---- Gmail ----

  /// Shows "Connected as …" if Google still has a session. Never imports.
  Future<void> restoreGmailAccount() async {
    if (state.gmailAccount != null) return;
    try {
      final account = await ref.read(gmailAuthServiceProvider).currentAccount();
      if (account != null) state = state.copyWith(gmailAccount: account.email);
    } catch (_) {}
  }

  /// [fresh]: the user asked to connect / switch account, so Google must show
  /// its account chooser instead of silently reusing the last account.
  Future<void> startGmail({required bool fresh}) async {
    if (state.gmail.running) return;
    _setGmail(
      const SyncJob(
        status: SyncStatus.running,
        progress: ImportProgress('Signing in to Google…'),
      ),
    );
    try {
      final auth = ref.read(gmailAuthServiceProvider);
      final account = fresh
          ? await auth.signInFresh()
          : (await auth.currentAccount() ?? await auth.signInFresh());
      state = state.copyWith(gmailAccount: account.email);

      final result = await ref
          .read(gmailImportServiceProvider)
          .importRecent(
            account: account,
            onProgress: (p) =>
                _setGmail(SyncJob(status: SyncStatus.running, progress: p)),
          );
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
    } catch (e) {
      if (e is GoogleSignInException &&
          e.code == GoogleSignInExceptionCode.canceled) {
        _setGmail(const SyncJob(message: 'Sign-in was cancelled.'));
        return;
      }
      _setGmail(
        SyncJob(status: SyncStatus.failed, message: 'Gmail import failed: $e'),
      );
      showRootSnackBar('Gmail sync failed — open Settings for details');
    }
  }

  Future<void> disconnectGmail() async {
    try {
      await ref.read(gmailAuthServiceProvider).disconnect();
    } catch (_) {}
    state = state.copyWith(
      clearAccount: true,
      gmail: const SyncJob(
        message:
            'Disconnected. LocalLedger can no longer read this Gmail account.',
      ),
    );
  }

  // ---- SMS ----

  /// The "Scan SMS inbox" button: asks for permission, then reads the whole
  /// 1-year window.
  Future<void> startSms() async {
    if (_smsBusy) return;
    final service = ref.read(smsImportServiceProvider);
    if (!await service.requestPermission()) {
      _setSms(
        const SyncJob(
          status: SyncStatus.failed,
          message: 'SMS permission was not granted, so nothing was scanned. You can allow it later in Settings.',
        ),
      );
      return;
    }
    _smsBusy = true;
    _setSms(
      const SyncJob(
        status: SyncStatus.running,
        progress: ImportProgress('Reading your messages…'),
      ),
    );
    try {
      final result = await service.importFromInbox(
        onProgress: (p) =>
            _setSms(SyncJob(status: SyncStatus.running, progress: p)),
      );
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
    } catch (e) {
      _setSms(
        SyncJob(status: SyncStatus.failed, message: 'SMS scan failed: $e'),
      );
      showRootSnackBar('SMS sync failed — open Settings for details');
    } finally {
      _smsBusy = false;
    }
  }

  /// Quiet catch-up on app open/resume. Shows the banner only if it actually
  /// runs, and only announces the end if it found something.
  Future<void> syncSmsIfDue() async {
    if (_smsBusy) return;
    final service = ref.read(smsImportServiceProvider);
    _smsBusy = true;
    try {
      final result = await service.syncIfDue(
        onProgress: (p) =>
            _setSms(SyncJob(status: SyncStatus.running, progress: p)),
      );
      if (result == null) {
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
    } catch (e) {
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
