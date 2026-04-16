import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/lat_lng.dart';
import '../entities/route_entity.dart';

abstract class DriverRouteRepository {
  Future<Either<Failure, RouteEntity>> createRoute(RouteEntity route);

  Future<Either<Failure, List<RouteEntity>>> getDriverRoutes(String driverId);

  Future<Either<Failure, void>> deactivateRoute(String routeId);

  Future<Either<Failure, RouteEntity>> updateRoute(RouteEntity route);

  Future<Either<Failure, List<RouteEntity>>> findRoutesNearby(LatLng point);

  Future<Either<Failure, RouteEntity>> getRoute(String routeId);
}
