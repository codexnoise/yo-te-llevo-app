class MapboxConstants {
  MapboxConstants._();

  static const String baseUrl = 'https://api.mapbox.com';
  static const String directionsEndpoint = '/directions/v5/mapbox/driving';
  static const String geocodingEndpoint = '/geocoding/v5/mapbox.places';
  static const String matrixEndpoint = '/directions-matrix/v1/mapbox/driving';

  static const int connectionTimeout = 10000; // 10s
  static const int receiveTimeout = 15000; // 15s

  // Default params
  static const String geometries = 'polyline6';
  static const String overview = 'full';
  static const String language = 'es';
  static const String country = 'ec';
}
