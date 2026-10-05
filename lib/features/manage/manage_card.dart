import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/glass_surface.dart';

class ManageItem {
  const ManageItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.screen,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget screen;
  final int? badge;
}

class ManageCard extends StatelessWidget {
  const ManageCard({super.key, required this.item});
  final ManageItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chart = ChartColors.of(context);
    return GlassCard(
      onTap: () =>
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => item.screen)),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: chart.soft,
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: chart.softText),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (item.badge != null)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${item.badge}',
                style: TextStyle(
                  color: theme.colorScheme.onError,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
