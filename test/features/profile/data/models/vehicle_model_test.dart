import 'package:flutter_test/flutter_test.dart';
import 'package:yo_te_llevo/features/profile/data/models/vehicle_model.dart';

void main() {
  group('VehicleModel', () {
    test('fromMap parses fields correctly', () {
      final model = VehicleModel.fromMap({
        VehicleModel.fBrand: 'Toyota',
        VehicleModel.fModel: 'Corolla',
        VehicleModel.fYear: 2020,
        VehicleModel.fPlate: 'ABC1234',
        VehicleModel.fColor: 'Blanco',
        VehicleModel.fSeats: 4,
      });

      expect(model.brand, 'Toyota');
      expect(model.model, 'Corolla');
      expect(model.year, 2020);
      expect(model.plate, 'ABC1234');
      expect(model.color, 'Blanco');
      expect(model.seats, 4);
    });

    test('fromMap uses defaults for missing fields', () {
      final model = VehicleModel.fromMap({});

      expect(model.brand, '');
      expect(model.model, '');
      expect(model.year, 0);
      expect(model.plate, '');
      expect(model.color, '');
      expect(model.seats, 0);
    });

    test('toFirestore serializes all fields', () {
      const model = VehicleModel(
        brand: 'Chevrolet',
        model: 'Aveo',
        year: 2018,
        plate: 'XYZ9876',
        color: 'Rojo',
        seats: 5,
      );

      final map = model.toFirestore();

      expect(map, {
        VehicleModel.fBrand: 'Chevrolet',
        VehicleModel.fModel: 'Aveo',
        VehicleModel.fYear: 2018,
        VehicleModel.fPlate: 'XYZ9876',
        VehicleModel.fColor: 'Rojo',
        VehicleModel.fSeats: 5,
      });
    });

    test('round-trip preserves equality', () {
      const original = VehicleModel(
        brand: 'Kia',
        model: 'Rio',
        year: 2022,
        plate: 'KIA0001',
        color: 'Negro',
        seats: 4,
      );

      final reconstructed = VehicleModel.fromMap(original.toFirestore());

      expect(reconstructed, equals(original));
    });
  });
}
