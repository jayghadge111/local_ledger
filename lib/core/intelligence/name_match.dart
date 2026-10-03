/// Decides whether a name in a bank message ("MR JAYESH BHIKA GHADGE") is the
/// user's own name ("Jayesh Bhika Ghadge"), so money the user sends to or
/// receives from themselves is recognised as a Self Transfer.
///
/// Banks shorten and decorate names — titles, initials, truncation, different
/// word order — so this compares word by word instead of as a whole string.
/// It is deliberately strict about *which* words must agree: two real people
/// can share a first name or a surname, but rarely both.
library;

const _titles = {
  'mr',
  'mrs',
  'ms',
  'miss',
  'mx',
  'shri',
  'shree',
  'sri',
  'smt',
  'kumari',
  'dr',
  'prof',
  'late',
};

/// Lower-case words of [name], without titles, punctuation or UPI-style
/// suffixes (anything after an "@").
List<String> nameWords(String name) {
  final beforeAt = name.split('@').first;
  return beforeAt
      .toLowerCase()
      .replaceAll(RegExp(r"[^a-z\s]"), ' ')
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty && !_titles.contains(w))
      .toList();
}

enum _Hit { none, initial, full }

_Hit _wordMatch(String a, String b) {
  if (a == b) return _Hit.full;
  // "B" for Bhika.
  if (a.length == 1 && b.startsWith(a)) return _Hit.initial;
  if (b.length == 1 && a.startsWith(b)) return _Hit.initial;
  // Banks truncate long names ("GHAD" for Ghadge).
  final shorter = a.length < b.length ? a : b;
  final longer = a.length < b.length ? b : a;
  if (shorter.length >= 4 && longer.startsWith(shorter)) return _Hit.full;
  return _Hit.none;
}

/// How many of [small]'s words are found, one-to-one, in [large], and how
/// many of those are full-word (not just initial) matches. Null if any word
/// of [small] has no partner.
int? _fullHitsIfAllCovered(List<String> small, List<String> large) {
  final taken = <int>{};
  var full = 0;
  for (final word in small) {
    var found = false;
    for (var i = 0; i < large.length; i++) {
      if (taken.contains(i)) continue;
      final hit = _wordMatch(word, large[i]);
      if (hit == _Hit.none) continue;
      taken.add(i);
      if (hit == _Hit.full) full++;
      found = true;
      break;
    }
    if (!found) return null;
  }
  return full;
}

/// True when [candidate] (a payer/payee/sender name from a message) is the
/// same person as [userName].
///
/// Needs at least two full-word agreements, and every word of the shorter
/// name must be accounted for in the longer — so "JAYESH GHADGE" and
/// "MR JAYESH BHIKA GHADGE" match, "JAYESH" alone or "JAYESH PATIL" don't.
/// A one-word name matches only an identical one-word name.
bool isSameName(String? userName, String? candidate) {
  if (userName == null || candidate == null) return false;
  final user = nameWords(userName);
  final other = nameWords(candidate);
  if (user.isEmpty || other.isEmpty) return false;

  if (user.length == 1 || other.length == 1) {
    return user.length == other.length &&
        user.first.length >= 3 &&
        user.first == other.first;
  }

  final small = user.length <= other.length ? user : other;
  final large = identical(small, user) ? other : user;
  final full = _fullHitsIfAllCovered(small, large);
  return full != null && full >= 2;
}
