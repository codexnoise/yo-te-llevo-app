import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../matching/domain/entities/match.dart';
import '../../../matching/domain/entities/match_candidate.dart';
import '../../../matching/domain/entities/match_status.dart';
import '../../../profile/domain/entities/user_entity.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../routes/domain/entities/route_entity.dart';
import '../../../routes/domain/repositories/driver_route_repository.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';
import '../datasources/trip_remote_datasource.dart';

class TripRepositoryImpl implements TripRepository {
  final TripRemoteDataSource _remote;
  final NetworkInfo _networkInfo;
  final ProfileRepository _profileRepository;
  final DriverRouteRepository _routeRepository;

  final Map<String, UserEntity> _userCache = {};
  final Map<String, RouteEntity> _routeCache = {};

  TripRepositoryImpl({
    required TripRemoteDataSource remote,
    required NetworkInfo networkInfo,
    required ProfileRepository profileRepository,
    required DriverRouteRepository routeRepository,
  })  : _remote = remote,
        _networkInfo = networkInfo,
        _profileRepository = profileRepository,
        _routeRepository = routeRepository;

  @override
  Future<Either<Failure, TripEntity>> requestTrip({
    required MatchCandidate candidate,
    required String passengerId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'Sin conexión a internet'));
    }
    try {
      final draft = Match(
        id: '',
        passengerId: passengerId,
        driverId: candidate.route.driverId,
        routeId: candidate.route.id,
        status: MatchStatus.pending,
        pickupPoint: candidate.pickupPoint,
        pickupAddress: candidate.pickupAddress,
        dropoffPoint: candidate.dropoffPoint,
        dropoffAddress: candidate.dropoffAddress,
        distanceToPickupMeters: candidate.distanceToPickupMeters,
        distanceToDropoffMeters: candidate.distanceToDropoffMeters,
        detourSeconds: candidate.detourSeconds,
        tripType: MatchTripType.recurring,
        days: candidate.route.schedule.days,
        startDate: null,
        price: candidate.price,
        pricingType: candidate.pricingType.name,
        createdAt: DateTime.now(),
      );

      final created = await _remote.createMatch(draft);
      final trip = await _enrich(created, viewerId: passengerId);
      return Right(trip);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> respondToRequest({
    required String matchId,
    required MatchStatus decision,
  }) async {
    if (decision != MatchStatus.accepted && decision != MatchStatus.rejected) {
      return const Left(
        ServerFailure(message: 'Decisión inválida'),
      );
    }
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'Sin conexión a internet'));
    }
    try {
      final current = await _remote.getMatch(matchId);
      if (current.status != MatchStatus.pending) {
        return const Left(
          ServerFailure(
              message: 'Solo se pueden responder solicitudes pendientes'),
        );
      }
      await _remote.updateStatus(matchId, decision);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> cancelTrip(String matchId) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'Sin conexión a internet'));
    }
    try {
      final current = await _remote.getMatch(matchId);
      if (current.status != MatchStatus.pending &&
          current.status != MatchStatus.accepted) {
        return const Left(
          ServerFailure(message: 'Este viaje ya no se puede cancelar'),
        );
      }
      await _remote.updateStatus(matchId, MatchStatus.cancelled);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> markActive(String matchId) async {
    return _transition(matchId, MatchStatus.accepted, MatchStatus.active);
  }

  @override
  Future<Either<Failure, void>> markCompleted(String matchId) async {
    return _transition(matchId, MatchStatus.active, MatchStatus.completed);
  }

  Future<Either<Failure, void>> _transition(
    String matchId,
    MatchStatus requiredStatus,
    MatchStatus next,
  ) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'Sin conexión a internet'));
    }
    try {
      final current = await _remote.getMatch(matchId);
      if (current.status != requiredStatus) {
        return Left(
          ServerFailure(
            message:
                'Estado inválido: se esperaba ${requiredStatus.name}, actual ${current.status.name}',
          ),
        );
      }
      await _remote.updateStatus(matchId, next);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Stream<Either<Failure, List<TripEntity>>> watchActiveTrips(String userId) {
    return _remote.watchActiveTrips(userId).asyncMap((matches) async {
      final trips = await Future.wait(
        matches.map((m) => _enrich(m, viewerId: userId)),
      );
      return Right<Failure, List<TripEntity>>(trips);
    }).handleError((Object error) {
      return Left<Failure, List<TripEntity>>(
        ServerFailure(message: error.toString()),
      );
    });
  }

  @override
  Future<Either<Failure, List<TripEntity>>> getHistory(
    String userId, {
    int limit = 50,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'Sin conexión a internet'));
    }
    try {
      final matches = await _remote.getHistory(userId, limit: limit);
      final trips = await Future.wait(
        matches.map((m) => _enrich(m, viewerId: userId)),
      );
      return Right(trips);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, TripEntity>> getTrip(String matchId) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'Sin conexión a internet'));
    }
    try {
      final match = await _remote.getMatch(matchId);
      final trip = await _enrich(match, viewerId: null);
      return Right(trip);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Stream<Either<Failure, TripEntity>> watchTrip(String matchId) {
    return _remote.watchMatch(matchId).asyncMap((match) async {
      final trip = await _enrich(match, viewerId: null);
      return Right<Failure, TripEntity>(trip);
    }).handleError((Object error) {
      return Left<Failure, TripEntity>(
        ServerFailure(message: error.toString()),
      );
    });
  }

  Future<TripEntity> _enrich(Match match, {required String? viewerId}) async {
    final counterpartId = viewerId == null
        ? match.driverId
        : (viewerId == match.passengerId ? match.driverId : match.passengerId);

    final counterpart = await _loadUser(counterpartId);
    final route = await _loadRoute(match.routeId);

    return TripEntity(
      match: match,
      counterpart: counterpart,
      route: route,
    );
  }

  Future<UserEntity?> _loadUser(String uid) async {
    if (uid.isEmpty) return null;
    final cached = _userCache[uid];
    if (cached != null) return cached;
    final result = await _profileRepository.getUser(uid);
    return result.fold((_) => null, (user) {
      _userCache[uid] = user;
      return user;
    });
  }

  Future<RouteEntity?> _loadRoute(String routeId) async {
    if (routeId.isEmpty) return null;
    final cached = _routeCache[routeId];
    if (cached != null) return cached;
    final result = await _routeRepository.getRoute(routeId);
    return result.fold((_) => null, (route) {
      _routeCache[routeId] = route;
      return route;
    });
  }
}
