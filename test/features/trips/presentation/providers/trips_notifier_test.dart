import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yo_te_llevo/core/errors/failures.dart';
import 'package:yo_te_llevo/core/utils/lat_lng.dart';
import 'package:yo_te_llevo/features/matching/domain/entities/match.dart';
import 'package:yo_te_llevo/features/matching/domain/entities/match_candidate.dart';
import 'package:yo_te_llevo/features/matching/domain/entities/match_status.dart';
import 'package:yo_te_llevo/features/routes/domain/entities/pricing_type.dart';
import 'package:yo_te_llevo/features/routes/domain/entities/route_entity.dart';
import 'package:yo_te_llevo/features/routes/domain/entities/route_pricing.dart';
import 'package:yo_te_llevo/features/routes/domain/entities/route_schedule.dart';
import 'package:yo_te_llevo/features/trips/domain/entities/trip.dart';
import 'package:yo_te_llevo/features/trips/domain/entities/trip_occurrence.dart';
import 'package:yo_te_llevo/features/trips/domain/repositories/trip_occurrence_repository.dart';
import 'package:yo_te_llevo/features/trips/domain/repositories/trip_repository.dart';
import 'package:yo_te_llevo/features/trips/presentation/providers/trips_notifier.dart';

class MockTripRepository extends Mock implements TripRepository {}

class MockTripOccurrenceRepository extends Mock
    implements TripOccurrenceRepository {}

class _FakeCandidate extends Fake implements MatchCandidate {}

RouteEntity _route() => RouteEntity(
      id: 'r1',
      driverId: 'd1',
      origin: const LatLng(0, 0),
      originAddress: 'O',
      destination: const LatLng(0, 0.03),
      destinationAddress: 'D',
      polylineEncoded: 'enc',
      polylinePoints: const [LatLng(0, 0)],
      geohashOrigin: 'gh',
      geohashDestination: 'gh',
      distanceMeters: 3000,
      durationSeconds: 300,
      schedule: const RouteSchedule(days: ['mon'], departureTime: '08:00'),
      pricing: const RoutePricing(type: PricingType.perTrip, amount: 2.0),
      availableSeats: 3,
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
    );

MatchCandidate _candidate() => MatchCandidate(
      route: _route(),
      pickupPoint: const LatLng(0, 0),
      pickupAddress: 'p',
      dropoffPoint: const LatLng(0, 0.02),
      dropoffAddress: 'd',
      distanceToPickupMeters: 100,
      distanceToDropoffMeters: 100,
      detourSeconds: 60,
      detourMeters: 10,
      fullRouteWithDetour: const [],
      price: 2.0,
      pricingType: PricingType.perTrip,
    );

Match _match({
  MatchStatus status = MatchStatus.pending,
  MatchTripType tripType = MatchTripType.recurring,
}) =>
    Match(
      id: 'm1',
      passengerId: 'p1',
      driverId: 'd1',
      routeId: 'r1',
      status: status,
      pickupPoint: const LatLng(0, 0),
      pickupAddress: 'p',
      dropoffPoint: const LatLng(0, 0.02),
      dropoffAddress: 'd',
      distanceToPickupMeters: 100,
      distanceToDropoffMeters: 100,
      detourSeconds: 60,
      tripType: tripType,
      days: const ['mon'],
      startDate: null,
      price: 2.0,
      pricingType: 'perTrip',
      createdAt: DateTime(2026, 4, 1),
    );

