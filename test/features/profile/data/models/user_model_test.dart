import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yo_te_llevo/features/profile/data/models/user_model.dart';
import 'package:yo_te_llevo/features/profile/domain/entities/user_role.dart';

void main() {
  group('UserModel', () {
    final fixedDate = DateTime(2025, 1, 15, 10, 30);

    test('fromMap parses all fields correctly', () {
      final model = UserModel.fromMap('uid_abc', {
        UserModel.fName: 'Diego Veles',
        UserModel.fEmail: 'diego@example.com',
        UserModel.fPhone: '0991234567',
        UserModel.fPhotoUrl: null,
        UserModel.fRole: 'driver',
        UserModel.fRating: 4.7,
        UserModel.fTotalTrips: 23,
        UserModel.fCreatedAt: Timestamp.fromDate(fixedDate),
      });

      expect(model.id, 'uid_abc');
      expect(model.name, 'Diego Veles');
      expect(model.email, 'diego@example.com');
      expect(model.phone, '0991234567');
      expect(model.photoUrl, null);
      expect(model.role, UserRole.driver);
      expect(model.rating, 4.7);
      expect(model.totalTrips, 23);
      expect(model.createdAt, fixedDate);
      expect(model.isDriver, true);
      expect(model.isPassenger, false);
    });

    test('fromMap uses defaults when fields are missing', () {
      final model = UserModel.fromMap('uid_xyz', {
        UserModel.fName: 'Ana',
        UserModel.fEmail: 'ana@example.com',
        UserModel.fRole: 'passenger',
        UserModel.fCreatedAt: Timestamp.fromDate(fixedDate),
      });

      expect(model.phone, null);
      expect(model.photoUrl, null);
      expect(model.rating, 5.0);
      expect(model.totalTrips, 0);
      expect(model.role, UserRole.passenger);
      expect(model.isPassenger, true);
      expect(model.isDriver, false);
    });

    test('fromMap handles role "both" with both flags true', () {
      final model = UserModel.fromMap('uid_b', {
        UserModel.fName: 'Lia',
        UserModel.fEmail: 'lia@example.com',
        UserModel.fRole: 'both',
        UserModel.fCreatedAt: Timestamp.fromDate(fixedDate),
      });

      expect(model.role, UserRole.both);
      expect(model.isDriver, true);
      expect(model.isPassenger, true);
    });

    test('toFirestore serializes role as enum name and createdAt as Timestamp',
        () {
      final model = UserModel(
        id: 'uid1',
        name: 'Pedro',
        email: 'pedro@example.com',
        phone: '0998765432',
        role: UserRole.both,
        rating: 4.9,
        totalTrips: 15,
        createdAt: fixedDate,
      );

      final map = model.toFirestore();

      expect(map[UserModel.fName], 'Pedro');
      expect(map[UserModel.fEmail], 'pedro@example.com');
      expect(map[UserModel.fPhone], '0998765432');
      expect(map[UserModel.fRole], 'both');
      expect(map[UserModel.fRating], 4.9);
      expect(map[UserModel.fTotalTrips], 15);
      expect(map[UserModel.fCreatedAt], isA<Timestamp>());
      expect((map[UserModel.fCreatedAt] as Timestamp).toDate(), fixedDate);
    });

    test('toFirestore with useServerTimestamp emits FieldValue', () {
      final model = UserModel(
        id: 'uid1',
        name: 'Pedro',
        email: 'pedro@example.com',
        role: UserRole.passenger,
        createdAt: fixedDate,
      );

      final map = model.toFirestore(useServerTimestamp: true);

      expect(map[UserModel.fCreatedAt], isA<FieldValue>());
    });

    test('round-trip preserves field values', () {
      final original = UserModel(
        id: 'uid_round',
        name: 'Round',
        email: 'round@example.com',
        phone: '0990000000',
        role: UserRole.driver,
        rating: 4.2,
        totalTrips: 7,
        createdAt: fixedDate,
      );

      final map = original.toFirestore();
      final reconstructed = UserModel.fromMap(original.id, map);

      expect(reconstructed, equals(original));
    });

    test('UserRole.fromString defaults to passenger for unknown values', () {
      expect(UserRole.fromString('driver'), UserRole.driver);
      expect(UserRole.fromString('both'), UserRole.both);
      expect(UserRole.fromString('passenger'), UserRole.passenger);
      expect(UserRole.fromString('unknown_value'), UserRole.passenger);
    });
  });
}
