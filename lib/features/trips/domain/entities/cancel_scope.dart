/// Alcance de una cancelación pedida desde la UI.
///
/// El usuario decide si cancela **sólo esta fecha** (deja la serie viva,
/// la fecha queda sin viaje) o **toda la serie** (todas las ocurrencias
/// `scheduled` futuras pasan a `cancelled` y la serie pasa a `cancelled`).
///
/// Para `tripType=oneTime` sólo aplica `occurrence` (no hay serie).
enum CancelScope {
  occurrence,
  series;

  /// Valor persistido en Firestore al hacer update de cancelación. Lo
  /// consume la CF `onOccurrenceStatusChanged` para decidir si debe
  /// propagar a la serie.
  String get wireValue => name;
}
