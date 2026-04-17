import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yo_te_llevo/core/errors/failures.dart';
import 'package:yo_te_llevo/features/chat/domain/repositories/chat_repository.dart';
import 'package:yo_te_llevo/features/chat/presentation/providers/chat_notifier.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late MockChatRepository repo;
  late ChatNotifier notifier;

  setUp(() {
    repo = MockChatRepository();
    notifier = ChatNotifier(repo, 'match1');
  });

  group('sendMessage', () {
    test('returns false for empty text without touching repo', () async {
      final ok = await notifier.sendMessage(senderId: 'u1', text: '   ');

      expect(ok, false);
      expect(notifier.state, const AsyncValue<void>.data(null));
      verifyNever(() => repo.sendMessage(
            matchId: any(named: 'matchId'),
            senderId: any(named: 'senderId'),
            text: any(named: 'text'),
          ));
    });

    test('transitions loading -> data and returns true on success', () async {
      when(() => repo.sendMessage(
            matchId: any(named: 'matchId'),
            senderId: any(named: 'senderId'),
            text: any(named: 'text'),
          )).thenAnswer((_) async => const Right(null));

      final future = notifier.sendMessage(senderId: 'u1', text: 'hola');

      expect(notifier.state.isLoading, true);

      final ok = await future;

      expect(ok, true);
      expect(notifier.state, const AsyncValue<void>.data(null));
      verify(() => repo.sendMessage(
            matchId: 'match1',
            senderId: 'u1',
            text: 'hola',
          )).called(1);
    });

    test('sets error state and returns false on failure', () async {
      when(() => repo.sendMessage(
            matchId: any(named: 'matchId'),
            senderId: any(named: 'senderId'),
            text: any(named: 'text'),
          )).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'nope')),
      );

      final ok = await notifier.sendMessage(senderId: 'u1', text: 'hola');

      expect(ok, false);
      expect(notifier.state.hasError, true);
      expect(notifier.state.error, 'nope');
    });
  });

  group('markAsRead', () {
    test('delegates to repository without touching state', () async {
      when(() => repo.markAsRead(
            matchId: any(named: 'matchId'),
            currentUserId: any(named: 'currentUserId'),
          )).thenAnswer((_) async => const Right(null));

      await notifier.markAsRead('u1');

      verify(() => repo.markAsRead(
            matchId: 'match1',
            currentUserId: 'u1',
          )).called(1);
      expect(notifier.state, const AsyncValue<void>.data(null));
    });
  });
}
