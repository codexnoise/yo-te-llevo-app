import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';
import 'package:yo_te_llevo/core/errors/failures.dart';
import 'package:yo_te_llevo/features/profile/domain/entities/user_entity.dart';
import 'package:yo_te_llevo/features/profile/domain/entities/user_role.dart';
import 'package:yo_te_llevo/features/profile/domain/repositories/profile_repository.dart';
import 'package:yo_te_llevo/features/ratings/domain/entities/rating.dart';
import 'package:yo_te_llevo/features/ratings/domain/repositories/rating_repository.dart';
import 'package:yo_te_llevo/features/ratings/presentation/providers/rating_notifier.dart';

class MockRatingRepository extends Mock implements RatingRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class FakeUserEntity extends Fake implements UserEntity {}

class FakeRatingEntity extends Fake implements RatingEntity {}

class _FixedUuid implements Uuid {
  final String value;
  const _FixedUuid(this.value);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #v4) return value;
    return super.noSuchMethod(invocation);
  }
}

UserEntity _user({
  String id = 'u2',
  double rating = 5.0,
  int totalTrips = 10,
}) {
  return UserEntity(
    id: id,
    name: 'Daniel',
    email: 'd@example.com',
    role: UserRole.driver,
    createdAt: DateTime(2026, 1, 1),
    rating: rating,
    totalTrips: totalTrips,
  );
}

