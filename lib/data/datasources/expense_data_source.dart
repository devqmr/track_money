import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import '../models/expense_model.dart';
import '../../core/constants/app_constants.dart';

abstract class ExpenseDataSource {
  /// Add a new expense
  Future<ExpenseModel> addExpense(ExpenseModel expense);
  
  /// Update an existing expense
  Future<ExpenseModel> updateExpense(ExpenseModel expense);
  
  /// Delete an expense
  Future<void> deleteExpense(String userId, String expenseId, String yearMonth);
  
  /// Get all expenses for a user
  Future<List<ExpenseModel>> getExpenses(String userId);
  
  /// Get expenses for a user filtered by category
  Future<List<ExpenseModel>> getExpensesByCategory(
    String userId, 
    String category,
  );
  
  /// Get expenses for a user within a date range
  Future<List<ExpenseModel>> getExpensesByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );
  
  /// Get expenses for a specific month
  Future<List<ExpenseModel>> getExpensesByMonth(
    String userId,
    String yearMonth,
  );
  
  /// Get expenses grouped by category for a time period
  Future<Map<String, double>> getExpensesSummaryByCategory(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );
}

class ExpenseDataSourceImpl implements ExpenseDataSource {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;
  
  ExpenseDataSourceImpl({
    required FirebaseFirestore firestore,
  }) : 
    _firestore = firestore,
    _uuid = const Uuid();
  
