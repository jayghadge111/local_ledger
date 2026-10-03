import 'package:flutter/material.dart';

import '../../core/rules/parser_rules.dart';
import 'brand_icons.dart';

/// How a recognised merchant looks in the transaction list: its brand colour
/// and either its logo glyph or, where no logo is bundled, an initial.
class MerchantBadgeData {
  const MerchantBadgeData(
    this.initial,
    this.color, {
    this.icon,
    this.name,
    this.asset,
    this.wordmark = false,
  });

  /// Bundled logo image (see `assets/logos/`), when there is one.
  final String? asset;

  /// The image is a wide logo rather than a square app icon, so it is shown
  /// whole on white instead of filling the circle.
  final bool wordmark;

  final String initial;
  final Color color;
  final IconData? icon;

  /// The brand's display name ("HDFC Bank"), for tooltips and accessibility.
  final String? name;

  /// Text/glyph colour that stays readable on [color].
  Color get foreground =>
      color.computeLuminance() > 0.6 ? const Color(0xFF111111) : Colors.white;
}

/// The recognised brand in [merchantName], or null. Brands come from the
/// rules in force (`rules/rules.bundled.json`), most specific first (Swiggy
/// Instamart before Swiggy, Amazon Pay and Prime Video before Amazon) — the
/// first match wins. Logos are bundled with the app; nothing is fetched.
BrandRule? brandFor(String merchantName) {
  for (final brand in ParserRules.current.brands) {
    if (brand.regex.hasMatch(merchantName)) return brand;
  }
  return null;
}

/// Badge for [merchantName] (e.g. "Swiggy Instamart" → Swiggy's logo on its
/// orange). Null for anything unrecognised, so callers can fall back to the
/// category icon.
MerchantBadgeData? merchantBadgeFor(String merchantName) {
  final brand = brandFor(merchantName);
  if (brand == null) return null;
  final icon = brand.iconKey == null ? null : brandIcons[brand.iconKey];
  return MerchantBadgeData(
    brand.initial,
    Color(brand.colorValue),
    icon: icon,
    name: brand.name,
    // A glyph beats an image; images fill in for brands without one.
    asset: icon == null ? brand.logoAsset : null,
    wordmark: icon == null && brand.logoIsWordmark,
  );
}
