import 'package:equatable/equatable.dart';

import '../../../matching/domain/entities/match.dart';
import 'occurrence_status.dart';

/// Una ocurrencia concreta de un viaje (spec §3.2).
///
/// Para `tripType=recurring` representa una de las fechas de la serie. Para
/// `tripType=oneTime` representa el único viaje de un Match. La unidad de
/// "iniciar/finalizar/cancelar" en la UI siempre es una `TripOccurrence`.
///
/// Persistida en Firestore en `/trip_occurrences/{id}` con doc ID
/// determinístico `<matchId>_<yyyyMMddHHmm>` para idempotencia de Cloud
/// Functions.
class TripOccurrence extends Equatable {
  final String id;
  final String matchId;
  final String passengerId;
  final String driverId;
  final String routeId;
  final DateTime scheduledAt;
  final OccurrenceStatus status;
  final MatchTripType tripType;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancelledBy;
  final String? cancellationReason;

  /// Snapshot del precio en centavos cuando se materializó la ocurrencia.
  /// Regla (decisión 2026-04-29):
  /// - `perTrip` / `daily` → cobro completo cada vez.
  /// - `weekly` / `monthly` → cobro completo sólo en la 1ra del ciclo;
  ///   resto del ciclo `0`.
  final int priceCents;

  /// Flags de idempotencia para los reminders push (spec §5.5).
  final OccurrenceReminders remindersSent;

  /// IANA timezone (ej. `America/Guayaquil`) en la que se interpretó
  /// `scheduledAt` al materializar la ocurrencia. `scheduledAt` se guarda
  /// en UTC.
  final String timezone;

  const TripOccurrence({
    required this.id,
    required this.matchId,
    required this.passengerId,
    required this.driverId,
    required this.routeId,
    required this.scheduledAt,
    required this.status,
    required this.tripType,
    required this.createdAt,
    required this.priceCents,
    required this.remindersSent,
    required this.timezone,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancelledBy,
    this.cancellationReason,
  });

  bool isParticipant(String userId) =>
      userId == passengerId || userId == driverId;

  bool isPassengerView(String userId) => userId == passengerId;

  /// Sólo el conductor puede pasar de `scheduled` a `active`.
  bool canStart(String userId) =>
      status == OccurrenceStatus.scheduled && userId == driverId;

  /// Sólo el conductor puede pasar de `active` a `completed`.
  bool canComplete(String userId) =>
      status == OccurrenceStatus.active && userId == driverId;

  /// Cualquier participante puede cancelar mientras la ocurrencia esté
  /// `scheduled` o `active`.
  bool canCancel(String userId) =>
      isParticipant(userId) &&
      (status == OccurrenceStatus.scheduled ||
          status == OccurrenceStatus.active);

  TripOccurrence copyWith({
    OccurrenceStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? cancelledBy,
    String? cancellationReason,
    OccurrenceReminders? remindersSent,
  }) {
    return TripOccurrence(
      id: id,
      matchId: matchId,
      passengerId: passengerId,
      driverId: driverId,
      routeId: routeId,
      scheduledAt: scheduledAt,
      status: status ?? this.status,
      tripType: tripType,
      createdAt: createdAt,
      priceCents: priceCents,
      remindersSent: remindersSent ?? this.remindersSent,
      timezone: timezone,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }

  @override
  List<Object?> get props => [
        id,
        matchId,
        passengerId,
        driverId,
        routeId,
        scheduledAt,
        status,
        tripType,
        createdAt,
        startedAt,
        completedAt,
        cancelledAt,
        cancelledBy,
        cancellationReason,
        priceCents,
        remindersSent,
        timezone,
      ];
}

/// Flags de idempotencia para los reminders push de una ocurrencia.
class OccurrenceReminders extends Equatable {
  final bool h12;
  final bool h1;
  final bool start15m;

  const OccurrenceReminders({
    this.h12 = false,
    this.h1 = false,
    this.start15m = false,
  });

  OccurrenceReminders copyWith({bool? h12, bool? h1, bool? start15m}) {
    return OccurrenceReminders(
      h12: h12 ?? this.h12,
      h1: h1 ?? this.h1,
      start15m: start15m ?? this.start15m,
    );
  }

  @override
  List<Object?> get props => [h12, h1, start15m];
}
