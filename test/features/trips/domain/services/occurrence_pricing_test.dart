import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:yo_te_llevo/features/trips/domain/services/occurrence_pricing.dart';

DateTime _localUtc(int y, int m, int d, [int h = 7, int min = 30]) {
  final loc = tz.getLocation('America/Guayaquil');
  return tz.TZDateTime(loc, y, m, d, h, min).toUtc();
}

void main() {
  setUpAll(() => tz_data.initializeTimeZones());

  group('priceCentsFor', () {
    test('perTrip cobra completo siempre', () {
      expect(
        priceCentsFor(
          pricingType: 'perTrip',
          matchPrice: 2.50,
          scheduledAt: _localUtc(2026, 4, 27),
          previousOccurrenceAt: null,
        ),
        250,
      );
      expect(
        priceCentsFor(
          pricingType: 'perTrip',
          matchPrice: 2.50,
          scheduledAt: _localUtc(2026, 4, 29),
          previousOccurrenceAt: _localUtc(2026, 4, 27),
        ),
        250,
      );
    });

    test('weekly cobra sólo la primera del ciclo', () {
      // Misma semana ISO → 0
      expect(
        priceCentsFor(
          pricingType: 'weekly',
          matchPrice: 10.0,
          scheduledAt: _localUtc(2026, 4, 29), // miércoles 29 abr
          previousOccurrenceAt: _localUtc(2026, 4, 27), // lunes 27 abr
        ),
        0,
      );
      // Cambio de semana → 1000
      expect(
        priceCentsFor(
          pricingType: 'weekly',
          matchPrice: 10.0,
          scheduledAt: _localUtc(2026, 5, 4), // lunes 4 may
          previousOccurrenceAt: _localUtc(2026, 5, 1), // viernes 1 may
        ),
        1000,
      );
      // Sin previa → cobra
      expect(
        priceCentsFor(
          pricingType: 'weekly',
          matchPrice: 10.0,
          scheduledAt: _localUtc(2026, 4, 27),
          previousOccurrenceAt: null,
        ),
        1000,
      );
    });

    test('monthly cobra sólo la primera del mes', () {
      expect(
        priceCentsFor(
          pricingType: 'monthly',
          matchPrice: 50.0,
          scheduledAt: _localUtc(2026, 4, 29),
          previousOccurrenceAt: _localUtc(2026, 4, 1),
        ),
        0,
      );
      expect(
        priceCentsFor(
          pricingType: 'monthly',
          matchPrice: 50.0,
          scheduledAt: _localUtc(2026, 5, 4),
          previousOccurrenceAt: _localUtc(2026, 4, 27),
        ),
        5000,
      );
    });

    test('daily se comporta como perTrip', () {
      expect(
        priceCentsFor(
          pricingType: 'daily',
          matchPrice: 1.5,
          scheduledAt: _localUtc(2026, 4, 29),
          previousOccurrenceAt: _localUtc(2026, 4, 28),
        ),
        150,
      );
    });
  });
}
