import 'package:equatable/equatable.dart';

import '../../../matching/domain/entities/match.dart';
import '../../../matching/domain/entities/match_status.dart';
import '../../../profile/domain/entities/user_entity.dart';
import '../../../routes/domain/entities/route_entity.dart';

/// Wrapper sobre [Match] que añade datos derivados para la UI: la
/// contraparte (pasajero o conductor) y la ruta del conductor cuando están
/// disponibles.
///
/// La persistencia vive bajo `/matches/{matchId}`. Esta clase no se serializa
/// — se arma en la capa de repositorio juntando un [Match] con lookups de
/// `/users` y `/routes`.
class TripEntity extends Equatable {
  final Match match;
  final UserEntity? counterpart;
  final RouteEntity? route;

  const TripEntity({
    required this.match,
    this.counterpart,
    this.route,
  });

  String get id => match.id;
  MatchStatus get status => match.status;

  /// true cuando [viewerId] es el pasajero del match (la contraparte es el
  /// conductor). false cuando [viewerId] es el conductor.
  bool isPassengerView(String viewerId) => viewerId == match.passengerId;

  /// true si el viewer es participante del viaje.
  bool isParticipant(String viewerId) =>
      viewerId == match.passengerId || viewerId == match.driverId;

  /// Cualquiera de los dos participantes puede cancelar mientras el viaje
  /// esté en pending o accepted (spec 6.3).
  bool get canCancel =>
      status == MatchStatus.pending || status == MatchStatus.accepted;

  /// Solo el conductor responde solicitudes pendientes.
  bool canRespond(String viewerId) =>
      status == MatchStatus.pending && viewerId == match.driverId;

  /// El conductor marca el viaje como iniciado cuando está accepted.
  bool canStart(String viewerId) =>
      status == MatchStatus.accepted && viewerId == match.driverId;

  /// El conductor finaliza un viaje activo.
  bool canComplete(String viewerId) =>
      status == MatchStatus.active && viewerId == match.driverId;

  /// El chat está disponible cuando hay compromiso mutuo.
  bool get canOpenChat =>
      status == MatchStatus.accepted || status == MatchStatus.active;

  /// Calificación habilitada solo cuando el viaje terminó.
  bool get canRate => status == MatchStatus.completed;

  TripEntity copyWith({
    Match? match,
    UserEntity? counterpart,
    RouteEntity? route,
  }) {
    return TripEntity(
      match: match ?? this.match,
      counterpart: counterpart ?? this.counterpart,
      route: route ?? this.route,
    );
  }

  @override
  List<Object?> get props => [match, counterpart, route];
}
