import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:yo_te_llevo/features/routes/data/datasources/polyline_cache_datasource.dart';

void main() {
  late Box<String> box;
  late PolylineCacheDataSource dataSource;

  setUp(() async {
    Hive.init('/tmp/hive_test_${DateTime.now().millisecondsSinceEpoch}');
    box = await Hive.openBox<String>('test_polyline_cache');
    dataSource = PolylineCacheDataSource(box);
  });

  tearDown(() async {
    await box.clear();
    await box.close();
  });

  group('PolylineCacheDataSource', () {
    const routeId = 'route_123';
    const polyline = 'mfz~@n`|yN_CeG';

    test('cachePolyline stores data with timestamp', () async {
      await dataSource.cachePolyline(routeId, polyline);

      final raw = box.get(routeId);
      expect(raw, isNotNull);

      final entry = jsonDecode(raw!) as Map<String, dynamic>;
      expect(entry['polyline'], polyline);
      expect(entry['timestamp'], isA<int>());
    });

    test('getPolyline returns cached polyline', () async {
      await dataSource.cachePolyline(routeId, polyline);
      final result = dataSource.getPolyline(routeId);

      expect(result, polyline);
    });

    test('getPolyline returns null for non-existent key', () {
      final result = dataSource.getPolyline('non_existent');
      expect(result, isNull);
    });

    test('getPolyline returns null and deletes expired cache', () async {
      // Insert an entry with a timestamp 8 days ago
      final expired = jsonEncode({
        'polyline': polyline,
        'timestamp': DateTime.now()
            .subtract(const Duration(days: 8))
            .millisecondsSinceEpoch,
      });
      await box.put(routeId, expired);

      final result = dataSource.getPolyline(routeId);

      expect(result, isNull);
      expect(box.get(routeId), isNull);
    });

    test('getPolyline returns polyline for non-expired cache (6 days)', () async {
      final recent = jsonEncode({
        'polyline': polyline,
        'timestamp': DateTime.now()
            .subtract(const Duration(days: 6))
            .millisecondsSinceEpoch,
      });
      await box.put(routeId, recent);

      final result = dataSource.getPolyline(routeId);
      expect(result, polyline);
    });

    test('invalidate removes specific route cache', () async {
      await dataSource.cachePolyline(routeId, polyline);
      await dataSource.cachePolyline('route_456', 'other_polyline');

      await dataSource.invalidate(routeId);

      expect(dataSource.getPolyline(routeId), isNull);
      expect(dataSource.getPolyline('route_456'), 'other_polyline');
    });

    test('clearAll removes all cached polylines', () async {
      await dataSource.cachePolyline(routeId, polyline);
      await dataSource.cachePolyline('route_456', 'other_polyline');

      await dataSource.clearAll();

      expect(dataSource.getPolyline(routeId), isNull);
      expect(dataSource.getPolyline('route_456'), isNull);
    });
  });
}
