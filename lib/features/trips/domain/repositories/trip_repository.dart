import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../matching/domain/entities/match_candidate.dart';
import '../../../matching/domain/entities/match_status.dart';
import '../entities/trip.dart';

abstract class TripRepository {
  /// Crea un match con status pending a partir del [candidate] elegido por el
  /// pasajero. Retorna el [TripEntity] enriquecido con contraparte y ruta.
  Future<Either<Failure, TripEntity>> requestTrip({
    required MatchCandidate candidate,
    required String passengerId,
  });

  /// El conductor responde una solicitud pending con [decision] ∈
  /// {accepted, rejected}.
  Future<Either<Failure, void>> respondToRequest({
    required String matchId,
    required MatchStatus decision,
  });

  /// Cancela un viaje en estado pending o accepted.
  Future<Either<Failure, void>> cancelTrip(String matchId);

  /// Transiciona accepted → active (conductor).
  Future<Either<Failure, void>> markActive(String matchId);

  /// Transiciona active → completed (conductor).
  Future<Either<Failure, void>> markCompleted(String matchId);

  /// Stream combinado de viajes del usuario en estados
  /// {pending, accepted, active} — ambos roles fusionados y deduplicados.
  Stream<Either<Failure, List<TripEntity>>> watchActiveTrips(String userId);

  /// Historial de viajes completados del usuario.
  Future<Either<Failure, List<TripEntity>>> getHistory(
    String userId, {
    int limit = 50,
  });

  Future<Either<Failure, TripEntity>> getTrip(String matchId);

  Stream<Either<Failure, TripEntity>> watchTrip(String matchId);
}
