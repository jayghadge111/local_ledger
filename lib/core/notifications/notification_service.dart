import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Local-only notification scheduling for recurring-payment reminders.
/// Nothing here ever touches the network — notifications are computed and
/// scheduled entirely on-device from data already in the local database.
class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _initFuture;

  /// Safe to call from several places at once (the Alerts screen and the
  /// budget watcher both do): they all share one initialisation, so the
  /// system permission dialog is requested exactly once.
  Future<void> init() => _initFuture ??= _init();

  Future<void> _init() async {
    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Fall back to whatever `package:timezone` defaults to (UTC) rather
      // than failing to initialize notifications entirely.
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
    // Declining, or the platform refusing, must never break the app: the
    // notifications are a nicety and the in-app alerts still show.
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
    }
  }

  /// Runs a notification call so that a platform error is logged, not thrown
  /// into whatever screen or watcher asked for it.
  Future<void> _safely(String what, Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('Notification $what failed: $e');
    }
  }

  /// Schedules (or reschedules, since the id is stable per merchant) a
  /// reminder two days before a recurring payment is expected.
  Future<void> scheduleRecurringReminder({
    required int id,
    required String merchant,
    required DateTime dueDate,
    required String amountLabel,
  }) async {
    final reminderDate = dueDate.subtract(const Duration(days: 2));
    if (reminderDate.isBefore(DateTime.now())) return;

    await _safely(
      'reminder',
      () => _plugin.zonedSchedule(
        id: id,
        title: 'Upcoming payment: $merchant',
        body: '$amountLabel due around ${_formatDate(dueDate)}',
        scheduledDate: tz.TZDateTime.from(reminderDate, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'recurring_payments',
            'Recurring payment reminders',
            channelDescription: 'Reminders for bills that repeat on a schedule',
            importance: Importance.defaultImportance,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      ),
    );
  }

  static const _alertDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'money_alerts',
      'Budget and lending alerts',
      channelDescription:
          'Over-budget warnings and reminders about money lent or borrowed',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Shows a notification right now (budget alerts).
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    await _safely('show', () async {
      await init();
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _alertDetails,
      );
    });
  }

  /// Schedules a notification for [when]; does nothing if that time has passed.
  /// Re-using an [id] replaces the earlier schedule.
  Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    if (!when.isAfter(DateTime.now())) return;
    await _safely('schedule', () async {
      await init();
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(when, tz.local),
        notificationDetails: _alertDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    });
  }

  Future<void> cancel(int id) =>
      _safely('cancel', () => _plugin.cancel(id: id));

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
