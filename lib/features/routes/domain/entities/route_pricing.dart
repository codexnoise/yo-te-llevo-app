import 'package:equatable/equatable.dart';

import 'pricing_type.dart';

class RoutePricing extends Equatable {
  final PricingType type;
  final double amount;
  final String currency;

  const RoutePricing({
    required this.type,
    required this.amount,
    this.currency = 'USD',
  });

  String get formatted => '\$${amount.toStringAsFixed(2)} ${type.suffix}';

  RoutePricing copyWith({
    PricingType? type,
    double? amount,
    String? currency,
  }) {
    return RoutePricing(
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
    );
  }

  @override
  List<Object> get props => [type, amount, currency];
}
