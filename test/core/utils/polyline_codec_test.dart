import 'package:flutter_test/flutter_test.dart';
import 'package:yo_te_llevo/core/utils/lat_lng.dart';
import 'package:yo_te_llevo/core/utils/polyline_codec.dart';

void main() {
  group('PolylineCodec', () {
    // Known polyline6 encoded string for two points in Cuenca
    // -2.8973, -79.0044 and -2.8895, -78.9844
    final testCoords = [
      const LatLng(-2.8973, -79.0044),
      const LatLng(-2.8895, -78.9844),
    ];

    test('encode then decode roundtrip preserves coordinates', () {
      final encoded = PolylineCodec.encode(testCoords);
      final decoded = PolylineCodec.decode(encoded);

      expect(decoded.length, equals(testCoords.length));
      for (int i = 0; i < testCoords.length; i++) {
        expect(decoded[i].latitude, closeTo(testCoords[i].latitude, 1e-6));
        expect(decoded[i].longitude, closeTo(testCoords[i].longitude, 1e-6));
      }
    });

    test('decode with precision 5 (Google format)', () {
      // Known Google polyline5: "_p~iF~ps|U" decodes to (38.5, -120.2)
      final decoded = PolylineCodec.decode('_p~iF~ps|U', precision: 5);
      expect(decoded.length, equals(1));
      expect(decoded[0].latitude, closeTo(38.5, 0.01));
      expect(decoded[0].longitude, closeTo(-120.2, 0.01));
    });

    test('encode empty list returns empty string', () {
      expect(PolylineCodec.encode([]), equals(''));
    });

    test('decode empty string returns empty list', () {
      expect(PolylineCodec.decode(''), isEmpty);
    });

    test('encode/decode multiple points', () {
      final coords = [
        const LatLng(-2.9001, -79.0059),
        const LatLng(-2.8973, -79.0044),
        const LatLng(-2.8895, -78.9844),
      ];

      final encoded = PolylineCodec.encode(coords);
      final decoded = PolylineCodec.decode(encoded);

      expect(decoded.length, equals(3));
      for (int i = 0; i < coords.length; i++) {
        expect(decoded[i].latitude, closeTo(coords[i].latitude, 1e-6));
        expect(decoded[i].longitude, closeTo(coords[i].longitude, 1e-6));
      }
    });
  });
}
