import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/message.dart';

/// Serialización Firestore para un [Message] en
/// `/matches/{matchId}/messages/{messageId}` (spec §7.1).
class MessageModel {
  static const String fSenderId = 'senderId';
  static const String fText = 'text';
  static const String fTimestamp = 'timestamp';
  static const String fRead = 'read';

  const MessageModel._();

  static Message fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Documento de mensaje vacío: ${doc.id}');
    }
    return fromMap(doc.id, data);
  }

  static Message fromMap(String id, Map<String, dynamic> data) {
    return Message(
      id: id,
      senderId: data[fSenderId] as String? ?? '',
      text: data[fText] as String? ?? '',
      timestamp: _parseTimestamp(data[fTimestamp]) ?? DateTime.now(),
      read: data[fRead] as bool? ?? false,
    );
  }

  /// Serialización para `add` de mensajes nuevos. `timestamp` se resuelve en
  /// el servidor para garantizar orden cronológico consistente entre
  /// clientes.
  static Map<String, dynamic> toCreateMap({
    required String senderId,
    required String text,
  }) {
    return {
      fSenderId: senderId,
      fText: text,
      fTimestamp: FieldValue.serverTimestamp(),
      fRead: false,
    };
  }

  /// Serialización completa para tests de round-trip. No usa
  /// `serverTimestamp`.
  static Map<String, dynamic> toMap(Message message) {
    return {
      fSenderId: message.senderId,
      fText: message.text,
      fTimestamp: Timestamp.fromDate(message.timestamp),
      fRead: message.read,
    };
  }

  static DateTime? _parseTimestamp(Object? raw) {
    if (raw is Timestamp) return raw.toDate();
    return null;
  }
}
