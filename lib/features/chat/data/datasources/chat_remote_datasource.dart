import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/message.dart';
import '../models/message_model.dart';

abstract class ChatRemoteDataSource {
  Stream<List<Message>> watchMessages(String matchId);

  Future<void> sendMessage({
    required String matchId,
    required String senderId,
    required String text,
  });

  /// Marca como leídos todos los mensajes entrantes de [currentUserId] en
  /// el chat. Firestore no soporta `!=` en queries: se filtra el
  /// [currentUserId] en cliente sobre los mensajes con `read == false`.
  Future<void> markAsRead({
    required String matchId,
    required String currentUserId,
  });
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final FirebaseFirestore _firestore;

  /// Batch max de Firestore; defensivo para evitar exceder el límite en
  /// caso extremo (spec §7.2: batch write).
  static const int _maxBatchWrites = 500;

  ChatRemoteDataSourceImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> _messages(String matchId) =>
      _firestore
          .collection(FirebaseConstants.matchesCollection)
          .doc(matchId)
          .collection(FirebaseConstants.messagesSubcollection);

  @override
  Stream<List<Message>> watchMessages(String matchId) {
    return _messages(matchId)
        .orderBy(MessageModel.fTimestamp)
        .snapshots()
        .map((snap) => snap.docs.map(MessageModel.fromFirestore).toList());
  }

  @override
  Future<void> sendMessage({
    required String matchId,
    required String senderId,
    required String text,
  }) async {
    try {
      await _messages(matchId).add(
        MessageModel.toCreateMap(senderId: senderId, text: text),
      );
    } on FirebaseException catch (e) {
      throw ServerException(message: _firestoreMessage(e));
    }
  }

  @override
  Future<void> markAsRead({
    required String matchId,
    required String currentUserId,
  }) async {
    try {
      final snap = await _messages(matchId)
          .where(MessageModel.fRead, isEqualTo: false)
          .get();

      final pending = snap.docs
          .where((d) => (d.data()[MessageModel.fSenderId] as String?) !=
              currentUserId)
          .toList();

      if (pending.isEmpty) return;

      // Partimos en chunks por si alguna vez hay >500 mensajes no leídos.
      for (var i = 0; i < pending.length; i += _maxBatchWrites) {
        final end = (i + _maxBatchWrites).clamp(0, pending.length);
        final batch = _firestore.batch();
        for (final doc in pending.sublist(i, end)) {
          batch.update(doc.reference, {MessageModel.fRead: true});
        }
        await batch.commit();
      }
    } on FirebaseException catch (e) {
      throw ServerException(message: _firestoreMessage(e));
    }
  }

  String _firestoreMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'No tienes permisos para esta operación';
      case 'unavailable':
        return 'Servicio temporalmente no disponible';
      case 'not-found':
        return 'Chat no encontrado';
      default:
        return e.message ?? 'Error de Firestore (${e.code})';
    }
  }
}
