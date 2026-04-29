import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/trip_occurrence.dart';
import '../repositories/trip_occurrence_repository.dart';

class GetUpcomingOccurrencesUseCase {
  final TripOccurrenceRepository _repo;
  GetUpcomingOccurrencesUseCase(this._repo);

  Stream<Either<Failure, List<TripOccurrence>>> call(
    String userId, {
    int limit = 10,
  }) =>
      _repo.watchUpcoming(userId, limit: limit);
}
