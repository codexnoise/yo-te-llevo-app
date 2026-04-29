import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/cancel_scope.dart';
import '../../domain/repositories/trip_occurrence_repository.dart';

/// Notifier de acciones sobre `TripOccurrence` y series. Mantiene un
/// `AsyncValue<void>` para que la UI muestre loading/error de la última
/// acción. La lista en pantalla se alimenta de `upcomingOccurrencesProvider`
/// / `occurrenceByIdProvider` / `seriesOccurrencesProvider`.
class OccurrenceActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final TripOccurrenceRepository _repo;

  OccurrenceActionsNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<bool> start(String occurrenceId) async {
    state = const AsyncValue.loading();
    return _apply(await _repo.startOccurrence(occurrenceId));
  }

  Future<bool> complete(String occurrenceId) async {
    state = const AsyncValue.loading();
    return _apply(await _repo.completeOccurrence(occurrenceId));
  }

  Future<bool> cancelOccurrence(
    String occurrenceId, {
    required String byUserId,
    String? reason,
  }) async {
    state = const AsyncValue.loading();
    return _apply(await _repo.cancel(
      occurrenceId,
      scope: CancelScope.occurrence,
      byUserId: byUserId,
      reason: reason,
    ));
  }

  Future<bool> cancelSeriesFromOccurrence(
    String occurrenceId, {
    required String byUserId,
    String? reason,
  }) async {
    state = const AsyncValue.loading();
    return _apply(await _repo.cancel(
      occurrenceId,
      scope: CancelScope.series,
      byUserId: byUserId,
      reason: reason,
    ));
  }

  Future<bool> pauseSeries(String matchId) async {
    state = const AsyncValue.loading();
    return _apply(await _repo.pauseSeries(matchId));
  }

  Future<bool> resumeSeries(String matchId) async {
    state = const AsyncValue.loading();
    return _apply(await _repo.resumeSeries(matchId));
  }

  Future<bool> cancelSeries(String matchId, {required String byUserId}) async {
    state = const AsyncValue.loading();
    return _apply(await _repo.cancelSeries(matchId, byUserId));
  }

  /// Bridge: tras aceptar un match recurring, generar las 2 primeras
  /// ocurrencias cliente-side. Cuando exista la CF `onMatchAccepted` (M3),
  /// este método pasa a no-op idempotente.
  Future<bool> seedAfterAccept(String matchId) async {
    state = const AsyncValue.loading();
    final result = await _repo.seedInitialOccurrences(matchId);
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
