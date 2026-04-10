import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';

class PolylineCacheDataSource {
  final Box<String> _box;

  PolylineCacheDataSource(this._box);

  Future<void> cachePolyline(String routeId, String encodedPolyline) async {
    try {
      final entry = jsonEncode({
        'polyline': encodedPolyline,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      await _box.put(routeId, entry);
    } catch (e) {
      throw CacheException(message: 'Failed to cache polyline: $e');
    }
  }

  String? getPolyline(String routeId) {
    try {
      final raw = _box.get(routeId);
      if (raw == null) return null;

      final entry = jsonDecode(raw) as Map<String, dynamic>;
      final timestamp = entry['timestamp'] as int;
      final age = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(timestamp));

      if (age.inDays >= AppConstants.polylineCacheExpirationDays) {
        _box.delete(routeId);
        return null;
      }

      return entry['polyline'] as String;
    } catch (e) {
      throw CacheException(message: 'Failed to read polyline cache: $e');
    }
  }

  Future<void> invalidate(String routeId) async {
    try {
      await _box.delete(routeId);
    } catch (e) {
      throw CacheException(message: 'Failed to invalidate cache: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      await _box.clear();
    } catch (e) {
      throw CacheException(message: 'Failed to clear cache: $e');
    }
  }
}
