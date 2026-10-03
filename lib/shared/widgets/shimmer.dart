import 'package:flutter/material.dart';

import 'glass_surface.dart';

/// Sweeps a soft highlight across [child] — used on placeholder shapes while
/// real content is still on its way.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.onSurface.withValues(alpha: 0.07);
    final highlight = scheme.onSurface.withValues(alpha: 0.16);
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(-1.6 + 3.2 * t, -0.3),
            end: Alignment(-0.6 + 3.2 * t, 0.3),
            colors: [base, highlight, base],
            stops: const [0.25, 0.5, 0.75],
          ).createShader(bounds),
          child: child,
        );
      },
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({required this.width, required this.height});

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

/// A grey, shimmering stand-in shaped like a [TransactionTile].
class TransactionTileSkeleton extends StatelessWidget {
  const TransactionTileSkeleton({super.key, this.variant = 0});

  /// Varies line widths slightly so a column of them doesn't look stamped.
  final int variant;

  @override
  Widget build(BuildContext context) {
    final w1 = [150.0, 120.0, 170.0][variant % 3];
    final w2 = [100.0, 130.0, 90.0][variant % 3];
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Shimmer(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Bone(width: w1, height: 14),
                  const SizedBox(height: 8),
                  _Bone(width: w2, height: 10),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _Bone(width: 70, height: 14),
                SizedBox(height: 8),
                _Bone(width: 36, height: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A scrollable column of [TransactionTileSkeleton]s for a full-screen load.
class TransactionListSkeleton extends StatelessWidget {
  const TransactionListSkeleton({super.key, this.count = 8});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => TransactionTileSkeleton(variant: i),
    );
  }
}
