import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/lat_lng.dart';
import '../entities/detour_result.dart';
import '../entities/geocoding_result.dart';
import '../entities/route_result.dart';

abstract class MapboxRepository {
  Future<Either<Failure, RouteResult>> getRoute(List<LatLng> waypoints);

  Future<Either<Failure, DetourResult>> calculateDetour({
    required LatLng driverOrigin,
    required LatLng driverDestination,
    required LatLng passengerPickup,
    required LatLng passengerDropoff,
    required double originalDurationSeconds,
    required double originalDistanceMeters,
  });

  Future<Either<Failure, List<GeocodingResult>>> search(
    String query, {
    LatLng? proximity,
    String country,
  });

  Future<Either<Failure, String>> reverseGeocode(LatLng point);

  Future<Either<Failure, void>> cachePolyline(
      String routeId, String encodedPolyline);

  Either<Failure, String?> getCachedPolyline(String routeId);

  Future<Either<Failure, void>> invalidateCache(String routeId);

  Future<Either<Failure, void>> clearCache();
}
