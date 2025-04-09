import 'package:equatable/equatable.dart';

class Expense extends Equatable {
  final String id;
  final double amount;
  final String currency;
  final DateTime date;
  final String category;
  final String paymentMethod;
  final String description;
  final String? receiptPath;
  final bool isRecurring;
  final String? recurringInterval; // daily, weekly, monthly, yearly
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? yearMonth; // Format: YYYY-MM

  const Expense({
    required this.id,
    required this.amount,
    required this.currency,
    required this.date,
    required this.category,
    required this.paymentMethod,
    required this.description,
    this.receiptPath,
    this.isRecurring = false,
    this.recurringInterval,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.yearMonth,
  });
  
  @override
  List<Object?> get props => [
    id,
    amount,
    currency,
    date,
    category,
    paymentMethod,
    description,
    receiptPath,
    isRecurring,
    recurringInterval,
    userId,
    createdAt,
    updatedAt,
    yearMonth,
  ];
} 