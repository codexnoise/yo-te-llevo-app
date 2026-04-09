import 'package:flutter_test/flutter_test.dart';
import 'package:yo_te_llevo/core/utils/haversine.dart';
import 'package:yo_te_llevo/core/utils/lat_lng.dart';

void main() {
  group('haversineDistance', () {
    // Cuenca, Ecuador coordinates
    const parqueCalderon = LatLng(-2.8973, -79.0044);
    const aeropuerto = LatLng(-2.8895, -78.9844);

    test('distance between Parque Calderón and Aeropuerto ~2.4km', () {
      // Haversine straight-line distance ≈ 2384m
      final distance = haversineDistance(parqueCalderon, aeropuerto);
      expect(distance, closeTo(2384, 2384 * 0.01)); // ±1%
    });

    test('distance between same point is 0', () {
      final distance = haversineDistance(parqueCalderon, parqueCalderon);
      expect(distance, equals(0.0));
    });

    test('distance is symmetric', () {
      final d1 = haversineDistance(parqueCalderon, aeropuerto);
      final d2 = haversineDistance(aeropuerto, parqueCalderon);
      expect(d1, equals(d2));
    });

    test('known distance: Cuenca centro to Parque Calderón ~350m', () {
      const cuencaCentro = LatLng(-2.9001, -79.0059);
      final distance = haversineDistance(cuencaCentro, parqueCalderon);
      // ~350m straight-line
      expect(distance, closeTo(350, 350 * 0.05)); // ±5% for short distances
    });
  });
}
