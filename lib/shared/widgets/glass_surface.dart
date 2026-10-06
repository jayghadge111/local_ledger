import 'package:flutter/material.dart';

/// A flat, bordered card — the app's standard elevated surface. White on
/// the light "Uber Slate" theme, dark slate in dark mode; a hairline border
/// instead of a shadow does most of the separation work, with a faint
/// shadow underneath for depth. Scales down slightly on press when [onTap]
/// is set, for a tactile feel.
class GlassCard extends StatefulWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 20,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(widget.borderRadius);

    final content = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: radius,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: widget.child,
    );

    final animated = AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: content,
    );

    if (widget.onTap == null) return animated;
    // A tappable card is one control for TalkBack: it reads everything on the
    // card together ("Swiggy, Oct 5, minus ₹450") and says it is a button,
    // instead of leaving an unlabeled tap target next to loose text.
    return Semantics(
      button: true,
      container: true,
      child: MergeSemantics(child: _tappable(radius, animated)),
    );
  }

  Widget _tappable(BorderRadius radius, Widget animated) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: widget.onTap,
          child: animated,
        ),
      ),
    );
  }
}
