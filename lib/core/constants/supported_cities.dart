/// Ciudades soportadas por el MVP.
///
/// Por ahora la app sólo opera en Cuenca (Ecuador). Cuando se habilite otra
/// ciudad basta con extender este archivo sin tocar datasources ni pantallas.
class SupportedCities {
  SupportedCities._();

  static const String defaultCity = 'Cuenca';
  static const String defaultProvince = 'Azuay';

  /// Caja geográfica para restringir búsquedas de Mapbox a Cuenca.
  /// Formato Mapbox: [minLon, minLat, maxLon, maxLat].
  static const List<double> cuencaBbox = [-79.10, -3.05, -78.90, -2.85];

  /// Centro aproximado del área urbana de Cuenca (para `proximity` y como
  /// punto inicial del mapa en `HomeMapScreen`).
  static const double cuencaCenterLon = -79.0045;
  static const double cuencaCenterLat = -2.9001;

  /// Zoom inicial del mapa cuando se abre sobre Cuenca.
  static const double cuencaDefaultZoom = 12;

  /// Tipos de feature admitidos en la búsqueda de lugares para evitar que
  /// Mapbox devuelva países, regiones o divisiones mayores.
  static const String searchTypes = 'address,poi,place,neighborhood,locality';
}
