/// Horizonte temporal de una serie recurrente solicitada por el pasajero.
///
/// Se traduce a un `endDate` absoluto en el momento del `requestTrip`. Los
/// valores se aproximan en días (no calendario real) para mantener simple el
/// MVP — feedback de testers definirá si conviene math de meses calendario.
enum RecurrenceDuration {
  oneWeek,
  twoWeeks,
  oneMonth,
  threeMonths;

  Duration get value {
    switch (this) {
      case RecurrenceDuration.oneWeek:
        return const Duration(days: 7);
      case RecurrenceDuration.twoWeeks:
        return const Duration(days: 15);
      case RecurrenceDuration.oneMonth:
        return const Duration(days: 30);
      case RecurrenceDuration.threeMonths:
        return const Duration(days: 90);
    }
  }

  String get label {
    switch (this) {
      case RecurrenceDuration.oneWeek:
        return '1 semana';
      case RecurrenceDuration.twoWeeks:
        return '15 días';
      case RecurrenceDuration.oneMonth:
        return '1 mes';
      case RecurrenceDuration.threeMonths:
        return '3 meses';
    }
  }

  static const defaultValue = RecurrenceDuration.oneMonth;
}
