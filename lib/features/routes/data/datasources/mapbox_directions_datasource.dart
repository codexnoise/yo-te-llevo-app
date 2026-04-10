import '../../../../core/constants/mapbox_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/lat_lng.dart';
import '../models/route_result_model.dart';

class MapboxDirectionsDataSource {
  final DioClient _client;

  MapboxDirectionsDataSource(this._client);

  Future<RouteResultModel> getRoute(List<LatLng> waypoints) async {
    if (waypoints.length < 2 || waypoints.length > 25) {
      throw const ServerException(
        message: 'Waypoints must be between 2 and 25',
      );
    }

    final coordinates = waypoints
        .map((p) => '${p.longitude},${p.latitude}')
        .join(';');

    try {
      final response = await _client.get(
        '${MapboxConstants.directionsEndpoint}/$coordinates',
        queryParameters: {
          'geometries': MapboxConstants.geometries,
          'overview': MapboxConstants.overview,
          'steps': 'false',
          'alternatives': 'false',
        },
      );

      if (response.statusCode != 200) {
        throw ServerException(
          message: 'Directions API error: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      final data = response.data as Map<String, dynamic>;
      final code = data['code'] as String?;

      if (code != 'Ok' || (data['routes'] as List?)?.isEmpty != false) {
        throw ServerException(
          message: 'Directions API returned no routes: $code',
        );
      }

      return RouteResultModel.fromDirectionsResponse(data);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Directions request failed: $e');
    }
  }
}
