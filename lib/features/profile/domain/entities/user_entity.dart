import 'package:equatable/equatable.dart';

import '../../../../core/constants/supported_cities.dart';
import 'user_role.dart';

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String? phone;
  final UserRole role;
  final double rating;
  final int totalTrips;
  final DateTime createdAt;
  final String? fcmToken;
  final String city;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    this.photoUrl,
    this.phone,
    this.rating = 5.0,
    this.totalTrips = 0,
    this.fcmToken,
    this.city = SupportedCities.defaultCity,
  });

  bool get isDriver => role == UserRole.driver || role == UserRole.both;

  bool get isPassenger => role == UserRole.passenger || role == UserRole.both;

  UserEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    String? phone,
    UserRole? role,
    double? rating,
    int? totalTrips,
    DateTime? createdAt,
    String? fcmToken,
    String? city,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      rating: rating ?? this.rating,
      totalTrips: totalTrips ?? this.totalTrips,
      createdAt: createdAt ?? this.createdAt,
      fcmToken: fcmToken ?? this.fcmToken,
      city: city ?? this.city,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        photoUrl,
        phone,
        role,
        rating,
        totalTrips,
        createdAt,
        fcmToken,
        city,
      ];
}
