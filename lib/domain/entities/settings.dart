import 'package:equatable/equatable.dart';

class Settings extends Equatable {
  final String userId;
  final String defaultCurrency;
  final List<String> currencies;
  final List<String> categories;
  final List<String> paymentMethods;
  final DateTime updatedAt;

  const Settings({
    required this.userId,
    required this.defaultCurrency,
    required this.currencies,
    required this.categories,
    required this.paymentMethods,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    userId,
    defaultCurrency,
    currencies,
    categories,
    paymentMethods,
    updatedAt,
  ];

  Settings copyWith({
    String? userId,
    String? defaultCurrency,
    List<String>? currencies,
    List<String>? categories,
    List<String>? paymentMethods,
    DateTime? updatedAt,
  }) {
    return Settings(
      userId: userId ?? this.userId,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      currencies: currencies ?? this.currencies,
      categories: categories ?? this.categories,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 