RatingEntity _rating(int stars, {String id = 'rx'}) {
  return RatingEntity(
    id: id,
    fromUserId: 'u-other',
    toUserId: 'u2',
    matchId: 'm-old',
    stars: stars,
    createdAt: DateTime(2026, 4, 1),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeUserEntity());
    registerFallbackValue(FakeRatingEntity());
  });

  late MockRatingRepository ratingRepo;
  late MockProfileRepository profileRepo;
  late RatingNotifier notifier;

  setUp(() {
    ratingRepo = MockRatingRepository();
    profileRepo = MockProfileRepository();
    notifier = RatingNotifier(
      ratingRepo,
      profileRepo,
      'm1',
      uuid: const _FixedUuid('generated-id'),
    );
  });

  group('validación local', () {
    test('rechaza stars fuera de rango (0)', () async {
      final ok = await notifier.submit(
        fromUserId: 'u1',
        toUserId: 'u2',
        stars: 0,
      );

      expect(ok, false);
      expect(notifier.state, isA<AsyncError>());
      verifyNever(() => ratingRepo.hasRated(
            fromUserId: any(named: 'fromUserId'),
            matchId: any(named: 'matchId'),
          ));
    });

    test('rechaza stars fuera de rango (6)', () async {
      final ok = await notifier.submit(
        fromUserId: 'u1',
        toUserId: 'u2',
        stars: 6,
      );

      expect(ok, false);
      expect(notifier.state, isA<AsyncError>());
    });

    test('rechaza auto-calificación (fromUserId == toUserId)', () async {
      final ok = await notifier.submit(
        fromUserId: 'u1',
        toUserId: 'u1',
        stars: 4,
      );

      expect(ok, false);
      expect(notifier.state, isA<AsyncError>());
      verifyNever(() => ratingRepo.hasRated(
            fromUserId: any(named: 'fromUserId'),
            matchId: any(named: 'matchId'),
          ));
    });
  });

  group('prevención de duplicados', () {
    test('rechaza si hasRated == true', () async {
      when(() => ratingRepo.hasRated(
            fromUserId: any(named: 'fromUserId'),
            matchId: any(named: 'matchId'),
          )).thenAnswer((_) async => const Right(true));

      final ok = await notifier.submit(
        fromUserId: 'u1',
        toUserId: 'u2',
        stars: 4,
      );

      expect(ok, false);
      expect(notifier.state, isA<AsyncError>());
      verifyNever(() => ratingRepo.submitRating(any()));
    });

    test('propaga fallo de hasRated al estado', () async {
      when(() => ratingRepo.hasRated(
            fromUserId: any(named: 'fromUserId'),
            matchId: any(named: 'matchId'),
          )).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'offline')),
      );

      final ok = await notifier.submit(
        fromUserId: 'u1',
        toUserId: 'u2',
        stars: 4,
      );

      expect(ok, false);
      expect(notifier.state, isA<AsyncError>());
    });
  });

  group('camino feliz', () {
    setUp(() {
      when(() => ratingRepo.hasRated(
            fromUserId: any(named: 'fromUserId'),
            matchId: any(named: 'matchId'),
          )).thenAnswer((_) async => const Right(false));
      when(() => ratingRepo.submitRating(any()))
          .thenAnswer((_) async => const Right(null));
      when(() => profileRepo.updateUser(any()))
          .thenAnswer((_) async => const Right(null));
    });

    test('persiste rating, recalcula average e incrementa totalTrips',
        () async {
      // Existentes: 5, 3. Nueva: 4. Promedio esperado = (5+3+4)/3 = 4.0.
      when(() => ratingRepo.getRatingsForUser('u2')).thenAnswer(
        (_) async => Right([
          _rating(5, id: 'r-prev-1'),
          _rating(3, id: 'r-prev-2'),
          _rating(4, id: 'generated-id'),
        ]),
      );
      when(() => profileRepo.getUser('u2')).thenAnswer(
        (_) async => Right(_user(rating: 4.0, totalTrips: 10)),
      );

      final ok = await notifier.submit(
        fromUserId: 'u1',
        toUserId: 'u2',
        stars: 4,
        comment: '  bueno  ',
      );

      expect(ok, true);
      expect(notifier.state, const AsyncValue<void>.data(null));

      // Rating enviado con id determinista y comentario trimmed.
      final captured = verify(() => ratingRepo.submitRating(captureAny()))
          .captured
          .single as RatingEntity;
      expect(captured.id, 'generated-id');
      expect(captured.stars, 4);
      expect(captured.comment, 'bueno');
      expect(captured.fromUserId, 'u1');
      expect(captured.toUserId, 'u2');
      expect(captured.matchId, 'm1');

      // updateUser llamado con rating recalculado (=4.0) y totalTrips+1.
      final updated = verify(() => profileRepo.updateUser(captureAny()))
          .captured
          .single as UserEntity;
      expect(updated.rating, 4.0);
      expect(updated.totalTrips, 11);
    });

    test('comentario vacío se guarda como null', () async {
      when(() => ratingRepo.getRatingsForUser('u2')).thenAnswer(
        (_) async => Right([_rating(5, id: 'generated-id')]),
      );
      when(() => profileRepo.getUser('u2')).thenAnswer(
        (_) async => Right(_user()),
      );

      await notifier.submit(
        fromUserId: 'u1',
        toUserId: 'u2',
        stars: 5,
        comment: '   ',
      );

      final captured = verify(() => ratingRepo.submitRating(captureAny()))
          .captured
          .single as RatingEntity;
      expect(captured.comment, isNull);
    });

    test('si submitRating falla, NO recalcula ni actualiza usuario',
        () async {
      when(() => ratingRepo.submitRating(any())).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'write-fail')),
      );

      final ok = await notifier.submit(
        fromUserId: 'u1',
        toUserId: 'u2',
        stars: 4,
      );

      expect(ok, false);
      expect(notifier.state, isA<AsyncError>());
      verifyNever(() => ratingRepo.getRatingsForUser(any()));
      verifyNever(() => profileRepo.updateUser(any()));
    });

    test('si getRatingsForUser falla tras persistir, reporta error',
        () async {
      when(() => ratingRepo.getRatingsForUser(any())).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'read-fail')),
      );

      final ok = await notifier.submit(
        fromUserId: 'u1',
        toUserId: 'u2',
        stars: 4,
      );

      expect(ok, false);
      expect(notifier.state, isA<AsyncError>());
      verifyNever(() => profileRepo.updateUser(any()));
    });

    test('si getUser falla, no intenta updateUser', () async {
      when(() => ratingRepo.getRatingsForUser('u2')).thenAnswer(
        (_) async => Right([_rating(5, id: 'generated-id')]),
      );
      when(() => profileRepo.getUser('u2')).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'missing')),
      );

      final ok = await notifier.submit(
        fromUserId: 'u1',
        toUserId: 'u2',
        stars: 5,
      );

      expect(ok, false);
      verifyNever(() => profileRepo.updateUser(any()));
    });
  });
}
