import 'package:flutter_test/flutter_test.dart';
import 'package:yo_te_llevo/core/utils/lat_lng.dart';
import 'package:yo_te_llevo/features/routes/data/models/geocoding_result_model.dart';

void main() {
  group('GeocodingResultModel', () {
    test('fromMapboxFeature parses valid feature', () {
      final feature = {
        'text': 'Terminal Terrestre',
        'place_name': 'Terminal Terrestre, Cuenca, Ecuador',
        'center': [-79.0044, -2.8973],
      };

      final result = GeocodingResultModel.fromMapboxFeature(feature);

      expect(result.name, 'Terminal Terrestre');
      expect(result.fullAddress, 'Terminal Terrestre, Cuenca, Ecuador');
      expect(result.coordinates.latitude, closeTo(-2.8973, 1e-4));
      expect(result.coordinates.longitude, closeTo(-79.0044, 1e-4));
    });

    test('fromMapboxFeature uses center[1] as lat and center[0] as lng', () {
      final feature = {
        'text': 'Test',
        'place_name': 'Test Place',
        'center': [-79.5, -2.5],
      };

      final result = GeocodingResultModel.fromMapboxFeature(feature);

      // center[0] is longitude, center[1] is latitude
      expect(result.coordinates, const LatLng(-2.5, -79.5));
    });

    test('fromMapboxFeature handles missing text and place_name', () {
      final feature = {
        'center': [-79.0, -2.9],
      };

      final result = GeocodingResultModel.fromMapboxFeature(feature);

      expect(result.name, '');
      expect(result.fullAddress, '');
    });

    test('equatable works correctly', () {
      const a = GeocodingResultModel(
        name: 'Test',
        fullAddress: 'Test Address',
        coordinates: LatLng(-2.9, -79.0),
      );
      const b = GeocodingResultModel(
        name: 'Test',
        fullAddress: 'Test Address',
        coordinates: LatLng(-2.9, -79.0),
      );

      expect(a, equals(b));
    });
  });
}
