/// A snapshot of a running import, for showing "how much done, how much left".
class ImportProgress {
  const ImportProgress(this.phase, {this.done = 0, this.total = 0, this.found = 0});

  /// What it's doing right now, e.g. "Reading bank emails".
  final String phase;
  final int done;

  /// 0 while the total isn't known yet (the bar then shows as indeterminate).
  final int total;

  /// Transactions imported so far.
  final int found;

  double? get fraction => total > 0 ? (done / total).clamp(0.0, 1.0).toDouble() : null;
  int get remaining => total > done ? total - done : 0;
}

typedef ImportProgressCallback = void Function(ImportProgress progress);
