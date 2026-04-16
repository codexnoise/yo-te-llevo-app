import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yo_te_llevo/core/errors/exceptions.dart';
import 'package:yo_te_llevo/core/errors/failures.dart';
import 'package:yo_te_llevo/core/network/network_info.dart';
import 'package:yo_te_llevo/core/utils/lat_lng.dart';
import 'package:yo_te_llevo/features/matching/domain/entities/match.dart';
import 'package:yo_te_llevo/features/matching/domain/entities/match_candidate.dart';
import 'package:yo_te_llevo/features/matching/domain/entities/match_status.dart';
import 'package:yo_te_llevo/features/profile/domain/entities/user_entity.dart';
import 'package:yo_te_llevo/features/profile/domain/entities/user_role.dart';
import 'package:yo_te_llevo/features/profile/domain/repositories/profile_repository.dart';
import 'package:yo_te_llevo/features/routes/domain/entities/pricing_type.dart';
import 'package:yo_te_llevo/features/routes/domain/entities/route_entity.dart';
import 'package:yo_te_llevo/features/routes/domain/entities/route_pricing.dart';
import 'package:yo_te_llevo/features/routes/domain/entities/route_schedule.dart';
import 'package:yo_te_llevo/features/routes/domain/repositories/driver_route_repository.dart';
import 'package:yo_te_llevo/features/trips/data/datasources/trip_remote_datasource.dart';
import 'package:yo_te_llevo/features/trips/data/repositories/trip_repository_impl.dart';

class MockTripRemoteDataSource extends Mock implements TripRemoteDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockDriverRouteRepository extends Mock implements DriverRouteRepository {}

class _FakeMatch extends Fake implements Match {}

RouteEntity _route() => RouteEntity(
      id: 'r1',
      driverId: 'd1',
      origin: const LatLng(0, 0),
      originAddress: 'O',
      destination: const LatLng(0, 0.03),
      destinationAddress: 'D',
      polylineEncoded: 'enc',
      polylinePoints: const [LatLng(0, 0), LatLng(0, 0.03)],
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
      pickupPoint: const LatLng(0, 0.005),
      pickupAddress: 'pickup',
      dropoffPoint: const LatLng(0, 0.025),
      dropoffAddress: 'dropoff',
      distanceToPickupMeters: 100,
      distanceToDropoffMeters: 120,
      detourSeconds: 60,
      detourMeters: 10,
      fullRouteWithDetour: const [],
      price: 2.0,
      pricingType: PricingType.perTrip,
    );

Match _match({MatchStatus status = MatchStatus.pending}) => Match(
      id: 'm1',
      passengerId: 'p1',
      driverId: 'd1',
      routeId: 'r1',
      status: status,
      pickupPoint: const LatLng(0, 0.005),
      pickupAddress: 'pickup',
      dropoffPoint: const LatLng(0, 0.025),
      dropoffAddress: 'dropoff',
      distanceToPickupMeters: 100,
      distanceToDropoffMeters: 120,
      detourSeconds: 60,
      tripType: MatchTripType.recurring,
      days: const ['mon'],
      startDate: null,
      price: 2.0,
      pricingType: 'perTrip',
      createdAt: DateTime(2026, 4, 10),
    );

