import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../rules/rules_manager.dart';
import 'diagnostic_log.dart';

/// Starts the app so that nothing that goes wrong — a widget failing to
/// build, an exception nobody awaited, an error in another isolate — can pass
/// unrecorded. Everything goes to the on-device [DiagnosticLog].
Future<void> runGuarded(Widget Function() app) async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await DiagnosticLog.instance.init();
    installErrorHandlers();
    // Message-reading rules: the downloaded set if it holds up, else built in.
    await RulesManager.initialise();
    runApp(app());
    // The first frame drew, so this start-up worked with these rules.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => RulesManager.instance?.bootSucceeded(),
    );
  }, (error, stack) => DiagnosticLog.instance.record('zone', error, stack));
}

/// Routes Flutter, platform and isolate errors into the log. Split out from
/// [runGuarded] so tests can install it without starting an app.
void installErrorHandlers([DiagnosticLog? log]) {
  final sink = log ?? DiagnosticLog.instance;

  FlutterError.onError = (details) {
    // For layout errors the stack says nothing useful; the widget that caused
    // it is named in the report as "…/lib/…/file.dart:line:col".
    final where = RegExp(
      r'lib/[\w/.]+\.dart:\d+:\d+',
    ).firstMatch(details.toString())?.group(0);
    sink.record(
      'flutter',
      details.exception,
      details.stack,
      [?details.context?.toDescription(), ?where].join(' @ '),
    );
    // Debug builds still print the usual red-screen report.
    FlutterError.presentError(details);
  };

  // Errors from async code that nothing awaited and no zone caught.
  PlatformDispatcher.instance.onError = (error, stack) {
    sink.record('platform', error, stack);
    return true;
  };

  // Errors that end another isolate (a background import, say).
  if (!kIsWeb) {
    final port = RawReceivePort((dynamic pair) {
      final list = pair as List<dynamic>;
      sink.record(
        'isolate',
        list.first as Object,
        StackTrace.fromString('${list.last}'),
      );
    });
    Isolate.current.addErrorListener(port.sendPort);
  }

  // A widget that fails to build shows a quiet placeholder instead of the
  // grey/red error box. Debug builds keep the box, which is more useful there.
  if (kReleaseMode) {
    ErrorWidget.builder = (details) => const _BrokenWidgetPlaceholder();
  }
}

/// Runs [action] and records, instead of throwing, whatever goes wrong. For
/// background work no screen is waiting on. Returns null on failure.
Future<T?> guarded<T>(String what, Future<T> Function() action) async {
  try {
    return await action();
  } catch (error, stack) {
    DiagnosticLog.instance.record('guarded', error, stack, what);
    return null;
  }
}

class _BrokenWidgetPlaceholder extends StatelessWidget {
  const _BrokenWidgetPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            "This part couldn't be shown.",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }
}
