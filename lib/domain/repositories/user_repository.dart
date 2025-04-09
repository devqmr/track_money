import 'package:dartz/dartz.dart';
import '../entities/user.dart';
import '../../core/errors/failures.dart';

abstract class UserRepository {
  /// Sign in with Google
  Future<Either<Failure, User>> signInWithGoogle();
  
  /// Sign out current user
  Future<Either<Failure, void>> signOut();
  
  /// Get current user
  Future<Either<Failure, User?>> getCurrentUser();
  
  /// Update user settings
  Future<Either<Failure, User>> updateUserSettings({
    required String userId, 
    String? defaultCurrency,
  });
  
  /// Check if user is signed in
  Future<bool> isSignedIn();
} 