UserEntity _user(String id, String name) => UserEntity(
      id: id,
      name: name,
      email: '$id@example.com',
      role: UserRole.both,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  late MockTripRemoteDataSource remote;
  late MockNetworkInfo network;
  late MockProfileRepository profile;
  late MockDriverRouteRepository routes;
  late TripRepositoryImpl repo;

  setUpAll(() {
    registerFallbackValue(_FakeMatch());
    registerFallbackValue(MatchStatus.pending);
  });

  setUp(() {
    remote = MockTripRemoteDataSource();
    network = MockNetworkInfo();
    profile = MockProfileRepository();
    routes = MockDriverRouteRepository();
    repo = TripRepositoryImpl(
      remote: remote,
      networkInfo: network,
      profileRepository: profile,
      routeRepository: routes,
    );

    when(() => network.isConnected).thenAnswer((_) async => true);
    when(() => profile.getUser(any()))
        .thenAnswer((inv) async => Right(_user(inv.positionalArguments[0] as String, 'User')));
    when(() => routes.getRoute(any())).thenAnswer((_) async => Right(_route()));
  });

  group('requestTrip', () {
    test('returns NetworkFailure when offline', () async {
      when(() => network.isConnected).thenAnswer((_) async => false);
      final result = await repo.requestTrip(
        candidate: _candidate(),
        passengerId: 'p1',
      );
      expect(result.isLeft(), true);
      verifyNever(() => remote.createMatch(any()));
    });

    test('creates match and enriches with counterpart and route', () async {
      when(() => remote.createMatch(any())).thenAnswer((_) async => _match());
      final result = await repo.requestTrip(
        candidate: _candidate(),
        passengerId: 'p1',
      );
      expect(result.isRight(), true);
      final trip = result.getOrElse(() => throw 'should be right');
      expect(trip.match.status, MatchStatus.pending);
      expect(trip.counterpart?.id, 'd1');
      expect(trip.route?.id, 'r1');
      verify(() => remote.createMatch(any())).called(1);
    });

    test('ServerException from remote becomes ServerFailure', () async {
      when(() => remote.createMatch(any()))
          .thenThrow(const ServerException(message: 'permission-denied'));
      final result = await repo.requestTrip(
        candidate: _candidate(),
        passengerId: 'p1',
      );
      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('Should be Left'),
      );
    });
  });

  group('respondToRequest', () {
    test('rejects decision != accepted|rejected', () async {
      final result = await repo.respondToRequest(
        matchId: 'm1',
        decision: MatchStatus.active,
      );
      expect(result.isLeft(), true);
    });

    test('blocks when current status != pending', () async {
      when(() => remote.getMatch('m1'))
          .thenAnswer((_) async => _match(status: MatchStatus.accepted));
      final result = await repo.respondToRequest(
        matchId: 'm1',
        decision: MatchStatus.accepted,
      );
      expect(result.isLeft(), true);
      verifyNever(() => remote.updateStatus(any(), any()));
    });

    test('accepts transition from pending', () async {
      when(() => remote.getMatch('m1')).thenAnswer((_) async => _match());
      when(() => remote.updateStatus(any(), any())).thenAnswer((_) async {});
      final result = await repo.respondToRequest(
        matchId: 'm1',
        decision: MatchStatus.accepted,
      );
      expect(result.isRight(), true);
      verify(() => remote.updateStatus('m1', MatchStatus.accepted)).called(1);
    });
  });

  group('cancelTrip', () {
    test('blocks when status is active', () async {
      when(() => remote.getMatch('m1'))
          .thenAnswer((_) async => _match(status: MatchStatus.active));
      final result = await repo.cancelTrip('m1');
      expect(result.isLeft(), true);
    });

    test('cancels from accepted', () async {
      when(() => remote.getMatch('m1'))
          .thenAnswer((_) async => _match(status: MatchStatus.accepted));
      when(() => remote.updateStatus(any(), any())).thenAnswer((_) async {});
      final result = await repo.cancelTrip('m1');
      expect(result.isRight(), true);
      verify(() => remote.updateStatus('m1', MatchStatus.cancelled)).called(1);
    });
  });

  group('markActive / markCompleted', () {
    test('markActive requires accepted', () async {
      when(() => remote.getMatch('m1')).thenAnswer((_) async => _match());
      final result = await repo.markActive('m1');
      expect(result.isLeft(), true);
    });

    test('markCompleted requires active', () async {
      when(() => remote.getMatch('m1'))
          .thenAnswer((_) async => _match(status: MatchStatus.active));
      when(() => remote.updateStatus(any(), any())).thenAnswer((_) async {});
      final result = await repo.markCompleted('m1');
      expect(result.isRight(), true);
      verify(() => remote.updateStatus('m1', MatchStatus.completed)).called(1);
    });
  });

  group('watchActiveTrips', () {
    test('wraps stream with Right and enriches each match', () async {
      final controller = StreamController<List<Match>>();
      when(() => remote.watchActiveTrips('p1'))
          .thenAnswer((_) => controller.stream);

      final events = <List<String>>[];
      final sub = repo.watchActiveTrips('p1').listen((either) {
        either.fold(
          (f) => fail('unexpected failure: $f'),
          (trips) => events.add(trips.map((t) => t.id).toList()),
        );
      });

      controller.add([_match()]);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      controller.add([_match(status: MatchStatus.accepted), _match()]);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await sub.cancel();
      await controller.close();

      expect(events.length, 2);
      expect(events.first, ['m1']);
      expect(events.last.length, 2);
    });
  });

  group('getHistory', () {
    test('returns enriched trips', () async {
      when(() => remote.getHistory('p1', limit: any(named: 'limit')))
          .thenAnswer((_) async => [_match(status: MatchStatus.completed)]);
      final result = await repo.getHistory('p1');
      expect(result.isRight(), true);
      final trips = result.getOrElse(() => throw 'right expected');
      expect(trips.length, 1);
      expect(trips.first.counterpart?.id, 'd1');
    });
  });
}
