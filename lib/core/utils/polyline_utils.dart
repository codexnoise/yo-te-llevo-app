import 'dart:math';

import 'haversine.dart';
import 'lat_lng.dart';

class NearestPointResult {
  final LatLng point;
  final double distance;
  final int segmentIndex;

  const NearestPointResult({
    required this.point,
    required this.distance,
    required this.segmentIndex,
  });
}

/// Returns the minimum distance in meters from [point] to the [polyline].
double pointToPolylineDistance(LatLng point, List<LatLng> polyline) {
  return nearestPointOnPolyline(point, polyline).distance;
}

/// Finds the nearest point on the [polyline] to the given [point].
///
/// Returns the closest coordinates, the distance in meters, and the
/// segment index where the closest point lies.
NearestPointResult nearestPointOnPolyline(LatLng point, List<LatLng> polyline) {
  assert(polyline.length >= 2, 'Polyline must have at least 2 points');

  double minDistance = double.infinity;
  LatLng closestPoint = polyline.first;
  int closestSegment = 0;

  for (int i = 0; i < polyline.length - 1; i++) {
    final projected = _projectPointOnSegment(point, polyline[i], polyline[i + 1]);
    final distance = haversineDistance(point, projected);

    if (distance < minDistance) {
      minDistance = distance;
      closestPoint = projected;
      closestSegment = i;
    }
  }

  return NearestPointResult(
    point: closestPoint,
    distance: minDistance,
    segmentIndex: closestSegment,
  );
}

/// Returns true if the pickup point is before the dropoff point on the route.
bool isCorrectDirection(int pickupSegmentIndex, int dropoffSegmentIndex) {
  return pickupSegmentIndex <= dropoffSegmentIndex;
}

/// Calculates the total distance in meters along the polyline from
/// [fromIndex] to [toIndex] (inclusive).
double polylineSegmentDistance(List<LatLng> polyline, int fromIndex, int toIndex) {
  assert(fromIndex >= 0 && toIndex < polyline.length && fromIndex <= toIndex);

  double total = 0;
  for (int i = fromIndex; i < toIndex; i++) {
    total += haversineDistance(polyline[i], polyline[i + 1]);
  }
  return total;
}

/// Projects point Q onto the line segment (A, B) and returns the closest
/// point on the segment.
LatLng _projectPointOnSegment(LatLng q, LatLng a, LatLng b) {
  final dx = b.latitude - a.latitude;
  final dy = b.longitude - a.longitude;

  if (dx == 0 && dy == 0) return a;

  // Scalar projection parameter t
  final t = ((q.latitude - a.latitude) * dx + (q.longitude - a.longitude) * dy) /
      (dx * dx + dy * dy);

  // Clamp t to [0, 1] to stay within the segment
  final clamped = max(0.0, min(1.0, t));

  return LatLng(
    a.latitude + clamped * dx,
    a.longitude + clamped * dy,
  );
}
