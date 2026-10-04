import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/color_theme_provider.dart';
import '../../../core/theme/color_themes.dart';

/// A radio list of the colour themes, each with a swatch preview. The choice
/// is saved and applied straight away; dark mode ignores it.
class ColorThemePicker extends ConsumerWidget {
  const ColorThemePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selected = ref.watch(colorThemeProvider).value ?? defaultColorTheme;
    final controller = ref.read(colorThemeControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Colour theme', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          'Applies to light mode. Dark mode keeps its own colours.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        for (final option in ColorTheme.values) ...[
          _ThemeTile(
            option: option,
            selected: option == selected,
            onTap: () => controller.setColorTheme(option),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final ColorTheme option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = option.tokens;

    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      button: true,
      label: tokens.name,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? scheme.onSurface : scheme.outlineVariant,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            tokens.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (option == defaultColorTheme) ...[
                          const SizedBox(width: 6),
                          Text(
                            '· recommended',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      tokens.summary,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _Swatches(tokens: tokens),
            ],
          ),
        ),
      ),
    );
  }
}

/// Page, card, chip and button colours of a theme, as four dots.
class _Swatches extends StatelessWidget {
  const _Swatches({required this.tokens});

  final ThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final colors = [
      tokens.scaffold,
      tokens.cardSurface,
      tokens.activeChip,
      tokens.ctaBackground,
    ];
    return SizedBox(
      width: 22.0 * 2 + 4,
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final c in colors)
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: tokens.secondaryText.withValues(alpha: 0.35),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
