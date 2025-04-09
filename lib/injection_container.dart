import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'data/datasources/auth_data_source.dart';
import 'data/datasources/settings_data_source.dart';
import 'data/datasources/expense_data_source.dart';
import 'data/repositories/user_repository_impl.dart';
import 'data/repositories/settings_repository_impl.dart';
import 'data/repositories/expense_repository_impl.dart';
import 'domain/repositories/user_repository.dart';
import 'domain/repositories/settings_repository.dart';
import 'domain/repositories/expense_repository.dart';
import 'domain/usecases/user/get_current_user.dart';
import 'domain/usecases/user/sign_in_with_google.dart';
import 'domain/usecases/user/sign_out.dart';
import 'domain/usecases/expense/add_expense_usecase.dart';
import 'domain/usecases/expense/get_expenses_by_date_range.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/settings/settings_bloc.dart';
import 'presentation/bloc/expense/expense_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Use cases
  sl.registerLazySingleton(() => SignInWithGoogle(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => AddExpenseUseCase(sl()));
  sl.registerLazySingleton(() => GetExpensesByDateRange(sl()));

  // Bloc
  sl.registerFactory<AuthBloc>(() => AuthBloc(
    signInWithGoogle: sl(),
    signOut: sl(),
    getCurrentUser: sl(),
  ));
  
  sl.registerFactory<SettingsBloc>(() => SettingsBloc(settingsRepository: sl()));
  
  sl.registerFactory<ExpenseBloc>(() => ExpenseBloc(
    expenseRepository: sl(),
    getExpensesByDateRange: sl(),
    addExpense: sl(),
  ));

  // Repositories
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(authDataSource: sl()),
  );

  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(settingsDataSource: sl()),
  );

  sl.registerLazySingleton<ExpenseRepository>(
    () => ExpenseRepositoryImpl(expenseDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<AuthDataSource>(
    () => AuthDataSourceImpl(
      firebaseAuth: sl(),
      googleSignIn: sl(),
      firestore: sl(),
    ),
  );

  sl.registerLazySingleton<SettingsDataSource>(
    () => SettingsDataSourceImpl(firestore: sl()),
  );

  sl.registerLazySingleton<ExpenseDataSource>(
    () => ExpenseDataSourceImpl(firestore: sl()),
  );

  // External
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => GoogleSignIn());
  sl.registerLazySingleton(() {
    final firestore = FirebaseFirestore.instance;
    firestore.settings = const Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED);
    return firestore;
  });
  sl.registerLazySingleton(() => const FlutterSecureStorage());
} 