import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../domain/entities/expense.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/expense/expense_bloc.dart';
import '../../bloc/settings/settings_bloc.dart';
import '../../bloc/settings/settings_state.dart';
import '../../bloc/settings/settings_event.dart';
import '../../widgets/expense/expense_card.dart';
import '../../widgets/expense/month_selector.dart';
import '../expense/add_expense_page.dart';

class ExpensesTab extends StatefulWidget {
  const ExpensesTab({Key? key}) : super(key: key);

  @override
  State<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends State<ExpensesTab> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();
  // Add a flag to track if we're handling an edit request
  bool _handlingEditRequest = false;

  // Get currency color from central utility
  Color getCurrencyColor(String currencyCode) {
    return CurrencyUtils.getCurrencyColor(currencyCode);
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
    
    final userId = context.read<AuthBloc>().state is AuthAuthenticated
        ? (context.read<AuthBloc>().state as AuthAuthenticated).user.id
        : '';
    
    if (userId.isNotEmpty) {
      // Load user settings
      context.read<SettingsBloc>().add(LoadSettingsEvent(userId: userId));
      
      // Check if we already have an ExpenseLoaded state with a selected month
      final expenseState = context.read<ExpenseBloc>().state;
      final DateTime month = expenseState is ExpenseLoaded
          ? expenseState.selectedMonth
          : DateTime.now();
      
      // Only load if not already loaded or if month is different
      if (expenseState is! ExpenseLoaded || 
          expenseState.selectedMonth.month != month.month || 
          expenseState.selectedMonth.year != month.year) {
        context.read<ExpenseBloc>().add(
          LoadExpensesByMonth(
            month: month,
            userId: userId,
          ),
        );
      }
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    final userId = context.read<AuthBloc>().state is AuthAuthenticated
        ? (context.read<AuthBloc>().state as AuthAuthenticated).user.id
        : '';
    
    if (userId.isNotEmpty) {
      final DateTime selectedMonth = context.read<ExpenseBloc>().state is ExpenseLoaded 
          ? (context.read<ExpenseBloc>().state as ExpenseLoaded).selectedMonth
          : DateTime.now();
      
      context.read<ExpenseBloc>().add(
        LoadExpensesByMonth(
          month: selectedMonth,
          userId: userId,
        ),
      );
    }
    
    // Simulate a little delay for better UX
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseBloc, ExpenseState>(
      builder: (context, state) {
        if (state is ExpenseInitial) {
          return _buildLoadingIndicator();
        } else if (state is ExpenseLoading) {
          return _buildLoadingIndicator();
        } else if (state is ExpenseError) {
          return _buildErrorState(state.message);
        } else if (state is ExpenseEditRequested) {
          // Only navigate if we're not already handling this edit request
          if (!_handlingEditRequest) {
            _handlingEditRequest = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddExpensePage(expense: state.expense),
                ),
              ).then((updated) {
                // Reset the flag when returning from edit page
                _handlingEditRequest = false;
                if (updated == true) {
                  // Refresh data if expense was updated
                  _refreshData();
                } else {
                  // If not updated, we need to reset to the loaded state
                  final userId = context.read<AuthBloc>().state is AuthAuthenticated
                    ? (context.read<AuthBloc>().state as AuthAuthenticated).user.id
                    : '';
                  
                  if (userId.isNotEmpty) {
                    context.read<ExpenseBloc>().add(
                      LoadExpensesByMonth(
                        month: state.selectedMonth,
                        userId: userId,
                      ),
                    );
                  }
                }
              });
            });
          }
          // Continue showing the current list while navigating
          return _buildExpenseList(context, state);
        } else if (state is ExpenseLoaded) {
          // Reset the flag when in loaded state
          _handlingEditRequest = false;
          return _buildExpenseList(context, state);
        }
        
