import 'package:dartz/dartz.dart';
import '../entities/settings.dart';
import '../../core/errors/failures.dart';

abstract class SettingsRepository {
  Future<Either<Failure, Settings>> getSettings(String userId);
  Future<Either<Failure, Settings>> updateSettings(Settings settings);
  Future<Either<Failure, Settings>> addCurrency(String userId, String currency, String iconPath);
  Future<Either<Failure, Settings>> removeCurrency(String userId, String currency);
  Future<Either<Failure, Settings>> setDefaultCurrency(String userId, String currency);
  Future<Either<Failure, Settings>> addCategory(String userId, String category);
  Future<Either<Failure, Settings>> removeCategory(String userId, String category);
  Future<Either<Failure, Settings>> addPaymentMethod(String userId, String paymentMethod);
  Future<Either<Failure, Settings>> removePaymentMethod(String userId, String paymentMethod);
} 