import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/cancel_scope.dart';
import '../repositories/trip_occurrence_repository.dart';

/// Cancela una serie completa, ya sea desde una ocurrencia (`scope=series`)
/// o desde el template directamente.
class CancelSeriesUseCase {
  final TripOccurrenceRepository _repo;
  CancelSeriesUseCase(this._repo);

  /// Pide la cancelación pasando por una ocurrencia concreta. Útil cuando
  /// el botón de cancelación está en `OccurrenceDetailsScreen`.
  Future<Either<Failure, void>> fromOccurrence(
    String occurrenceId, {
    required String byUserId,
    String? reason,
  }) =>
      _repo.cancel(
        occurrenceId,
        scope: CancelScope.series,
        byUserId: byUserId,
        reason: reason,
      );

  /// Cancela el template directamente — usado por `SeriesManagementScreen`.
  Future<Either<Failure, void>> fromMatch(
    String matchId, {
    required String byUserId,
  }) =>
      _repo.cancelSeries(matchId, byUserId);
}
