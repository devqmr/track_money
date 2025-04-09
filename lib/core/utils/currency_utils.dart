import 'package:flutter/material.dart';

/// Utility class for currency-related functions
class CurrencyUtils {
  /// Get a color for a given currency code
  /// Specific currencies (USD, SAR, EGP) will always get their assigned colors
  /// Other currencies will get a color based on hash code
  static Color getCurrencyColor(String currencyCode) {
    // Fixed colors for specific currencies
    switch (currencyCode) {
      case 'USD':
        return Colors.green;
      case 'SAR':
        return Colors.orange;
      case 'EGP':
        return Colors.pink;
      default:
        // Generate a color based on the currency code's hash for other currencies
        final int hashCode = currencyCode.hashCode;
        final List<Color> colors = [
          Colors.blue,
          Colors.purple,
          Colors.teal,
          Colors.indigo,
          Colors.red,
          Colors.amber,
          Colors.cyan,
          Colors.deepPurple,
          Colors.lightBlue,
          Colors.lime,
        ];
        
        return colors[hashCode.abs() % colors.length];
    }
  }
} 