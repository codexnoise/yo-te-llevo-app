import 'package:equatable/equatable.dart';

class RouteSchedule extends Equatable {
  final List<String> days;
  final String departureTime;
  final String? returnTime;

  const RouteSchedule({
    required this.days,
    required this.departureTime,
    this.returnTime,
  });

  RouteSchedule copyWith({
    List<String>? days,
    String? departureTime,
    String? Function()? returnTime,
  }) {
    return RouteSchedule(
      days: days ?? this.days,
      departureTime: departureTime ?? this.departureTime,
      returnTime: returnTime != null ? returnTime() : this.returnTime,
    );
  }

  @override
  List<Object?> get props => [days, departureTime, returnTime];
}
