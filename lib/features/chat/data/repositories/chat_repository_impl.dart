import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  ChatRepositoryImpl({
    required ChatRemoteDataSource remote,
    required NetworkInfo networkInfo,
  })  : _remote = remote,
        _networkInfo = networkInfo;

  @override
  Stream<Either<Failure, List<Message>>> watchMessages(String matchId) async* {
    try {
      await for (final messages in _remote.watchMessages(matchId)) {
        yield Right<Failure, List<Message>>(messages);
      }
    } catch (e) {
      yield Left<Failure, List<Message>>(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendMessage({
    required String matchId,
    required String senderId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const Left(ServerFailure(message: 'El mensaje está vacío'));
    }
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'Sin conexión a internet'));
    }
    try {
      await _remote.sendMessage(
        matchId: matchId,
        senderId: senderId,
        text: trimmed,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead({
    required String matchId,
    required String currentUserId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'Sin conexión a internet'));
    }
    try {
      await _remote.markAsRead(
        matchId: matchId,
        currentUserId: currentUserId,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
