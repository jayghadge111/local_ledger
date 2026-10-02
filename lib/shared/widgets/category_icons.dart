import 'package:flutter/material.dart';

/// Maps a category's stored `iconKey` string to a Material icon.
IconData iconForKey(String? key) {
  switch (key) {
    case 'restaurant':
      return Icons.restaurant;
    case 'local_grocery_store':
      return Icons.local_grocery_store;
    case 'directions_car':
      return Icons.directions_car;
    case 'shopping_bag':
      return Icons.shopping_bag;
    case 'receipt_long':
      return Icons.receipt_long;
    case 'movie':
      return Icons.movie;
    case 'local_hospital':
      return Icons.local_hospital;
    case 'swap_horiz':
      return Icons.swap_horiz;
    case 'payments':
      return Icons.payments;
    default:
      return Icons.category;
  }
}
