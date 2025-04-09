class AppConstants {
  static const String appName = 'TrackMoney';
  
  // Currency constants
  static const String sarCurrency = 'SAR';
  static const String usdCurrency = 'USD';
  static const String egpCurrency = 'EGP';
  
  // Collection names for Firestore
  static const String usersCollection = 'users';
  static const String expensesCollection = 'expenses';
  static const String categoriesCollection = 'categories';
  static const String settingsCollection = 'settings';
  static const String budgetsCollection = 'budgets';
  
  // Default categories
  static const List<String> defaultCategories = [
    'Food',
    'Shopping',
    'Transportation',
    'Entertainment',
    'Health',
    'Telecom',
    'Education',
    'Rent',
    'Housing',
    'Utilities',
    'Others',
  ];
  
  // Default payment methods
  static const List<String> defaultPaymentMethods = [
    'Cash',
    'BOP',
    'AIP',
    'PalPay',
    'JawwalPay',
    'Bank Transfer',
    'Credit Card',
  ];
} 