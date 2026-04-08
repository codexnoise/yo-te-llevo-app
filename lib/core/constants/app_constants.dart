class AppConstants {
  AppConstants._();

  static const String appName = 'Yo Te Llevo';
  static const String appVersion = '1.0.0';

  // Matching
  static const double toleranceRadiusMeters = 800;
  static const double haversineFilterMeters = 5000;
  static const int maxDetourSeconds = 600;

  // Cache
  static const String polylineCacheBox = 'polyline_cache';
  static const String userPrefsBox = 'user_prefs';
  static const int polylineCacheExpirationDays = 7;
}
