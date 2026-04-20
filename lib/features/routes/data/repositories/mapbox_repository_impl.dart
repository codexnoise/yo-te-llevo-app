import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/lat_lng.dart';
import '../../domain/entities/detour_result.dart';
import '../../domain/entities/geocoding_result.dart';
import '../../domain/entities/route_result.dart';
import '../../domain/repositories/mapbox_repository.dart';
import '../datasources/mapbox_directions_datasource.dart';
import '../datasources/mapbox_geocoding_datasource.dart';
import '../datasources/polyline_cache_datasource.dart';

class MapboxRepositoryImpl implements MapboxRepository {
  final MapboxDirectionsDataSource _directionsDataSource;
  final MapboxGeocodingDataSource _geocodingDataSource;
  final PolylineCacheDataSource _cacheDataSource;
  final NetworkInfo _networkInfo;

  MapboxRepositoryImpl({
    required MapboxDirectionsDataSource directionsDataSource,
    required MapboxGeocodingDataSource geocodingDataSource,
    required PolylineCacheDataSource cacheDataSource,
    required NetworkInfo networkInfo,
  })  : _directionsDataSource = directionsDataSource,
        _geocodingDataSource = geocodingDataSource,
        _cacheDataSource = cacheDataSource,
        _networkInfo = networkInfo;

  @override
  Future<Either<Failure, RouteResult>> getRoute(
      List<LatLng> waypoints) async {
    if (!await _networkInfo.isConnected) {
      return const Left(
          NetworkFailure(message: 'Sin conexión a internet'));
    }
    try {
      final result = await _directionsDataSource.getRoute(waypoints);
      return Right(result.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, DetourResult>> calculateDetour({
    required LatLng driverOrigin,
    required LatLng driverDestination,
    required LatLng passengerPickup,
    required LatLng passengerDropoff,
    required double originalDurationSeconds,
    required double originalDistanceMeters,
  }) async {
    final detourResult = await getRoute([
      driverOrigin,
      passengerPickup,
      passengerDropoff,
      driverDestination,
    ]);

    return detourResult.map((route) => DetourResult(
          extraSeconds: route.durationSeconds - originalDurationSeconds,
          extraMeters: route.distanceMeters - originalDistanceMeters,
          totalDurationSeconds: route.durationSeconds,
          totalDistanceMeters: route.distanceMeters,
          fullRoute: route,
        ));
  }

  @override
  Future<Either<Failure, List<GeocodingResult>>> search(
    String query, {
    LatLng? proximity,
    String country = 'ec',
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(
          NetworkFailure(message: 'Sin conexión a internet'));
    }
    try {
      final results = await _geocodingDataSource.search(
        query,
        proximity: proximity,
        country: country,
      );
      return Right(results.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, String>> reverseGeocode(LatLng point) async {
    if (!await _networkInfo.isConnected) {
      return const Left(
          NetworkFailure(message: 'Sin conexión a internet'));
    }
    try {
      final result = await _geocodingDataSource.reverseGeocode(point);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> cachePolyline(
      String routeId, String encodedPolyline) async {
    try {
      await _cacheDataSource.cachePolyline(routeId, encodedPolyline);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Either<Failure, String?> getCachedPolyline(String routeId) {
    try {
      final result = _cacheDataSource.getPolyline(routeId);
      return Right(result);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> invalidateCache(String routeId) async {
    try {
      await _cacheDataSource.invalidate(routeId);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> clearCache() async {
    try {
      await _cacheDataSource.clearAll();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }
}
