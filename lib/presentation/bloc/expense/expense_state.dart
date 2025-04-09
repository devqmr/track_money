part of 'expense_bloc.dart';

abstract class ExpenseState extends Equatable {
  const ExpenseState();
  
  @override
  List<Object?> get props => [];
}

class ExpenseInitial extends ExpenseState {}

class ExpenseLoading extends ExpenseState {}

class ExpenseError extends ExpenseState {
  final String message;

  const ExpenseError({required this.message});
  
  @override
  List<Object?> get props => [message];
}

class ExpenseLoaded extends ExpenseState {
  final List<Expense> expenses;
  final Map<DateTime, List<Expense>> expensesByDate;
  final Map<String, double> totalByCurrency;
  final DateTime selectedMonth;
  final bool isLoading;

  const ExpenseLoaded({
    required this.expenses,
    required this.expensesByDate,
    required this.totalByCurrency,
    required this.selectedMonth,
    this.isLoading = false,
  });
  
  @override
  List<Object?> get props => [
    expenses, 
    expensesByDate, 
    totalByCurrency,
    selectedMonth,
    isLoading,
  ];
}

class ExpenseEditRequested extends ExpenseLoaded {
  final Expense expense;

  const ExpenseEditRequested({
    required this.expense,
    required List<Expense> expenses,
    required Map<DateTime, List<Expense>> expensesByDate,
    required Map<String, double> totalByCurrency,
    required DateTime selectedMonth,
    bool isLoading = false,
  }) : super(
    expenses: expenses,
    expensesByDate: expensesByDate,
    totalByCurrency: totalByCurrency,
    selectedMonth: selectedMonth,
    isLoading: isLoading,
  );
  
  @override
  List<Object?> get props => [
    expense,
    ...super.props,
  ];
} 