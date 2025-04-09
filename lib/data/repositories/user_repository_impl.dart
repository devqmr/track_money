import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/auth_data_source.dart';

class UserRepositoryImpl implements UserRepository {
  final AuthDataSource authDataSource;

  UserRepositoryImpl({required this.authDataSource});

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    try {
      final userModel = await authDataSource.signInWithGoogle();
      return Right(userModel);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await authDataSource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final userModel = await authDataSource.getCurrentUser();
      return Right(userModel);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> updateUserSettings({
    required String userId,
    String? defaultCurrency,
  }) async {
    try {
      final userModel = await authDataSource.updateUserSettings(
        userId: userId,
        defaultCurrency: defaultCurrency,
      );
      return Right(userModel);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<bool> isSignedIn() async {
    return await authDataSource.isSignedIn();
  }
} 