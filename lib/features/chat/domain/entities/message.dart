import 'package:equatable/equatable.dart';

/// Mensaje de chat entre pasajero y conductor dentro de un match.
///
/// Persistido en `/matches/{matchId}/messages/{messageId}` (spec §7.1).
/// No incluye `matchId` porque el camino lo provee; se mantiene el id del
/// documento para identificar mensajes de forma única en la UI.
class Message extends Equatable {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool read;

  const Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.read,
  });

  Message copyWith({
    String? id,
    String? senderId,
    String? text,
    DateTime? timestamp,
    bool? read,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      read: read ?? this.read,
    );
  }

  @override
  List<Object?> get props => [id, senderId, text, timestamp, read];
}
