import 'package:dartz/dartz.dart';
import '../entities/budget.dart';
import '../../core/errors/failures.dart';

abstract class BudgetRepository {
  /// Add a new budget
  Future<Either<Failure, Budget>> addBudget(Budget budget);
  
  /// Update an existing budget
  Future<Either<Failure, Budget>> updateBudget(Budget budget);
  
  /// Delete a budget
  Future<Either<Failure, void>> deleteBudget(String budgetId);
  
  /// Get all budgets for a user
  Future<Either<Failure, List<Budget>>> getBudgets(String userId);
  
  /// Get budgets for a user filtered by category
  Future<Either<Failure, List<Budget>>> getBudgetsByCategory(
    String userId, 
    String category,
  );
  
  /// Get active budgets for current date
  Future<Either<Failure, List<Budget>>> getActiveBudgets(String userId);
  
  /// Get budget utilization (percentage spent of budget)
  Future<Either<Failure, Map<String, double>>> getBudgetUtilization(
    String userId,
    String budgetId,
  );
} 