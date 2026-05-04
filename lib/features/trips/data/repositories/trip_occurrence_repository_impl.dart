import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../matching/domain/entities/match.dart';
import '../../domain/entities/cancel_scope.dart';
import '../../domain/entities/match_series_status.dart';
import '../../domain/entities/occurrence_status.dart';
import '../../domain/entities/trip_occurrence.dart';
import '../../domain/repositories/trip_occurrence_repository.dart';
import '../../domain/services/next_occurrence.dart';
import '../../domain/services/occurrence_pricing.dart';
import '../datasources/trip_occurrence_firestore_ds.dart';
import '../datasources/trip_remote_datasource.dart';

class TripOccurrenceRepositoryImpl implements TripOccurrenceRepository {
  final TripOccurrenceRemoteDataSource _remote;
  final TripRemoteDataSource _matchRemote;
  final NetworkInfo _networkInfo;

  /// Constante de la spec §4.1: ventana rodante de 2 ocurrencias futuras.
  static const int _seedCount = 2;

  TripOccurrenceRepositoryImpl({
    required TripOccurrenceRemoteDataSource remote,
    required TripRemoteDataSource matchRemote,
    required NetworkInfo networkInfo,
  })  : _remote = remote,
        _matchRemote = matchRemote,
        _networkInfo = networkInfo;

  @override
  Stream<Either<Failure, List<TripOccurrence>>> watchUpcoming(
    String userId, {
    int limit = 10,
  }) {
    return _remote
        .watchUpcoming(userId, limit: limit)
        .map<Either<Failure, List<TripOccurrence>>>((list) => Right(list))
        .handleError(
          (Object error) =>
              Left<Failure, List<TripOccurrence>>(
            ServerFailure(message: error.toString()),
          ),
        );
  }

  @override
  Stream<Either<Failure, TripOccurrence>> watchById(String occurrenceId) {
    return _remote
        .watchOccurrence(occurrenceId)
        .map<Either<Failure, TripOccurrence>>((o) => Right(o))
        .handleError(
          (Object error) => Left<Failure, TripOccurrence>(
            ServerFailure(message: error.toString()),
          ),
        );
  }

  @override
  Stream<Either<Failure, List<TripOccurrence>>> watchBySeries(String matchId) {
    return _remote
        .watchBySeries(matchId)
        .map<Either<Failure, List<TripOccurrence>>>((list) => Right(list))
        .handleError(
          (Object error) =>
              Left<Failure, List<TripOccurrence>>(
            ServerFailure(message: error.toString()),
          ),
        );
  }

