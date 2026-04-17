import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yo_te_llevo/core/errors/exceptions.dart';
import 'package:yo_te_llevo/core/errors/failures.dart';
import 'package:yo_te_llevo/core/network/network_info.dart';
import 'package:yo_te_llevo/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:yo_te_llevo/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:yo_te_llevo/features/chat/domain/entities/message.dart';

class MockChatRemoteDataSource extends Mock implements ChatRemoteDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

Message _message({
  String id = 'm1',
  String senderId = 'u1',
  String text = 'hi',
  bool read = false,
}) {
  return Message(
    id: id,
    senderId: senderId,
    text: text,
    timestamp: DateTime(2026, 4, 15, 10, 0),
    read: read,
  );
}

void main() {
  late MockChatRemoteDataSource remote;
  late MockNetworkInfo network;
  late ChatRepositoryImpl repo;

  setUp(() {
    remote = MockChatRemoteDataSource();
    network = MockNetworkInfo();
    repo = ChatRepositoryImpl(remote: remote, networkInfo: network);

    when(() => network.isConnected).thenAnswer((_) async => true);
  });

  group('sendMessage', () {
    test('returns ServerFailure when text is empty', () async {
      final result = await repo.sendMessage(
        matchId: 'match1',
        senderId: 'u1',
        text: '   ',
      );

      expect(result.isLeft(), true);
      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('expected Left'),
      );
      verifyNever(() => remote.sendMessage(
            matchId: any(named: 'matchId'),
            senderId: any(named: 'senderId'),
            text: any(named: 'text'),
          ));
    });

    test('returns NetworkFailure when offline', () async {
      when(() => network.isConnected).thenAnswer((_) async => false);

      final result = await repo.sendMessage(
        matchId: 'match1',
        senderId: 'u1',
        text: 'hola',
      );

      result.fold(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('trims text before calling remote', () async {
      when(() => remote.sendMessage(
            matchId: any(named: 'matchId'),
            senderId: any(named: 'senderId'),
            text: any(named: 'text'),
          )).thenAnswer((_) async {});

      final result = await repo.sendMessage(
        matchId: 'match1',
        senderId: 'u1',
        text: '  hola  ',
      );

      expect(result.isRight(), true);
      verify(() => remote.sendMessage(
            matchId: 'match1',
            senderId: 'u1',
            text: 'hola',
          )).called(1);
    });

    test('maps ServerException to ServerFailure', () async {
      when(() => remote.sendMessage(
            matchId: any(named: 'matchId'),
            senderId: any(named: 'senderId'),
            text: any(named: 'text'),
          )).thenThrow(const ServerException(message: 'boom'));

      final result = await repo.sendMessage(
        matchId: 'match1',
        senderId: 'u1',
        text: 'hola',
      );

      result.fold(
        (f) {
          expect(f, isA<ServerFailure>());
          expect(f.message, 'boom');
        },
        (_) => fail('expected Left'),
      );
    });
  });

  group('markAsRead', () {
    test('returns NetworkFailure when offline', () async {
      when(() => network.isConnected).thenAnswer((_) async => false);

      final result = await repo.markAsRead(
        matchId: 'match1',
        currentUserId: 'u1',
      );

      result.fold(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('delegates to remote when online', () async {
      when(() => remote.markAsRead(
            matchId: any(named: 'matchId'),
            currentUserId: any(named: 'currentUserId'),
          )).thenAnswer((_) async {});

      final result = await repo.markAsRead(
        matchId: 'match1',
        currentUserId: 'u1',
      );

      expect(result.isRight(), true);
      verify(() => remote.markAsRead(
            matchId: 'match1',
            currentUserId: 'u1',
          )).called(1);
    });

    test('maps ServerException to ServerFailure', () async {
      when(() => remote.markAsRead(
            matchId: any(named: 'matchId'),
            currentUserId: any(named: 'currentUserId'),
          )).thenThrow(const ServerException(message: 'fail'));

      final result = await repo.markAsRead(
        matchId: 'match1',
        currentUserId: 'u1',
      );

      result.fold(
        (f) {
          expect(f, isA<ServerFailure>());
          expect(f.message, 'fail');
        },
        (_) => fail('expected Left'),
      );
    });
  });

  group('watchMessages', () {
    test('wraps remote stream values in Right', () async {
      final controller = StreamController<List<Message>>();
      when(() => remote.watchMessages('match1'))
          .thenAnswer((_) => controller.stream);

      final events = repo.watchMessages('match1').take(1).toList();
      controller.add([_message()]);
      await controller.close();

      final results = await events;
      expect(results, hasLength(1));
      results.first.fold(
        (_) => fail('expected Right'),
        (list) {
          expect(list, hasLength(1));
          expect(list.first.id, 'm1');
        },
      );
    });

    test('emits Left(ServerFailure) when remote stream errors', () async {
      final controller = StreamController<List<Message>>();
      when(() => remote.watchMessages('match1'))
          .thenAnswer((_) => controller.stream);

      final events = repo.watchMessages('match1').take(1).toList();
      controller.addError(const ServerException(message: 'stream broke'));
      await controller.close();

      final results = await events;
      expect(results, hasLength(1));
      results.first.fold(
        (f) {
          expect(f, isA<ServerFailure>());
          expect(f.message, contains('stream broke'));
        },
        (_) => fail('expected Left'),
      );
    });
  });
}
