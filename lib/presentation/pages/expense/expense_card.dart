import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/expense.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;

  const ExpenseCard({
    Key? key,
    required this.expense,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Define icon mapping for expense categories
    final Map<String, IconData> categoryIcons = {
      'Food': Icons.restaurant,
      'Shopping': Icons.shopping_bag,
      'Transportation': Icons.directions_car,
      'Entertainment': Icons.movie,
      'Utilities': Icons.water_damage,
      'Housing': Icons.home,
      'Healthcare': Icons.medical_services,
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
    

    final String currencySymbol = expense.currency == 'USD' ? '\$' : '₪';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      color: isDarkMode 
        ? AppTheme.darkCardColor // Use darker card in dark mode
        : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDarkMode 
            ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
            : Theme.of(context).colorScheme.surface,
          child: Icon(
            icon, 
            color: Theme.of(context).colorScheme.primary,
            size: 22,
          ),
        ),
        title: Text(
          expense.category,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
        ),
        subtitle: expense.description.isEmpty 
            ? null 
            : Text(
                expense.description,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currencySymbol,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
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