void main() {
  late MockTripRepository repo;
  late MockTripOccurrenceRepository occRepo;
  late TripsNotifier notifier;

  setUpAll(() {
    registerFallbackValue(_FakeCandidate());
    registerFallbackValue(MatchStatus.pending);
    registerFallbackValue(MatchTripType.oneTime);
  });

  setUp(() {
    repo = MockTripRepository();
    occRepo = MockTripOccurrenceRepository();
    notifier = TripsNotifier(repo, occRepo);
  });

  group('requestTrip', () {
    test('emits data(null) on success and returns the trip', () async {
      when(() => repo.requestTrip(
            candidate: any(named: 'candidate'),
            passengerId: any(named: 'passengerId'),
            tripType: any(named: 'tripType'),
            selectedDays: any(named: 'selectedDays'),
            endDate: any(named: 'endDate'),
          )).thenAnswer((_) async => Right(TripEntity(match: _match())));

      final trip = await notifier.requestTrip(
        candidate: _candidate(),
        passengerId: 'p1',
      );

      expect(trip, isNotNull);
      expect(notifier.state, const AsyncValue<void>.data(null));
    });

    test('emits error and returns null on failure', () async {
      when(() => repo.requestTrip(
            candidate: any(named: 'candidate'),
            passengerId: any(named: 'passengerId'),
            tripType: any(named: 'tripType'),
            selectedDays: any(named: 'selectedDays'),
            endDate: any(named: 'endDate'),
          )).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'boom')),
      );

      final trip = await notifier.requestTrip(
        candidate: _candidate(),
        passengerId: 'p1',
      );

      expect(trip, isNull);
      expect(notifier.state, isA<AsyncError<void>>());
    });

    test('forwards tripType, selectedDays and endDate to the repo', () async {
      when(() => repo.requestTrip(
            candidate: any(named: 'candidate'),
            passengerId: any(named: 'passengerId'),
            tripType: any(named: 'tripType'),
            selectedDays: any(named: 'selectedDays'),
            endDate: any(named: 'endDate'),
          )).thenAnswer((_) async => Right(TripEntity(match: _match())));

      final endDate = DateTime(2026, 6, 30);
      await notifier.requestTrip(
        candidate: _candidate(),
        passengerId: 'p1',
        tripType: MatchTripType.recurring,
        selectedDays: const ['mon', 'wed'],
        endDate: endDate,
      );

      verify(() => repo.requestTrip(
            candidate: any(named: 'candidate'),
            passengerId: 'p1',
            tripType: MatchTripType.recurring,
            selectedDays: const ['mon', 'wed'],
            endDate: endDate,
          )).called(1);
    });
  });

  group('accept / reject', () {
    test('accept on recurring match invokes seedInitialOccurrences',
        () async {
      when(() => repo.respondToRequest(
            matchId: any(named: 'matchId'),
            decision: any(named: 'decision'),
          )).thenAnswer((_) async => const Right(null));
      when(() => repo.getTrip('m1'))
          .thenAnswer((_) async => Right(TripEntity(
                match: _match(tripType: MatchTripType.recurring),
              )));
      when(() => occRepo.seedInitialOccurrences('m1'))
          .thenAnswer((_) async => const Right(<TripOccurrence>[]));

      final ok = await notifier.accept('m1');

      expect(ok, true);
      verify(() => repo.respondToRequest(
            matchId: 'm1',
            decision: MatchStatus.accepted,
          )).called(1);
      verify(() => occRepo.seedInitialOccurrences('m1')).called(1);
    });

    test('accept on oneTime match does NOT invoke seed', () async {
      when(() => repo.respondToRequest(
            matchId: any(named: 'matchId'),
            decision: any(named: 'decision'),
          )).thenAnswer((_) async => const Right(null));
      when(() => repo.getTrip('m1'))
          .thenAnswer((_) async => Right(TripEntity(
                match: _match(tripType: MatchTripType.oneTime),
              )));

      final ok = await notifier.accept('m1');

      expect(ok, true);
      verifyNever(() => occRepo.seedInitialOccurrences(any()));
    });

    test('seed failure does not degrade accept', () async {
      when(() => repo.respondToRequest(
            matchId: any(named: 'matchId'),
            decision: any(named: 'decision'),
          )).thenAnswer((_) async => const Right(null));
      when(() => repo.getTrip('m1'))
          .thenAnswer((_) async => Right(TripEntity(
                match: _match(tripType: MatchTripType.recurring),
              )));
      when(() => occRepo.seedInitialOccurrences('m1')).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'seed failed')),
      );

      final ok = await notifier.accept('m1');

      expect(ok, true);
    });

    test('reject on failure sets error and returns false', () async {
      when(() => repo.respondToRequest(
            matchId: any(named: 'matchId'),
            decision: any(named: 'decision'),
          )).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'nope')),
      );

      final ok = await notifier.reject('m1');
      expect(ok, false);
      expect(notifier.state, isA<AsyncError<void>>());
    });
  });

  test('cancel calls repo.cancelTrip', () async {
    when(() => repo.cancelTrip('m1'))
        .thenAnswer((_) async => const Right(null));
    final ok = await notifier.cancel('m1');
    expect(ok, true);
    verify(() => repo.cancelTrip('m1')).called(1);
  });

  test('start calls repo.markActive', () async {
    when(() => repo.markActive('m1'))
        .thenAnswer((_) async => const Right(null));
    final ok = await notifier.start('m1');
    expect(ok, true);
  });

  test('complete calls repo.markCompleted', () async {
    when(() => repo.markCompleted('m1'))
        .thenAnswer((_) async => const Right(null));
    final ok = await notifier.complete('m1');
    expect(ok, true);
  });
}
