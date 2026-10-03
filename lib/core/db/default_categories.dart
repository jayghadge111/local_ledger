class DefaultCategory {
  const DefaultCategory(this.id, this.name, this.iconKey);

  final String id;
  final String name;
  final String iconKey;
}

/// Seeded when the database is first created; categories added later are
/// inserted by the migration that introduced them. [iconKey] is looked up
/// against `categoryIcons` in the UI layer rather than storing an IconData
/// directly, since Drift columns are plain SQL types.
const defaultCategories = [
  DefaultCategory('cat_food', 'Food & dining', 'restaurant'),
  DefaultCategory('cat_groceries', 'Groceries', 'local_grocery_store'),
  DefaultCategory('cat_transport', 'Transport', 'directions_car'),
  DefaultCategory('cat_shopping', 'Shopping', 'shopping_bag'),
  DefaultCategory('cat_bills', 'Bills & utilities', 'receipt_long'),
  DefaultCategory('cat_entertainment', 'Entertainment', 'movie'),
  DefaultCategory('cat_health', 'Health', 'local_hospital'),
  DefaultCategory('cat_transfer', 'Transfer', 'swap_horiz'),
  DefaultCategory('cat_self_transfer', 'Self Transfer', 'sync_alt'),
  DefaultCategory('cat_emi', 'EMI', 'event_repeat'),
  DefaultCategory('cat_investment', 'SIP / Investment', 'trending_up'),
  DefaultCategory('cat_lending', 'Lending money', 'north_east'),
  DefaultCategory('cat_borrowing', 'Borrowing money', 'south_west'),
  DefaultCategory('cat_income', 'Income', 'payments'),
  DefaultCategory('cat_other', 'Other', 'category'),
];
