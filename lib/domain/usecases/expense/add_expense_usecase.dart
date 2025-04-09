import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../../core/errors/failures.dart';
import '../../entities/expense.dart';
import '../../repositories/expense_repository.dart';

class AddExpenseUseCase {
  final ExpenseRepository repository;

  AddExpenseUseCase(this.repository);

  Future<Either<Failure, Expense>> call(Params params) async {
    print('TRACK_MONEY_LOG: AddExpenseUseCase.call started');
    
    // Basic validation
    if (params.amount <= 0) {
      print('TRACK_MONEY_LOG: Validation failed - amount is zero or negative');
      return Left(ValidationFailure('Amount must be greater than zero'));
    }

    if (params.category.isEmpty) {
      print('TRACK_MONEY_LOG: Validation failed - category is empty');
      return Left(ValidationFailure('Category is required'));
    }

    if (params.paymentMethod.isEmpty) {
      print('TRACK_MONEY_LOG: Validation failed - payment method is empty');
      return Left(ValidationFailure('Payment method is required'));
    }

    print('TRACK_MONEY_LOG: Validation passed, creating expense entity');
    // Create a new Expense entity
    final expense = Expense(
      id: const Uuid().v4(), // This will be replaced by the repository
      amount: params.amount,
      currency: params.currency,
      date: params.date,
      category: params.category,
      paymentMethod: params.paymentMethod,
      description: params.description,
      userId: params.userId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    print('TRACK_MONEY_LOG: Calling repository.addExpense');
    final result = await repository.addExpense(expense);
    print('TRACK_MONEY_LOG: Repository returned result: ${result.isRight() ? 'Success' : 'Failure'}');
    
    return result;
  }
}

class Params extends Equatable {
  final double amount;
  final String currency;
  final DateTime date;
  final String category;
  final String paymentMethod;
  final String description;
  final String userId;

  const Params({
    required this.amount,
    required this.currency,
    required this.date,
    required this.category,
    required this.paymentMethod,
    required this.description,
    required this.userId,
  });

  @override
  List<Object> get props => [
    amount,
    currency,
    date,
    category,
    paymentMethod,
    description,
    userId,
  ];
} 