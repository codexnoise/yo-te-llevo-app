/// Estado de una `TripOccurrence` (instancia concreta de un viaje en una
/// fecha y hora dadas).
///
/// Diagrama (spec §3.3):
/// ```
/// scheduled → active → completed
///          ↘ cancelled
///          ↘ noShow
/// ```
enum OccurrenceStatus {
  scheduled,
  active,
  completed,
  cancelled,
  noShow;

  /// Decodifica el valor persistido en Firestore. Acepta tanto `noShow`
  /// (camelCase) como `no_show` (snake_case) por compat con CFs futuras.
  static OccurrenceStatus fromString(String value) {
    final normalized = value == 'no_show' ? 'noShow' : value;
    return OccurrenceStatus.values.firstWhere(
      (s) => s.name == normalized,
      orElse: () => OccurrenceStatus.scheduled,
    );
  }

  /// Las transiciones permitidas por el spec §3.3. Cualquier intento fuera
  /// de este conjunto se rechaza tanto a nivel de repo como de Firestore
  /// rules.
  bool canTransitionTo(OccurrenceStatus next) {
    switch (this) {
      case OccurrenceStatus.scheduled:
        return next == OccurrenceStatus.active ||
            next == OccurrenceStatus.cancelled ||
            next == OccurrenceStatus.noShow;
      case OccurrenceStatus.active:
        return next == OccurrenceStatus.completed ||
            next == OccurrenceStatus.cancelled;
      case OccurrenceStatus.completed:
      case OccurrenceStatus.cancelled:
      case OccurrenceStatus.noShow:
        return false;
    }
  }
}
