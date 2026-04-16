import 'package:flutter_test/flutter_test.dart';
import 'package:yo_te_llevo/core/utils/lat_lng.dart';
import 'package:yo_te_llevo/features/matching/domain/entities/match.dart';
import 'package:yo_te_llevo/features/matching/domain/entities/match_status.dart';
import 'package:yo_te_llevo/features/trips/domain/entities/trip.dart';

Match _match({
  String id = 'm1',
  String passengerId = 'p1',
  String driverId = 'd1',
  MatchStatus status = MatchStatus.pending,
}) {
  return Match(
    id: id,
    passengerId: passengerId,
    driverId: driverId,
    routeId: 'r1',
    status: status,
    pickupPoint: const LatLng(0, 0),
    pickupAddress: 'pickup',
    dropoffPoint: const LatLng(0, 0.02),
    dropoffAddress: 'dropoff',
    distanceToPickupMeters: 100,
    distanceToDropoffMeters: 100,
    detourSeconds: 60,
    tripType: MatchTripType.recurring,
    days: const ['mon'],
    startDate: null,
    price: 2.0,
    pricingType: 'perTrip',
    createdAt: DateTime(2026, 4, 1),
  );
}

void main() {
  group('TripEntity', () {
    test('isPassengerView true when viewer is passenger', () {
      final trip = TripEntity(match: _match());
      expect(trip.isPassengerView('p1'), true);
      expect(trip.isPassengerView('d1'), false);
    });

    test('isParticipant detects both roles', () {
      final trip = TripEntity(match: _match());
      expect(trip.isParticipant('p1'), true);
      expect(trip.isParticipant('d1'), true);
      expect(trip.isParticipant('other'), false);
    });

    test('canCancel allows pending and accepted only', () {
      expect(
          TripEntity(match: _match(status: MatchStatus.pending)).canCancel, true);
      expect(
          TripEntity(match: _match(status: MatchStatus.accepted)).canCancel,
          true);
      expect(TripEntity(match: _match(status: MatchStatus.active)).canCancel,
          false);
      expect(
          TripEntity(match: _match(status: MatchStatus.completed)).canCancel,
          false);
      expect(
          TripEntity(match: _match(status: MatchStatus.cancelled)).canCancel,
          false);
    });

    test('canRespond only for driver on pending', () {
      final trip = TripEntity(match: _match(status: MatchStatus.pending));
      expect(trip.canRespond('d1'), true);
      expect(trip.canRespond('p1'), false);
    });

    test('canStart only for driver on accepted', () {
      final accepted = TripEntity(match: _match(status: MatchStatus.accepted));
      expect(accepted.canStart('d1'), true);
      expect(accepted.canStart('p1'), false);
      final pending = TripEntity(match: _match(status: MatchStatus.pending));
      expect(pending.canStart('d1'), false);
    });

    test('canComplete only for driver on active', () {
      final active = TripEntity(match: _match(status: MatchStatus.active));
      expect(active.canComplete('d1'), true);
      expect(active.canComplete('p1'), false);
    });

    test('canOpenChat true on accepted and active', () {
      expect(
          TripEntity(match: _match(status: MatchStatus.accepted)).canOpenChat,
          true);
      expect(
          TripEntity(match: _match(status: MatchStatus.active)).canOpenChat,
          true);
      expect(
          TripEntity(match: _match(status: MatchStatus.pending)).canOpenChat,
          false);
      expect(
          TripEntity(match: _match(status: MatchStatus.completed)).canOpenChat,
          false);
    });

    test('canRate only on completed', () {
      expect(
          TripEntity(match: _match(status: MatchStatus.completed)).canRate,
          true);
      expect(TripEntity(match: _match(status: MatchStatus.active)).canRate,
          false);
    });
  });
}
