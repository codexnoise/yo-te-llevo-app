import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/lat_lng.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/repositories/driver_route_repository.dart';
import '../../domain/repositories/mapbox_repository.dart';
import '../datasources/route_remote_datasource.dart';
import '../models/route_model.dart';

class DriverRouteRepositoryImpl implements DriverRouteRepository {
  final RouteRemoteDataSource _remoteDataSource;
  final MapboxRepository _mapboxRepository;
  final NetworkInfo _networkInfo;

  DriverRouteRepositoryImpl({
    required RouteRemoteDataSource remoteDataSource,
    required MapboxRepository mapboxRepository,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _mapboxRepository = mapboxRepository,
        _networkInfo = networkInfo;

  @override
  Future<Either<Failure, RouteEntity>> createRoute(RouteEntity route) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'Sin conexión a internet'));
    }
    try {
      final model =
          await _remoteDataSource.createRoute(RouteModel.fromEntity(route));
      _mapboxRepository.cachePolyline(model.id, model.polylineEncoded);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<RouteEntity>>> getDriverRoutes(
      String driverId) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'Sin conexión a internet'));
    }
    try {
      final models = await _remoteDataSource.getDriverRoutes(driverId);
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deactivateRoute(String routeId) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'Sin conexión a internet'));
    }
    try {
      await _remoteDataSource.deactivateRoute(routeId);
      _mapboxRepository.invalidateCache(routeId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, RouteEntity>> updateRoute(RouteEntity route) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'Sin conexión a internet'));
    }
    try {
      final model = RouteModel.fromEntity(route);
      await _remoteDataSource.updateRoute(model);
      _mapboxRepository.invalidateCache(route.id);
      _mapboxRepository.cachePolyline(route.id, route.polylineEncoded);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<RouteEntity>>> findRoutesNearby(
      LatLng point) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'Sin conexión a internet'));
    }
    try {
      final models = await _remoteDataSource.findRoutesNearby(point);
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
