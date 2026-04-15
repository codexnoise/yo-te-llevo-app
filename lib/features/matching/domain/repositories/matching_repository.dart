import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/match_candidate.dart';
import '../entities/match_search_input.dart';

abstract class MatchingRepository {
  Future<Either<Failure, List<MatchCandidate>>> searchMatches(
    MatchSearchInput input,
  );
}
