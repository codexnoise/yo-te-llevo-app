import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../routes/domain/entities/route_entity.dart';
import '../../domain/entities/match_candidate.dart';
import '../../domain/entities/match_search_input.dart';
import '../../domain/repositories/matching_repository.dart';
import '../services/matching_engine.dart';

class MatchingRepositoryImpl implements MatchingRepository {
  final MatchingEngine _engine;
  final NetworkInfo _networkInfo;

  MatchingRepositoryImpl({
    required MatchingEngine engine,
    required NetworkInfo networkInfo,
  })  : _engine = engine,
        _networkInfo = networkInfo;

  @override
  Future<Either<Failure, List<MatchCandidate>>> searchMatches(
    MatchSearchInput input,
  ) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'Sin conexión a internet'));
    }

    final phase0 = await _engine.routeRepo.findRoutesNearby(input.origin);
    Failure? phase0Failure;
    List<RouteEntity> routes = const [];
    phase0.fold(
      (failure) => phase0Failure = failure,
      (list) => routes = list,
    );
    if (phase0Failure != null) return Left(phase0Failure!);

    try {
      final candidates = await _engine.run(routes, input);
      return Right(candidates);
    } catch (e) {
      return Left(ServerFailure(message: 'Error ejecutando el matching: $e'));
    }
  }
}
