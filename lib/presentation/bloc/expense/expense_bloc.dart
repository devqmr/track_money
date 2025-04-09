import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/repositories/expense_repository.dart';
import '../../../domain/usecases/expense/get_expenses_by_date_range.dart' hide Params;
import '../../../domain/usecases/expense/add_expense_usecase.dart';

part 'expense_event.dart';
part 'expense_state.dart';

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final ExpenseRepository expenseRepository;
  final GetExpensesByDateRange getExpensesByDateRange;
  final AddExpenseUseCase addExpense;

  ExpenseBloc({
    required this.expenseRepository,
    required this.getExpensesByDateRange,
    required this.addExpense,
  }) : super(ExpenseInitial()) {
    on<LoadExpensesByMonth>(_onLoadExpensesByMonth);
    on<ChangeMonth>(_onChangeMonth);
    on<AddNewExpense>(_onAddNewExpense);
    on<DeleteExpense>(_onDeleteExpense);
    on<EditExpenseRequested>(_onEditExpenseRequested);
  }

  void _onLoadExpensesByMonth(
    LoadExpensesByMonth event, 
    Emitter<ExpenseState> emit
  ) async {
    emit(ExpenseLoading());
    
    final selectedMonth = event.month;
    final userId = event.userId;
    
    // Format yearMonth string for the query
    final String yearMonth = '${selectedMonth.year}-${selectedMonth.month.toString().padLeft(2, '0')}';
    
    try {
      // Use getExpensesByMonth directly since we now have a collection per month
      final result = await expenseRepository.getExpensesByMonth(
        userId, 
        yearMonth
      );
      
      result.fold(
        (failure) => emit(ExpenseError(message: failure.toString())),
        (expenses) {
          // Group expenses by date
          final Map<DateTime, List<Expense>> expensesByDate = {};
          
          for (var expense in expenses) {
            final dateKey = DateTime(expense.date.year, expense.date.month, expense.date.day);
            
            if (!expensesByDate.containsKey(dateKey)) {
              expensesByDate[dateKey] = [];
            }
            
            expensesByDate[dateKey]!.add(expense);
          }
          
          // Calculate totals by currency
          final Map<String, double> totalByCurrency = {};
          
          for (var expense in expenses) {
            if (!totalByCurrency.containsKey(expense.currency)) {
              totalByCurrency[expense.currency] = 0;
            }
            
            totalByCurrency[expense.currency] = 
                totalByCurrency[expense.currency]! + expense.amount;
          }
          
          emit(ExpenseLoaded(
            expenses: expenses,
            expensesByDate: expensesByDate,
            totalByCurrency: totalByCurrency,
            selectedMonth: selectedMonth,
          ));
        }
      );
    } catch (e) {
      emit(ExpenseError(message: e.toString()));
    }
  }

  void _onChangeMonth(
    ChangeMonth event, 
    Emitter<ExpenseState> emit
  ) async {
    if (state is ExpenseLoaded) {
      final currentState = state as ExpenseLoaded;
      
      // Emit the same state but with loading flag
      emit(ExpenseLoaded(
        expenses: currentState.expenses,
        expensesByDate: currentState.expensesByDate,
        totalByCurrency: currentState.totalByCurrency,
        selectedMonth: currentState.selectedMonth,
        isLoading: true,
      ));
      
      // Calculate the new month
      final currentMonth = currentState.selectedMonth;
      DateTime newMonth;
      
      if (event.direction == MonthChangeDirection.next) {
        newMonth = DateTime(currentMonth.year, currentMonth.month + 1);
      } else {
        newMonth = DateTime(currentMonth.year, currentMonth.month - 1);
      }
      
      add(LoadExpensesByMonth(month: newMonth, userId: event.userId));
    }
  }

  void _onAddNewExpense(
    AddNewExpense event, 
    Emitter<ExpenseState> emit
  ) async {
    if (state is ExpenseLoaded) {
      emit(ExpenseLoading());
      
      final result = await addExpense(event.params);
      
      result.fold(
        (failure) => emit(ExpenseError(message: failure.toString())),
        (expense) {
          // Reload expenses for the current month
          add(LoadExpensesByMonth(
            month: event.params.date,
            userId: event.params.userId
          ));
        }
      );
    }
  }

  void _onDeleteExpense(
    DeleteExpense event,
    Emitter<ExpenseState> emit
  ) async {
    if (state is ExpenseLoaded) {
      final currentState = state as ExpenseLoaded;
      
      // Show loading while deleting
      emit(ExpenseLoading());
      
      // Call repository to delete expense
      final result = await expenseRepository.deleteExpense(
        event.userId, 
        event.expenseId, 
        event.yearMonth
      );
      
      result.fold(
        (failure) => emit(ExpenseError(message: failure.toString())),
        (_) {
          // Reload expenses for the current month to refresh the UI
          add(LoadExpensesByMonth(
            month: currentState.selectedMonth,
            userId: event.userId
          ));
        }
      );
    }
  }

  void _onEditExpenseRequested(
    EditExpenseRequested event,
    Emitter<ExpenseState> emit
  ) async {
    // Navigate to edit expense page or show edit dialog
    // This will be handled in the UI layer
    // Here we can just pass the event through without changing state
    
    // If you want to handle actual update, add an UpdateExpense event
    // and implement a handler for it similar to _onDeleteExpense
    
    // Emit a navigation state that the UI can listen for
    if (state is ExpenseLoaded) {
      final currentState = state as ExpenseLoaded;
      emit(ExpenseEditRequested(
        expense: event.expense,
        expenses: currentState.expenses,
        expensesByDate: currentState.expensesByDate,
        totalByCurrency: currentState.totalByCurrency,
        selectedMonth: currentState.selectedMonth,
      ));
    }
  }
} 