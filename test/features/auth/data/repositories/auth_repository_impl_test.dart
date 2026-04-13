import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yo_te_llevo/core/errors/exceptions.dart';
import 'package:yo_te_llevo/core/errors/failures.dart';
import 'package:yo_te_llevo/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:yo_te_llevo/features/auth/data/repositories/auth_repository_impl.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(mockDataSource);
  });

  const tEmail = 'user@example.com';
  const tPassword = 'secret123';
  const tUid = 'uid_123';

  group('signUpWithEmail', () {
    test('returns Right(uid) on success', () async {
      when(() => mockDataSource.signUpWithEmail(
            email: tEmail,
            password: tPassword,
          )).thenAnswer((_) async => tUid);

      final result =
          await repository.signUpWithEmail(email: tEmail, password: tPassword);

      expect(result, const Right(tUid));
      verify(() => mockDataSource.signUpWithEmail(
            email: tEmail,
            password: tPassword,
          )).called(1);
    });

    test('returns Left(AuthFailure) on AuthException', () async {
      when(() => mockDataSource.signUpWithEmail(
            email: tEmail,
            password: tPassword,
          )).thenThrow(const AuthException(
              message: 'Este email ya está registrado',
              code: 'email-already-in-use'));

      final result =
          await repository.signUpWithEmail(email: tEmail, password: tPassword);

      result.fold(
        (failure) {
          expect(failure, isA<AuthFailure>());
          expect(failure.message, 'Este email ya está registrado');
        },
        (_) => fail('Should be Left'),
      );
    });

    test('returns Left(ServerFailure) on unexpected exception', () async {
      when(() => mockDataSource.signUpWithEmail(
            email: tEmail,
            password: tPassword,
          )).thenThrow(Exception('boom'));

      final result =
          await repository.signUpWithEmail(email: tEmail, password: tPassword);

      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Should be Left'),
      );
    });
  });

  group('signInWithEmail', () {
    test('returns Right(uid) on success', () async {
      when(() => mockDataSource.signInWithEmail(
            email: tEmail,
            password: tPassword,
          )).thenAnswer((_) async => tUid);

      final result =
          await repository.signInWithEmail(email: tEmail, password: tPassword);

      expect(result, const Right(tUid));
    });

    test('returns Left(AuthFailure) on wrong credentials', () async {
      when(() => mockDataSource.signInWithEmail(
            email: tEmail,
            password: tPassword,
          )).thenThrow(const AuthException(
              message: 'Credenciales incorrectas',
              code: 'wrong-password'));

      final result =
          await repository.signInWithEmail(email: tEmail, password: tPassword);

      result.fold(
        (failure) {
          expect(failure, isA<AuthFailure>());
          expect(failure.message, 'Credenciales incorrectas');
        },
        (_) => fail('Should be Left'),
      );
    });
  });

  group('signOut', () {
    test('returns Right(null) on success', () async {
      when(() => mockDataSource.signOut()).thenAnswer((_) async {});

      final result = await repository.signOut();

      expect(result, const Right(null));
      verify(() => mockDataSource.signOut()).called(1);
    });

    test('returns Left(AuthFailure) on AuthException', () async {
      when(() => mockDataSource.signOut()).thenThrow(
          const AuthException(message: 'Error al cerrar sesión'));

      final result = await repository.signOut();

      result.fold(
        (failure) {
          expect(failure, isA<AuthFailure>());
          expect(failure.message, 'Error al cerrar sesión');
        },
        (_) => fail('Should be Left'),
      );
    });
  });

  group('authStateChanges & currentUserId', () {
    test('forwards stream from datasource', () {
      final stream = Stream<String?>.fromIterable([null, tUid, null]);
      when(() => mockDataSource.authStateChanges).thenAnswer((_) => stream);

      expect(repository.authStateChanges, emitsInOrder([null, tUid, null]));
    });

    test('forwards currentUserId from datasource', () {
      when(() => mockDataSource.currentUserId).thenReturn(tUid);

      expect(repository.currentUserId, tUid);
    });
  });
}
