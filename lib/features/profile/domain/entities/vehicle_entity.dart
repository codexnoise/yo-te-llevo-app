import 'package:equatable/equatable.dart';

class VehicleEntity extends Equatable {
  final String brand;
  final String model;
  final int year;
  final String plate;
  final String color;
  final int seats;

  const VehicleEntity({
    required this.brand,
    required this.model,
    required this.year,
    required this.plate,
    required this.color,
    required this.seats,
  });

  VehicleEntity copyWith({
    String? brand,
    String? model,
    int? year,
    String? plate,
    String? color,
    int? seats,
  }) {
    return VehicleEntity(
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      plate: plate ?? this.plate,
      color: color ?? this.color,
      seats: seats ?? this.seats,
    );
  }

  @override
  List<Object> get props => [brand, model, year, plate, color, seats];
}
