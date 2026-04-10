import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/providers/connectivity_provider.dart';
import '../../data/datasources/mapbox_directions_datasource.dart';
import '../../data/datasources/mapbox_geocoding_datasource.dart';
import '../../data/datasources/polyline_cache_datasource.dart';
import '../../data/repositories/mapbox_repository_impl.dart';
import '../../domain/repositories/mapbox_repository.dart';

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

final directionsDataSourceProvider =
    Provider<MapboxDirectionsDataSource>((ref) {
  return MapboxDirectionsDataSource(ref.watch(dioClientProvider));
});

final geocodingDataSourceProvider =
    Provider<MapboxGeocodingDataSource>((ref) {
  return MapboxGeocodingDataSource(ref.watch(dioClientProvider));
});

final polylineCacheDataSourceProvider =
    Provider<PolylineCacheDataSource>((ref) {
  final box = Hive.box<String>(AppConstants.polylineCacheBox);
  return PolylineCacheDataSource(box);
});

final mapboxRepositoryProvider = Provider<MapboxRepository>((ref) {
  return MapboxRepositoryImpl(
    directionsDataSource: ref.watch(directionsDataSourceProvider),
    geocodingDataSource: ref.watch(geocodingDataSourceProvider),
    cacheDataSource: ref.watch(polylineCacheDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});
