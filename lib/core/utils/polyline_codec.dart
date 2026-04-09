import 'lat_lng.dart';

class PolylineCodec {
  PolylineCodec._();

  /// Decodes an encoded polyline string into a list of [LatLng] coordinates.
  ///
  /// [precision] is 6 for Mapbox polyline6 format, 5 for Google standard.
  static List<LatLng> decode(String encoded, {int precision = 6}) {
    final List<LatLng> coordinates = [];
    final factor = _pow10(precision);
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;

      // Decode latitude
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);

      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      // Decode longitude
      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);

      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      coordinates.add(LatLng(lat / factor, lng / factor));
    }

    return coordinates;
  }

  /// Encodes a list of [LatLng] coordinates into a polyline string.
  ///
  /// [precision] is 6 for Mapbox polyline6 format, 5 for Google standard.
  static String encode(List<LatLng> coordinates, {int precision = 6}) {
    final factor = _pow10(precision);
    final buffer = StringBuffer();
    int prevLat = 0;
    int prevLng = 0;

    for (final coord in coordinates) {
      final lat = (coord.latitude * factor).round();
      final lng = (coord.longitude * factor).round();

      _encodeValue(lat - prevLat, buffer);
      _encodeValue(lng - prevLng, buffer);

      prevLat = lat;
      prevLng = lng;
    }

    return buffer.toString();
  }

  static void _encodeValue(int value, StringBuffer buffer) {
    int v = value < 0 ? ~(value << 1) : (value << 1);
    while (v >= 0x20) {
      buffer.writeCharCode((0x20 | (v & 0x1F)) + 63);
      v >>= 5;
    }
    buffer.writeCharCode(v + 63);
  }

  static double _pow10(int exponent) {
    double result = 1;
    for (int i = 0; i < exponent; i++) {
      result *= 10;
    }
    return result;
  }
}
