import 'dart:math';

import 'lat_lng.dart';

const double _earthRadiusMeters = 6371000;

/// Calculates the great-circle distance in meters between two coordinates
/// using the Haversine formula.
double haversineDistance(LatLng a, LatLng b) {
  final dLat = _toRadians(b.latitude - a.latitude);
  final dLng = _toRadians(b.longitude - a.longitude);

  final halfDLat = sin(dLat / 2);
  final halfDLng = sin(dLng / 2);

  final aValue = halfDLat * halfDLat +
      cos(_toRadians(a.latitude)) *
          cos(_toRadians(b.latitude)) *
          halfDLng *
          halfDLng;

  final c = 2 * atan2(sqrt(aValue), sqrt(1 - aValue));

  return _earthRadiusMeters * c;
}

double _toRadians(double degrees) => degrees * pi / 180;
