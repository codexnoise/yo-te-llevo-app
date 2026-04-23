import '../../../../core/constants/mapbox_constants.dart';
import '../../../../core/constants/supported_cities.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/lat_lng.dart';
import '../models/geocoding_result_model.dart';

class MapboxGeocodingDataSource {
  final DioClient _client;

  MapboxGeocodingDataSource(this._client);

  Future<List<GeocodingResultModel>> search(
    String query, {
    LatLng? proximity,
    String country = MapboxConstants.country,
  }) async {
    if (query.trim().isEmpty) return [];

    final queryParams = <String, dynamic>{
      'limit': '5',
      'language': MapboxConstants.language,
      'country': country,
      'types': SupportedCities.searchTypes,
      'bbox': SupportedCities.cuencaBbox.join(','),
    };

    final proximityLon =
        proximity?.longitude ?? SupportedCities.cuencaCenterLon;
    final proximityLat =
        proximity?.latitude ?? SupportedCities.cuencaCenterLat;
    queryParams['proximity'] = '$proximityLon,$proximityLat';

    try {
      final response = await _client.get(
        '${MapboxConstants.geocodingEndpoint}/${Uri.encodeComponent(query)}.json',
        queryParameters: queryParams,
      );

      if (response.statusCode != 200) {
        throw ServerException(
          message: 'Geocoding API error: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      final data = response.data as Map<String, dynamic>;
      final features = data['features'] as List? ?? [];

      return features
          .map((f) => GeocodingResultModel.fromMapboxFeature(
              f as Map<String, dynamic>))
          .toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Geocoding search failed: $e');
    }
  }

  Future<String> reverseGeocode(LatLng point) async {
    try {
      final response = await _client.get(
        '${MapboxConstants.geocodingEndpoint}/${point.longitude},${point.latitude}.json',
        queryParameters: {
          'limit': '1',
          'language': MapboxConstants.language,
        },
      );

      if (response.statusCode != 200) {
        throw ServerException(
          message: 'Reverse geocoding error: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      final data = response.data as Map<String, dynamic>;
      final features = data['features'] as List? ?? [];

      if (features.isEmpty) return 'Ubicación desconocida';

      final feature = features.first as Map<String, dynamic>;
      return feature['place_name'] as String? ?? 'Ubicación desconocida';
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Reverse geocoding failed: $e');
    }
  }
}
