import 'package:equatable/equatable.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettingsEvent extends SettingsEvent {
  final String userId;

  const LoadSettingsEvent({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class UpdateSettingsEvent extends SettingsEvent {
  final String userId;
  final String? defaultCurrency;
  final List<String>? currencies;
  final List<String>? categories;
  final List<String>? paymentMethods;

  const UpdateSettingsEvent({
    required this.userId,
    this.defaultCurrency,
    this.currencies,
    this.categories,
    this.paymentMethods,
  });

  @override
  List<Object?> get props => [
    userId,
    defaultCurrency,
    currencies,
    categories,
    paymentMethods,
  ];
}

class AddCurrencyEvent extends SettingsEvent {
  final String userId;
  final String currency;
  final String iconPath;

  const AddCurrencyEvent({
    required this.userId,
    required this.currency,
    required this.iconPath,
  });

  @override
  List<Object?> get props => [userId, currency, iconPath];
}

class RemoveCurrencyEvent extends SettingsEvent {
  final String userId;
  final String currency;

  const RemoveCurrencyEvent({
    required this.userId,
    required this.currency,
  });

  @override
  List<Object?> get props => [userId, currency];
}

class SetDefaultCurrencyEvent extends SettingsEvent {
  final String userId;
  final String currency;

  const SetDefaultCurrencyEvent({
    required this.userId,
    required this.currency,
  });

  @override
  List<Object?> get props => [userId, currency];
}

class AddCategoryEvent extends SettingsEvent {
  final String userId;
  final String category;

  const AddCategoryEvent({
    required this.userId,
    required this.category,
  });

  @override
  List<Object?> get props => [userId, category];
}

class RemoveCategoryEvent extends SettingsEvent {
  final String userId;
  final String category;

  const RemoveCategoryEvent({
    required this.userId,
    required this.category,
  });

  @override
  List<Object?> get props => [userId, category];
}

class AddPaymentMethodEvent extends SettingsEvent {
  final String userId;
  final String paymentMethod;

  const AddPaymentMethodEvent({
    required this.userId,
    required this.paymentMethod,
  });

  @override
  List<Object?> get props => [userId, paymentMethod];
}

class RemovePaymentMethodEvent extends SettingsEvent {
  final String userId;
  final String paymentMethod;

  const RemovePaymentMethodEvent({
    required this.userId,
    required this.paymentMethod,
  });

  @override
  List<Object?> get props => [userId, paymentMethod];
} 