import 'package:flutter_test/flutter_test.dart';
import 'package:yo_te_llevo/core/utils/geohash_utils.dart';
import 'package:yo_te_llevo/core/utils/lat_lng.dart';

void main() {
  const cuencaCentro = LatLng(-2.9001, -79.0059);

  group('GeohashUtils.encode', () {
    test('generates consistent geohash for same coordinates', () {
      final hash1 = GeohashUtils.encode(cuencaCentro);
      final hash2 = GeohashUtils.encode(cuencaCentro);
      expect(hash1, equals(hash2));
    });

    test('generates geohash with correct precision length', () {
      final hash5 = GeohashUtils.encode(cuencaCentro, precision: 5);
      final hash7 = GeohashUtils.encode(cuencaCentro, precision: 7);
      expect(hash5.length, equals(5));
      expect(hash7.length, equals(7));
    });

    test('nearby points share geohash prefix', () {
      const parqueCalderon = LatLng(-2.8973, -79.0044);
      final hash1 = GeohashUtils.encode(cuencaCentro, precision: 5);
      final hash2 = GeohashUtils.encode(parqueCalderon, precision: 5);
      // At precision 5 (~5km cells) these nearby points should share a prefix
      expect(hash1.substring(0, 3), equals(hash2.substring(0, 3)));
    });
  });

  group('GeohashUtils.getNeighbors', () {
    test('returns 9 geohashes', () {
      final hash = GeohashUtils.encode(cuencaCentro);
      final neighbors = GeohashUtils.getNeighbors(hash);
      expect(neighbors.length, equals(9));
    });

    test('includes the original geohash', () {
      final hash = GeohashUtils.encode(cuencaCentro);
      final neighbors = GeohashUtils.getNeighbors(hash);
      expect(neighbors, contains(hash));
    });

    test('all neighbors have same length as original', () {
      final hash = GeohashUtils.encode(cuencaCentro);
      final neighbors = GeohashUtils.getNeighbors(hash);
      for (final n in neighbors) {
        expect(n.length, equals(hash.length));
      }
    });
  });

  group('GeohashUtils.queryRanges', () {
    test('returns 9 ranges', () {
      final ranges = GeohashUtils.queryRanges(cuencaCentro);
      expect(ranges.length, equals(9));
    });

    test('each range end is start + tilde', () {
      final ranges = GeohashUtils.queryRanges(cuencaCentro);
      for (final range in ranges) {
        expect(range.end, equals('${range.start}~'));
      }
    });

    test('ranges cover the original geohash', () {
      final hash = GeohashUtils.encode(cuencaCentro);
      final ranges = GeohashUtils.queryRanges(cuencaCentro);
      final starts = ranges.map((r) => r.start).toList();
      expect(starts, contains(hash));
    });
  });
}
