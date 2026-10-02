import 'package:flutter/material.dart';

class MerchantBadgeData {
  const MerchantBadgeData(this.initial, this.color);
  final String initial;
  final Color color;
}

/// A small local table mapping common merchant names to a brand-ish color
/// and initial, so the transaction list reads at a glance even without
/// real logo artwork.
///
/// Deliberately not real brand logos: those are trademarked assets, and
/// fetching them from a logo API (e.g. Clearbit) would mean calling a
/// third-party service for every transaction — directly at odds with this
/// app's local-only design. This stays 100% on-device.
const _knownMerchants = <String, MerchantBadgeData>{
  'netflix': MerchantBadgeData('N', Color(0xFFE50914)),
  'swiggy': MerchantBadgeData('S', Color(0xFFFC8019)),
  'zomato': MerchantBadgeData('Z', Color(0xFFE23744)),
  'amazon': MerchantBadgeData('a', Color(0xFF131921)),
  'myntra': MerchantBadgeData('M', Color(0xFFFF3F6C)),
  'uber': MerchantBadgeData('U', Color(0xFF000000)),
  'ola': MerchantBadgeData('O', Color(0xFF61C454)),
  'bigbasket': MerchantBadgeData('B', Color(0xFF84C225)),
  'bookmyshow': MerchantBadgeData('B', Color(0xFFC4242B)),
  'apollo': MerchantBadgeData('A', Color(0xFF0072BC)),
  'practo': MerchantBadgeData('P', Color(0xFF1AA37A)),
  'airtel': MerchantBadgeData('A', Color(0xFFE40000)),
  'bescom': MerchantBadgeData('B', Color(0xFFF2B33D)),
  'starbucks': MerchantBadgeData('S', Color(0xFF00704A)),
};

/// Looks up a badge by substring match against the merchant name (e.g.
/// "Swiggy Instamart" still matches "swiggy"). Returns null for anything
/// unrecognized, so callers can fall back to the category icon.
MerchantBadgeData? merchantBadgeFor(String merchantName) {
  final lower = merchantName.toLowerCase();
  for (final entry in _knownMerchants.entries) {
    if (lower.contains(entry.key)) return entry.value;
  }
  return null;
}
