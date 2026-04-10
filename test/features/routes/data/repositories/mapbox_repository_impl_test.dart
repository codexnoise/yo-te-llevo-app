import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yo_te_llevo/core/errors/exceptions.dart';
import 'package:yo_te_llevo/core/errors/failures.dart';
import 'package:yo_te_llevo/core/network/network_info.dart';
import 'package:yo_te_llevo/core/utils/lat_lng.dart';
import 'package:yo_te_llevo/features/routes/data/datasources/mapbox_directions_datasource.dart';
import 'package:yo_te_llevo/features/routes/data/datasources/mapbox_geocoding_datasource.dart';
import 'package:yo_te_llevo/features/routes/data/datasources/polyline_cache_datasource.dart';
import 'package:yo_te_llevo/features/routes/data/models/geocoding_result_model.dart';
import 'package:yo_te_llevo/features/routes/data/models/route_result_model.dart';
import 'package:yo_te_llevo/features/routes/data/repositories/mapbox_repository_impl.dart';

class MockDirectionsDataSource extends Mock
    implements MapboxDirectionsDataSource {}

class MockGeocodingDataSource extends Mock
    implements MapboxGeocodingDataSource {}

class MockPolylineCacheDataSource extends Mock
    implements PolylineCacheDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late MapboxRepositoryImpl repository;
  late MockDirectionsDataSource mockDirections;
  late MockGeocodingDataSource mockGeocoding;
  late MockPolylineCacheDataSource mockCache;
  late MockNetworkInfo mockNetwork;

  setUp(() {
    mockDirections = MockDirectionsDataSource();
    mockGeocoding = MockGeocodingDataSource();
    mockCache = MockPolylineCacheDataSource();
    mockNetwork = MockNetworkInfo();
    repository = MapboxRepositoryImpl(
      directionsDataSource: mockDirections,
      geocodingDataSource: mockGeocoding,
      cacheDataSource: mockCache,
      networkInfo: mockNetwork,
    );
  });

  setUpAll(() {
    registerFallbackValue(const LatLng(0, 0));
  });

  const testWaypoints = [
    LatLng(-2.8973, -79.0044),
    LatLng(-2.8895, -78.9844),
  ];

  const testRouteResult = RouteResultModel(
    polylineEncoded: 'abc123',
    polylineDecoded: [],
    distanceMeters: 1500,
    durationSeconds: 120,
  );

  group('getRoute', () {
    test('returns RouteResultModel on success', () async {
      when(() => mockNetwork.isConnected).thenAnswer((_) async => true);
      when(() => mockDirections.getRoute(testWaypoints))
          .thenAnswer((_) async => testRouteResult);

      final result = await repository.getRoute(testWaypoints);

      expect(result, const Right(testRouteResult));
      verify(() => mockDirections.getRoute(testWaypoints)).called(1);
    });

    test('returns NetworkFailure when offline', () async {
      when(() => mockNetwork.isConnected).thenAnswer((_) async => false);

      final result = await repository.getRoute(testWaypoints);

      expect(result, isA<Left>());
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Should be Left'),
      );
    });

    test('returns ServerFailure on ServerException', () async {
      when(() => mockNetwork.isConnected).thenAnswer((_) async => true);
      when(() => mockDirections.getRoute(testWaypoints))
          .thenThrow(const ServerException(message: 'API error'));

      final result = await repository.getRoute(testWaypoints);

      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'API error');
        },
        (_) => fail('Should be Left'),
      );
    });
  });

  group('calculateDetour', () {
    test('returns DetourResultModel with correct extra values', () async {
      when(() => mockNetwork.isConnected).thenAnswer((_) async => true);
      when(() => mockDirections.getRoute(any()))
          .thenAnswer((_) async => testRouteResult);

      final result = await repository.calculateDetour(
        driverOrigin: const LatLng(-2.90, -79.01),
        driverDestination: const LatLng(-2.88, -78.98),
        passengerPickup: const LatLng(-2.89, -79.00),
        passengerDropoff: const LatLng(-2.885, -78.99),
        originalDurationSeconds: 100,
        originalDistanceMeters: 1000,
      );

      result.fold(
        (failure) => fail('Should be Right: $failure'),
        (detour) {
          expect(detour.extraSeconds, 20); // 120 - 100
          expect(detour.extraMeters, 500); // 1500 - 1000
          expect(detour.totalDurationSeconds, 120);
          expect(detour.totalDistanceMeters, 1500);
          expect(detour.fullRoute, testRouteResult);
        },
      );
    });
  });

  group('search', () {
    const testResults = [
      GeocodingResultModel(
        name: 'Terminal',
        fullAddress: 'Terminal Terrestre, Cuenca',
        coordinates: LatLng(-2.8973, -79.0044),
      ),
    ];

    test('returns list on success', () async {
      when(() => mockNetwork.isConnected).thenAnswer((_) async => true);
      when(() => mockGeocoding.search(
            'Terminal',
            proximity: any(named: 'proximity'),
            country: any(named: 'country'),
          )).thenAnswer((_) async => testResults);

      final result = await repository.search('Terminal');

      expect(result, const Right(testResults));
    });

    test('returns NetworkFailure when offline', () async {
      when(() => mockNetwork.isConnected).thenAnswer((_) async => false);

      final result = await repository.search('Terminal');

      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Should be Left'),
      );
    });
  });

  group('reverseGeocode', () {
    test('returns address string on success', () async {
      when(() => mockNetwork.isConnected).thenAnswer((_) async => true);
      when(() => mockGeocoding.reverseGeocode(any()))
          .thenAnswer((_) async => 'Av. de las Américas, Cuenca');

      final result =
          await repository.reverseGeocode(const LatLng(-2.8973, -79.0044));

      expect(result, const Right('Av. de las Américas, Cuenca'));
    });
  });

  group('cache operations', () {
    test('cachePolyline stores successfully', () async {
      when(() => mockCache.cachePolyline('r1', 'poly'))
          .thenAnswer((_) async {});

      final result = await repository.cachePolyline('r1', 'poly');

      expect(result, const Right(null));
      verify(() => mockCache.cachePolyline('r1', 'poly')).called(1);
    });

    test('getCachedPolyline returns cached value', () {
      when(() => mockCache.getPolyline('r1')).thenReturn('poly');

      final result = repository.getCachedPolyline('r1');

      expect(result, const Right('poly'));
    });

    test('getCachedPolyline returns CacheFailure on exception', () {
      when(() => mockCache.getPolyline('r1'))
          .thenThrow(const CacheException(message: 'read error'));

      final result = repository.getCachedPolyline('r1');

      result.fold(
        (failure) {
          expect(failure, isA<CacheFailure>());
          expect(failure.message, 'read error');
        },
        (_) => fail('Should be Left'),
      );
    });

    test('invalidateCache deletes entry', () async {
      when(() => mockCache.invalidate('r1')).thenAnswer((_) async {});

      final result = await repository.invalidateCache('r1');

      expect(result, const Right(null));
    });

    test('clearCache clears all', () async {
      when(() => mockCache.clearAll()).thenAnswer((_) async {});

      final result = await repository.clearCache();

      expect(result, const Right(null));
    });
  });
}
