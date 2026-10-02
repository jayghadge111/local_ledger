import 'package:flutter/material.dart';

/// Maps a category's stored `iconKey` string to a Material icon. Uses the
/// "rounded" icon family throughout — flatter, friendlier strokes that sit
/// better with the app's monochrome theme than the sharper default set.
IconData iconForKey(String? key) {
  switch (key) {
    case 'restaurant':
      return Icons.restaurant_rounded;
    case 'local_grocery_store':
      return Icons.local_grocery_store_rounded;
    case 'directions_car':
      return Icons.directions_car_filled_rounded;
    case 'shopping_bag':
      return Icons.shopping_bag_rounded;
    case 'receipt_long':
      return Icons.receipt_long_rounded;
    case 'movie':
      return Icons.local_movies_rounded;
    case 'local_hospital':
      return Icons.local_hospital_rounded;
    case 'swap_horiz':
      return Icons.swap_horiz_rounded;
    case 'payments':
      return Icons.payments_rounded;
    default:
      return Icons.category_rounded;
  }
}
