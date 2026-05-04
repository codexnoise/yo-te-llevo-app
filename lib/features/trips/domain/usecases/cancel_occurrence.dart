import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/cancel_scope.dart';
import '../repositories/trip_occurrence_repository.dart';

/// Cancela **una sola** ocurrencia (la serie sigue viva).
class CancelOccurrenceUseCase {
  final TripOccurrenceRepository _repo;
  CancelOccurrenceUseCase(this._repo);

  Future<Either<Failure, void>> call(
    String occurrenceId, {
    required String byUserId,
    String? reason,
  }) =>
      _repo.cancel(
        occurrenceId,
        scope: CancelScope.occurrence,
        byUserId: byUserId,
        reason: reason,
      );
}
