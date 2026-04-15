import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yo_te_llevo/core/errors/failures.dart';
import 'package:yo_te_llevo/core/utils/lat_lng.dart';
import 'package:yo_te_llevo/features/matching/domain/entities/match_candidate.dart';
import 'package:yo_te_llevo/features/matching/domain/entities/match_search_input.dart';
import 'package:yo_te_llevo/features/matching/domain/repositories/matching_repository.dart';
import 'package:yo_te_llevo/features/matching/presentation/providers/matching_notifier.dart';
import 'package:yo_te_llevo/features/routes/domain/entities/pricing_type.dart';
import 'package:yo_te_llevo/features/routes/domain/entities/route_entity.dart';
import 'package:yo_te_llevo/features/routes/domain/entities/route_pricing.dart';
import 'package:yo_te_llevo/features/routes/domain/entities/route_schedule.dart';

class MockMatchingRepository extends Mock implements MatchingRepository {}

class _FakeMatchSearchInput extends Fake implements MatchSearchInput {}

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
      pickupAddress: 'p',
      dropoffPoint: const LatLng(0, 0.025),
      dropoffAddress: 'd',
      distanceToPickupMeters: 100,
      distanceToDropoffMeters: 120,
      detourSeconds: 60,
      detourMeters: 10,
      fullRouteWithDetour: const [],
      price: 2.0,
      pricingType: PricingType.perTrip,
    );

void main() {
  late MockMatchingRepository repo;
  late MatchingNotifier notifier;

  setUpAll(() {
    registerFallbackValue(_FakeMatchSearchInput());
  });

  setUp(() {
    repo = MockMatchingRepository();
    notifier = MatchingNotifier(repo);
  });

  const input = MatchSearchInput(
    origin: LatLng(0, 0),
    destination: LatLng(0, 0.03),
    days: ['mon'],
  );

  test('initial state is empty and not searching', () {
    expect(notifier.state.isSearching, false);
    expect(notifier.state.candidates, isEmpty);
    expect(notifier.state.error, isNull);
  });

  test('searchMatches sets isSearching true then populates candidates',
      () async {
    final candidates = [_candidate()];
    when(() => repo.searchMatches(any()))
        .thenAnswer((_) async => Right(candidates));

    final future = notifier.searchMatches(input);
    expect(notifier.state.isSearching, true);
    expect(notifier.state.lastInput, input);

    await future;
    expect(notifier.state.isSearching, false);
    expect(notifier.state.candidates, candidates);
    expect(notifier.state.error, isNull);
  });

  test('searchMatches stores failure on Left', () async {
    when(() => repo.searchMatches(any())).thenAnswer(
        (_) async => const Left(NetworkFailure(message: 'offline')));

    await notifier.searchMatches(input);

    expect(notifier.state.isSearching, false);
    expect(notifier.state.error, isA<NetworkFailure>());
    expect(notifier.state.candidates, isEmpty);
  });

  test('clear resets state to initial', () async {
    when(() => repo.searchMatches(any()))
        .thenAnswer((_) async => Right([_candidate()]));
    await notifier.searchMatches(input);

    notifier.clear();

    expect(notifier.state.isSearching, false);
    expect(notifier.state.candidates, isEmpty);
    expect(notifier.state.error, isNull);
    expect(notifier.state.lastInput, isNull);
  });
}
