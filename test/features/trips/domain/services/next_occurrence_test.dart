import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:yo_te_llevo/features/trips/domain/services/next_occurrence.dart';

DateTime _utcOf({
  required String tz,
  required int y,
  required int m,
  required int d,
  int h = 0,
  int min = 0,
}) {
  final loc = _locationOf(tz);
  return _local(loc, y, m, d, h, min).toUtc();
}

tz.Location _locationOf(String name) => tz.getLocation(name);

tz.TZDateTime _local(tz.Location loc, int y, int m, int d, int h, int min) =>
    tz.TZDateTime(loc, y, m, d, h, min);

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  const cuenca = 'America/Guayaquil';

  group('nextOccurrence', () {
    test('devuelve el próximo lunes 07:30 si después es martes', () {
      // 2026-04-29 es miércoles. Próximo lunes/miércoles/viernes después
      // del 30 de abril 23:59 UTC debería ser viernes 1 de mayo.
      final after = _utcOf(tz: cuenca, y: 2026, m: 4, d: 28, h: 23, min: 59);
      final next = nextOccurrence(
        days: const ['mon', 'wed', 'fri'],
        departureTime: '07:30',
        after: after,
        timezone: cuenca,
      );
      expect(next, isNotNull);
      final localNext = tz.TZDateTime.from(next!, tz.getLocation(cuenca));
      expect(localNext.weekday, DateTime.wednesday);
      expect(localNext.hour, 7);
      expect(localNext.minute, 30);
    });

    test('respeta endDate y devuelve null si la próxima cae fuera', () {
      // Lunes 4 de mayo 07:30 ya pasaría endDate del domingo 3 de mayo.
      final after = _utcOf(tz: cuenca, y: 2026, m: 5, d: 1, h: 8);
      final endDate = _utcOf(tz: cuenca, y: 2026, m: 5, d: 3, h: 23);
      final next = nextOccurrence(
        days: const ['mon'],
        departureTime: '07:30',
        after: after,
        timezone: cuenca,
        endDate: endDate,
      );
      expect(next, isNull);
    });

    test('cambia de mes correctamente', () {
      // 30 abril 2026 → próximo lunes es 4 de mayo.
      final after = _utcOf(tz: cuenca, y: 2026, m: 4, d: 30, h: 8);
      final next = nextOccurrence(
        days: const ['mon'],
        departureTime: '07:30',
        after: after,
        timezone: cuenca,
      );
      expect(next, isNotNull);
      final localNext = tz.TZDateTime.from(next!, tz.getLocation(cuenca));
      expect(localNext.month, 5);
      expect(localNext.day, 4);
    });

    test('año bisiesto: 28 feb → 1 mar', () {
      // 2024 fue bisiesto. Sábado 28 feb 2024 buscamos el próximo viernes.
      final after = _utcOf(tz: cuenca, y: 2024, m: 2, d: 28, h: 8);
      final next = nextOccurrence(
        days: const ['fri'],
        departureTime: '07:30',
        after: after,
        timezone: cuenca,
      );
      expect(next, isNotNull);
      final localNext = tz.TZDateTime.from(next!, tz.getLocation(cuenca));
      expect(localNext.month, 3);
      expect(localNext.day, 1);
      expect(localNext.weekday, DateTime.friday);
    });

    test('returns null para días vacíos o departureTime inválido', () {
      final after = DateTime.utc(2026, 4, 29);
      expect(
        nextOccurrence(
          days: const [],
          departureTime: '07:30',
          after: after,
        ),
        isNull,
      );
      expect(
        nextOccurrence(
          days: const ['mon'],
          departureTime: 'no-hora',
          after: after,
        ),
        isNull,
      );
    });

    test('genera múltiples ocurrencias monótonamente crecientes', () {
      final after = _utcOf(tz: cuenca, y: 2026, m: 4, d: 27, h: 0);
      final list = nextOccurrences(
        count: 4,
        days: const ['mon', 'wed'],
        departureTime: '07:30',
        after: after,
        timezone: cuenca,
      );
      expect(list, hasLength(4));
      for (var i = 1; i < list.length; i++) {
        expect(list[i].isAfter(list[i - 1]), isTrue);
      }
    });
  });
}
