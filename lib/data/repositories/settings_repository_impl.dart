import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_data_source.dart';
import '../models/settings_model.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsDataSource settingsDataSource;

  SettingsRepositoryImpl({required this.settingsDataSource});

  @override
  Future<Either<Failure, Settings>> getSettings(String userId) async {
    try {
      final settings = await settingsDataSource.getSettings(userId);
      return Right(settings);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Settings>> updateSettings(Settings settings) async {
    try {
      final settingsModel = SettingsModel.fromEntity(settings);
      final updatedSettings = await settingsDataSource.updateSettings(settingsModel);
      return Right(updatedSettings);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Settings>> addCurrency(String userId, String currency, String iconPath) async {
    try {
      final settings = await settingsDataSource.addCurrency(userId, currency, iconPath);
      return Right(settings);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Settings>> removeCurrency(String userId, String currency) async {
    try {
      final settings = await settingsDataSource.removeCurrency(userId, currency);
      return Right(settings);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Settings>> setDefaultCurrency(String userId, String currency) async {
    try {
      final settings = await settingsDataSource.setDefaultCurrency(userId, currency);
      return Right(settings);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Settings>> addCategory(String userId, String category) async {
    try {
      final settings = await settingsDataSource.addCategory(userId, category);
      return Right(settings);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Settings>> removeCategory(String userId, String category) async {
    try {
      final settings = await settingsDataSource.removeCategory(userId, category);
      return Right(settings);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Settings>> addPaymentMethod(String userId, String paymentMethod) async {
    try {
      final settings = await settingsDataSource.addPaymentMethod(userId, paymentMethod);
      return Right(settings);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Settings>> removePaymentMethod(String userId, String paymentMethod) async {
    try {
      final settings = await settingsDataSource.removePaymentMethod(userId, paymentMethod);
      return Right(settings);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
} 