import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yo_te_llevo/core/utils/lat_lng.dart';

void main() {
  group('LatLng', () {
    const cuencaCentro = LatLng(-2.9001, -79.0059);

    test('equality works', () {
      const a = LatLng(-2.9001, -79.0059);
      const b = LatLng(-2.9001, -79.0059);
      expect(a, equals(b));
    });

    test('inequality works', () {
      const a = LatLng(-2.9001, -79.0059);
      const b = LatLng(-2.8973, -79.0044);
      expect(a, isNot(equals(b)));
    });

    test('toJson / fromJson roundtrip', () {
      final json = cuencaCentro.toJson();
      expect(json, {'latitude': -2.9001, 'longitude': -79.0059});

      final restored = LatLng.fromJson(json);
      expect(restored, equals(cuencaCentro));
    });

    test('toGeoPoint / fromGeoPoint roundtrip', () {
      final geoPoint = cuencaCentro.toGeoPoint();
      expect(geoPoint, isA<GeoPoint>());
      expect(geoPoint.latitude, -2.9001);
      expect(geoPoint.longitude, -79.0059);

      final restored = LatLng.fromGeoPoint(geoPoint);
      expect(restored, equals(cuencaCentro));
    });

    test('toString', () {
      expect(cuencaCentro.toString(), 'LatLng(-2.9001, -79.0059)');
    });
  });
}
