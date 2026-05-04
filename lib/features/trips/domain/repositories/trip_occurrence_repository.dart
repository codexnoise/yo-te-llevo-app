import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/cancel_scope.dart';
import '../entities/trip_occurrence.dart';

abstract class TripOccurrenceRepository {
  /// Stream de las próximas ocurrencias del usuario [userId] (en cualquiera
  /// de los dos roles). Filtra `scheduledAt >= now` y limita resultados.
  Stream<Either<Failure, List<TripOccurrence>>> watchUpcoming(
    String userId, {
    int limit = 10,
  });

  /// Stream de una ocurrencia específica.
  Stream<Either<Failure, TripOccurrence>> watchById(String occurrenceId);

  /// Stream de todas las ocurrencias de una serie (template) ordenadas por
  /// `scheduledAt` asc — para `SeriesManagementScreen`.
  Stream<Either<Failure, List<TripOccurrence>>> watchBySeries(String matchId);

  /// Cancela una ocurrencia.
  ///
  /// - [scope] = `occurrence`: sólo esta fecha. La serie sigue.
  /// - [scope] = `series`: marca la ocurrencia como cancelada y propaga el
  ///   estado al template (`MatchSeriesStatus.cancelled`) + cancela todas
  ///   las futuras `scheduled` en batch.
  Future<Either<Failure, void>> cancel(
    String occurrenceId, {
    required CancelScope scope,
    required String byUserId,
    String? reason,
  });

  /// Conductor pasa de `scheduled` a `active`.
  Future<Either<Failure, void>> startOccurrence(String occurrenceId);

  /// Conductor pasa de `active` a `completed`. Al completar, se debe
  /// generar la siguiente ocurrencia (esto lo hace una CF en M3; mientras
  /// tanto el bridge del repo lo hace cliente-side si la serie sigue
  /// activa).
  Future<Either<Failure, void>> completeOccurrence(String occurrenceId);

  /// Pausa el template de la serie. Mientras esté pausada no se generan
  /// nuevas ocurrencias. Las que ya estén `scheduled` se conservan.
  Future<Either<Failure, void>> pauseSeries(String matchId);

  /// Reanuda una serie pausada — vuelve a `active`.
  Future<Either<Failure, void>> resumeSeries(String matchId);

  /// Cancela el template de la serie (sin pasar por una ocurrencia
  /// concreta). Usado por `SeriesManagementScreen`.
  Future<Either<Failure, void>> cancelSeries(String matchId, String byUserId);

  /// Bridge cliente-side mientras no exista la CF `onMatchAccepted` (M3).
  /// Genera las 2 primeras ocurrencias de la serie. Idempotente: si ya
  /// existen, no las recrea.
  ///
  /// Devuelve la lista de ocurrencias generadas (o vacía si no aplicaba).
  Future<Either<Failure, List<TripOccurrence>>> seedInitialOccurrences(
    String matchId,
  );
}