        return const Center(
          child: Text(
            'No data available',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
      ),
    );
  }
  
  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Error: $message',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildExpenseList(BuildContext context, ExpenseLoaded state) {
    final monthYearFormat = DateFormat('MM/yyyy');
    final dayFormat = DateFormat('EEEE\nMMM d, yyyy');
    
    final dateKeys = state.expensesByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    
    return RefreshIndicator(
      key: _refreshKey,
      color: Colors.green,
      backgroundColor: Colors.white,
      strokeWidth: 2.5,
      onRefresh: _refreshData,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _animationController,
                          curve: Curves.easeInOut,
                        ),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.1),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _animationController,
                            curve: Curves.easeOut,
                          )),
                          child: child,
                        ),
                      );
                    },
                    child: MonthSelector(
                      selectedMonth: state.selectedMonth,
                      onPreviousMonth: () {
                        HapticFeedback.lightImpact();
                        final userId = context.read<AuthBloc>().state is AuthAuthenticated
                          ? (context.read<AuthBloc>().state as AuthAuthenticated).user.id
                          : '';
                        
                        if (userId.isNotEmpty) {
                          _animationController.reset();
                          _animationController.forward();
                          context.read<ExpenseBloc>().add(
                            ChangeMonth(
                              direction: MonthChangeDirection.previous,
                              userId: userId,
                            ),
                          );
                        }
                      },
                      onNextMonth: () {
                        HapticFeedback.lightImpact();
                        final userId = context.read<AuthBloc>().state is AuthAuthenticated
                          ? (context.read<AuthBloc>().state as AuthAuthenticated).user.id
                          : '';
                        
                        if (userId.isNotEmpty) {
                          _animationController.reset();
                          _animationController.forward();
                          context.read<ExpenseBloc>().add(
                            ChangeMonth(
                              direction: MonthChangeDirection.next,
                              userId: userId,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 20.0),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.easeInOut,
                    ),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.1),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _animationController,
                        curve: Curves.easeOut,
                      )),
                      child: child,
                    ),
                  );
                },
                child: Card(
                  elevation: 2,
                  shadowColor: Colors.black.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Theme.of(context).cardTheme.color
                      : const Color(0xFFEFF8F1),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.assessment_outlined,
                              size: 20,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Report this month',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Divider(
                          height: 24, 
                          thickness: 0.5, 
                          color: Theme.of(context).dividerTheme.color,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Outflow',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: state.totalByCurrency.entries.map((entry) {
                                final currencyCode = entry.key;
                                final currencyColor = getCurrencyColor(currencyCode);
                                
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        margin: const EdgeInsets.only(right: 6),
                                        decoration: BoxDecoration(
                                          color: currencyColor.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          currencyCode,
                                          style: TextStyle(
                                            color: currencyColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        entry.value.toStringAsFixed(2),
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          dateKeys.isEmpty
              ? SliverToBoxAdapter(
                  child: SizedBox(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No expenses recorded',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Expenses you add will appear here',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final date = dateKeys[index];
                      final expenses = state.expensesByDate[date]!;
                      
                      // Calculate total spent for this day by currency
                      Map<String, double> totalByCurrency = {};
                      
                      // Get currencies from settings or fallback to defaults
                      final settingsState = context.read<SettingsBloc>().state;
                      if (settingsState is SettingsLoaded) {
                        // Initialize all currencies from settings with zero
                        for (var currency in settingsState.settings.currencies) {
                          totalByCurrency[currency] = 0.0;
                        }
                      } else {
                        // Fallback to default currencies
                        totalByCurrency = {
                          AppConstants.usdCurrency: 0.0,
                          AppConstants.sarCurrency: 0.0,
                          AppConstants.egpCurrency: 0.0
                        };
                      }
                      
                      for (var expense in expenses) {
                        // Ensure the currency exists in the map
                        if (!totalByCurrency.containsKey(expense.currency)) {
                          totalByCurrency[expense.currency] = 0.0;
                        }
                        totalByCurrency[expense.currency] = 
                            totalByCurrency[expense.currency]! + expense.amount;
                      }
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDateHeader(date),
                                  const SizedBox(width: 20),
                                  Expanded(child: Container()),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: totalByCurrency.entries
                                        .where((entry) => entry.value > 0)
                                        .map((entry) {
                                      final currencyCode = entry.key;
                                      final currencyColor = getCurrencyColor(currencyCode);
                                      
                                      return Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                            margin: const EdgeInsets.symmetric(horizontal: 4),
                                            decoration: BoxDecoration(
                                              color: currencyColor.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              currencyCode,
                                              style: TextStyle(
                                                color: currencyColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            entry.value.toStringAsFixed(2),
                                            style: TextStyle(
                                              color: Theme.of(context).textTheme.bodyLarge?.color,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                            ...expenses.asMap().entries.map((entry) {
                              final int idx = entry.key;
                              final expense = entry.value;
                              return AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  // Stagger the animations slightly
                                  final delay = idx * 0.05;
                                  final startAt = delay;
                                  final endAt = startAt + 0.6; // Ensure this is <= 1.0
                                  
                                  return FadeTransition(
                                    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                                      CurvedAnimation(
                                        parent: _animationController,
                                        curve: Interval(startAt, endAt, curve: Curves.easeOut),
                                      ),
                                    ),
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0.05, 0.0),
                                        end: Offset.zero,
                                      ).animate(
                                        CurvedAnimation(
                                          parent: _animationController,
                                          curve: Interval(startAt, endAt, curve: Curves.easeOut),
                                        ),
                                      ),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Dismissible(
                                    key: Key(expense.id),
                                    background: _buildSwipeActionBackground(
                                      alignment: Alignment.centerLeft,
                                      color: Colors.blue,
                                      icon: Icons.edit,
                                      label: 'Edit',
                                    ),
                                    secondaryBackground: _buildSwipeActionBackground(
                                      alignment: Alignment.centerRight,
                                      color: Colors.red,
                                      icon: Icons.delete,
                                      label: 'Delete',
                                    ),
                                    confirmDismiss: (direction) async {
                                      if (direction == DismissDirection.startToEnd) {
                                        // Handle edit action
                                        HapticFeedback.mediumImpact();
                                        _handleEditExpense(expense);
                                        return false; // Don't actually dismiss
                                      } else {
                                        // Handle delete action - show confirmation dialog
                                        HapticFeedback.mediumImpact();
                                        return await _showDeleteConfirmation(context);
                                      }
                                    },
                                    onDismissed: (direction) {
                                      if (direction == DismissDirection.endToStart) {
                                        // User confirmed delete
                                        _handleDeleteExpense(expense);
                                      }
                                    },
                                    child: ExpenseCard(expense: expense),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      );
                    },
                    childCount: dateKeys.length,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildSwipeActionBackground({
    required AlignmentGeometry alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      color: color,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alignment == Alignment.centerLeft) ...[
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ] else ...[
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: Colors.white),
          ],
        ],
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Expense'),
          content: const Text('Are you sure you want to delete this expense?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'DELETE',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    ) ?? false; // Default to false if dialog is dismissed
  }

  void _handleEditExpense(Expense expense) {
    // Get the current user ID
    final userId = context.read<AuthBloc>().state is AuthAuthenticated
        ? (context.read<AuthBloc>().state as AuthAuthenticated).user.id
        : '';
    
    if (userId.isNotEmpty) {
      context.read<ExpenseBloc>().add(
        EditExpenseRequested(expense: expense, userId: userId),
      );
    }
  }

  void _handleDeleteExpense(Expense expense) {
    // Get the current user ID
    final userId = context.read<AuthBloc>().state is AuthAuthenticated
        ? (context.read<AuthBloc>().state as AuthAuthenticated).user.id
        : '';
    
    if (userId.isNotEmpty) {
      // Get yearMonth from expense or generate it
      final yearMonth = expense.yearMonth ?? _generateYearMonth(expense.date);
      
      context.read<ExpenseBloc>().add(
        DeleteExpense(
          expenseId: expense.id, 
          userId: userId,
          yearMonth: yearMonth,
        ),
      );
    }
  }
  
  // Helper method to generate yearMonth format
  String _generateYearMonth(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  Widget _buildDateHeader(DateTime date) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dateBackgroundColor = isDarkMode 
        ? Theme.of(context).cardTheme.color?.withOpacity(0.8) 
        : const Color(0xFFEFF8F1);
    final dateTextColor = isDarkMode 
        ? Theme.of(context).textTheme.bodyLarge?.color 
        : Colors.black87;
    final dayNumberColor = isDarkMode 
        ? Theme.of(context).colorScheme.primary 
        : Colors.black;
    
    return Container(
      width: 100,
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: dateBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat.d().format(date),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: dayNumberColor,
            ),
          ),
          Text(
            DateFormat('EEEE').format(date),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: dateTextColor,
            ),
          ),
          Text(
            DateFormat('MMM yyyy').format(date),
            style: TextStyle(
              fontSize: 10,
              color: dateTextColor,
            ),
          ),
        ],
      ),
    );
  }
} 