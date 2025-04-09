import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/expense.dart';
import '../../repositories/expense_repository.dart';

class AddExpense {
  final ExpenseRepository repository;

  AddExpense(this.repository);

  Future<Either<Failure, Expense>> call(Expense expense) async {
    return await repository.addExpense(expense);
  }
} 