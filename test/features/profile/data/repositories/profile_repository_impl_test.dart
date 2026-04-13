import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yo_te_llevo/core/errors/exceptions.dart';
import 'package:yo_te_llevo/core/errors/failures.dart';
import 'package:yo_te_llevo/core/network/network_info.dart';
import 'package:yo_te_llevo/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:yo_te_llevo/features/profile/data/models/user_model.dart';
import 'package:yo_te_llevo/features/profile/data/models/vehicle_model.dart';
import 'package:yo_te_llevo/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:yo_te_llevo/features/profile/domain/entities/user_entity.dart';
import 'package:yo_te_llevo/features/profile/domain/entities/user_role.dart';
import 'package:yo_te_llevo/features/profile/domain/entities/vehicle_entity.dart';

class MockProfileRemoteDataSource extends Mock
    implements ProfileRemoteDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class FakeUserModel extends Fake implements UserModel {}

class FakeVehicleModel extends Fake implements VehicleModel {}

void main() {
  late ProfileRepositoryImpl repository;
  late MockProfileRemoteDataSource mockRemote;
  late MockNetworkInfo mockNetwork;

  setUpAll(() {
    registerFallbackValue(FakeUserModel());
    registerFallbackValue(FakeVehicleModel());
  });

  setUp(() {
    mockRemote = MockProfileRemoteDataSource();
    mockNetwork = MockNetworkInfo();
    repository = ProfileRepositoryImpl(
      remoteDataSource: mockRemote,
      networkInfo: mockNetwork,
    );
  });

  final tCreatedAt = DateTime.utc(2025, 2, 10);
  final tUserModel = UserModel(
    id: 'uid1',
    name: 'Diego',
    email: 'diego@example.com',
    role: UserRole.driver,
    createdAt: tCreatedAt,
  );
  final tUserEntity = UserEntity(
    id: 'uid1',
    name: 'Diego',
    email: 'diego@example.com',
    role: UserRole.driver,
    createdAt: tCreatedAt,
  );
  const tVehicle = VehicleEntity(
    brand: 'Toyota',
    model: 'Yaris',
    year: 2021,
    plate: 'ABC1234',
    color: 'Gris',
    seats: 4,
  );

  group('getUser', () {
    test('returns Right(UserEntity) on success', () async {
      when(() => mockNetwork.isConnected).thenAnswer((_) async => true);
      when(() => mockRemote.getUser('uid1'))
          .thenAnswer((_) async => tUserModel);

      final result = await repository.getUser('uid1');

      result.fold(
        (failure) => fail('Should be Right: $failure'),
        (user) => expect(user, tUserEntity),
      );
    });

    test('returns Left(NetworkFailure) when offline', () async {
      when(() => mockNetwork.isConnected).thenAnswer((_) async => false);

      final result = await repository.getUser('uid1');

      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Should be Left'),
      );
      verifyNever(() => mockRemote.getUser(any()));
    });

    test('returns Left(ServerFailure) on ServerException', () async {
      when(() => mockNetwork.isConnected).thenAnswer((_) async => true);
      when(() => mockRemote.getUser('uid1'))
          .thenThrow(const ServerException(message: 'Perfil no encontrado'));

      final result = await repository.getUser('uid1');

      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'Perfil no encontrado');
        },
        (_) => fail('Should be Left'),
      );
    });
  });

  group('createUser', () {
    test('returns Right(null) on success', () async {
      when(() => mockNetwork.isConnected).thenAnswer((_) async => true);
      when(() => mockRemote.createUser(any())).thenAnswer((_) async {});

      final result = await repository.createUser(tUserEntity);

      expect(result, const Right(null));
      verify(() => mockRemote.createUser(any())).called(1);
    });

    test('returns Left(NetworkFailure) when offline', () async {
      when(() => mockNetwork.isConnected).thenAnswer((_) async => false);

      final result = await repository.createUser(tUserEntity);

      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Should be Left'),
      );
    });

    test('returns Left(ServerFailure) on ServerException', () async {
      when(() => mockNetwork.isConnected).thenAnswer((_) async => true);
      when(() => mockRemote.createUser(any()))
          .thenThrow(const ServerException(message: 'permission denied'));

      final result = await repository.createUser(tUserEntity);

      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'permission denied');
        },
        (_) => fail('Should be Left'),
      );
    });
  });

  group('updateUser', () {
    test('returns Right(null) on success', () async {
      when(() => mockNetwork.isConnected).thenAnswer((_) async => true);
      when(() => mockRemote.updateUser(any())).thenAnswer((_) async {});

      final result = await repository.updateUser(tUserEntity);

      expect(result, const Right(null));
    });
  });

  group('getVehicle', () {
    test('returns Right(VehicleEntity) when present', () async {
      when(() => mockNetwork.isConnected).thenAnswer((_) async => true);
      when(() => mockRemote.getVehicle('uid1')).thenAnswer(
        (_) async => const VehicleModel(
          brand: 'Toyota',
          model: 'Yaris',
          year: 2021,
          plate: 'ABC1234',
          color: 'Gris',
          seats: 4,
        ),
      );

      final result = await repository.getVehicle('uid1');

      result.fold(
        (failure) => fail('Should be Right: $failure'),
        (vehicle) => expect(vehicle, tVehicle),
      );
    });

    test('returns Right(null) when no vehicle exists', () async {
      when(() => mockNetwork.isConnected).thenAnswer((_) async => true);
      when(() => mockRemote.getVehicle('uid1')).thenAnswer((_) async => null);

      final result = await repository.getVehicle('uid1');

      result.fold(
        (failure) => fail('Should be Right'),
        (vehicle) => expect(vehicle, null),
      );
    });
  });

  group('saveVehicle', () {
    test('returns Right(null) on success', () async {
      when(() => mockNetwork.isConnected).thenAnswer((_) async => true);
      when(() => mockRemote.saveVehicle('uid1', any()))
          .thenAnswer((_) async {});

      final result = await repository.saveVehicle('uid1', tVehicle);

      expect(result, const Right(null));
      verify(() => mockRemote.saveVehicle('uid1', any())).called(1);
    });

    test('returns Left(NetworkFailure) when offline', () async {
      when(() => mockNetwork.isConnected).thenAnswer((_) async => false);

      final result = await repository.saveVehicle('uid1', tVehicle);

      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Should be Left'),
      );
    });

    test('returns Left(ServerFailure) on ServerException', () async {
      when(() => mockNetwork.isConnected).thenAnswer((_) async => true);
      when(() => mockRemote.saveVehicle('uid1', any()))
          .thenThrow(const ServerException(message: 'permission denied'));

      final result = await repository.saveVehicle('uid1', tVehicle);

      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'permission denied');
        },
        (_) => fail('Should be Left'),
      );
    });
  });
}
