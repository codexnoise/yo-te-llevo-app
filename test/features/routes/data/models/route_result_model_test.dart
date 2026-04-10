import 'package:flutter_test/flutter_test.dart';
import 'package:yo_te_llevo/features/routes/data/models/route_result_model.dart';

void main() {
  group('RouteResultModel', () {
    test('fromDirectionsResponse parses valid response', () {
      final json = {
        'routes': [
          {
            'geometry': 'mfz~@n`|yN_CeG',
            'distance': 1500.5,
            'duration': 120.3,
          }
        ],
        'code': 'Ok',
      };

      final result = RouteResultModel.fromDirectionsResponse(json);

      expect(result.polylineEncoded, 'mfz~@n`|yN_CeG');
      expect(result.distanceMeters, 1500.5);
      expect(result.durationSeconds, 120.3);
      expect(result.polylineDecoded, isNotEmpty);
    });

    test('fromDirectionsResponse handles integer distance/duration', () {
      final json = {
        'routes': [
          {
            'geometry': 'mfz~@n`|yN_CeG',
            'distance': 1500,
            'duration': 120,
          }
        ],
        'code': 'Ok',
      };

      final result = RouteResultModel.fromDirectionsResponse(json);

      expect(result.distanceMeters, 1500.0);
      expect(result.durationSeconds, 120.0);
    });

    test('equatable compares by encoded polyline, distance and duration', () {
      const a = RouteResultModel(
        polylineEncoded: 'abc',
        polylineDecoded: [],
        distanceMeters: 100,
        durationSeconds: 50,
      );
      const b = RouteResultModel(
        polylineEncoded: 'abc',
        polylineDecoded: [],
        distanceMeters: 100,
        durationSeconds: 50,
      );

      expect(a, equals(b));
    });
  });
}
