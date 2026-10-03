import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/db/settings_repository.dart';
import '../../core/profile/greeting.dart';
import '../../features/settings/widgets/edit_name_dialog.dart';

IconData dayPartIcon(DayPart part) => switch (part) {
  DayPart.morning => Icons.wb_twilight_rounded,
  DayPart.afternoon => Icons.wb_sunny_rounded,
  DayPart.evening => Icons.wb_twilight_rounded,
  DayPart.night => Icons.nightlight_round,
};

/// A round monogram of the user's initials — black on the light theme, white
/// on dark — with a soft ring.
class NameAvatar extends StatelessWidget {
  const NameAvatar({
    super.key,
    required this.name,
    this.size = 52,
    this.inverse = false,
  });

  final String? name;
  final double size;

  /// Draw on a dark/inverted surface (the Settings hero card).
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = inverse ? scheme.surface : scheme.onSurface;
    final ink = inverse ? scheme.onSurface : scheme.surface;
    final initials = initialsOf(name);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(color: fill.withValues(alpha: 0.18), width: 4),
      ),
      child: initials.isEmpty
          ? Icon(Icons.person_rounded, color: ink, size: size * 0.5)
          : Text(
              initials,
              style: TextStyle(
                color: ink,
                fontSize: size * 0.34,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
    );
  }
}

/// The top of the Home screen: monogram, a time-of-day greeting and the
/// user's first name, with today's date on the right. Tapping it when no
/// name is saved yet invites them to add one.
class GreetingHeader extends ConsumerWidget {
  const GreetingHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final name = ref.watch(userNameProvider).value;
    final now = DateTime.now();
    final first = firstNameOf(name);
    final muted = theme.colorScheme.onSurfaceVariant;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: name == null ? () => showEditNameDialog(context, ref) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        // While the shell animates in, the body is briefly laid out much
        // narrower than the screen — the header must degrade, not overflow.
        child: LayoutBuilder(
          builder: (context, box) {
            if (box.maxWidth < 120) return const SizedBox(height: 52);
            final showDate = box.maxWidth >= 300;
            return Row(
              children: [
                NameAvatar(name: name),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            dayPartIcon(dayPartOf(now)),
                            size: 15,
                            color: muted,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              greetingFor(now),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        first ?? 'Add your name',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: first == null ? muted : null,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showDate) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Text(
                      DateFormat('EEE, d MMM').format(now),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
