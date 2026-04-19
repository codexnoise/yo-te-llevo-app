import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yo_te_llevo/core/errors/exceptions.dart';
import 'package:yo_te_llevo/core/errors/failures.dart';
import 'package:yo_te_llevo/core/network/network_info.dart';
import 'package:yo_te_llevo/features/ratings/data/datasources/rating_remote_datasource.dart';
import 'package:yo_te_llevo/features/ratings/data/models/rating_model.dart';
import 'package:yo_te_llevo/features/ratings/data/repositories/rating_repository_impl.dart';
import 'package:yo_te_llevo/features/ratings/domain/entities/rating.dart';

class MockRatingRemoteDataSource extends Mock
    implements RatingRemoteDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class FakeRatingModel extends Fake implements RatingModel {}

RatingEntity _entity({
  String id = 'r1',
  String fromUserId = 'u1',
  String toUserId = 'u2',
  String matchId = 'm1',
  int stars = 4,
  String? comment,
}) {
  return RatingEntity(
    id: id,
    fromUserId: fromUserId,
    toUserId: toUserId,
    matchId: matchId,
    stars: stars,
    comment: comment,
    createdAt: DateTime(2026, 4, 15),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeRatingModel());
  });

  late MockRatingRemoteDataSource remote;
  late MockNetworkInfo network;
  late RatingRepositoryImpl repo;

  setUp(() {
    remote = MockRatingRemoteDataSource();
    network = MockNetworkInfo();
    repo = RatingRepositoryImpl(remote: remote, networkInfo: network);

    when(() => network.isConnected).thenAnswer((_) async => true);
  });

  group('submitRating', () {
    test('returns NetworkFailure when offline', () async {
      when(() => network.isConnected).thenAnswer((_) async => false);

      final result = await repo.submitRating(_entity());

      result.fold(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('expected Left'),
      );
      verifyNever(() => remote.createRating(any()));
    });

    test('delegates to remote when online', () async {
      when(() => remote.createRating(any())).thenAnswer((_) async {});

      final result = await repo.submitRating(_entity());

      expect(result.isRight(), true);
      verify(() => remote.createRating(any())).called(1);
    });

    test('maps ServerException to ServerFailure', () async {
      when(() => remote.createRating(any()))
          .thenThrow(const ServerException(message: 'boom'));

      final result = await repo.submitRating(_entity());

      result.fold(
        (f) {
          expect(f, isA<ServerFailure>());
          expect(f.message, 'boom');
        },
        (_) => fail('expected Left'),
      );
    });
  });

  group('hasRated', () {
    test('returns NetworkFailure when offline', () async {
      when(() => network.isConnected).thenAnswer((_) async => false);

      final result = await repo.hasRated(fromUserId: 'u1', matchId: 'm1');

      result.fold(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('returns Right(true) when remote finds match', () async {
      when(() => remote.hasRated(
            fromUserId: any(named: 'fromUserId'),
            matchId: any(named: 'matchId'),
          )).thenAnswer((_) async => true);

      final result = await repo.hasRated(fromUserId: 'u1', matchId: 'm1');

      result.fold(
        (_) => fail('expected Right'),
        (value) => expect(value, true),
      );
    });

    test('maps ServerException to ServerFailure', () async {
      when(() => remote.hasRated(
            fromUserId: any(named: 'fromUserId'),
            matchId: any(named: 'matchId'),
          )).thenThrow(const ServerException(message: 'perm denied'));

      final result = await repo.hasRated(fromUserId: 'u1', matchId: 'm1');

      result.fold(
        (f) {
          expect(f, isA<ServerFailure>());
          expect(f.message, 'perm denied');
        },
        (_) => fail('expected Left'),
      );
    });
  });

  group('getRatingsForUser', () {
    test('returns NetworkFailure when offline', () async {
      when(() => network.isConnected).thenAnswer((_) async => false);

      final result = await repo.getRatingsForUser('u2');

      result.fold(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('converts remote models to entities', () async {
      when(() => remote.getRatingsForUser(any())).thenAnswer((_) async => [
            RatingModel(
              id: 'r1',
              fromUserId: 'u1',
              toUserId: 'u2',
              matchId: 'm1',
              stars: 5,
              createdAt: DateTime(2026, 4, 15),
            ),
            RatingModel(
              id: 'r2',
              fromUserId: 'u3',
              toUserId: 'u2',
              matchId: 'm2',
              stars: 3,
              createdAt: DateTime(2026, 4, 16),
            ),
          ]);

      final result = await repo.getRatingsForUser('u2');

      result.fold(
        (_) => fail('expected Right'),
        (list) {
          expect(list, hasLength(2));
          expect(list.first.stars, 5);
          expect(list.last.stars, 3);
        },
      );
    });

    test('maps ServerException to ServerFailure', () async {
      when(() => remote.getRatingsForUser(any()))
          .thenThrow(const ServerException(message: 'fail'));

      final result = await repo.getRatingsForUser('u2');

      result.fold(
        (f) {
          expect(f, isA<ServerFailure>());
          expect(f.message, 'fail');
        },
        (_) => fail('expected Left'),
      );
    });
  });
}
