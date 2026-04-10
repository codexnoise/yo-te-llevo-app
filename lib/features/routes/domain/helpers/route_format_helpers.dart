class RouteFormatHelpers {
  RouteFormatHelpers._();

  static String formatDuration(int seconds) {
    if (seconds < 60) return '$seconds seg';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) return '$hours h';
    return '$hours h $remainingMinutes min';
  }

  static String formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    final km = meters / 1000;
    return '${km.toStringAsFixed(1)} km';
  }
}
