import 'package:equatable/equatable.dart';

import '../../../../core/utils/lat_lng.dart';
import '../../domain/entities/geocoding_result.dart';

class GeocodingResultModel extends Equatable {
  final String name;
  final String fullAddress;
  final LatLng coordinates;

  const GeocodingResultModel({
    required this.name,
    required this.fullAddress,
    required this.coordinates,
  });

  factory GeocodingResultModel.fromMapboxFeature(Map<String, dynamic> feature) {
    final center = feature['center'] as List;
    final placeName = feature['place_name'] as String? ?? '';
    final text = feature['text'] as String? ?? '';

    return GeocodingResultModel(
      name: text,
      fullAddress: placeName,
      coordinates: LatLng(
        (center[1] as num).toDouble(),
        (center[0] as num).toDouble(),
      ),
    );
  }

  GeocodingResult toEntity() => GeocodingResult(
        name: name,
        fullAddress: fullAddress,
        coordinates: coordinates,
      );

  @override
  List<Object> get props => [name, fullAddress, coordinates];
}
