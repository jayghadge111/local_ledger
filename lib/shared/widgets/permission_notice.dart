import 'package:flutter/material.dart';

import '../../core/permissions/app_permissions.dart';

/// A quiet note that a permission the app wants is off, with the one button
/// that can fix it: "Allow" while the system will still ask, "Open settings"
/// once it won't (a refusal for good, or a permission turned off later in
/// system settings).
class PermissionNotice extends StatelessWidget {
  const PermissionNotice({
    super.key,
    required this.state,
    required this.message,
    required this.onAllow,
    required this.onOpenSettings,
  });

  final PermissionState state;

  /// Why it matters, in a sentence.
  final String message;
  final VoidCallback onAllow;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blocked = state == PermissionState.blocked;
    final color = theme.colorScheme.tertiary;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(Icons.lock_outline_rounded, size: 20, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(message, style: theme.textTheme.bodySmall),
                ),
              ),
            ],
          ),
          // Underneath, so a long label or big text never pushes it off the
          // edge of a narrow screen.
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: blocked ? onOpenSettings : onAllow,
              child: Text(blocked ? 'Open settings' : 'Allow'),
            ),
          ),
        ],
      ),
    );
  }
}
