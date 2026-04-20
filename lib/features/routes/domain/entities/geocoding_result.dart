import 'package:equatable/equatable.dart';

import '../../../../core/utils/lat_lng.dart';

class GeocodingResult extends Equatable {
  final String name;
  final String fullAddress;
  final LatLng coordinates;

  const GeocodingResult({
    required this.name,
    required this.fullAddress,
    required this.coordinates,
  });

  @override
  List<Object> get props => [name, fullAddress, coordinates];
}
