import 'package:flutter/material.dart';

import '../../core/diagnostics/diagnostic_log.dart';
import '../../shared/widgets/glass_background.dart';
import '../manage/manage_card.dart';
import 'widgets/diagnostics_card.dart';

/// The problem log and "Email diagnostic log", on their own screen.
class DiagnosticsScreen extends StatelessWidget {
  const DiagnosticsScreen({super.key, this.log});

  /// Defaults to the app's own log; tests pass their own.
  final DiagnosticLog? log;

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Diagnostics')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [DiagnosticsCard(log: log)],
        ),
      ),
    );
  }
}

/// The Settings entry for [DiagnosticsScreen], in the same style as the other
/// tools, with how many problems are noted as its summary.
class DiagnosticsEntryCard extends StatefulWidget {
  const DiagnosticsEntryCard({super.key, this.log});
  final DiagnosticLog? log;

  @override
  State<DiagnosticsEntryCard> createState() => _DiagnosticsEntryCardState();
}

class _DiagnosticsEntryCardState extends State<DiagnosticsEntryCard> {
  late final Future<int> _count = (widget.log ?? DiagnosticLog.instance)
      .entries()
      .then((e) => e.length);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _count,
      builder: (context, snapshot) {
        final n = snapshot.data ?? 0;
        return ManageCard(
          item: ManageItem(
            icon: Icons.bug_report_outlined,
            title: 'Diagnostics',
            subtitle: n == 0
                ? 'If something goes wrong, the details are kept here'
                : '$n problem${n == 1 ? '' : 's'} noted · share the log',
            screen: DiagnosticsScreen(log: widget.log),
          ),
        );
      },
    );
  }
}
