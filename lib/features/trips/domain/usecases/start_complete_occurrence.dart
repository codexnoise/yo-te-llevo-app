import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/trip_occurrence_repository.dart';

class StartOccurrenceUseCase {
  final TripOccurrenceRepository _repo;
  StartOccurrenceUseCase(this._repo);

  Future<Either<Failure, void>> call(String occurrenceId) =>
      _repo.startOccurrence(occurrenceId);
}

class CompleteOccurrenceUseCase {
  final TripOccurrenceRepository _repo;
  CompleteOccurrenceUseCase(this._repo);

  Future<Either<Failure, void>> call(String occurrenceId) =>
      _repo.completeOccurrence(occurrenceId);
}
