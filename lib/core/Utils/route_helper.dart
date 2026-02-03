import 'package:flutter/material.dart';
import '../../presentation/add_transaction/screens/add_transaction_screen.dart';

/// Helper class for handling routes with arguments
class RouteHelper {
  /// Get AddTransactionScreen based on arguments
  static Widget getAddTransactionScreen(Object? arguments) {
    if (arguments is String) {
      // Edit mode with transaction ID
      return AddTransactionScreen(transactionId: arguments);
    }
    // Add mode (no transaction ID)
    return const AddTransactionScreen();
  }
}