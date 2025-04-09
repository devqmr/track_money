import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../data/models/expense_model.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/usecases/expense/add_expense_usecase.dart';
import '../../../domain/repositories/expense_repository.dart';
import '../../../injection_container.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/settings/settings_bloc.dart';
import '../../bloc/settings/settings_event.dart';
import '../../bloc/settings/settings_state.dart';

class AddExpensePage extends StatefulWidget {
  final Expense? expense; // Optional expense parameter for edit mode
  
  const AddExpensePage({Key? key, this.expense}) : super(key: key);

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> with SingleTickerProviderStateMixin {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  String _selectedCategory = ""; // Will be set from settings
  String _selectedPaymentMethod = ""; // Will be set from settings
  String _note = "";
  DateTime _selectedDate = DateTime.now();
  String _selectedCurrency = ""; // Will be set from settings
  late AnimationController _animationController;
  
  final _addExpenseUseCase = sl<AddExpenseUseCase>();
  final _expenseRepository = sl<ExpenseRepository>();
  
  // Determine if we're in edit mode
  bool get isEditMode => widget.expense != null;

  // Get color for a currency code
  Color getCurrencyColor(String currencyCode) {
    return CurrencyUtils.getCurrencyColor(currencyCode);
  }

  // Convert categories from settings into the format we need
  List<Map<String, dynamic>> get _categories {
    final settingsState = context.read<SettingsBloc>().state;
    if (settingsState is SettingsLoaded) {
      return settingsState.settings.categories.map((categoryName) {
        IconData icon;
        Color color;
        // Assign appropriate icons based on category name
        switch(categoryName) {
          case 'Food':
            icon = Icons.restaurant;
            color = Colors.redAccent;
            break;
          case 'Transportation':
            icon = Icons.directions_car;
            color = Colors.blue;
            break;
          case 'Utilities':
            icon = Icons.power;
            color = Colors.amber;
            break;
          case 'Entertainment':
            icon = Icons.movie;
            color = Colors.purple;
            break;
          case 'Shopping':
            icon = Icons.shopping_bag;
            color = Colors.pink;
            break;
          case 'Health':
            icon = Icons.health_and_safety;
            color = Colors.teal;
            break;
          case 'Education':
            icon = Icons.school;
            color = Colors.indigo;
            break;
          case 'Housing':
            icon = Icons.home;
            color = Colors.brown;
            break;
          case 'Travel':
            icon = Icons.flight;
            color = Colors.deepOrange;
            break;
          default:
            icon = Icons.category;
            color = Colors.blueGrey;
        }
        return {"name": categoryName, "icon": icon, "color": color};
      }).toList();
    }
    return [];
  }

  // Convert payment methods from settings into the format we need
  List<Map<String, dynamic>> get _paymentMethods {
    final settingsState = context.read<SettingsBloc>().state;
    if (settingsState is SettingsLoaded) {
      return settingsState.settings.paymentMethods.map((methodName) {
        IconData icon;
        Color color;
        String? cardType;
        
        // Assign appropriate icons based on payment method
        switch(methodName) {
          case 'Cash':
            icon = Icons.money;
            color = Colors.green;
            break;
          case 'BOP':
            icon = Icons.credit_card;
            color = Colors.blue;
            break;
          case 'AIP':
            icon = Icons.credit_card;
            color = Colors.red;
            break;
          case 'PalPay':
            icon = Icons.account_balance_wallet;
            color = Colors.deepPurple;
            break;
          case 'JawwalPay':
            icon = Icons.phone_android;
            color = Colors.orange;
            break;
          case 'Bank Transfer':
            icon = Icons.account_balance;
            color = Colors.teal;
            break;
          case 'Credit Card':
            icon = Icons.credit_score;
            color = Colors.pink;
            break;
          default:
            icon = Icons.payment;
            color = Colors.grey;
        }
        
        return {
          "name": methodName, 
          "icon": icon, 
          "color": color, 
          "cardType": cardType
        };
      }).toList();
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Initialize with expense data if in edit mode
    if (isEditMode) {
      _amountController.text = widget.expense!.amount.toString();
      _selectedCategory = widget.expense!.category;
      _selectedPaymentMethod = widget.expense!.paymentMethod;
      _note = widget.expense!.description;
      _selectedDate = widget.expense!.date;
      _selectedCurrency = widget.expense!.currency;
      _noteController.text = _note;
    } else {
      // Initialize note controller
      _noteController.text = _note;
    }
    
    // Load settings
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<SettingsBloc>().add(LoadSettingsEvent(userId: authState.user.id));
    }
    
    // Focus on amount field to show keyboard immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _amountFocusNode.requestFocus();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _amountFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleCurrency() {
    final settingsState = context.read<SettingsBloc>().state;
    if (settingsState is SettingsLoaded) {
      final currentIndex = settingsState.settings.currencies.indexOf(_selectedCurrency);
      final nextIndex = (currentIndex + 1) % settingsState.settings.currencies.length;
      setState(() {
        _selectedCurrency = settingsState.settings.currencies[nextIndex];
      });
    }
  }

  void _showCurrencyDropdown(BuildContext context, List<String> currencies) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset position = button.localToGlobal(Offset.zero);
    final Size size = button.size;
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + size.height,
        position.dx + size.width,
        position.dy,
      ),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: surfaceColor,
      items: currencies.map((currency) {
        final Color currencyColor = getCurrencyColor(currency);
        
        return PopupMenuItem<String>(
          value: currency,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: currencyColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  currency,
                  style: TextStyle(
                    color: currencyColor,
                    fontWeight: currency == _selectedCurrency ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                currency,
                style: TextStyle(
                  color: textColor,
                  fontWeight: currency == _selectedCurrency ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (currency == _selectedCurrency)
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(Icons.check, size: 16),
                ),
            ],
          ),
        );
      }).toList(),
    ).then((selectedCurrency) {
      if (selectedCurrency != null) {
        setState(() {
          _selectedCurrency = selectedCurrency;
        });
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2026),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: isDarkMode ? Colors.black : Colors.white,
              surface: surfaceColor,
              onSurface: onSurfaceColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _saveExpense() async {
    print('TRACK_MONEY_LOG: Starting ${isEditMode ? "updateExpense" : "saveExpense"} method');
    
    // Validate amount
    if (_amountController.text.isEmpty) {
      print('TRACK_MONEY_LOG: Empty amount, showing error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          margin: EdgeInsets.fromLTRB(15, 5, 15, 15),
        ),
      );
      return;
    }
    
    // Show loading indicator
    print('TRACK_MONEY_LOG: Showing loading dialog');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFF65C1B0),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isEditMode ? 'Updating expense...' : 'Saving expense...',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
    
    try {
      // Parse amount
      final double amount = double.parse(_amountController.text);
      print('TRACK_MONEY_LOG: Parsed amount: $amount');
      
      // Get current user ID
      print('TRACK_MONEY_LOG: Getting current user');
      final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('TRACK_MONEY_LOG: User not authenticated');
        throw Exception('User not authenticated');
      }
      
      final String userId = currentUser.uid;
      print('TRACK_MONEY_LOG: Got userId: $userId');
      
      // Get yearMonth format from the selected date
      final String yearMonth = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}';
      
      if (isEditMode) {
        // Update existing expense
        final updatedExpense = Expense(
          id: widget.expense!.id,
          amount: amount,
          currency: _selectedCurrency,
          date: _selectedDate,
          category: _selectedCategory,
          paymentMethod: _selectedPaymentMethod,
          description: _note,
          userId: widget.expense!.userId,
          createdAt: widget.expense!.createdAt,
          updatedAt: DateTime.now(),
          yearMonth: yearMonth,
        );
        
        // Call repository to update expense
        print('TRACK_MONEY_LOG: Calling repository to update expense');
        final result = await _expenseRepository.updateExpense(updatedExpense);
        
        // Close loading dialog
        print('TRACK_MONEY_LOG: Closing loading dialog');
        if (context.mounted) {
          Navigator.pop(context);
        }
        
        // Handle result
        print('TRACK_MONEY_LOG: Handling result');
        result.fold(
          (failure) {
            print('TRACK_MONEY_LOG: Failure received: ${failure.message}');
            // Show error message
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${failure.message}'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  margin: const EdgeInsets.fromLTRB(15, 5, 15, 15),
                ),
              );
            }
          },
          (success) async {
            print('TRACK_MONEY_LOG: Success received');
            // Check if device is offline
            print('TRACK_MONEY_LOG: Checking connectivity');
            bool isOffline = false;
            try {
              // A simple check - this isn't comprehensive but works for most cases
              final connectivityResult = await Connectivity().checkConnectivity();
              isOffline = connectivityResult == ConnectivityResult.none;
              print('TRACK_MONEY_LOG: Connection status - offline: $isOffline');
            } catch (e) {
              // If we can't check connectivity, assume we're online
              print('TRACK_MONEY_LOG: Error checking connectivity: $e');
              isOffline = false;
            }
            
            // Show success message
            print('TRACK_MONEY_LOG: Showing success message');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isOffline 
                    ? 'Expense updated locally. Will sync when online.' 
                    : 'Expense updated successfully!'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  margin: const EdgeInsets.fromLTRB(15, 5, 15, 15),
                ),
              );
              
              // Close the page and return success=true to trigger refresh on the previous page
              print('TRACK_MONEY_LOG: Closing page with success result');
              Navigator.pop(context, true);
            }
          },
        );
      } else {
        // Add new expense
        // Create params for use case
        print('TRACK_MONEY_LOG: Creating params for use case');
        final params = Params(
          amount: amount,
          currency: _selectedCurrency,
          date: _selectedDate,
          category: _selectedCategory,
          paymentMethod: _selectedPaymentMethod,
          description: _note,
          userId: userId,
        );
        
        // Call the use case
        print('TRACK_MONEY_LOG: Calling _addExpenseUseCase');
        final result = await _addExpenseUseCase(params);
        print('TRACK_MONEY_LOG: Use case returned result');
        
        // Close loading dialog
        print('TRACK_MONEY_LOG: Closing loading dialog');
        if (context.mounted) {
          Navigator.pop(context);
        }
        
        // Handle result
        print('TRACK_MONEY_LOG: Handling result');
        result.fold(
          (failure) {
            print('TRACK_MONEY_LOG: Failure received: ${failure.message}');
            // Show error message
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${failure.message}'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  margin: const EdgeInsets.fromLTRB(15, 5, 15, 15),
                ),
              );
            }
          },
          (success) async {
            print('TRACK_MONEY_LOG: Success received: ${success.id}');
            // Check if device is offline
            print('TRACK_MONEY_LOG: Checking connectivity');
            bool isOffline = false;
            try {
              // A simple check - this isn't comprehensive but works for most cases
              final connectivityResult = await Connectivity().checkConnectivity();
              isOffline = connectivityResult == ConnectivityResult.none;
              print('TRACK_MONEY_LOG: Connection status - offline: $isOffline');
            } catch (e) {
              // If we can't check connectivity, assume we're online
              print('TRACK_MONEY_LOG: Error checking connectivity: $e');
              isOffline = false;
            }
            
            // Show success message
            print('TRACK_MONEY_LOG: Showing success message');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isOffline 
                    ? 'Expense saved locally. Will sync when online.' 
                    : 'Expense saved successfully!'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  margin: const EdgeInsets.fromLTRB(15, 5, 15, 15),
                ),
              );
              
              // Close the page and return success=true to trigger refresh on the previous page
              print('TRACK_MONEY_LOG: Closing page with success result');
              Navigator.pop(context, true);
            }
          },
        );
      }
    } catch (e) {
      print('TRACK_MONEY_LOG: Exception caught: $e');
      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ${isEditMode ? "updating" : "saving"} expense: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            margin: const EdgeInsets.fromLTRB(15, 5, 15, 15),
          ),
        );
      }
    }
  }

  void _showNoteDialog(BuildContext context) {
    final textController = TextEditingController(text: _note);
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Note', style: TextStyle(color: textColor)),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Enter your note here',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _note = textController.text.trim();
                });
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Build animated widget with fade and slide transition
  Widget _buildAnimatedWidget({
    required Widget child,
    required double delay,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, _) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: _animationController,
            curve: Interval(delay, 1.0, curve: Curves.easeOut),
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(delay, 1.0, curve: Curves.easeOut),
              ),
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get theme colors
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryTextColor = Theme.of(context).textTheme.bodySmall?.color;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          isEditMode ? 'Edit Expense' : 'Add Expense',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: surfaceColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).iconTheme.color,
            size: 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          if (settingsState is SettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (settingsState is SettingsError) {
            return Center(child: Text('Error: ${settingsState.message}'));
          }

          if (settingsState is SettingsLoaded) {
            // Set initial values if not set
            if (_selectedCategory.isEmpty) {
              _selectedCategory = settingsState.settings.categories.first;
            }
            if (_selectedPaymentMethod.isEmpty) {
              _selectedPaymentMethod = settingsState.settings.paymentMethods.first;
            }
            if (_selectedCurrency.isEmpty) {
              _selectedCurrency = settingsState.settings.defaultCurrency;
            }

            // Get the color for the selected currency
            final currencyColor = getCurrencyColor(_selectedCurrency);

            return SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Amount Section
                      _buildAnimatedWidget(
                        delay: 0.0,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16.0, bottom: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Amount',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: secondaryTextColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: primaryColor,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                                ),
                                height: 70,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Currency dropdown
                                    Builder(
                                      builder: (context) {
                                        return GestureDetector(
                                          onTap: () {
                                            _showCurrencyDropdown(
                                              context, 
                                              settingsState.settings.currencies,
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                            margin: const EdgeInsets.only(left: 8),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: currencyColor.withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(
                                                      color: currencyColor.withOpacity(0.3),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    _selectedCurrency,
                                                    style: TextStyle(
                                                      color: currencyColor,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Icon(
                                                  Icons.arrow_drop_down,
                                                  size: 24,
                                                  color: secondaryTextColor,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }
                                    ),
                                    // Divider between currency and amount
                                    Container(
                                      height: 36,
                                      width: 1,
                                      color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                                      margin: const EdgeInsets.symmetric(horizontal: 8),
                                    ),
                                    // Amount field
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 12.0),
                                        child: TextField(
                                          controller: _amountController,
                                          focusNode: _amountFocusNode,
                                          style: TextStyle(
                                            fontSize: 46,
                                            fontWeight: FontWeight.w300,
                                            letterSpacing: -0.5,
                                            color: textColor,
                                            height: 1.1,
                                          ),
                                          textAlign: TextAlign.center,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            hintText: '0',
                                            hintStyle: TextStyle(
                                              color: Theme.of(context).hintColor,
                                              fontSize: 46,
                                              fontWeight: FontWeight.w300,
                                            ),
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
                                          ),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      Divider(height: 1, thickness: 1, color: Theme.of(context).dividerTheme.color),
                      
                      // Expense Category Section
                      _buildAnimatedWidget(
                        delay: 0.1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Expense',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  children: _categories.map((category) {
                                    final bool isSelected = category["name"] == _selectedCategory;
                                    final Color categoryColor = isSelected 
                                      ? category["color"] 
                                      : (isDarkMode ? Colors.grey[300]! : Colors.grey[700]!);
                                    
                                    // Create a stronger background color in dark mode
                                    final Color backgroundColor = isSelected 
                                      ? (isDarkMode 
                                          ? category["color"].withOpacity(0.3) 
                                          : category["color"].withOpacity(0.15))
                                      : (isDarkMode 
                                          ? Theme.of(context).colorScheme.surface
                                          : Colors.grey.shade100);
                                    
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 10.0),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _selectedCategory = category["name"];
                                            });
                                          },
                                          borderRadius: BorderRadius.circular(16),
                                          splashColor: category["color"].withOpacity(0.1),
                                          highlightColor: category["color"].withOpacity(0.05),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: backgroundColor,
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  category["icon"],
                                                  color: categoryColor,
                                                  size: 22,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  category["name"],
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                                    color: categoryColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      Divider(height: 1, thickness: 1, color: Theme.of(context).dividerTheme.color),
                      
                      // Payment Method Section
                      _buildAnimatedWidget(
                        delay: 0.2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pay by',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  children: _paymentMethods.map((method) {
                                    final bool isSelected = method["name"] == _selectedPaymentMethod;
                                    final Color methodColor = isSelected 
                                      ? method["color"] 
                                      : (isDarkMode ? Colors.grey[300]! : Colors.grey[700]!);
                                    
                                    // Create a stronger background color in dark mode
                                    final Color backgroundColor = isSelected 
                                      ? (isDarkMode 
                                          ? method["color"].withOpacity(0.3) 
                                          : method["color"].withOpacity(0.15))
                                      : (isDarkMode 
                                          ? Theme.of(context).colorScheme.surface
                                          : Colors.grey.shade100);
                                    
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 10.0),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _selectedPaymentMethod = method["name"];
                                            });
                                          },
                                          borderRadius: BorderRadius.circular(16),
                                          splashColor: method["color"].withOpacity(0.1),
                                          highlightColor: method["color"].withOpacity(0.05),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: backgroundColor,
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  method["icon"],
                                                  color: methodColor,
                                                  size: 22,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  method["name"],
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                                    color: methodColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      Divider(height: 1, thickness: 1, color: Theme.of(context).dividerTheme.color),
                      
                      // Note Field - Replace this section with the inline TextField
                      _buildAnimatedWidget(
                        delay: 0.3,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.edit_note_outlined,
                                    color: secondaryTextColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Add a note',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                                  border: Border.all(
                                    color: primaryColor.withOpacity(0.3),
                                    width: 1.0,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                child: TextField(
                                  controller: _noteController,
                                  onChanged: (value) {
                                    setState(() {
                                      _note = value;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Enter your note here',
                                    hintStyle: TextStyle(
                                      color: Theme.of(context).hintColor,
                                      fontSize: 14,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                  maxLines: 3,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: textColor,
                                    height: 1.3,
                                  ),
                                  textAlignVertical: TextAlignVertical.top,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      Divider(height: 1, thickness: 1, color: Theme.of(context).dividerTheme.color),
                      
                      // Date Field
                      _buildAnimatedWidget(
                        delay: 0.4,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              _selectDate(context);
                            },
                            borderRadius: BorderRadius.circular(8),
                            splashColor: Colors.grey.withOpacity(0.1),
                            highlightColor: Colors.grey.withOpacity(0.05),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14.0),
                              child: Row(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(left: 4),
                                    child: Icon(
                                      Icons.calendar_today_outlined,
                                      color: secondaryTextColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      DateFormat('E, dd MMM yyyy').format(_selectedDate),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: Theme.of(context).hintColor,
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Save Button
                      _buildAnimatedWidget(
                        delay: 0.5,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveExpense,
                            style: Theme.of(context).elevatedButtonTheme.style,
                            child: Text(
                              isEditMode ? 'Update' : 'Save',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return const Center(child: Text('Loading settings...'));
        },
      ),
    );
  }
} 