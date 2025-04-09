import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_data_source.dart';
import '../models/expense_model.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseDataSource expenseDataSource;

  ExpenseRepositoryImpl({required this.expenseDataSource});

  @override
  Future<Either<Failure, Expense>> addExpense(Expense expense) async {
    try {
      final expenseModel = await expenseDataSource.addExpense(
        ExpenseModel.fromEntity(expense),
      );
      return Right(expenseModel);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Expense>> updateExpense(Expense expense) async {
    try {
      final expenseModel = await expenseDataSource.updateExpense(
        ExpenseModel.fromEntity(expense),
      );
      return Right(expenseModel);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteExpense(String userId, String expenseId, String yearMonth) async {
    try {
      await expenseDataSource.deleteExpense(userId, expenseId, yearMonth);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Expense>>> getExpenses(String userId) async {
    try {
      final expenses = await expenseDataSource.getExpenses(userId);
      return Right(expenses);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Expense>>> getExpensesByCategory(
    String userId,
    String category,
  ) async {
    try {
      final expenses = await expenseDataSource.getExpensesByCategory(
        userId,
        category,
      );
      return Right(expenses);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Expense>>> getExpensesByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final expenses = await expenseDataSource.getExpensesByDateRange(
        userId,
        startDate,
        endDate,
      );
      return Right(expenses);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Expense>>> getExpensesByMonth(
    String userId,
    String yearMonth,
  ) async {
    try {
      final expenses = await expenseDataSource.getExpensesByMonth(
        userId,
        yearMonth,
      );
      return Right(expenses);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, double>>> getExpensesSummaryByCategory(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final summary = await expenseDataSource.getExpensesSummaryByCategory(
        userId,
        startDate,
        endDate,
      );
      return Right(summary);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> storeReceiptImage(
    String userId,
    String imagePath,
  ) async {
    // This would require additional implementation with Firebase Storage
    // For now, returning a placeholder path
    return const Right('placeholder_receipt_path');
  }
} 