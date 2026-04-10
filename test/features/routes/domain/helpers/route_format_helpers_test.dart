import 'package:flutter_test/flutter_test.dart';
import 'package:yo_te_llevo/features/routes/domain/helpers/route_format_helpers.dart';

void main() {
  group('RouteFormatHelpers.formatDuration', () {
    test('formats seconds < 60 as "X seg"', () {
      expect(RouteFormatHelpers.formatDuration(30), '30 seg');
      expect(RouteFormatHelpers.formatDuration(0), '0 seg');
      expect(RouteFormatHelpers.formatDuration(59), '59 seg');
    });

    test('formats minutes < 60 as "X min"', () {
      expect(RouteFormatHelpers.formatDuration(60), '1 min');
      expect(RouteFormatHelpers.formatDuration(300), '5 min');
      expect(RouteFormatHelpers.formatDuration(3540), '59 min');
    });

    test('formats hours with remaining minutes', () {
      expect(RouteFormatHelpers.formatDuration(3660), '1 h 1 min');
      expect(RouteFormatHelpers.formatDuration(7500), '2 h 5 min');
    });

    test('formats exact hours without remaining minutes', () {
      expect(RouteFormatHelpers.formatDuration(3600), '1 h');
      expect(RouteFormatHelpers.formatDuration(7200), '2 h');
    });
  });

  group('RouteFormatHelpers.formatDistance', () {
    test('formats meters < 1000 as "X m"', () {
      expect(RouteFormatHelpers.formatDistance(500), '500 m');
      expect(RouteFormatHelpers.formatDistance(0), '0 m');
      expect(RouteFormatHelpers.formatDistance(999), '999 m');
    });

    test('formats meters >= 1000 as "X.X km"', () {
      expect(RouteFormatHelpers.formatDistance(1000), '1.0 km');
      expect(RouteFormatHelpers.formatDistance(1500), '1.5 km');
      expect(RouteFormatHelpers.formatDistance(15234), '15.2 km');
    });

    test('rounds meters correctly', () {
      expect(RouteFormatHelpers.formatDistance(499.6), '500 m');
      expect(RouteFormatHelpers.formatDistance(1050), '1.1 km');
    });
  });
}
