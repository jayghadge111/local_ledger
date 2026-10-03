import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/db/app_database.dart';
import 'package:local_ledger/core/db/providers.dart';
import 'package:local_ledger/core/update/app_update_service.dart';
import 'package:local_ledger/core/update/update_controller.dart';
import 'package:local_ledger/features/update/update_banner.dart';

class _FakeService implements AppUpdateService {
  _FakeService();

  UpdateOffer? offer = const UpdateOffer(label: 'Build 42');
  int checks = 0;
  bool installed = false;
  StreamController<UpdateEvent> events = StreamController<UpdateEvent>();

  @override
  Future<UpdateOffer?> check() async {
    checks++;
    return offer;
  }

  @override
  Stream<UpdateEvent> download() {
    events = StreamController<UpdateEvent>();
    return events.stream;
  }

  @override
  Future<void> install() async => installed = true;
}

Future<void> tick() => Future<void>.delayed(const Duration(milliseconds: 20));

Future<void> until(
  bool Function() done, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final end = DateTime.now().add(timeout);
  while (!done() && DateTime.now().isBefore(end)) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  late AppDatabase db;
  late _FakeService service;
  late ProviderContainer container;

  UpdateController ctrl() => container.read(updateControllerProvider.notifier);
  UpdateState state() => container.read(updateControllerProvider);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    service = _FakeService();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        appUpdateServiceProvider.overrideWithValue(service),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('nothing to offer: the banner stays hidden', () async {
    service.offer = null;
    await ctrl().check();
    expect(state().stage, UpdateStage.none);
    expect(state().visible, isFalse);
  });

  test(
    'an update is announced, then downloaded with progress, then installed',
    () async {
      await ctrl().check();
      expect(state().stage, UpdateStage.available);
      expect(state().visible, isTrue);
      expect(state().offer!.label, 'Build 42');

      ctrl().start();
      expect(state().stage, UpdateStage.downloading);

      service.events.add(const UpdateProgress(0.4));
      await tick();
      expect(state().progress, 0.4);

      // Play-style: no percentage.
      service.events.add(const UpdateProgress(null));
      await tick();
      expect(state().progress, isNull);
      expect(state().stage, UpdateStage.downloading);

      service.events.add(const UpdateDownloaded());
      await tick();
      expect(state().stage, UpdateStage.downloaded);

      await ctrl().install();
      expect(service.installed, isTrue);
    },
  );

  test(
    '"Later" hides this version for good, but a newer one shows again',
    () async {
      await ctrl().check();
      await ctrl().dismiss();
      expect(state().visible, isFalse);

      // Next launch: same version stays hidden.
      container.invalidate(updateControllerProvider);
      await ctrl().check(force: true);
      expect(state().stage, UpdateStage.available);
      expect(state().visible, isFalse);

      // A different version is announced.
      container.invalidate(updateControllerProvider);
      service.offer = const UpdateOffer(label: 'Build 43');
      await ctrl().check(force: true);
      expect(state().visible, isTrue);
    },
  );

  test('an important update cannot be put off', () async {
    service.offer = const UpdateOffer(label: 'Build 50', priority: 5);
    await ctrl().check();
    await ctrl().dismiss();
    expect(state().visible, isTrue);
  });

  test('a failed download can be retried', () async {
    await ctrl().check();
    ctrl().start();
    service.events.add(const UpdateFailed('no network'));
    await tick();
    expect(state().stage, UpdateStage.failed);
    expect(state().message, 'no network');
    expect(state().visible, isTrue);

    ctrl().retry();
    expect(state().stage, UpdateStage.downloading);
  });

  test('declining in the system dialog returns to "available"', () async {
    await ctrl().check();
    ctrl().start();
    service.events.add(const UpdateCancelled());
    await tick();
    expect(state().stage, UpdateStage.available);
  });

  test('the store is asked at most every few hours unless forced', () async {
    await ctrl().check();
    await ctrl().check();
    expect(service.checks, 1);
    await ctrl().check(force: true);
    expect(service.checks, 2);
  });

  test('a check does not disturb a download in progress', () async {
    await ctrl().check();
    ctrl().start();
    await ctrl().check(force: true);
    expect(state().stage, UpdateStage.downloading);
    expect(service.checks, 1);
  });

  test('debug simulator: a whole fake update runs end to end', () async {
    ctrl().simulate(duration: const Duration(milliseconds: 300));
    expect(state().stage, UpdateStage.available);
    expect(state().offer!.simulated, isTrue);

    ctrl().start();
    await until(() => state().stage == UpdateStage.downloaded);
    expect(state().stage, UpdateStage.downloaded);

    await ctrl().install();
    expect(state().stage, UpdateStage.installed);
    expect(state().message, contains('Simulated'));

    ctrl().clear();
    expect(state().stage, UpdateStage.none);
  });

  test('debug simulator: Play-style downloads show no percentage', () async {
    ctrl().simulate(
      withProgress: false,
      duration: const Duration(milliseconds: 300),
    );
    ctrl().start();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(state().stage, UpdateStage.downloading);
    expect(state().progress, isNull);
    await until(() => state().stage == UpdateStage.downloaded);
  });

  test('debug simulator: can fail partway', () async {
    ctrl().simulate(
      failAtFraction: 0.5,
      duration: const Duration(milliseconds: 300),
    );
    ctrl().start();
    await until(() => state().stage == UpdateStage.failed);
    expect(state().stage, UpdateStage.failed);
  });

  group('the Home banner', () {
    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: UpdateBanner())),
        ),
      );
    }

    testWidgets('is invisible with no update', (tester) async {
      await pump(tester);
      expect(find.text('Update available'), findsNothing);
      expect(find.text('Update'), findsNothing);
    });

    testWidgets('offers, downloads with a percentage, then asks to restart', (
      tester,
    ) async {
      await tester.runAsync(() => ctrl().check());
      await pump(tester);
      expect(find.text('Update available'), findsOneWidget);
      expect(find.text('Update'), findsOneWidget);
      expect(find.text('Later'), findsOneWidget);

      await tester.tap(find.text('Update'));
      await tester.pump();
      expect(find.text('Downloading update…'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      service.events.add(const UpdateProgress(0.42));
      await tester.runAsync(tick);
      await tester.pump();
      expect(find.text('42%'), findsOneWidget);

      service.events.add(const UpdateDownloaded());
      await tester.runAsync(tick);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Update ready'), findsOneWidget);
      expect(find.text('Restart to install'), findsOneWidget);
    });

    testWidgets('an important update has no "Later"', (tester) async {
      service.offer = const UpdateOffer(label: 'Build 50', priority: 5);
      await tester.runAsync(() => ctrl().check());
      await pump(tester);
      expect(find.text('Important update'), findsOneWidget);
      expect(find.text('Later'), findsNothing);
    });

    testWidgets('a failure shows the reason and a Retry', (tester) async {
      await tester.runAsync(() => ctrl().check());
      ctrl().start();
      service.events.add(const UpdateFailed('Check your connection'));
      await tester.runAsync(tick);
      await pump(tester);
      expect(find.text('Update failed'), findsOneWidget);
      expect(find.text('Check your connection'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
