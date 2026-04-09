import 'package:dart_geohash/dart_geohash.dart';

import 'lat_lng.dart';

class GeohashUtils {
  GeohashUtils._();

  static final _hasher = GeoHasher();

  /// Encodes a [LatLng] into a geohash string.
  /// Precision 5 ≈ ~5km × 5km cell.
  static String encode(LatLng point, {int precision = 5}) {
    return _hasher.encode(point.longitude, point.latitude, precision: precision);
  }

  /// Returns 9 geohashes: the cell containing the point + 8 adjacent cells.
  static List<String> getNeighbors(String geohash) {
    final neighbors = _hasher.neighbors(geohash);
    return [
      geohash,
      ...neighbors.values.where((v) => v != geohash),
    ];
  }

  /// Returns 9 (start, end) pairs for Firestore range queries.
  /// Each pair covers one geohash cell. Use with:
  /// `where('geohash', isGreaterThanOrEqualTo: start).where('geohash', isLessThan: end)`
  static List<({String start, String end})> queryRanges(LatLng point, {int precision = 5}) {
    final geohash = encode(point, precision: precision);
    final cells = getNeighbors(geohash);

    return cells.map((cell) => (start: cell, end: '$cell~')).toList();
  }
}
