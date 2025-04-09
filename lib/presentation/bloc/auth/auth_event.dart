import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatusEvent extends AuthEvent {
  const CheckAuthStatusEvent();
}

class SignInWithGoogleEvent extends AuthEvent {
  const SignInWithGoogleEvent();
}

class SignOutEvent extends AuthEvent {
  const SignOutEvent();
}

class UpdateUserSettingsEvent extends AuthEvent {
  final String userId;
  final String? defaultCurrency;

  const UpdateUserSettingsEvent({
    required this.userId,
    this.defaultCurrency,
  });

  @override
  List<Object?> get props => [userId, defaultCurrency];
} 