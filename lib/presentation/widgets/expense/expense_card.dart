import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:track_money/core/utils/currency_utils.dart';
import '../../../domain/entities/expense.dart';
import '../../../core/constants/app_constants.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;

  const ExpenseCard({
    Key? key,
    required this.expense,
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    // Define icon mapping for expense categories
    final Map<String, IconData> categoryIcons = {
      'Food': Icons.restaurant,
      'Shopping': Icons.shopping_bag,
      'Transportation': Icons.directions_car,
      'Entertainment': Icons.movie,
      'Utilities': Icons.water_damage,
      'Housing': Icons.home,
      'Health': Icons.medical_services,
      'Education': Icons.school,
      'Personal': Icons.person,
      'Travel': Icons.flight,
      'Subscription': Icons.subscriptions,
      'Dating': Icons.favorite,
      'Dinner': Icons.dinner_dining,
      'Dessert': Icons.cake,
      'Cupcake': Icons.cake,
      // Default icon for any other category
    };

    // Get icon for this category or use a default
    final IconData icon = categoryIcons[expense.category] ?? Icons.attach_money;
    
    // Get color for this currency
    final Color currencyColor =  CurrencyUtils.getCurrencyColor(expense.currency);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      color: Theme.of(context).brightness == Brightness.dark 
                      ? Theme.of(context).cardTheme.color
                      : const Color(0xFFEFF8F1),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: AutoSizeText(expense.category, maxLines: 1),
        subtitle: expense.description.isEmpty 
            ? null 
            : Text(expense.description),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: currencyColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                expense.currency,
                style: TextStyle(
                  color: currencyColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              expense.amount.toStringAsFixed(2),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 