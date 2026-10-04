import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/settings_repository.dart';
import '../../../core/profile/greeting.dart';
import '../../../shared/widgets/greeting_header.dart';
import 'edit_name_dialog.dart';

/// The hero card at the top of Settings: a panel in the theme's button colour with the user's monogram, a time-of-day greeting and their
/// full name, with quiet concentric rings as texture.
class ProfileCard extends ConsumerWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name = ref.watch(userNameProvider).value;
    final now = DateTime.now();
    final bg = scheme.primary;
    final fg = scheme.onPrimary;

    // While the shell animates in, the body is briefly laid out far narrower
    // than the screen — leave a quiet gap rather than overflow.
    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth < 230) return const SizedBox(height: 120);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () => showEditNameDialog(context, ref),
            child: Ink(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: bg.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  children: [
                    Positioned(
                      right: -50,
                      top: -60,
                      child: _Ring(size: 190, color: fg),
                    ),
                    Positioned(
                      right: -10,
                      top: -20,
                      child: _Ring(size: 110, color: fg),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              NameAvatar(name: name, size: 58, inverse: true),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        DayPartIcon(dayPartOf(now)),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            greetingFor(now),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: fg.withValues(
                                                    alpha: 0.7,
                                                  ),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      name ?? 'Add your name',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            color: fg,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.3,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Text(
                                  name == null
                                      ? 'Add your name so payments to yourself show as Self Transfer, not spending.'
                                      : 'Used on this device to spot Self Transfers.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: fg.withValues(alpha: 0.65),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: fg.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.edit_rounded,
                                      size: 14,
                                      color: fg,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      name == null ? 'Add' : 'Edit',
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            color: fg,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.10), width: 1.5),
        ),
      ),
    );
  }
}
