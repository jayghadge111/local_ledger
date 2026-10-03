enum DayPart { morning, afternoon, evening, night }

DayPart dayPartOf(DateTime time) {
  final h = time.hour;
  if (h >= 5 && h < 12) return DayPart.morning;
  if (h >= 12 && h < 17) return DayPart.afternoon;
  if (h >= 17 && h < 21) return DayPart.evening;
  return DayPart.night;
}

String greetingFor(DateTime time) => switch (dayPartOf(time)) {
  DayPart.morning => 'Good morning',
  DayPart.afternoon => 'Good afternoon',
  DayPart.evening => 'Good evening',
  DayPart.night => 'Good night',
};

const _titles = {'mr', 'mrs', 'ms', 'miss', 'dr', 'shri', 'smt', 'sri'};

List<String> _words(String? name) => (name ?? '')
    .split(RegExp(r'\s+'))
    .map((w) => w.replaceAll(RegExp(r'[^A-Za-zÀ-￿.\-]'), ''))
    .where(
      (w) =>
          w.isNotEmpty &&
          !_titles.contains(w.toLowerCase().replaceAll('.', '')),
    )
    .toList();

String _cap(String w) =>
    w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase();

/// "jayesh bhika GHADGE" -> "Jayesh Bhika Ghadge".
String prettyName(String? name) => _words(name).map(_cap).join(' ');

/// "Jayesh" — what to call the user in a greeting. Null when no name is set.
String? firstNameOf(String? name) {
  final words = _words(name);
  return words.isEmpty ? null : _cap(words.first);
}

/// "JG" — up to two letters for an avatar. Empty when no name is set.
String initialsOf(String? name) {
  final words = _words(name);
  if (words.isEmpty) return '';
  if (words.length == 1) return words.first[0].toUpperCase();
  return (words.first[0] + words.last[0]).toUpperCase();
}
