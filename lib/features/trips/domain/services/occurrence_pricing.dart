import 'package:timezone/timezone.dart' as tz;

/// Calcula el `priceCents` snapshot para una `TripOccurrence` aplicando la
/// regla acordada (decisión 2026-04-29): cobro completo sólo en la **1ra
/// ocurrencia del ciclo**.
///
/// Reglas por [pricingType]:
/// - `perTrip` / `daily` → cada ocurrencia cobra `matchPrice * 100`.
/// - `weekly` → la primera ocurrencia de cada semana ISO (interpretada en
///   [timezone]) cobra `matchPrice * 100`; el resto cobra `0`.
/// - `monthly` → la primera ocurrencia de cada mes calendario cobra; el
///   resto cobra `0`.
///
/// [previousOccurrenceAt] es el `scheduledAt` de la ocurrencia anterior de
/// la misma serie (UTC). Si es null, se asume que ésta es la primera de
/// todas → siempre cobra.
int priceCentsFor({
  required String pricingType,
  required double matchPrice,
  required DateTime scheduledAt,
  required DateTime? previousOccurrenceAt,
  String timezone = 'America/Guayaquil',
}) {
  final fullCharge = (matchPrice * 100).round();

  switch (pricingType) {
    case 'perTrip':
    case 'daily':
      return fullCharge;
    case 'weekly':
      if (previousOccurrenceAt == null) return fullCharge;
      return _sameIsoWeek(
        previousOccurrenceAt,
        scheduledAt,
        timezone,
      )
          ? 0
          : fullCharge;
    case 'monthly':
      if (previousOccurrenceAt == null) return fullCharge;
      return _sameMonth(previousOccurrenceAt, scheduledAt, timezone)
          ? 0
          : fullCharge;
    default:
      // Pricing desconocido: cobramos completo, deuda explícita.
      return fullCharge;
  }
}

bool _sameIsoWeek(DateTime a, DateTime b, String timezone) {
  final loc = tz.getLocation(timezone);
  final la = tz.TZDateTime.from(a, loc);
  final lb = tz.TZDateTime.from(b, loc);
  return _isoWeekKey(la) == _isoWeekKey(lb);
}

bool _sameMonth(DateTime a, DateTime b, String timezone) {
  final loc = tz.getLocation(timezone);
  final la = tz.TZDateTime.from(a, loc);
  final lb = tz.TZDateTime.from(b, loc);
  return la.year == lb.year && la.month == lb.month;
}

/// Devuelve una clave estable `YYYY-Www` (ISO 8601). Implementación manual
/// para no depender de `intl` ni mantener BOM de DateFormat.
String _isoWeekKey(tz.TZDateTime d) {
  // Algoritmo ISO 8601: la semana 1 contiene el primer jueves del año.
  final thursday =
      d.add(Duration(days: DateTime.thursday - d.weekday));
  final firstThursday = tz.TZDateTime(d.location, thursday.year, 1, 4);
  final firstThursdayWeekStart = firstThursday
      .subtract(Duration(days: firstThursday.weekday - DateTime.monday));
  final daysDiff = thursday.difference(firstThursdayWeekStart).inDays;
  final week = (daysDiff ~/ 7) + 1;
  return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
}
