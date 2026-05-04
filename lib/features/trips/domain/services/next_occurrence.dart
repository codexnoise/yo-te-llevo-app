import 'package:timezone/timezone.dart' as tz;

/// Códigos cortos de día de la semana usados en `Match.days` y
/// `RouteSchedule.days`. El orden corresponde a `DateTime.weekday`
/// (1 = Monday … 7 = Sunday).
const Map<String, int> _weekdayCodes = {
  'mon': DateTime.monday,
  'tue': DateTime.tuesday,
  'wed': DateTime.wednesday,
  'thu': DateTime.thursday,
  'fri': DateTime.friday,
  'sat': DateTime.saturday,
  'sun': DateTime.sunday,
};

/// Calcula la **próxima** fecha+hora UTC en la que debe ocurrir un viaje
/// recurrente, dado:
/// - [days]: códigos de día (`mon|tue|...|sun`).
/// - [departureTime]: hora local `HH:mm` (interpretada en [timezone]).
/// - [timezone]: IANA tz (default `America/Guayaquil`).
/// - [after]: fecha-hora UTC de referencia. La función devuelve la primera
///   ocurrencia **estrictamente posterior**.
/// - [endDate]: fecha límite (UTC, opcional). Si la próxima ocurrencia caería
///   después, devuelve `null` (la serie terminó).
///
/// Implementación: itera hasta 14 días desde [after]. La spec §4.3 garantiza
/// que ese rango es suficiente porque al menos un día de la semana coincide
/// con [days] dentro de 7 días.
///
/// **Pre-condición**: la base de datos `timezone` debe inicializarse al
/// arranque de la app vía `initializeTimeZones()` del paquete `timezone`.
DateTime? nextOccurrence({
  required List<String> days,
  required String departureTime,
  required DateTime after,
  String timezone = 'America/Guayaquil',
  DateTime? endDate,
}) {
  if (days.isEmpty) return null;
  final time = _parseHHmm(departureTime);
  if (time == null) return null;

  final wantedWeekdays = days
      .map((d) => _weekdayCodes[d.toLowerCase()])
      .where((w) => w != null)
      .cast<int>()
      .toSet();
  if (wantedWeekdays.isEmpty) return null;

  final location = tz.getLocation(timezone);
  // Cursor en la zona local del usuario para iterar día a día sin que el
  // borde del día (medianoche) salte por la zona UTC.
  final afterLocal = tz.TZDateTime.from(after, location);

  for (var step = 0; step <= 14; step++) {
    final dayLocal = afterLocal.add(Duration(days: step));
    if (!wantedWeekdays.contains(dayLocal.weekday)) continue;

    final candidate = tz.TZDateTime(
      location,
      dayLocal.year,
      dayLocal.month,
      dayLocal.day,
      time.$1,
      time.$2,
    );

    final candidateUtc = candidate.toUtc();
    if (!candidateUtc.isAfter(after)) continue;

    if (endDate != null && candidateUtc.isAfter(endDate)) {
      return null;
    }
    return candidateUtc;
  }
  return null;
}

/// Genera las próximas N ocurrencias aplicando [nextOccurrence] iterativamente.
/// Detiene si encuentra `null` (serie terminada por [endDate]).
List<DateTime> nextOccurrences({
  required int count,
  required List<String> days,
  required String departureTime,
  required DateTime after,
  String timezone = 'America/Guayaquil',
  DateTime? endDate,
}) {
  final result = <DateTime>[];
  var cursor = after;
  for (var i = 0; i < count; i++) {
    final next = nextOccurrence(
      days: days,
      departureTime: departureTime,
      after: cursor,
      timezone: timezone,
      endDate: endDate,
    );
    if (next == null) break;
    result.add(next);
    cursor = next;
  }
  return result;
}

(int, int)? _parseHHmm(String raw) {
  final parts = raw.split(':');
  if (parts.length != 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  if (h < 0 || h > 23 || m < 0 || m > 59) return null;
  return (h, m);
}
