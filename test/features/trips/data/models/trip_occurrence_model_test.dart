import 'package:flutter_test/flutter_test.dart';
import 'package:yo_te_llevo/features/matching/domain/entities/match.dart';
import 'package:yo_te_llevo/features/trips/data/models/trip_occurrence_model.dart';
import 'package:yo_te_llevo/features/trips/domain/entities/occurrence_status.dart';
import 'package:yo_te_llevo/features/trips/domain/entities/trip_occurrence.dart';

TripOccurrence _sample({
  String id = 'm1_202604270730',
  OccurrenceStatus status = OccurrenceStatus.scheduled,
}) {
  return TripOccurrence(
    id: id,
    matchId: 'm1',
    passengerId: 'p1',
    driverId: 'd1',
    routeId: 'r1',
    scheduledAt: DateTime.utc(2026, 4, 27, 12, 30),
    status: status,
    tripType: MatchTripType.recurring,
    createdAt: DateTime.utc(2026, 4, 26, 10),
    priceCents: 1000,
    remindersSent: const OccurrenceReminders(),
    timezone: 'America/Guayaquil',
  );
}

void main() {
  group('TripOccurrenceModel', () {
    test('docIdFor produce id determinístico en UTC', () {
      final id = TripOccurrenceModel.docIdFor(
        matchId: 'abc',
        scheduledAt: DateTime.utc(2026, 4, 27, 12, 30),
      );
      expect(id, 'abc_202604271230');
    });

    test('docIdFor convierte fechas locales a UTC antes de formatear', () {
      // 27 abr 07:30 en America/Guayaquil (UTC-5) = 27 abr 12:30 UTC.
      final scheduledLocal =
          DateTime(2026, 4, 27, 7, 30).toUtc().add(const Duration(hours: 5));
      final id = TripOccurrenceModel.docIdFor(
        matchId: 'abc',
        scheduledAt: scheduledLocal,
      );
      // Lo importante es que sea estable entre llamadas con la misma input.
      final again = TripOccurrenceModel.docIdFor(
        matchId: 'abc',
        scheduledAt: scheduledLocal,
      );
      expect(id, again);
    });

    test('round-trip toMap → fromMap preserva campos clave', () {
      final original = _sample(status: OccurrenceStatus.completed).copyWith(
        completedAt: DateTime.utc(2026, 4, 27, 13),
      );
      final map = TripOccurrenceModel.toMap(original);
      final restored = TripOccurrenceModel.fromMap(original.id, map);

      expect(restored.id, original.id);
      expect(restored.matchId, original.matchId);
      expect(restored.scheduledAt.toUtc(), original.scheduledAt.toUtc());
      expect(restored.status, original.status);
      expect(restored.priceCents, original.priceCents);
      expect(restored.timezone, original.timezone);
      expect(restored.tripType, original.tripType);
      expect(restored.completedAt, isNotNull);
    });

    test('fromMap maneja status no_show (snake_case) por compat con CFs', () {
      final map = TripOccurrenceModel.toMap(_sample());
      map[TripOccurrenceModel.fStatus] = 'no_show';
      final restored = TripOccurrenceModel.fromMap('id', map);
      expect(restored.status, OccurrenceStatus.noShow);
    });
  });
}
