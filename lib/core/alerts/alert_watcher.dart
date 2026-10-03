import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../analytics/analytics_providers.dart';
import '../analytics/budget_status.dart';
import '../db/budgets_repository.dart';
import '../db/providers.dart';
import '../db/settings_repository.dart';
import '../lending/lending_repository.dart';
import '../notifications/notification_providers.dart';
import '../notifications/notification_service.dart';
import 'budget_alerts.dart';

final _money = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

/// Watches the data while the app is open and raises local notifications:
///  * a budget reaching 80% or going over, once per category per month;
///  * reminders for money lent or borrowed, the day before and on the due day.
///
/// Everything is computed on the device from the local database.
final alertWatcherProvider = Provider<void>((ref) {
  final watcher = _AlertWatcher(ref);
  ref.listen(
    analyticsTransactionsProvider,
    (_, _) => watcher.checkBudgets(),
    fireImmediately: true,
  );
  ref.listen(budgetsProvider, (_, _) => watcher.checkBudgets());
  ref.listen(budgetOverridesProvider, (_, _) => watcher.checkBudgets());
  ref.listen(categoriesProvider, (_, _) => watcher.checkBudgets());
  ref.listen(
    lendingBalancesProvider,
    (_, _) => watcher.syncLendingReminders(),
    fireImmediately: true,
  );
});

class _AlertWatcher {
  _AlertWatcher(this._ref);

  final Ref _ref;
  bool _checking = false;
  bool _again = false;

  NotificationService get _notifications =>
      _ref.read(notificationServiceProvider);

  Future<void> checkBudgets() async {
    if (_checking) {
      _again = true;
      return;
    }
    _checking = true;
    try {
      do {
        _again = false;
        await _checkBudgetsOnce();
      } while (_again);
    } finally {
      _checking = false;
    }
  }

  Future<void> _checkBudgetsOnce() async {
    final categories = _ref.read(categoriesProvider).value;
    final now = DateTime.now();
    final month = DateTime(now.year, now.month);
    final budgets = _ref.read(monthBudgetsProvider(month));
    if (categories == null || budgets.isEmpty) return;
    final statuses = budgetStatuses(
      budgets: budgets,
      transactions: _ref.read(analyticsTransactionsProvider),
      month: month,
    );

    final settings = _ref.read(settingsRepositoryProvider);
    final shown = keysForMonth(
      _decode(await settings.get(SettingsKeys.budgetAlertsShown)),
      month,
    );
    final fresh = newBudgetAlerts(statuses, month, shown);
    if (fresh.isEmpty) return;

    final names = {for (final c in categories) c.id: c.name};
    for (final alert in fresh) {
      final s = alert.status;
      final name = names[s.categoryId] ?? 'Other';
      final id = (alert.key.hashCode & 0x3fffffff) | 0x40000000;
      if (alert.level == BudgetLevel.over) {
        await _notifications.showNow(
          id: id,
          title: 'Over budget: $name',
          body:
              '${_money.format(s.spentMinor / 100)} spent against a ${_money.format(s.limitMinor / 100)} limit — '
              '${_money.format(s.overByMinor / 100)} over.',
        );
      } else {
        await _notifications.showNow(
          id: id,
          title: '$name is at ${(s.fraction * 100).round()}% of its budget',
          body:
              '${_money.format(s.spentMinor / 100)} of ${_money.format(s.limitMinor / 100)} used in ${DateFormat('MMMM').format(month)}.',
        );
      }
      shown.add(alert.key);
    }
    await settings.set(
      SettingsKeys.budgetAlertsShown,
      jsonEncode(shown.toList()),
    );
  }

  Set<String> _decode(String? raw) {
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as List).cast<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  /// (Re)schedules a reminder the day before and on the due day (9 am) for
  /// every open entry that has a due date, and cancels those that no longer apply.
  Future<void> syncLendingReminders() async {
    final balances = _ref.read(lendingBalancesProvider);
    for (final b in balances) {
      final base = (b.entry.id.hashCode & 0x1fffffff) << 1;
      final dayBeforeId = base & 0x3fffffff;
      final dueDayId = (base | 1) & 0x3fffffff;
      final due = b.entry.dueDate;
      if (b.isSettled || due == null) {
        await _notifications.cancel(dayBeforeId);
        await _notifications.cancel(dueDayId);
        continue;
      }
      final dueMorning = DateTime(due.year, due.month, due.day, 9);
      final amount = _money.format(b.outstandingMinor / 100);
      final who = b.entry.person;
      final owedToMe = b.isLent;
      await _notifications.scheduleAt(
        id: dayBeforeId,
        title: owedToMe ? '$who repays tomorrow' : 'Repay $who tomorrow',
        body: owedToMe
            ? '$who is due to pay you $amount.'
            : 'You owe $who $amount.',
        when: dueMorning.subtract(const Duration(days: 1)),
      );
      await _notifications.scheduleAt(
        id: dueDayId,
        title: owedToMe ? '$who owes you $amount' : 'Repay $who today',
        body: owedToMe ? 'Due today.' : 'Due today: $amount.',
        when: dueMorning,
      );
    }
  }
}
