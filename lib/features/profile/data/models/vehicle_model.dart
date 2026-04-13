import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/vehicle_entity.dart';

class VehicleModel extends VehicleEntity {
  static const String fBrand = 'brand';
  static const String fModel = 'model';
  static const String fYear = 'year';
  static const String fPlate = 'plate';
  static const String fColor = 'color';
  static const String fSeats = 'seats';

  const VehicleModel({
    required super.brand,
    required super.model,
    required super.year,
    required super.plate,
    required super.color,
    required super.seats,
  });

  factory VehicleModel.fromEntity(VehicleEntity entity) {
    return VehicleModel(
      brand: entity.brand,
      model: entity.model,
      year: entity.year,
      plate: entity.plate,
      color: entity.color,
      seats: entity.seats,
    );
  }

  VehicleEntity toEntity() {
    return VehicleEntity(
      brand: brand,
      model: model,
      year: year,
      plate: plate,
      color: color,
      seats: seats,
    );
  }

  factory VehicleModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Documento de vehículo vacío: ${doc.id}');
    }
    return VehicleModel.fromMap(data);
  }

  factory VehicleModel.fromMap(Map<String, dynamic> data) {
    return VehicleModel(
      brand: data[fBrand] as String? ?? '',
      model: data[fModel] as String? ?? '',
      year: (data[fYear] as num?)?.toInt() ?? 0,
      plate: data[fPlate] as String? ?? '',
      color: data[fColor] as String? ?? '',
      seats: (data[fSeats] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      fBrand: brand,
      fModel: model,
      fYear: year,
      fPlate: plate,
      fColor: color,
      fSeats: seats,
    };
  }
}