  @override
  Future<Either<Failure, void>> cancel(
    String occurrenceId, {
    required CancelScope scope,
    required String byUserId,
    String? reason,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'Sin conexión a internet'));
    }
    try {
      final occurrence = await _remote.getOccurrence(occurrenceId);
      if (!occurrence.canCancel(byUserId)) {
        return const Left(
          ServerFailure(message: 'Esta ocurrencia ya no se puede cancelar'),
        );
      }
      await _remote.updateStatus(
        occurrenceId,
        next: OccurrenceStatus.cancelled,
        cancelledBy: byUserId,
        cancellationReason: reason,
        cancelScope: scope,
      );
      // Bridge cliente-side mientras no exista CF (M3): si scope=series,
      // propagamos al template + cancelamos futuras.
      if (scope == CancelScope.series) {
        await _remote.cancelSeriesBatch(
          occurrence.matchId,
          byUserId: byUserId,
          reason: reason,
        );
      }
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> startOccurrence(String occurrenceId) async {
    return _transition(
      occurrenceId,
      from: OccurrenceStatus.scheduled,
      to: OccurrenceStatus.active,
    );
  }

  @override
  Future<Either<Failure, void>> completeOccurrence(String occurrenceId) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'Sin conexión a internet'));
    }
    try {
      final occurrence = await _remote.getOccurrence(occurrenceId);
      if (occurrence.status != OccurrenceStatus.active) {
        return Left(ServerFailure(
          message:
              'Estado inválido: se esperaba active, actual ${occurrence.status.name}',
        ));
      }
      await _remote.updateStatus(
        occurrenceId,
        next: OccurrenceStatus.completed,
      );
      // Bridge cliente-side mientras no exista CF (M3): generar la siguiente
      // ocurrencia si la serie sigue activa.
      if (occurrence.tripType == MatchTripType.recurring) {
        await _materializeNextAfter(occurrence);
      }
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> pauseSeries(String matchId) async {
    return _seriesTransition(matchId, MatchSeriesStatus.paused);
  }

  @override
  Future<Either<Failure, void>> resumeSeries(String matchId) async {
    return _seriesTransition(matchId, MatchSeriesStatus.active);
  }

  @override
  Future<Either<Failure, void>> cancelSeries(
    String matchId,
    String byUserId,
  ) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'Sin conexión a internet'));
    }
    try {
      await _remote.cancelSeriesBatch(matchId, byUserId: byUserId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<TripOccurrence>>> seedInitialOccurrences(
    String matchId,
  ) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'Sin conexión a internet'));
    }
    try {
      final match = await _matchRemote.getMatch(matchId);
      final created = await _materializeInitial(match);
      return Right(created);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  Future<Either<Failure, void>> _transition(
    String occurrenceId, {
    required OccurrenceStatus from,
    required OccurrenceStatus to,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'Sin conexión a internet'));
    }
    try {
      final current = await _remote.getOccurrence(occurrenceId);
      if (current.status != from) {
        return Left(ServerFailure(
          message:
              'Estado inválido: se esperaba ${from.name}, actual ${current.status.name}',
        ));
      }
      if (!current.status.canTransitionTo(to)) {
        return Left(ServerFailure(
          message: 'Transición no permitida: ${current.status.name} → ${to.name}',
        ));
      }
      await _remote.updateStatus(occurrenceId, next: to);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  Future<Either<Failure, void>> _seriesTransition(
    String matchId,
    MatchSeriesStatus to,
  ) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'Sin conexión a internet'));
    }
    try {
      await _remote.updateSeriesStatus(matchId, to);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  /// Para una serie recién aceptada, genera las primeras [_seedCount]
  /// ocurrencias. Para `oneTime` genera 1.
  Future<List<TripOccurrence>> _materializeInitial(Match match) async {
    final created = <TripOccurrence>[];
    if (match.tripType == MatchTripType.oneTime) {
      final scheduledAt =
          match.startDate ?? match.createdAt.add(const Duration(hours: 1));
      final occurrence = _buildOccurrence(
        match: match,
        scheduledAt: scheduledAt,
        previousOccurrenceAt: null,
      );
      created.add(await _remote.createOccurrence(occurrence));
      return created;
    }
    if (match.departureTime == null || match.days.isEmpty) {
      return created;
    }
    final after = match.startDate ?? DateTime.now().toUtc();
    final dates = nextOccurrences(
      count: _seedCount,
      days: match.days,
      departureTime: match.departureTime!,
      after: after,
      timezone: match.timezone,
      endDate: match.endDate,
    );
    DateTime? previous;
    for (final date in dates) {
      final occurrence = _buildOccurrence(
        match: match,
        scheduledAt: date,
        previousOccurrenceAt: previous,
      );
      final saved = await _remote.createOccurrence(occurrence);
      created.add(saved);
      previous = date;
    }
    return created;
  }

  /// Tras completar una ocurrencia recurrente, materializa la siguiente
  /// (manteniendo la ventana rodante de 2). No-op si la serie ya no está
  /// activa o si pasó `endDate`.
  Future<void> _materializeNextAfter(TripOccurrence completed) async {
    final match = await _matchRemote.getMatch(completed.matchId);
    if (match.seriesStatus != MatchSeriesStatus.active) return;
    if (match.departureTime == null || match.days.isEmpty) return;
    final futures = await _remote.getFutureScheduledOf(match.id);
    if (futures.length >= _seedCount) return;
    final base = futures.isNotEmpty
        ? futures
            .map((o) => o.scheduledAt)
            .reduce((a, b) => a.isAfter(b) ? a : b)
        : completed.scheduledAt;
    final next = nextOccurrence(
      days: match.days,
      departureTime: match.departureTime!,
      after: base,
      timezone: match.timezone,
      endDate: match.endDate,
    );
    if (next == null) return;
    final occurrence = _buildOccurrence(
      match: match,
      scheduledAt: next,
      previousOccurrenceAt: base,
    );
    await _remote.createOccurrence(occurrence);
  }

  TripOccurrence _buildOccurrence({
    required Match match,
    required DateTime scheduledAt,
    required DateTime? previousOccurrenceAt,
  }) {
    final priceCents = priceCentsFor(
      pricingType: match.pricingType,
      matchPrice: match.price,
      scheduledAt: scheduledAt,
      previousOccurrenceAt: previousOccurrenceAt,
      timezone: match.timezone,
    );
    return TripOccurrence(
      id: '',
      matchId: match.id,
      passengerId: match.passengerId,
      driverId: match.driverId,
      routeId: match.routeId,
      scheduledAt: scheduledAt,
      status: OccurrenceStatus.scheduled,
      tripType: match.tripType,
      createdAt: DateTime.now(),
      priceCents: priceCents,
      remindersSent: const OccurrenceReminders(),
      timezone: match.timezone,
    );
  }
}
