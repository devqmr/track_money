import 'package:dartz/dartz.dart';
import '../entities/expense.dart';
import '../../core/errors/failures.dart';

abstract class ExpenseRepository {
  /// Add a new expense
  Future<Either<Failure, Expense>> addExpense(Expense expense);
  
  /// Update an existing expense
  Future<Either<Failure, Expense>> updateExpense(Expense expense);
  
  /// Delete an expense
  Future<Either<Failure, void>> deleteExpense(String userId, String expenseId, String yearMonth);
  
  /// Get all expenses for a user
  Future<Either<Failure, List<Expense>>> getExpenses(String userId);
  
  /// Get expenses for a user filtered by category
  Future<Either<Failure, List<Expense>>> getExpensesByCategory(
    String userId, 
    String category,
  );
  
  /// Get expenses for a user within a date range
  Future<Either<Failure, List<Expense>>> getExpensesByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );
  
  /// Get expenses for a specific month
  Future<Either<Failure, List<Expense>>> getExpensesByMonth(
    String userId,
    String yearMonth,
  );
  
  /// Get expenses grouped by category for a time period
  Future<Either<Failure, Map<String, double>>> getExpensesSummaryByCategory(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );
  
  /// Store receipt image locally and return path
  Future<Either<Failure, String>> storeReceiptImage(
    String userId,
    String imagePath,
  );
} 