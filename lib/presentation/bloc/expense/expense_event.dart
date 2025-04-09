part of 'expense_bloc.dart';

abstract class ExpenseEvent extends Equatable {
  const ExpenseEvent();

  @override
  List<Object> get props => [];
}

enum MonthChangeDirection { previous, next }

class LoadExpensesByMonth extends ExpenseEvent {
  final DateTime month;
  final String userId;

  const LoadExpensesByMonth({
    required this.month,
    required this.userId,
  });

  @override
  List<Object> get props => [month, userId];
}

class ChangeMonth extends ExpenseEvent {
  final MonthChangeDirection direction;
  final String userId;

  const ChangeMonth({
    required this.direction,
    required this.userId,
  });

  @override
  List<Object> get props => [direction, userId];
}

class AddNewExpense extends ExpenseEvent {
  final Params params;

  const AddNewExpense({
    required this.params,
  });

  @override
  List<Object> get props => [params];
}

class DeleteExpense extends ExpenseEvent {
  final String expenseId;
  final String userId;
  final String yearMonth;

  const DeleteExpense({
    required this.expenseId,
    required this.userId,
    required this.yearMonth,
  });

  @override
  List<Object> get props => [expenseId, userId, yearMonth];
}

class EditExpenseRequested extends ExpenseEvent {
  final Expense expense;
  final String userId;

  const EditExpenseRequested({
    required this.expense,
    required this.userId,
  });

  @override
  List<Object> get props => [expense, userId];
} 