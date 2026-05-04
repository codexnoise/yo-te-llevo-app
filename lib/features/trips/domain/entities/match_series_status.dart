/// Estado del **template** de una serie de viajes recurrentes (spec §3.3).
/// No aplica a `tripType=oneTime` — para esos casos el campo es null.
///
/// ```
/// draft → active → paused → ended
///                       ↘ cancelled
/// ```
enum MatchSeriesStatus {
  draft,
  active,
  paused,
  ended,
  cancelled;

  static MatchSeriesStatus fromString(String value) {
    return MatchSeriesStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => MatchSeriesStatus.draft,
    );
  }

  bool canTransitionTo(MatchSeriesStatus next) {
    switch (this) {
      case MatchSeriesStatus.draft:
        return next == MatchSeriesStatus.active ||
            next == MatchSeriesStatus.cancelled;
      case MatchSeriesStatus.active:
        return next == MatchSeriesStatus.paused ||
            next == MatchSeriesStatus.ended ||
            next == MatchSeriesStatus.cancelled;
      case MatchSeriesStatus.paused:
        return next == MatchSeriesStatus.active ||
            next == MatchSeriesStatus.cancelled ||
            next == MatchSeriesStatus.ended;
      case MatchSeriesStatus.ended:
      case MatchSeriesStatus.cancelled:
        return false;
    }
  }
}
