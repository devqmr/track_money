import 'package:track_money/core/constants/app_constants.dart';
import 'package:track_money/domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required String id,
    required String email,
    required String displayName,
    required String photoUrl,
    String defaultCurrency = AppConstants.sarCurrency,
    required DateTime createdAt,
    required DateTime lastLoginAt,
  }) : super(
          id: id,
          email: email,
          displayName: displayName,
          photoUrl: photoUrl,
          defaultCurrency: defaultCurrency,
          createdAt: createdAt,
          lastLoginAt: lastLoginAt,
        );

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      displayName: json['displayName'],
      photoUrl: json['photoUrl'],
      defaultCurrency: json['defaultCurrency'],
      createdAt: DateTime.parse(json['createdAt']),
      lastLoginAt: DateTime.parse(json['lastLoginAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'defaultCurrency': defaultCurrency,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
    };
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoUrl,
      defaultCurrency: user.defaultCurrency,
      createdAt: user.createdAt,
      lastLoginAt: user.lastLoginAt,
    );
  }
} 