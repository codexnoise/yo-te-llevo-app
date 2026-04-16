import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yo_te_llevo/core/utils/lat_lng.dart';
import 'package:yo_te_llevo/features/matching/domain/entities/match.dart';
import 'package:yo_te_llevo/features/matching/domain/entities/match_status.dart';
import 'package:yo_te_llevo/features/trips/data/models/match_model.dart';

Match _sample() => Match(
      id: 'm1',
      passengerId: 'p1',
      driverId: 'd1',
      routeId: 'r1',
      status: MatchStatus.pending,
      pickupPoint: const LatLng(-2.9, -79.0),
      pickupAddress: 'Parque Calderón',
      dropoffPoint: const LatLng(-2.89, -78.98),
      dropoffAddress: 'Terminal',
      distanceToPickupMeters: 350,
      distanceToDropoffMeters: 410,
      detourSeconds: 240,
      tripType: MatchTripType.recurring,
      days: const ['mon', 'tue', 'wed'],
      startDate: DateTime(2026, 4, 15),
      price: 2.5,
      pricingType: 'perTrip',
      createdAt: DateTime(2026, 4, 10, 8, 30),
    );

void main() {
  group('MatchModel', () {
    test('toMap serializes schedule and pricing as nested maps', () {
      final map = MatchModel.toMap(_sample());

      expect(map[MatchModel.fPassengerId], 'p1');
      expect(map[MatchModel.fDriverId], 'd1');
      expect(map[MatchModel.fRouteId], 'r1');
      expect(map[MatchModel.fStatus], 'pending');
      expect(map[MatchModel.fPickupLat], closeTo(-2.9, 1e-9));
      expect(map[MatchModel.fPickupLng], closeTo(-79.0, 1e-9));
      expect(map[MatchModel.fDropoffLat], closeTo(-2.89, 1e-9));
      expect(map[MatchModel.fPickupAddress], 'Parque Calderón');
      expect(map[MatchModel.fDistanceToPickup], 350);

      final schedule = map[MatchModel.fSchedule] as Map<String, dynamic>;
      expect(schedule[MatchModel.fScheduleType], 'recurring');
      expect(schedule[MatchModel.fScheduleDays], ['mon', 'tue', 'wed']);
      expect(schedule[MatchModel.fScheduleStartDate], isA<Timestamp>());

      final pricing = map[MatchModel.fPricing] as Map<String, dynamic>;
      expect(pricing[MatchModel.fPricingType], 'perTrip');
      expect(pricing[MatchModel.fPricingAmount], 2.5);
    });

    test('toCreateMap uses server timestamps for createdAt/updatedAt', () {
      final map = MatchModel.toCreateMap(_sample());
      expect(map[MatchModel.fCreatedAt], isA<FieldValue>());
      expect(map[MatchModel.fUpdatedAt], isA<FieldValue>());
    });

    test('fromMap round-trip preserves all relevant fields', () {
      final original = _sample();
      final map = MatchModel.toMap(original);
      final reconstructed = MatchModel.fromMap('m1', map);

      expect(reconstructed, equals(original));
    });

    test('fromMap tolerates missing schedule/pricing with defaults', () {
      final reconstructed = MatchModel.fromMap('m2', {
        MatchModel.fPassengerId: 'p1',
        MatchModel.fDriverId: 'd1',
        MatchModel.fRouteId: 'r1',
        MatchModel.fStatus: 'accepted',
        MatchModel.fPickupLat: 0,
        MatchModel.fPickupLng: 0,
        MatchModel.fPickupAddress: '',
        MatchModel.fDropoffLat: 0,
        MatchModel.fDropoffLng: 0,
        MatchModel.fDropoffAddress: '',
        MatchModel.fDistanceToPickup: 0,
        MatchModel.fDistanceToDropoff: 0,
        MatchModel.fDetourDuration: 0,
        MatchModel.fCreatedAt: Timestamp.fromDate(DateTime(2026, 1, 1)),
      });

      expect(reconstructed.status, MatchStatus.accepted);
      expect(reconstructed.days, isEmpty);
      expect(reconstructed.pricingType, 'perTrip');
      expect(reconstructed.price, 0);
      expect(reconstructed.tripType, MatchTripType.oneTime);
    });
  });
}
