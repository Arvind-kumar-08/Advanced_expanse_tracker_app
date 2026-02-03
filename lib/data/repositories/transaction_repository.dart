import 'dart:async';

import '../datasources/local/hive_datasources.dart';
import '../datasources/remote/firestore_datasource.dart';
import '../models/transaction_model.dart';

/// Repository for transaction operations
/// Implements offline-first approach with cloud sync
class TransactionRepository {
  final HiveDataSource _hiveDataSource;
  final FirestoreDataSource _firestoreDataSource;

  TransactionRepository({
    required HiveDataSource hiveDataSource,
    required FirestoreDataSource firestoreDataSource,
  })  : _hiveDataSource = hiveDataSource,
        _firestoreDataSource = firestoreDataSource;

  // ==================== CREATE OPERATIONS ====================

  /// Add new transaction (saves locally and syncs to cloud)
  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      // Save to local storage first (offline-first)
      await _hiveDataSource.saveTransaction(transaction);

      // Try to sync to cloud
      try {
        await _firestoreDataSource.saveTransaction(transaction);
        // Mark as synced in local storage
        await _hiveDataSource.markTransactionAsSynced(transaction.id);
      } catch (e) {
        // Cloud sync failed, but local save succeeded
        // Transaction will be synced later
        print('Cloud sync failed, will retry later: $e');
      }
    } catch (e) {
      throw Exception('Failed to add transaction: ${e.toString()}');
    }
  }

  // ==================== READ OPERATIONS ====================

  /// Get all transactions for a user
  Future<List<TransactionModel>> getAllTransactions(String userId) async {
    try {
      // Return from local storage (offline-first)
      return _hiveDataSource.getTransactionsByUserId(userId);
    } catch (e) {
      throw Exception('Failed to get transactions: ${e.toString()}');
    }
  }

  /// Get transaction by ID
  Future<TransactionModel?> getTransactionById(String id) async {
    try {
      return _hiveDataSource.getTransactionById(id);
    } catch (e) {
      throw Exception('Failed to get transaction: ${e.toString()}');
    }
  }

  /// Get transactions by date range
  Future<List<TransactionModel>> getTransactionsByDateRange(
      String userId,
      DateTime startDate,
      DateTime endDate,
      ) async {
    try {
      return _hiveDataSource.getTransactionsByDateRange(
        userId,
        startDate,
        endDate,
      );
    } catch (e) {
      throw Exception('Failed to get transactions by date: ${e.toString()}');
    }
  }

  /// Get transactions by type (income/expense)
  Future<List<TransactionModel>> getTransactionsByType(
      String userId,
      TransactionType type,
      ) async {
    try {
      return _hiveDataSource.getTransactionsByType(userId, type);
    } catch (e) {
      throw Exception('Failed to get transactions by type: ${e.toString()}');
    }
  }

  /// Get transactions by category
  Future<List<TransactionModel>> getTransactionsByCategory(
      String userId,
      String category,
      ) async {
    try {
      return _hiveDataSource.getTransactionsByCategory(userId, category);
    } catch (e) {
      throw Exception('Failed to get transactions by category: ${e.toString()}');
    }
  }

  /// Get transactions for current month
  Future<List<TransactionModel>> getCurrentMonthTransactions(String userId) async {
    try {
      final now = DateTime.now();
      final firstDay = DateTime(now.year, now.month, 1);
      final lastDay = DateTime(now.year, now.month + 1, 0);

      return getTransactionsByDateRange(userId, firstDay, lastDay);
    } catch (e) {
      throw Exception('Failed to get current month transactions: ${e.toString()}');
    }
  }

  /// Stream of transactions (real-time updates from Firestore)
  Stream<List<TransactionModel>> getTransactionsStream(String userId) {
    return _firestoreDataSource.getTransactionsStream(userId);
  }

  // ==================== UPDATE OPERATIONS ====================

  /// Update transaction
  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      // Mark as unsynced for local update
      final unsyncedTransaction = transaction.markAsUnsynced();

      // Update in local storage
      await _hiveDataSource.updateTransaction(unsyncedTransaction);

      // Try to sync to cloud
      try {
        await _firestoreDataSource.updateTransaction(transaction);
        // Mark as synced
        await _hiveDataSource.markTransactionAsSynced(transaction.id);
      } catch (e) {
        // Cloud sync failed, will retry later
        print('Cloud sync failed, will retry later: $e');
      }
    } catch (e) {
      throw Exception('Failed to update transaction: ${e.toString()}');
    }
  }

  // ==================== DELETE OPERATIONS ====================

  /// Delete transaction
  Future<void> deleteTransaction(String userId, String transactionId) async {
    try {
      // Delete from local storage
      await _hiveDataSource.deleteTransaction(transactionId);

      // Try to delete from cloud
      try {
        await _firestoreDataSource.deleteTransaction(userId, transactionId);
      } catch (e) {
        // Cloud deletion failed, but local deletion succeeded
        print('Cloud deletion failed: $e');
      }
    } catch (e) {
      throw Exception('Failed to delete transaction: ${e.toString()}');
    }
  }

  /// Delete all transactions for a user
  Future<void> deleteAllTransactions(String userId) async {
    try {
      await _hiveDataSource.deleteAllTransactions(userId);

      try {
        await _firestoreDataSource.deleteAllTransactions(userId);
      } catch (e) {
        print('Cloud deletion failed: $e');
      }
    } catch (e) {
      throw Exception('Failed to delete all transactions: ${e.toString()}');
    }
  }

  // ==================== SYNC OPERATIONS ====================

  /// Sync local transactions to cloud
  Future<void> syncToCloud(String userId) async {
    try {
      // Get all unsynced transactions
      final unsyncedTransactions = _hiveDataSource.getUnsyncedTransactions(userId);

      if (unsyncedTransactions.isEmpty) {
        print('No transactions to sync');
        return;
      }

      // Upload to Firestore
      await _firestoreDataSource.saveTransactions(unsyncedTransactions);

      // Mark all as synced locally
      for (var transaction in unsyncedTransactions) {
        await _hiveDataSource.markTransactionAsSynced(transaction.id);
      }

      print('Synced ${unsyncedTransactions.length} transactions to cloud');
    } catch (e) {
      throw Exception('Failed to sync to cloud: ${e.toString()}');
    }
  }

  /// Sync cloud transactions to local storage
  Future<void> syncFromCloud(String userId) async {
    try {
      // Get all transactions from cloud
      final cloudTransactions = await _firestoreDataSource.getAllTransactions(userId);

      // Save to local storage
      await _hiveDataSource.saveTransactions(cloudTransactions);

      // Update last sync time
      await _hiveDataSource.saveLastSyncTime(DateTime.now());

      print('Synced ${cloudTransactions.length} transactions from cloud');
    } catch (e) {
      throw Exception('Failed to sync from cloud: ${e.toString()}');
    }
  }

  /// Full bidirectional sync
  Future<void> fullSync(String userId) async {
    try {
      // First, upload unsynced local transactions
      await syncToCloud(userId);

      // Then, download latest from cloud
      await syncFromCloud(userId);

      print('Full sync completed successfully');
    } catch (e) {
      throw Exception('Full sync failed: ${e.toString()}');
    }
  }

  /// Get last sync time
  DateTime? getLastSyncTime() {
    return _hiveDataSource.getLastSyncTime();
  }

  // ==================== ANALYTICS OPERATIONS ====================

  /// Calculate total income
  Future<double> getTotalIncome(String userId) async {
    try {
      final transactions = await getTransactionsByType(
        userId,
        TransactionType.income,
      );
      return transactions.fold<double>(0.0, (sum, t) => sum + t.amount);
    } catch (e) {
      throw Exception('Failed to calculate total income: ${e.toString()}');
    }
  }

  /// Calculate total expense
  Future<double> getTotalExpense(String userId) async {
    try {
      final transactions = await getTransactionsByType(
        userId,
        TransactionType.expense,
      );
      return transactions.fold<double>(0.0, (sum, t) => sum + t.amount);
    } catch (e) {
      throw Exception('Failed to calculate total expense: ${e.toString()}');
    }
  }

  /// Calculate balance (income - expense)
  Future<double> getBalance(String userId) async {
    try {
      final income = await getTotalIncome(userId);
      final expense = await getTotalExpense(userId);
      return income - expense;
    } catch (e) {
      throw Exception('Failed to calculate balance: ${e.toString()}');
    }
  }

  /// Get category-wise expenses
  Future<Map<String, double>> getCategoryWiseExpenses(String userId) async {
    try {
      final expenses = await getTransactionsByType(
        userId,
        TransactionType.expense,
      );

      final Map<String, double> categoryTotals = {};

      for (var transaction in expenses) {
        categoryTotals[transaction.category] =
            (categoryTotals[transaction.category] ?? 0) + transaction.amount;
      }

      return categoryTotals;
    } catch (e) {
      throw Exception('Failed to get category-wise expenses: ${e.toString()}');
    }
  }

  /// Get category-wise income
  Future<Map<String, double>> getCategoryWiseIncome(String userId) async {
    try {
      final incomes = await getTransactionsByType(
        userId,
        TransactionType.income,
      );

      final Map<String, double> categoryTotals = {};

      for (var transaction in incomes) {
        categoryTotals[transaction.category] =
            (categoryTotals[transaction.category] ?? 0) + transaction.amount;
      }

      return categoryTotals;
    } catch (e) {
      throw Exception('Failed to get category-wise income: ${e.toString()}');
    }
  }

  /// Get monthly trend data
  Future<Map<String, Map<String, double>>> getMonthlyTrend(
      String userId,
      int monthCount,
      ) async {
    try {
      final Map<String, Map<String, double>> monthlyData = {};
      final now = DateTime.now();

      for (int i = 0; i < monthCount; i++) {
        final month = DateTime(now.year, now.month - i, 1);
        final firstDay = DateTime(month.year, month.month, 1);
        final lastDay = DateTime(month.year, month.month + 1, 0);

        final transactions = await getTransactionsByDateRange(
          userId,
          firstDay,
          lastDay,
        );

        final income = transactions
            .where((t) => t.type == TransactionType.income)
            .fold(0.0, (sum, t) => sum + t.amount);

        final expense = transactions
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (sum, t) => sum + t.amount);

        final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';
        monthlyData[monthKey] = {
          'income': income,
          'expense': expense,
        };
      }

      return monthlyData;
    } catch (e) {
      throw Exception('Failed to get monthly trend: ${e.toString()}');
    }
  }

  /// Get transaction count
  int getTransactionCount(String userId) {
    return _hiveDataSource.getTransactionCount(userId);
  }

  /// Check if user has any data
  bool hasUserData(String userId) {
    return _hiveDataSource.hasUserData(userId);
  }
}

