import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yo_te_llevo/core/errors/failures.dart';
import 'package:yo_te_llevo/core/utils/lat_lng.dart';
import 'package:yo_te_llevo/core/utils/polyline_utils.dart';
import 'package:yo_te_llevo/features/matching/data/services/matching_engine.dart';
import 'package:yo_te_llevo/features/matching/domain/entities/match_candidate.dart';
import 'package:yo_te_llevo/features/matching/domain/entities/match_search_input.dart';
import 'package:yo_te_llevo/features/routes/domain/entities/detour_result.dart';
import 'package:yo_te_llevo/features/routes/domain/entities/pricing_type.dart';
import 'package:yo_te_llevo/features/routes/domain/entities/route_result.dart';
import 'package:yo_te_llevo/features/routes/domain/entities/route_entity.dart';
import 'package:yo_te_llevo/features/routes/domain/entities/route_pricing.dart';
import 'package:yo_te_llevo/features/routes/domain/entities/route_schedule.dart';
import 'package:yo_te_llevo/features/routes/domain/repositories/driver_route_repository.dart';
import 'package:yo_te_llevo/features/routes/domain/repositories/mapbox_repository.dart';

class MockDriverRouteRepository extends Mock implements DriverRouteRepository {}

class MockMapboxRepository extends Mock implements MapboxRepository {}

