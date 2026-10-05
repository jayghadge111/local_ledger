import 'package:flutter/material.dart';

/// A label + [Switch] row. Deliberately not [SwitchListTile]: that widget
/// computes ink-splash visibility from its nearest [Material] ancestor's
/// color, which is transparent throughout this app (see [GlassBackground]),
/// and triggers a "background color or ink splashes may be invisible"
/// warning on every frame as a result.
class GlassSwitchRow extends StatelessWidget {
  const GlassSwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
