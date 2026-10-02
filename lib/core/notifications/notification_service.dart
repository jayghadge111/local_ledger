import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Local-only notification scheduling for recurring-payment reminders.
/// Nothing here ever touches the network — notifications are computed and
/// scheduled entirely on-device from data already in the local database.
class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Fall back to whatever `package:timezone` defaults to (UTC) rather
      // than failing to initialize notifications entirely.
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _initialized = true;
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

    await _plugin.zonedSchedule(
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
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id: id);

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
