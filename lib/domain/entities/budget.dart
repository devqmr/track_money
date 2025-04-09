import 'package:equatable/equatable.dart';

class Budget extends Equatable {
  final String id;
  final String name;
  final double amount;
  final String currency;
  final String period; // daily, weekly, monthly, yearly
  final String? category; // null means all categories
  final DateTime startDate;
  final DateTime endDate;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Budget({
    required this.id,
    required this.name,
    required this.amount,
    required this.currency,
    required this.period,
    this.category,
    required this.startDate,
    required this.endDate,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    amount,
    currency,
    period,
    category,
    startDate,
    endDate,
    userId,
    createdAt,
    updatedAt,
  ];
} 