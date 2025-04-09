import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../entities/expense.dart';
import '../../repositories/expense_repository.dart';

class GetExpensesByDateRange {
  final ExpenseRepository repository;

  GetExpensesByDateRange(this.repository);

  Future<Either<Failure, List<Expense>>> call(Params params) async {
    return await repository.getExpensesByDateRange(
      params.userId,
      params.startDate,
      params.endDate,
    );
  }
}

class Params extends Equatable {
  final String userId;
  final DateTime startDate;
  final DateTime endDate;

  const Params({
    required this.userId,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object> get props => [userId, startDate, endDate];
} 