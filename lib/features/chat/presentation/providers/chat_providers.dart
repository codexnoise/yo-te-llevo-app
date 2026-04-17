import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../shared/providers/connectivity_provider.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/datasources/chat_remote_datasource.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import 'chat_notifier.dart';

final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  return ChatRemoteDataSourceImpl(ref.watch(firestoreProvider));
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(
    remote: ref.watch(chatRemoteDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

/// Stream de mensajes ordenados ascendentemente por timestamp para el
/// [matchId]. Lanza `StateError` en `Left` para que `AsyncValue.error`
/// recoja el mensaje.
final messagesStreamProvider =
    StreamProvider.autoDispose.family<List<Message>, String>((ref, matchId) async* {
  final repo = ref.watch(chatRepositoryProvider);
  await for (final Either<Failure, List<Message>> event
      in repo.watchMessages(matchId)) {
    yield event.fold(
      (failure) => throw StateError(failure.message),
      (messages) => messages,
    );
  }
});

/// Notifier por match. Familia para aislar los estados de envío entre
/// chats abiertos simultáneamente.
final chatNotifierProvider = StateNotifierProvider.autoDispose
    .family<ChatNotifier, AsyncValue<void>, String>((ref, matchId) {
  return ChatNotifier(ref.watch(chatRepositoryProvider), matchId);
});
