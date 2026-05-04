import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/trip_occurrence_repository.dart';

class PauseSeriesUseCase {
  final TripOccurrenceRepository _repo;
  PauseSeriesUseCase(this._repo);

  Future<Either<Failure, void>> call(String matchId) =>
      _repo.pauseSeries(matchId);
}

class ResumeSeriesUseCase {
  final TripOccurrenceRepository _repo;
  ResumeSeriesUseCase(this._repo);

  Future<Either<Failure, void>> call(String matchId) =>
      _repo.resumeSeries(matchId);
}
