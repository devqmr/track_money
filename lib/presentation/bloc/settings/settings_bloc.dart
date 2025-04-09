import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/settings_repository.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository settingsRepository;

  SettingsBloc({required this.settingsRepository}) : super(SettingsInitial()) {
    on<LoadSettingsEvent>(_onLoadSettings);
    on<UpdateSettingsEvent>(_onUpdateSettings);
    on<AddCurrencyEvent>(_onAddCurrency);
    on<RemoveCurrencyEvent>(_onRemoveCurrency);
    on<SetDefaultCurrencyEvent>(_onSetDefaultCurrency);
    on<AddCategoryEvent>(_onAddCategory);
    on<RemoveCategoryEvent>(_onRemoveCategory);
    on<AddPaymentMethodEvent>(_onAddPaymentMethod);
    on<RemovePaymentMethodEvent>(_onRemovePaymentMethod);
  }

  Future<void> _onLoadSettings(
    LoadSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoading());
    try {
      final result = await settingsRepository.getSettings(event.userId);
      await result.fold(
        (failure) async => emit(SettingsError(message: failure.toString())),
        (settings) async => emit(SettingsLoaded(settings: settings)),
      );
    } catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }

  Future<void> _onUpdateSettings(
    UpdateSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoading());
    
    try {
      final result = await settingsRepository.getSettings(event.userId);
      
      final success = await result.fold<Future<bool>>(
        (failure) async {
          emit(SettingsError(message: failure.toString()));
          return false;
        },
        (currentSettings) async {
          final updatedSettings = currentSettings.copyWith(
            defaultCurrency: event.defaultCurrency ?? currentSettings.defaultCurrency,
            currencies: event.currencies ?? currentSettings.currencies,
            categories: event.categories ?? currentSettings.categories,
            paymentMethods: event.paymentMethods ?? currentSettings.paymentMethods,
          );

          final updateResult = await settingsRepository.updateSettings(updatedSettings);
          
          return await updateResult.fold<Future<bool>>(
            (failure) async {
              emit(SettingsError(message: failure.toString()));
              return false;
            },
            (settings) async {
              emit(SettingsLoaded(settings: settings));
              return true;
            },
          );
        },
      );
      
      // If we've reached here and success is false and no state has been emitted,
      // we'll emit an error state to ensure the UI updates
      if (!success && state is SettingsLoading) {
        emit(SettingsError(message: "Failed to update settings"));
      }
    } catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }

  Future<void> _onAddCurrency(
    AddCurrencyEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoading());
    try {
      final result = await settingsRepository.addCurrency(
        event.userId,
        event.currency,
        event.iconPath,
      );
      await result.fold(
        (failure) async => emit(SettingsError(message: failure.toString())),
        (settings) async => emit(SettingsLoaded(settings: settings)),
      );
    } catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }

  Future<void> _onRemoveCurrency(
    RemoveCurrencyEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoading());
    try {
      final result = await settingsRepository.removeCurrency(
        event.userId,
        event.currency,
      );
      await result.fold(
        (failure) async => emit(SettingsError(message: failure.toString())),
        (settings) async => emit(SettingsLoaded(settings: settings)),
      );
    } catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }

  Future<void> _onSetDefaultCurrency(
    SetDefaultCurrencyEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoading());
    try {
      final result = await settingsRepository.setDefaultCurrency(
        event.userId,
        event.currency,
      );
      await result.fold(
        (failure) async => emit(SettingsError(message: failure.toString())),
        (settings) async => emit(SettingsLoaded(settings: settings)),
      );
    } catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }

  Future<void> _onAddCategory(
    AddCategoryEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoading());
    try {
      final result = await settingsRepository.addCategory(
        event.userId,
        event.category,
      );
      await result.fold(
        (failure) async => emit(SettingsError(message: failure.toString())),
        (settings) async => emit(SettingsLoaded(settings: settings)),
      );
    } catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }

  Future<void> _onRemoveCategory(
    RemoveCategoryEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoading());
    try {
      final result = await settingsRepository.removeCategory(
        event.userId,
        event.category,
      );
      await result.fold(
        (failure) async => emit(SettingsError(message: failure.toString())),
        (settings) async => emit(SettingsLoaded(settings: settings)),
      );
    } catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }

  Future<void> _onAddPaymentMethod(
    AddPaymentMethodEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoading());
    try {
      final result = await settingsRepository.addPaymentMethod(
        event.userId,
        event.paymentMethod,
      );
      await result.fold(
        (failure) async => emit(SettingsError(message: failure.toString())),
        (settings) async => emit(SettingsLoaded(settings: settings)),
      );
    } catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }

  Future<void> _onRemovePaymentMethod(
    RemovePaymentMethodEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoading());
    try {
      final result = await settingsRepository.removePaymentMethod(
        event.userId,
        event.paymentMethod,
      );
      await result.fold(
        (failure) async => emit(SettingsError(message: failure.toString())),
        (settings) async => emit(SettingsLoaded(settings: settings)),
      );
    } catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }
} 