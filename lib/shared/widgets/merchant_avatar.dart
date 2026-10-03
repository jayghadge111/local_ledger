import 'package:flutter/material.dart';

import 'category_icons.dart';
import 'merchant_badge.dart';

/// Shows a colored initial for recognized merchants (see [merchantBadgeFor])
/// or the transaction's category icon otherwise.
class MerchantAvatar extends StatelessWidget {
  const MerchantAvatar({
    super.key,
    required this.merchant,
    required this.categoryIconKey,
    this.isTransfer = false,
  });

  final String merchant;
  final String? categoryIconKey;

  /// A Self Transfer: shown with the swap glyph instead of a merchant initial.
  final bool isTransfer;

  @override
  Widget build(BuildContext context) {
    final badge = isTransfer ? null : merchantBadgeFor(merchant);
    if (badge != null) {
      return CircleAvatar(
        backgroundColor: badge.color,
        child: Text(
          badge.initial,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    return CircleAvatar(
      backgroundColor: theme.colorScheme.secondaryContainer,
      child: Icon(
        isTransfer ? Icons.sync_alt_rounded : iconForKey(categoryIconKey),
        color: theme.colorScheme.onSecondaryContainer,
      ),
    );
  }
}
