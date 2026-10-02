/// How far back SMS and Gmail imports reach: from the 1st of the current
/// month, one year ago. On 15 Oct 2026 that is 1 Oct 2025.
DateTime importCutoff([DateTime? now]) {
  final today = now ?? DateTime.now();
  return DateTime(today.year - 1, today.month, 1);
}
