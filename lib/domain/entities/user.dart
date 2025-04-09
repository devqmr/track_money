import 'package:equatable/equatable.dart';
import 'package:track_money/core/constants/app_constants.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final String photoUrl;
  final String defaultCurrency;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  const User({
    required this.id,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    this.defaultCurrency = AppConstants.sarCurrency, // Default to SAR
    required this.createdAt,
    required this.lastLoginAt,
  });

  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    photoUrl,
    defaultCurrency,
    createdAt,
    lastLoginAt,
  ];
} 