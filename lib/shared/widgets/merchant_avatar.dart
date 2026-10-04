import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'category_icons.dart';
import 'merchant_badge.dart';

/// A transaction's round avatar: the merchant's logo on its brand colour when
/// the merchant is recognised (see [merchantBadgeFor]); otherwise — if the
/// message named no merchant — the account's bank logo; otherwise the
/// category icon.
class MerchantAvatar extends StatelessWidget {
  const MerchantAvatar({
    super.key,
    required this.merchant,
    required this.categoryIconKey,
    this.isTransfer = false,
    this.bankName,
    this.radius = 20,
  });

  final String merchant;
  final String? categoryIconKey;

  /// A Self Transfer: shown with the swap glyph instead of a merchant logo.
  final bool isTransfer;

  /// The account's bank, used for the logo when [merchant] isn't a known
  /// brand and the message named no real merchant (so the bank is all there
  /// is to show).
  final String? bankName;

  final double radius;

  @override
  Widget build(BuildContext context) {
    final badge = isTransfer
        ? null
        : (merchantBadgeFor(merchant) ??
              (bankName == null ? null : merchantBadgeFor(bankName!)));
    if (badge != null) {
      final icon = badge.icon;
      final asset = badge.asset;
      if (asset != null) {
        return Semantics(
          label: badge.name,
          child: Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
            ),
            clipBehavior: Clip.antiAlias,
            padding: badge.wordmark
                ? EdgeInsets.all(radius * 0.18)
                : EdgeInsets.zero,
            child: Image.asset(
              asset,
              fit: badge.wordmark ? BoxFit.contain : BoxFit.cover,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, _, _) => Center(
                child: Text(
                  badge.initial,
                  style: TextStyle(
                    color: badge.color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        );
      }
      return Semantics(
        label: badge.name,
        child: CircleAvatar(
          radius: radius,
          backgroundColor: badge.color,
          child: icon != null
              ? Icon(icon, color: badge.foreground, size: radius * 1.05)
              : Text(
                  badge.initial,
                  maxLines: 1,
                  style: TextStyle(
                    color: badge.foreground,
                    fontWeight: FontWeight.w800,
                    fontSize: badge.initial.length > 1
                        ? radius * 0.62
                        : radius * 0.8,
                  ),
                ),
        ),
      );
    }

    final chart = ChartColors.of(context);
    return CircleAvatar(
      radius: radius,
      backgroundColor: chart.soft,
      child: Icon(
        isTransfer ? Icons.sync_alt_rounded : iconForKey(categoryIconKey),
        color: chart.softText,
      ),
    );
  }
}
