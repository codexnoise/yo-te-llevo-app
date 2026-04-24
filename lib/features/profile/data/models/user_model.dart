import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/supported_cities.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/user_role.dart';

class UserModel extends UserEntity {
  static const String fName = 'name';
  static const String fEmail = 'email';
  static const String fPhotoUrl = 'photoUrl';
  static const String fPhone = 'phone';
  static const String fRole = 'role';
  static const String fRating = 'rating';
  static const String fTotalTrips = 'totalTrips';
  static const String fCreatedAt = 'createdAt';
  static const String fFcmToken = 'fcmToken';
  static const String fCity = 'city';

  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    required super.createdAt,
    super.photoUrl,
    super.phone,
    super.rating = 5.0,
    super.totalTrips = 0,
    super.fcmToken,
    super.city = SupportedCities.defaultCity,
  });

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      role: entity.role,
      createdAt: entity.createdAt,
      photoUrl: entity.photoUrl,
      phone: entity.phone,
      rating: entity.rating,
      totalTrips: entity.totalTrips,
      fcmToken: entity.fcmToken,
      city: entity.city,
    );
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      name: name,
      email: email,
      role: role,
      createdAt: createdAt,
      photoUrl: photoUrl,
      phone: phone,
      rating: rating,
      totalTrips: totalTrips,
      fcmToken: fcmToken,
      city: city,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Documento de usuario vacío: ${doc.id}');
    }
    return UserModel.fromMap(doc.id, data);
  }

  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    final createdAtRaw = data[fCreatedAt];
    final createdAt = createdAtRaw is Timestamp
        ? createdAtRaw.toDate()
        : DateTime.now();

    return UserModel(
      id: id,
      name: data[fName] as String? ?? '',
      email: data[fEmail] as String? ?? '',
      photoUrl: data[fPhotoUrl] as String?,
      phone: data[fPhone] as String?,
      role: UserRole.fromString(data[fRole] as String? ?? 'passenger'),
      rating: (data[fRating] as num?)?.toDouble() ?? 5.0,
      totalTrips: (data[fTotalTrips] as num?)?.toInt() ?? 0,
      createdAt: createdAt,
      fcmToken: data[fFcmToken] as String?,
      city: data[fCity] as String? ?? SupportedCities.defaultCity,
    );
  }

  /// Serialización para `set` / `update`. Si [useServerTimestamp] es true, el
  /// campo createdAt se envía como [FieldValue.serverTimestamp] (uso típico
  /// en creación). Si es false, se envía como Timestamp del valor actual.
  Map<String, dynamic> toFirestore({bool useServerTimestamp = false}) {
    return {
      fName: name,
      fEmail: email,
      fPhotoUrl: photoUrl,
      fPhone: phone,
      fRole: role.name,
      fRating: rating,
      fTotalTrips: totalTrips,
      fCreatedAt:
          useServerTimestamp ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt),
      fFcmToken: fcmToken,
      fCity: city,
    };
  }
}
