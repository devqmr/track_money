import 'package:track_money/domain/entities/settings.dart';

class SettingsModel extends Settings {
  const SettingsModel({
    required String userId,
    required String defaultCurrency,
    required List<String> currencies,
    required List<String> categories,
    required List<String> paymentMethods,
    required DateTime updatedAt,
  }) : super(
          userId: userId,
          defaultCurrency: defaultCurrency,
          currencies: currencies,
          categories: categories,
          paymentMethods: paymentMethods,
          updatedAt: updatedAt,
        );

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      userId: json['userId'],
      defaultCurrency: json['defaultCurrency'],
      currencies: List<String>.from(json['currencies']),
      categories: List<String>.from(json['categories']),
      paymentMethods: List<String>.from(json['paymentMethods']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'defaultCurrency': defaultCurrency,
      'currencies': currencies,
      'categories': categories,
      'paymentMethods': paymentMethods,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SettingsModel.fromEntity(Settings settings) {
    return SettingsModel(
      userId: settings.userId,
      defaultCurrency: settings.defaultCurrency,
      currencies: settings.currencies,
      categories: settings.categories,
      paymentMethods: settings.paymentMethods,
      updatedAt: settings.updatedAt,
    );
  }
} 