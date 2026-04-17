import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/message.dart';

/// Contrato del repositorio de chat del Módulo 7 (spec §7.2).
///
/// El chat es por match: los participantes están acotados por las rules
/// Firestore. El repositorio no valida pertenencia; eso lo hace el backend.
abstract class ChatRepository {
  /// Stream de mensajes ordenados por `timestamp` ascendente (más antiguos
  /// primero). Emite `Left(ServerFailure)` si Firestore rompe la suscripción
  /// (p. ej. permisos).
  Stream<Either<Failure, List<Message>>> watchMessages(String matchId);

  /// Crea un mensaje con `senderId = currentUserId`, `timestamp` resuelto
  /// por `FieldValue.serverTimestamp()` y `read = false`.
  Future<Either<Failure, void>> sendMessage({
    required String matchId,
    required String senderId,
    required String text,
  });

  /// Marca como leídos todos los mensajes entrantes del chat: los que no
  /// fueron enviados por [currentUserId] y siguen con `read == false`.
  /// Usa un batch write (spec §7.2).
  Future<Either<Failure, void>> markAsRead({
    required String matchId,
    required String currentUserId,
  });
}
