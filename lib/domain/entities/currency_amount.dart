import 'package:equatable/equatable.dart';

class CurrencyAmount extends Equatable {
  const CurrencyAmount({
    required this.currency,
    required this.value,
  });

  final String currency;
  final double value;

  String get formatted => '${value.toStringAsFixed(2)} $currency';

  CurrencyAmount operator +(CurrencyAmount other) {
    assert(currency == other.currency, 'Cannot sum different currencies');
    return CurrencyAmount(currency: currency, value: value + other.value);
  }

  CurrencyAmount operator -(CurrencyAmount other) {
    assert(currency == other.currency, 'Cannot subtract different currencies');
    return CurrencyAmount(currency: currency, value: value - other.value);
  }

  CurrencyAmount abs() => CurrencyAmount(currency: currency, value: value.abs());

  @override
  List<Object?> get props => [currency, value];
}
