import 'package:flutter_test/flutter_test.dart';
import 'package:yo_te_llevo/core/utils/haversine.dart';
import 'package:yo_te_llevo/core/utils/lat_lng.dart';
import 'package:yo_te_llevo/core/utils/polyline_utils.dart';

void main() {
  // Polyline simulating a route through Cuenca (roughly west to east)
  final polyline = [
    const LatLng(-2.9010, -79.0100), // P0 - west
    const LatLng(-2.9000, -79.0050), // P1
    const LatLng(-2.8990, -79.0000), // P2
    const LatLng(-2.8980, -78.9950), // P3
    const LatLng(-2.8970, -78.9900), // P4 - east
  ];

  group('pointToPolylineDistance', () {
    test('point on the polyline returns distance < 10m', () {
      // Point that is exactly on the polyline (midpoint of P1-P2)
      const onPolyline = LatLng(-2.8995, -79.0025);
      final distance = pointToPolylineDistance(onPolyline, polyline);
      expect(distance, lessThan(10));
    });

    test('point ~500m away returns approximately 500m', () {
      // Point displaced ~500m north of polyline midpoint
      // 500m in latitude ≈ 0.0045 degrees
      const farPoint = LatLng(-2.8945, -79.0025);
      final distance = pointToPolylineDistance(farPoint, polyline);
      expect(distance, closeTo(500, 100)); // ±100m tolerance
    });
  });

  group('nearestPointOnPolyline', () {
    test('returns point within polyline bounds', () {
      const testPoint = LatLng(-2.8995, -79.0025);
      final result = nearestPointOnPolyline(testPoint, polyline);

      // Nearest point latitude should be between polyline extremes
      expect(result.point.latitude, greaterThanOrEqualTo(-2.9010));
      expect(result.point.latitude, lessThanOrEqualTo(-2.8970));
      expect(result.point.longitude, greaterThanOrEqualTo(-79.0100));
      expect(result.point.longitude, lessThanOrEqualTo(-78.9900));
    });

    test('returns valid segment index', () {
      const testPoint = LatLng(-2.8995, -79.0025);
      final result = nearestPointOnPolyline(testPoint, polyline);

      expect(result.segmentIndex, greaterThanOrEqualTo(0));
      expect(result.segmentIndex, lessThan(polyline.length - 1));
    });
  });

  group('isCorrectDirection', () {
    test('returns true when pickup is before dropoff', () {
      expect(isCorrectDirection(1, 3), isTrue);
    });

    test('returns true when pickup and dropoff are on same segment', () {
      expect(isCorrectDirection(2, 2), isTrue);
    });

    test('returns false when pickup is after dropoff', () {
      expect(isCorrectDirection(3, 1), isFalse);
    });
  });

  group('polylineSegmentDistance', () {
    test('distance from first to last equals sum of all segments', () {
      final totalDistance = polylineSegmentDistance(polyline, 0, polyline.length - 1);

      // Calculate manually
      double manual = 0;
      for (int i = 0; i < polyline.length - 1; i++) {
        manual += haversineDistance(polyline[i], polyline[i + 1]);
      }

      expect(totalDistance, closeTo(manual, 0.01));
    });

    test('partial segment distance is less than total', () {
      final partial = polylineSegmentDistance(polyline, 1, 3);
      final total = polylineSegmentDistance(polyline, 0, polyline.length - 1);
      expect(partial, lessThan(total));
    });

    test('single point distance is 0', () {
      final distance = polylineSegmentDistance(polyline, 2, 2);
      expect(distance, equals(0.0));
    });
  });
}
