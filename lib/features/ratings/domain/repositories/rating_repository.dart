import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/rating.dart';

/// Contrato del repositorio de calificaciones (spec §8).
abstract class RatingRepository {
  /// Persiste una calificación en `/ratings`. El server-timestamp lo
  /// resuelve el datasource.
  Future<Either<Failure, void>> submitRating(RatingEntity rating);

  /// True si [fromUserId] ya calificó [matchId]. Usado para bloquear la
  /// doble calificación desde UI (spec §8.3). No reemplaza validación
  /// server-side (pendiente).
  Future<Either<Failure, bool>> hasRated({
    required String fromUserId,
    required String matchId,
  });

  /// Todas las calificaciones recibidas por [userId]. Se usa para recalcular
  /// el promedio almacenado en `/users/{userId}.rating` (spec §8.2).
  Future<Either<Failure, List<RatingEntity>>> getRatingsForUser(String userId);
}
