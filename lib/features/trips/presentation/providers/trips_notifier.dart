import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../matching/domain/entities/match.dart';
import '../../../matching/domain/entities/match_candidate.dart';
import '../../../matching/domain/entities/match_status.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';

/// Expone las acciones de un viaje: solicitar, responder, cancelar, iniciar,
/// finalizar. El estado refleja solo el ciclo de la última acción (loading
/// → data/error). La lista en pantalla se alimenta de
/// `activeTripsStreamProvider`.
class TripsNotifier extends StateNotifier<AsyncValue<void>> {
  final TripRepository _repository;

  TripsNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<TripEntity?> requestTrip({
    required MatchCandidate candidate,
    required String passengerId,
    MatchTripType tripType = MatchTripType.oneTime,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repository.requestTrip(
      candidate: candidate,
      passengerId: passengerId,
      tripType: tripType,
    );
    return result.fold<TripEntity?>(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return null;
      },
      (trip) {
        state = const AsyncValue.data(null);
        return trip;
      },
    );
  }

  Future<bool> accept(String matchId) =>
      _respond(matchId, MatchStatus.accepted);

  Future<bool> reject(String matchId) =>
      _respond(matchId, MatchStatus.rejected);

  Future<bool> cancel(String matchId) async {
    state = const AsyncValue.loading();
    return _apply(await _repository.cancelTrip(matchId));
  }

  Future<bool> start(String matchId) async {
    state = const AsyncValue.loading();
    return _apply(await _repository.markActive(matchId));
  }

  Future<bool> complete(String matchId) async {
    state = const AsyncValue.loading();
    return _apply(await _repository.markCompleted(matchId));
  }

  Future<bool> _respond(String matchId, MatchStatus decision) async {
    state = const AsyncValue.loading();
    final result = await _repository.respondToRequest(
      matchId: matchId,
      decision: decision,
    );
    return _apply(result);
  }

  bool _apply(Either<Failure, void> result) {
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        return true;
      },
    );
  }
}
