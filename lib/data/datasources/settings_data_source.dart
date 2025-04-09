import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/settings_model.dart';
import '../../core/constants/app_constants.dart';

abstract class SettingsDataSource {
  Future<SettingsModel> getSettings(String userId);
  Future<SettingsModel> updateSettings(SettingsModel settings);
  Future<SettingsModel> addCurrency(String userId, String currency, String iconPath);
  Future<SettingsModel> removeCurrency(String userId, String currency);
  Future<SettingsModel> setDefaultCurrency(String userId, String currency);
  Future<SettingsModel> addCategory(String userId, String category);
  Future<SettingsModel> removeCategory(String userId, String category);
  Future<SettingsModel> addPaymentMethod(String userId, String paymentMethod);
  Future<SettingsModel> removePaymentMethod(String userId, String paymentMethod);
}

class SettingsDataSourceImpl implements SettingsDataSource {
  final FirebaseFirestore _firestore;

  SettingsDataSourceImpl({required FirebaseFirestore firestore}) : _firestore = firestore;

  @override
  Future<SettingsModel> getSettings(String userId) async {
    final doc = await _firestore
        .collection(AppConstants.settingsCollection)
        .doc(userId)
        .get();

    if (!doc.exists) {
      // Create default settings if they don't exist
      final defaultSettings = SettingsModel(
        userId: userId,
        defaultCurrency: AppConstants.sarCurrency,
        currencies: [AppConstants.sarCurrency, AppConstants.usdCurrency, AppConstants.egpCurrency],
        categories: AppConstants.defaultCategories,
        paymentMethods: AppConstants.defaultPaymentMethods,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.settingsCollection)
          .doc(userId)
          .set(defaultSettings.toJson());

      return defaultSettings;
    }

    return SettingsModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  @override
  Future<SettingsModel> updateSettings(SettingsModel settings) async {
    await _firestore
        .collection(AppConstants.settingsCollection)
        .doc(settings.userId)
        .update(settings.toJson());

    return settings;
  }

  @override
  Future<SettingsModel> addCurrency(String userId, String currency, String iconPath) async {
    final settings = await getSettings(userId);
    final updatedCurrencies = [...settings.currencies, currency];

    final updatedSettings = SettingsModel(
      userId: settings.userId,
      defaultCurrency: settings.defaultCurrency,
      currencies: updatedCurrencies,
      categories: settings.categories,
      paymentMethods: settings.paymentMethods,
      updatedAt: DateTime.now(),
    );

    return updateSettings(updatedSettings);
  }

  @override
  Future<SettingsModel> removeCurrency(String userId, String currency) async {
    final settings = await getSettings(userId);
    
    if (currency == settings.defaultCurrency) {
      throw Exception('Cannot remove default currency');
    }

    final updatedCurrencies = settings.currencies.where((c) => c != currency).toList();

    final updatedSettings = SettingsModel(
      userId: settings.userId,
      defaultCurrency: settings.defaultCurrency,
      currencies: updatedCurrencies,
      categories: settings.categories,
      paymentMethods: settings.paymentMethods,
      updatedAt: DateTime.now(),
    );

    return updateSettings(updatedSettings);
  }

  @override
  Future<SettingsModel> setDefaultCurrency(String userId, String currency) async {
    final settings = await getSettings(userId);
    
    if (!settings.currencies.contains(currency)) {
      throw Exception('Currency not found in user settings');
    }

    final updatedSettings = SettingsModel(
      userId: settings.userId,
      defaultCurrency: currency,
      currencies: settings.currencies,
      categories: settings.categories,
      paymentMethods: settings.paymentMethods,
      updatedAt: DateTime.now(),
    );

    return updateSettings(updatedSettings);
  }

  @override
  Future<SettingsModel> addCategory(String userId, String category) async {
    final settings = await getSettings(userId);
    
    if (settings.categories.contains(category)) {
      throw Exception('Category already exists');
    }

    final updatedSettings = SettingsModel(
      userId: settings.userId,
      defaultCurrency: settings.defaultCurrency,
      currencies: settings.currencies,
      categories: [...settings.categories, category],
      paymentMethods: settings.paymentMethods,
      updatedAt: DateTime.now(),
    );

    return updateSettings(updatedSettings);
  }

  @override
  Future<SettingsModel> removeCategory(String userId, String category) async {
    final settings = await getSettings(userId);
    
    if (!settings.categories.contains(category)) {
      throw Exception('Category not found');
    }

    final updatedSettings = SettingsModel(
      userId: settings.userId,
      defaultCurrency: settings.defaultCurrency,
      currencies: settings.currencies,
      categories: settings.categories.where((c) => c != category).toList(),
      paymentMethods: settings.paymentMethods,
      updatedAt: DateTime.now(),
    );

    return updateSettings(updatedSettings);
  }

  @override
  Future<SettingsModel> addPaymentMethod(String userId, String paymentMethod) async {
    final settings = await getSettings(userId);
    
    if (settings.paymentMethods.contains(paymentMethod)) {
      throw Exception('Payment method already exists');
    }

    final updatedSettings = SettingsModel(
      userId: settings.userId,
      defaultCurrency: settings.defaultCurrency,
      currencies: settings.currencies,
      categories: settings.categories,
      paymentMethods: [...settings.paymentMethods, paymentMethod],
      updatedAt: DateTime.now(),
    );

    return updateSettings(updatedSettings);
  }

  @override
  Future<SettingsModel> removePaymentMethod(String userId, String paymentMethod) async {
    final settings = await getSettings(userId);
    
    if (!settings.paymentMethods.contains(paymentMethod)) {
      throw Exception('Payment method not found');
    }

    final updatedSettings = SettingsModel(
      userId: settings.userId,
      defaultCurrency: settings.defaultCurrency,
      currencies: settings.currencies,
      categories: settings.categories,
      paymentMethods: settings.paymentMethods.where((p) => p != paymentMethod).toList(),
      updatedAt: DateTime.now(),
    );

    return updateSettings(updatedSettings);
  }
} 