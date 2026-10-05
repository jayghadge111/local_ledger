import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/lending/lending_math.dart';
import '../../core/lending/lending_messages.dart';

import 'package:intl/intl.dart';

/// The picture shared with a status message: who, how much was lent or
/// borrowed, how much is paid and pending, and when it is due.
///
/// It has its own fixed colours, not the app theme, so the image looks the
/// same wherever it is sent — and in dark mode too.
class LendingStatusCard extends StatelessWidget {
  const LendingStatusCard({super.key, required this.balance, this.now});

  final LendingBalance balance;

  /// What counts as today (replaceable in tests).
  final DateTime? now;

  /// Logical width; rendered at 3x for a crisp 1080 px image.
  static const width = 360.0;

  static const _navy = Color(0xFF0C4A6E);
  static const _ice = Color(0xFFF0F9FF);
  static const _line = Color(0xFFBAE6FD);
  static const _track = Color(0xFFE0F2FE);
  static const _muted = Color(0xFF64748B);
  static const _green = Color(0xFF15803D);
  static const _amber = Color(0xFFB45309);
  static const _red = Color(0xFFB91C1C);

  @override
  Widget build(BuildContext context) {
    final b = balance;
    final e = b.entry;
    final today = now ?? DateTime.now();
    final percent = paidPercent(b);
    final lent = b.isLent;
    final settled = b.isSettled;
    final overdue = b.isOverdue(today);

    final (statusText, statusColor) = settled
        ? ('Settled', _green)
        : overdue
        ? ('Overdue', _red)
        : e.dueDate != null
        ? ('Due ${DateFormat('d MMM').format(e.dueDate!)}', _amber)
        : ('Open', _muted);

    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _ice,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _line),
        ),
        child: DefaultTextStyle(
          style: const TextStyle(color: _navy, fontSize: 13, height: 1.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: _navy,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'NativeSpend',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                lent ? 'Lent to' : 'Borrowed from',
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
              Text(
                e.person,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                settled
                    ? 'Fully paid'
                    : lent
                    ? 'Pending'
                    : 'Still to pay',
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
              Text(
                settled ? rupees(e.amountMinor) : rupees(b.outstandingMinor),
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  height: 10,
                  color: _track,
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: percent / 100,
                    child: Container(color: settled ? _green : _navy),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _figure(lent ? 'Paid' : 'Paid back', rupees(b.paidMinor)),
                  const Spacer(),
                  Text(
                    '$percent% paid',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  _figure('Total', rupees(e.amountMinor), alignEnd: true),
                ],
              ),
              const SizedBox(height: 16),
              Container(height: 1, color: _line),
              const SizedBox(height: 10),
              Text(
                '${lent ? 'Lent' : 'Borrowed'} on '
                '${DateFormat('d MMM yyyy').format(e.date)}'
                '${e.dueDate == null ? '' : ' · due ${DateFormat('d MMM yyyy').format(e.dueDate!)}'}',
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                'As of ${DateFormat('d MMM yyyy').format(today)}',
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _figure(String label, String value, {bool alignEnd = false}) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _muted, fontSize: 11)),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

/// Renders the card inside [boundaryKey]'s [RepaintBoundary] to a PNG.
Future<Uint8List?> captureCardPng(GlobalKey boundaryKey) async {
  final render = boundaryKey.currentContext?.findRenderObject();
  if (render is! RenderRepaintBoundary) return null;
  final image = await render.toImage(pixelRatio: 3);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data?.buffer.asUint8List();
}
