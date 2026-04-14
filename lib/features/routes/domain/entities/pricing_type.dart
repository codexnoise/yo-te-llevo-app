enum PricingType {
  perTrip,
  daily,
  weekly,
  monthly;

  String get label {
    switch (this) {
      case PricingType.perTrip:
        return 'Por viaje';
      case PricingType.daily:
        return 'Diario';
      case PricingType.weekly:
        return 'Semanal';
      case PricingType.monthly:
        return 'Mensual';
    }
  }

  String get suffix {
    switch (this) {
      case PricingType.perTrip:
        return '/viaje';
      case PricingType.daily:
        return '/día';
      case PricingType.weekly:
        return '/semana';
      case PricingType.monthly:
        return '/mes';
    }
  }

  static PricingType fromString(String value) {
    switch (value) {
      case 'perTrip':
        return PricingType.perTrip;
      case 'daily':
        return PricingType.daily;
      case 'weekly':
        return PricingType.weekly;
      case 'monthly':
        return PricingType.monthly;
      default:
        return PricingType.perTrip;
    }
  }
}
