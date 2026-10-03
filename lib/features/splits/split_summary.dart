import '../../core/db/app_database.dart';

/// Short text for a split transaction's chip: "Split · Rahul",
/// "Split · Rahul, Priya +1", or "Split · settled" once everyone has paid.
String splitChipLabel(List<SplitShare> shares) {
  if (shares.isEmpty) return '';
  if (shares.every((s) => s.settled)) return 'Split · settled';
  final names = <String>[];
  for (final s in shares) {
    if (!names.contains(s.personName)) names.add(s.personName);
  }
  final shown = names.take(2).join(', ');
  final more = names.length - 2;
  return more > 0 ? 'Split · $shown +$more' : 'Split · $shown';
}

/// What the user paid for themself: the total minus everyone else's shares.
int myShareMinor(int totalMinor, List<SplitShare> shares) =>
    (totalMinor - shares.fold<int>(0, (sum, s) => sum + s.shareMinor)).clamp(
      0,
      totalMinor,
    );