  /// Helper function to add timeout to any Future operation
  Future<T> _withTimeout<T>(Future<T> operation, String operationName) async {
    try {
      return await operation.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          print('TRACK_MONEY_LOG: $operationName timeout');
          throw TimeoutException('$operationName timeout');
        },
      );
    } catch (e) {
      if (e is TimeoutException) {
        rethrow;
      }
      throw Exception('Error in $operationName: $e');
    }
  }
  
  @override
  Future<ExpenseModel> addExpense(ExpenseModel expense) async {
    print('TRACK_MONEY_LOG: ExpenseDataSource.addExpense started');
    print('TRACK_MONEY_LOG: Expense input details - Category: ${expense.category}, Amount: ${expense.amount}, Currency: ${expense.currency}, Date: ${expense.date}');
    final String id = _uuid.v4();
    final DateTime now = DateTime.now();
    
    // Create yearMonth format from the expense date
    final String yearMonth = '${expense.date.year}-${expense.date.month.toString().padLeft(2, '0')}';
    
    print('TRACK_MONEY_LOG: Creating new expense with ID: $id, YearMonth: $yearMonth');
    final ExpenseModel newExpense = expense.copyWith(
      id: id,
      createdAt: now,
      updatedAt: now,
      yearMonth: yearMonth,
    );
    
    try {
      print('TRACK_MONEY_LOG: Attempting to save to Firestore');
      print('TRACK_MONEY_LOG: User ID: ${expense.userId}, Collection: ${AppConstants.expensesCollection}/${yearMonth}');
      
      // Create expense document reference with the yearMonth subcollection
      print('TRACK_MONEY_LOG: Creating expense document reference');
      final expenseDocRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(expense.userId)
        .collection(AppConstants.expensesCollection)
        .doc(yearMonth)
        .collection('items')
        .doc(id);
      
      // Add the expense document
      print('TRACK_MONEY_LOG: Setting expense document data');
      await _withTimeout(
        expenseDocRef.set(newExpense.toJson()),
        'Set expense operation'
      );
      
      print('TRACK_MONEY_LOG: Operation completed successfully');
      return newExpense;
    } catch (e, stackTrace) {
      print('TRACK_MONEY_LOG: Error saving to Firestore: $e');
      print('TRACK_MONEY_LOG: Error stack trace: $stackTrace');
      
      // Check for specific error types
      if (e.toString().contains('permission-denied')) {
        print('TRACK_MONEY_LOG: Permission denied error - check security rules');
      } else if (e.toString().contains('not-found')) {
        print('TRACK_MONEY_LOG: Document not found error - check paths and references');
      } else if (e.toString().contains('FAILED_PRECONDITION')) {
        print('TRACK_MONEY_LOG: Failed precondition - possibly missing index or invalid data');
      }
      
      // If it's a network-related error, return the expense anyway
      // Firestore will sync when connection is restored
      if (e.toString().contains('network') || 
          e.toString().contains('connection') ||
          e.toString().contains('timeout')) {
        print('TRACK_MONEY_LOG: Network-related error detected, returning expense anyway');
        return newExpense;
      }
      print('TRACK_MONEY_LOG: Non-network error, rethrowing: $e');
      throw e; // Rethrow other types of errors
    }
  }
  
  @override
  Future<ExpenseModel> updateExpense(ExpenseModel expense) async {
    final DateTime now = DateTime.now();
    
    final ExpenseModel updatedExpense = expense.copyWith(
      updatedAt: now,
    );
    
    // Fetch the old expense to compare with the updated one
    final oldExpenseDoc = await _withTimeout(
      _firestore
        .collection(AppConstants.usersCollection)
        .doc(expense.userId)
        .collection(AppConstants.expensesCollection)
        .doc(expense.yearMonth)
        .collection('items')
        .doc(expense.id)
        .get(),
      'Get old expense operation'
    );
      
    if (!oldExpenseDoc.exists) {
      throw Exception('Expense does not exist');
    }
    
    final oldExpense = ExpenseModel.fromJson(oldExpenseDoc.data() as Map<String, dynamic>);
    
    try {
      // If the date changed to a different month, we need to move the expense to a different yearMonth collection
      if (oldExpense.yearMonth != updatedExpense.yearMonth) {
        // Delete from old month collection
        await _withTimeout(
          _firestore
            .collection(AppConstants.usersCollection)
            .doc(expense.userId)
            .collection(AppConstants.expensesCollection)
            .doc(oldExpense.yearMonth)
            .collection('items')
            .doc(expense.id)
            .delete(),
          'Delete old expense operation'
        );
        
        // Add to new month collection
        await _withTimeout(
          _firestore
            .collection(AppConstants.usersCollection)
            .doc(expense.userId)
            .collection(AppConstants.expensesCollection)
            .doc(updatedExpense.yearMonth)
            .collection('items')
            .doc(expense.id)
            .set(updatedExpense.toJson()),
          'Set updated expense operation'
        );
      } else {
        // If month is the same, just update the document in place
        await _withTimeout(
          _firestore
            .collection(AppConstants.usersCollection)
            .doc(expense.userId)
            .collection(AppConstants.expensesCollection)
            .doc(expense.yearMonth)
            .collection('items')
            .doc(expense.id)
            .update(updatedExpense.toJson()),
          'Update expense operation'
        );
      }
      
      return updatedExpense;
    } catch (e) {
      if (e.toString().contains('network') || 
          e.toString().contains('connection') ||
          e.toString().contains('timeout')) {
        print('TRACK_MONEY_LOG: Network-related error in updateExpense, returning expense anyway');
        return updatedExpense;
      }
      throw Exception('Failed to update expense: $e');
    }
  }
  
  @override
  Future<void> deleteExpense(String userId, String expenseId, String yearMonth) async {
    try {
      // Delete the expense document
      await _withTimeout(
        _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.expensesCollection)
          .doc(yearMonth)
          .collection('items')
          .doc(expenseId)
          .delete(),
        'Delete expense operation'
      );
        
    } catch (e) {
      if (e.toString().contains('network') || 
          e.toString().contains('connection') ||
          e.toString().contains('timeout')) {
        print('TRACK_MONEY_LOG: Network-related error in deleteExpense, operation will sync later');
        return; // Allow the operation to continue offline
      }
      throw Exception('Failed to delete expense: $e');
    }
  }
  
  @override
  Future<List<ExpenseModel>> getExpenses(String userId) async {
    // To get all expenses across all months, we need to fetch all month documents first
    final QuerySnapshot monthsSnapshot = await _firestore
      .collection(AppConstants.usersCollection)
      .doc(userId)
      .collection(AppConstants.expensesCollection)
      .get();
      
    // Create a list to store all expenses
    List<ExpenseModel> allExpenses = [];
    
    // For each month, fetch all expenses
    for (final monthDoc in monthsSnapshot.docs) {
      final String yearMonth = monthDoc.id;
      
      final QuerySnapshot expensesSnapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.expensesCollection)
        .doc(yearMonth)
        .collection('items')
        .orderBy('date', descending: true)
        .get();
        
      final monthExpenses = expensesSnapshot.docs
        .map((doc) => ExpenseModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
        
      allExpenses.addAll(monthExpenses);
    }
    
    // Sort all expenses by date descending
    allExpenses.sort((a, b) => b.date.compareTo(a.date));
    
    return allExpenses;
  }
  
  @override
  Future<List<ExpenseModel>> getExpensesByCategory(
    String userId, 
    String category,
  ) async {
    // To get expenses by category across all months, we need to fetch all month documents first
    final QuerySnapshot monthsSnapshot = await _firestore
      .collection(AppConstants.usersCollection)
      .doc(userId)
      .collection(AppConstants.expensesCollection)
      .get();
      
    // Create a list to store filtered expenses
    List<ExpenseModel> filteredExpenses = [];
    
    // For each month, fetch expenses filtered by category
    for (final monthDoc in monthsSnapshot.docs) {
      final String yearMonth = monthDoc.id;
      
      final QuerySnapshot expensesSnapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.expensesCollection)
        .doc(yearMonth)
        .collection('items')
        .where('category', isEqualTo: category)
        .orderBy('date', descending: true)
        .get();
        
      final categoryExpenses = expensesSnapshot.docs
        .map((doc) => ExpenseModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
        
      filteredExpenses.addAll(categoryExpenses);
    }
    
    // Sort all expenses by date descending
    filteredExpenses.sort((a, b) => b.date.compareTo(a.date));
    
    return filteredExpenses;
  }
  
  @override
  Future<List<ExpenseModel>> getExpensesByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Create yearMonth format for start and end dates
    final String startYearMonth = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}';
    final String endYearMonth = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}';
    
    // Get all months within the range
    final QuerySnapshot monthsSnapshot = await _firestore
      .collection(AppConstants.usersCollection)
      .doc(userId)
      .collection(AppConstants.expensesCollection)
      .where(FieldPath.documentId, isGreaterThanOrEqualTo: startYearMonth)
      .where(FieldPath.documentId, isLessThanOrEqualTo: endYearMonth)
      .get();
      
    // Create a list to store filtered expenses
    List<ExpenseModel> filteredExpenses = [];
    
    // For each month, fetch expenses within the date range
    for (final monthDoc in monthsSnapshot.docs) {
      final String yearMonth = monthDoc.id;
      
      final QuerySnapshot expensesSnapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.expensesCollection)
        .doc(yearMonth)
        .collection('items')
        .orderBy('date', descending: true)
        .get();
        
      final monthExpenses = expensesSnapshot.docs
        .map((doc) => ExpenseModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList()
        .where((expense) => 
          expense.date.isAfter(startDate.subtract(Duration(days: 1))) && 
          expense.date.isBefore(endDate.add(Duration(days: 1))))
        .toList();
        
      filteredExpenses.addAll(monthExpenses);
    }
    
    // Sort all expenses by date descending
    filteredExpenses.sort((a, b) => b.date.compareTo(a.date));
    
    return filteredExpenses;
  }
  
  @override
  Future<List<ExpenseModel>> getExpensesByMonth(
    String userId,
    String yearMonth,
  ) async {
    // This is now much simpler since expenses are already organized by month
    final QuerySnapshot expensesSnapshot = await _firestore
      .collection(AppConstants.usersCollection)
      .doc(userId)
      .collection(AppConstants.expensesCollection)
      .doc(yearMonth)
      .collection('items')
      .orderBy('date', descending: true)
      .get();
      
    return expensesSnapshot.docs
      .map((doc) => ExpenseModel.fromJson(doc.data() as Map<String, dynamic>))
      .toList();
  }
  
  @override
  Future<Map<String, double>> getExpensesSummaryByCategory(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Create yearMonth format for start and end dates
    final String startYearMonth = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}';
    final String endYearMonth = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}';
    
    // Get all months within the range
    final QuerySnapshot monthsSnapshot = await _firestore
      .collection(AppConstants.usersCollection)
      .doc(userId)
      .collection(AppConstants.expensesCollection)
      .where(FieldPath.documentId, isGreaterThanOrEqualTo: startYearMonth)
      .where(FieldPath.documentId, isLessThanOrEqualTo: endYearMonth)
      .get();
      
    final Map<String, double> summary = {};
    
    // For each month, fetch all expenses and calculate summary
    for (final monthDoc in monthsSnapshot.docs) {
      final String yearMonth = monthDoc.id;
      
      final QuerySnapshot expensesSnapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.expensesCollection)
        .doc(yearMonth)
        .collection('items')
        .get();
        
      // Group expenses by category and sum amounts
      for (final doc in expensesSnapshot.docs) {
        final expense = ExpenseModel.fromJson(doc.data() as Map<String, dynamic>);
        
        // Filter expenses by date if needed (for partial months)
        if (expense.date.isAfter(startDate.subtract(Duration(days: 1))) && 
            expense.date.isBefore(endDate.add(Duration(days: 1)))) {
          final category = expense.category;
          final amount = expense.amount;
          
          if (summary.containsKey(category)) {
            summary[category] = summary[category]! + amount;
          } else {
            summary[category] = amount;
          }
        }
      }
    }
    
    return summary;
  }
} 