RouteEntity _route({
  String id = 'r1',
  LatLng origin = const LatLng(0, 0),
  LatLng destination = const LatLng(0, 0.03),
  List<LatLng> polylinePoints = const [
    LatLng(0, 0),
    LatLng(0, 0.01),
    LatLng(0, 0.02),
    LatLng(0, 0.03),
  ],
  List<String> days = const ['mon', 'tue', 'wed'],
  double price = 2.0,
  int availableSeats = 3,
  bool isActive = true,
}) {
  return RouteEntity(
    id: id,
    driverId: 'd1',
    origin: origin,
    originAddress: 'O',
    destination: destination,
    destinationAddress: 'D',
    polylineEncoded: 'enc',
    polylinePoints: polylinePoints,
    geohashOrigin: 'gh1',
    geohashDestination: 'gh2',
    distanceMeters: 3300,
    durationSeconds: 300,
    schedule: RouteSchedule(days: days, departureTime: '08:00'),
    pricing: RoutePricing(type: PricingType.perTrip, amount: price),
    availableSeats: availableSeats,
    isActive: isActive,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  late MockDriverRouteRepository mockRouteRepo;
  late MockMapboxRepository mockMapboxRepo;
  late MatchingEngine engine;

  setUpAll(() {
    registerFallbackValue(const LatLng(0, 0));
    registerFallbackValue(<LatLng>[]);
  });

  setUp(() {
    mockRouteRepo = MockDriverRouteRepository();
    mockMapboxRepo = MockMapboxRepository();
    engine = MatchingEngine(mockRouteRepo, mockMapboxRepo);
  });

  group('phase1Filter', () {
    const input = MatchSearchInput(
      origin: LatLng(0, 0),
      destination: LatLng(0, 0.03),
      days: ['mon', 'fri'],
    );

    test('keeps route when days intersect and extremes are within 5km', () {
      final result = engine.phase1Filter([_route()], input);
      expect(result, hasLength(1));
    });

    test('discards route with no day intersection', () {
      final result = engine.phase1Filter(
        [_route(days: const ['sat', 'sun'])],
        input,
      );
      expect(result, isEmpty);
    });

    test('discards inactive routes', () {
      final result = engine.phase1Filter([_route(isActive: false)], input);
      expect(result, isEmpty);
    });

    test('discards routes with no available seats', () {
      final result = engine.phase1Filter([_route(availableSeats: 0)], input);
      expect(result, isEmpty);
    });

    test('discards route whose extremes are both farther than 5km', () {
      final farRoute = _route(
        origin: const LatLng(1, 1),
        destination: const LatLng(1, 1.03),
      );
      final result = engine.phase1Filter([farRoute], input);
      expect(result, isEmpty);
    });

    test('accepts when passenger origin is near route destination', () {
      final passengerNearDest = const MatchSearchInput(
        origin: LatLng(0, 0.03),
        destination: LatLng(0, 0),
        days: ['mon'],
      );
      final result = engine.phase1Filter([_route()], passengerNearDest);
      expect(result, hasLength(1));
    });
  });

  group('phase2Polyline', () {
    const input = MatchSearchInput(
      origin: LatLng(0.0001, 0.005),
      destination: LatLng(0.0001, 0.025),
      days: ['mon'],
    );

    setUp(() {
      when(() => mockMapboxRepo.getCachedPolyline(any()))
          .thenReturn(const Right(null));
    });

    test('accepts when pickup/dropoff within 800m and direction correct',
        () async {
      final result = await engine.phase2Polyline([_route()], input);
      expect(result, hasLength(1));
      expect(result.first.pickup.distance, lessThan(800));
      expect(result.first.dropoff.distance, lessThan(800));
    });

    test('discards when passenger origin is farther than 800m from polyline',
        () async {
      final far = const MatchSearchInput(
        origin: LatLng(0.02, 0.005),
        destination: LatLng(0.0001, 0.025),
        days: ['mon'],
      );
      final result = await engine.phase2Polyline([_route()], far);
      expect(result, isEmpty);
    });

    test('discards when direction is wrong (pickup after dropoff)', () async {
      final reversed = const MatchSearchInput(
        origin: LatLng(0.0001, 0.025),
        destination: LatLng(0.0001, 0.005),
        days: ['mon'],
      );
      final result = await engine.phase2Polyline([_route()], reversed);
      expect(result, isEmpty);
    });

    test('uses Mapbox fallback when no cache and no entity polyline',
        () async {
      when(() => mockMapboxRepo.getRoute(any())).thenAnswer(
        (_) async => const Right(RouteResult(
          polylineEncoded: 'fallback',
          polylineDecoded: [
            LatLng(0, 0),
            LatLng(0, 0.01),
            LatLng(0, 0.02),
            LatLng(0, 0.03),
          ],
          distanceMeters: 3300,
          durationSeconds: 300,
        )),
      );
      when(() => mockMapboxRepo.cachePolyline(any(), any()))
          .thenAnswer((_) async => const Right(null));

      final routeNoPolyline = _route(polylinePoints: const []);
      final result = await engine.phase2Polyline([routeNoPolyline], input);

      expect(result, hasLength(1));
      verify(() => mockMapboxRepo.getRoute(any())).called(1);
      verify(() => mockMapboxRepo.cachePolyline('r1', 'fallback')).called(1);
    });
  });

  group('phase3Detour', () {
    late Phase2Result phase2Result;

    setUp(() {
      phase2Result = Phase2Result(
        route: _route(),
        polyline: const [
          LatLng(0, 0),
          LatLng(0, 0.01),
          LatLng(0, 0.02),
          LatLng(0, 0.03),
        ],
        pickup: const NearestPointResult(
          point: LatLng(0, 0.005),
          distance: 50,
          segmentIndex: 0,
        ),
        dropoff: const NearestPointResult(
          point: LatLng(0, 0.025),
          distance: 60,
          segmentIndex: 2,
        ),
      );
    });

    test('builds MatchCandidate on success', () async {
      const fullRoute = RouteResult(
        polylineEncoded: 'det',
        polylineDecoded: [LatLng(0, 0), LatLng(0, 0.03)],
        distanceMeters: 3400,
        durationSeconds: 400,
      );
      when(() => mockMapboxRepo.calculateDetour(
            driverOrigin: any(named: 'driverOrigin'),
            driverDestination: any(named: 'driverDestination'),
            passengerPickup: any(named: 'passengerPickup'),
            passengerDropoff: any(named: 'passengerDropoff'),
            originalDurationSeconds: any(named: 'originalDurationSeconds'),
            originalDistanceMeters: any(named: 'originalDistanceMeters'),
          )).thenAnswer((_) async => const Right(DetourResult(
            extraSeconds: 100,
            extraMeters: 100,
            totalDurationSeconds: 400,
            totalDistanceMeters: 3400,
            fullRoute: fullRoute,
          )));
      when(() => mockMapboxRepo.reverseGeocode(const LatLng(0, 0.005)))
          .thenAnswer((_) async => const Right('Pickup St'));
      when(() => mockMapboxRepo.reverseGeocode(const LatLng(0, 0.025)))
          .thenAnswer((_) async => const Right('Dropoff Ave'));

      final result = await engine.phase3Detour([phase2Result]);

      expect(result, hasLength(1));
      expect(result.first.pickupAddress, 'Pickup St');
      expect(result.first.dropoffAddress, 'Dropoff Ave');
      expect(result.first.detourSeconds, 100);
    });

    test('discards candidate when detour exceeds max', () async {
      const fullRoute = RouteResult(
        polylineEncoded: 'det',
        polylineDecoded: [],
        distanceMeters: 5000,
        durationSeconds: 1200,
      );
      when(() => mockMapboxRepo.calculateDetour(
            driverOrigin: any(named: 'driverOrigin'),
            driverDestination: any(named: 'driverDestination'),
            passengerPickup: any(named: 'passengerPickup'),
            passengerDropoff: any(named: 'passengerDropoff'),
            originalDurationSeconds: any(named: 'originalDurationSeconds'),
            originalDistanceMeters: any(named: 'originalDistanceMeters'),
          )).thenAnswer((_) async => const Right(DetourResult(
            extraSeconds: 900,
            extraMeters: 500,
            totalDurationSeconds: 1200,
            totalDistanceMeters: 5000,
            fullRoute: fullRoute,
          )));
      when(() => mockMapboxRepo.reverseGeocode(any()))
          .thenAnswer((_) async => const Right('addr'));

      final result = await engine.phase3Detour([phase2Result]);
      expect(result, isEmpty);
    });

    test('skips candidate when an API call fails without aborting batch',
        () async {
      when(() => mockMapboxRepo.calculateDetour(
            driverOrigin: any(named: 'driverOrigin'),
            driverDestination: any(named: 'driverDestination'),
            passengerPickup: any(named: 'passengerPickup'),
            passengerDropoff: any(named: 'passengerDropoff'),
            originalDurationSeconds: any(named: 'originalDurationSeconds'),
            originalDistanceMeters: any(named: 'originalDistanceMeters'),
          )).thenAnswer(
              (_) async => const Left(ServerFailure(message: 'api down')));
      when(() => mockMapboxRepo.reverseGeocode(any()))
          .thenAnswer((_) async => const Right('addr'));

      final result = await engine.phase3Detour([phase2Result]);
      expect(result, isEmpty);
    });
  });

  group('rank', () {
    MatchCandidate build({
      required double distance,
      required double detour,
      required double price,
      required String routeId,
    }) {
      return MatchCandidate(
        route: _route(id: routeId, price: price),
        pickupPoint: const LatLng(0, 0),
        pickupAddress: 'p',
        dropoffPoint: const LatLng(0, 0.03),
        dropoffAddress: 'd',
        distanceToPickupMeters: distance,
        distanceToDropoffMeters: distance,
        detourSeconds: detour,
        detourMeters: 10,
        fullRouteWithDetour: const [],
        price: price,
        pricingType: PricingType.perTrip,
      );
    }

    test('orders by distance → detour → price', () {
      final candidates = [
        build(distance: 500, detour: 100, price: 2.0, routeId: 'c'),
        build(distance: 100, detour: 300, price: 3.0, routeId: 'a'),
        build(distance: 100, detour: 200, price: 5.0, routeId: 'b'),
        build(distance: 100, detour: 200, price: 1.0, routeId: 'first'),
      ];
      final sorted = engine.rank(candidates);
      expect(sorted.map((c) => c.route.id).toList(),
          ['first', 'b', 'a', 'c']);
    });
  });
}
