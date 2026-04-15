import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yo_te_llevo/core/errors/failures.dart';
import 'package:yo_te_llevo/core/network/network_info.dart';
import 'package:yo_te_llevo/core/utils/lat_lng.dart';
import 'package:yo_te_llevo/features/matching/data/repositories/matching_repository_impl.dart';
import 'package:yo_te_llevo/features/matching/data/services/matching_engine.dart';
import 'package:yo_te_llevo/features/matching/domain/entities/match_candidate.dart';
import 'package:yo_te_llevo/features/matching/domain/entities/match_search_input.dart';
import 'package:yo_te_llevo/features/routes/domain/entities/route_entity.dart';
import 'package:yo_te_llevo/features/routes/domain/repositories/driver_route_repository.dart';
import 'package:yo_te_llevo/features/routes/domain/repositories/mapbox_repository.dart';

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockDriverRouteRepository extends Mock implements DriverRouteRepository {}

class MockMapboxRepository extends Mock implements MapboxRepository {}

void main() {
  late MockNetworkInfo network;
  late MockDriverRouteRepository routeRepo;
  late MockMapboxRepository mapboxRepo;
  late MatchingRepositoryImpl repo;

  setUpAll(() {
    registerFallbackValue(const LatLng(0, 0));
  });

  setUp(() {
    network = MockNetworkInfo();
    routeRepo = MockDriverRouteRepository();
    mapboxRepo = MockMapboxRepository();
    repo = MatchingRepositoryImpl(
      engine: MatchingEngine(routeRepo, mapboxRepo),
      networkInfo: network,
    );
  });

  const input = MatchSearchInput(
    origin: LatLng(0, 0),
    destination: LatLng(0, 0.03),
    days: ['mon'],
  );

  test('returns NetworkFailure when offline', () async {
    when(() => network.isConnected).thenAnswer((_) async => false);

    final result = await repo.searchMatches(input);

    expect(result, isA<Left>());
    result.fold(
      (failure) => expect(failure, isA<NetworkFailure>()),
      (_) => fail('expected Left'),
    );
  });

  test('propagates failure from findRoutesNearby', () async {
    when(() => network.isConnected).thenAnswer((_) async => true);
    when(() => routeRepo.findRoutesNearby(any())).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'firestore down')));

    final result = await repo.searchMatches(input);

    result.fold(
      (failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, 'firestore down');
      },
      (_) => fail('expected Left'),
    );
  });

  test('returns empty list when no nearby routes', () async {
    when(() => network.isConnected).thenAnswer((_) async => true);
    when(() => routeRepo.findRoutesNearby(any()))
        .thenAnswer((_) async => const Right(<RouteEntity>[]));

    final result = await repo.searchMatches(input);

    expect(result, const Right<Failure, List<MatchCandidate>>([]));
  });
}
