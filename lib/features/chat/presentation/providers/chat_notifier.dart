import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/repositories/chat_repository.dart';

/// Acciones del chat (enviar, marcar leídos). El estado refleja únicamente
/// el ciclo del último envío (loading → data/error). La lista de mensajes
/// vive en `messagesStreamProvider`.
class ChatNotifier extends StateNotifier<AsyncValue<void>> {
  final ChatRepository _repository;
  final String _matchId;

  ChatNotifier(this._repository, this._matchId)
      : super(const AsyncValue.data(null));

  /// Retorna `true` si el mensaje se envió. Texto vacío no llama al repo y
  /// retorna `false` sin tocar `state`.
  Future<bool> sendMessage({
    required String senderId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return false;
    state = const AsyncValue.loading();
    final result = await _repository.sendMessage(
      matchId: _matchId,
      senderId: senderId,
      text: text,
    );
    return _apply(result);
  }

  /// Fire-and-forget. No cambia `state`: un error al marcar leídos no debe
  /// bloquear la UI.
  Future<void> markAsRead(String currentUserId) async {
    await _repository.markAsRead(
      matchId: _matchId,
      currentUserId: currentUserId,
    );
  }

  bool _apply(Either<Failure, void> result) {
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        return true;
      },
    );
  }
}
