import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/lat_lng.dart';
import '../../data/models/detour_result_model.dart';
import '../../data/models/geocoding_result_model.dart';
import '../../data/models/route_result_model.dart';

abstract class MapboxRepository {
  Future<Either<Failure, RouteResultModel>> getRoute(List<LatLng> waypoints);

  Future<Either<Failure, DetourResultModel>> calculateDetour({
    required LatLng driverOrigin,
    required LatLng driverDestination,
    required LatLng passengerPickup,
    required LatLng passengerDropoff,
    required double originalDurationSeconds,
    required double originalDistanceMeters,
  });

  Future<Either<Failure, List<GeocodingResultModel>>> search(
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
