import 'package:track_money/domain/entities/expense.dart';

class ExpenseModel extends Expense {
  const ExpenseModel({
    required String id,
    required double amount,
    required String currency,
    required DateTime date,
    required String category,
    required String paymentMethod,
    required String description,
    String? receiptPath,
    bool isRecurring = false,
    String? recurringInterval,
    required String userId,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String yearMonth,
  }) : super(
          id: id,
          amount: amount,
          currency: currency,
          date: date,
          category: category,
          paymentMethod: paymentMethod,
          description: description,
          receiptPath: receiptPath,
          isRecurring: isRecurring,
          recurringInterval: recurringInterval,
          userId: userId,
          createdAt: createdAt,
          updatedAt: updatedAt,
          yearMonth: yearMonth,
        );

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'],
      amount: json['amount'].toDouble(),
      currency: json['currency'],
      date: DateTime.parse(json['date']),
      category: json['category'],
      paymentMethod: json['paymentMethod'],
      description: json['description'],
      receiptPath: json['receiptPath'],
      isRecurring: json['isRecurring'] ?? false,
      recurringInterval: json['recurringInterval'],
      userId: json['userId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      yearMonth: json['yearMonth'] ?? _generateYearMonth(DateTime.parse(json['date'])),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'currency': currency,
      'date': date.toIso8601String(),
      'category': category,
      'paymentMethod': paymentMethod,
      'description': description,
      'receiptPath': receiptPath,
      'isRecurring': isRecurring,
      'recurringInterval': recurringInterval,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'yearMonth': yearMonth,
    };
  }

  static String _generateYearMonth(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  factory ExpenseModel.fromEntity(Expense expense) {
    return ExpenseModel(
      id: expense.id,
      amount: expense.amount,
      currency: expense.currency,
      date: expense.date,
      category: expense.category,
      paymentMethod: expense.paymentMethod,
      description: expense.description,
      receiptPath: expense.receiptPath,
      isRecurring: expense.isRecurring,
      recurringInterval: expense.recurringInterval,
      userId: expense.userId,
      createdAt: expense.createdAt,
      updatedAt: expense.updatedAt,
      yearMonth: expense.yearMonth ?? _generateYearMonth(expense.date),
    );
  }
  
  // Create a new expense model with updated values
  ExpenseModel copyWith({
    String? id,
    double? amount,
    String? currency,
    DateTime? date,
    String? category,
    String? paymentMethod,
    String? description,
    String? receiptPath,
    bool? isRecurring,
    String? recurringInterval,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? yearMonth,
  }) {
    final newDate = date ?? this.date;
    final newYearMonth = yearMonth ?? _generateYearMonth(newDate);
    
    return ExpenseModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      date: newDate,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      description: description ?? this.description,
      receiptPath: receiptPath ?? this.receiptPath,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringInterval: recurringInterval ?? this.recurringInterval,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      yearMonth: newYearMonth,
    );
  }
} 