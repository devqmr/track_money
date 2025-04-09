import 'package:dartz/dartz.dart';
import '../entities/category.dart';
import '../../core/errors/failures.dart';

abstract class CategoryRepository {
  /// Add a new category
  Future<Either<Failure, Category>> addCategory(Category category);
  
  /// Update an existing category
  Future<Either<Failure, Category>> updateCategory(Category category);
  
  /// Delete a category
  Future<Either<Failure, void>> deleteCategory(String categoryId);
  
  /// Get all categories for a user
  Future<Either<Failure, List<Category>>> getCategories(String userId);
  
  /// Initialize default categories for a new user
  Future<Either<Failure, List<Category>>> initializeDefaultCategories(String userId);
} 