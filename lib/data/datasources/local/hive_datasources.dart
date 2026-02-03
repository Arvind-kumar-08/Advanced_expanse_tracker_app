import 'package:hive_flutter/hive_flutter.dart';
import '../../models/user_model.dart';
import '../../models/transaction_model.dart';

/// Local data source using Hive for offline storage
class HiveDataSource {
  // Box names
  static const String _userBoxName = 'user_box';
  static const String _transactionBoxName = 'transaction_box';
  static const String _settingsBoxName = 'settings_box';

  // Boxes
  late Box<UserModel> _userBox;
  late Box<TransactionModel> _transactionBox;
  late Box<dynamic> _settingsBox;

  /// Initialize Hive and open boxes
  Future<void> init() async {
    try {
      // Initialize Hive
      await Hive.initFlutter();

      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(UserModelAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(TransactionModelAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(TransactionTypeAdapter());
      }

      // Open boxes
      _userBox = await Hive.openBox<UserModel>(_userBoxName);
      _transactionBox = await Hive.openBox<TransactionModel>(_transactionBoxName);
      _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);

      print('Hive initialized successfully');
    } catch (e) {
      print('Error initializing Hive: $e');
      rethrow;
    }
  }

  // ==================== USER OPERATIONS ====================

  /// Save user to local storage
  Future<void> saveUser(UserModel user) async {
    try {
      await _userBox.put('current_user', user);
    } catch (e) {
      print('Error saving user: $e');
      rethrow;
    }
  }

  /// Get current user from local storage
  UserModel? getCurrentUser() {
    try {
      return _userBox.get('current_user');
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  /// Delete user from local storage
  Future<void> deleteUser() async {
    try {
      await _userBox.delete('current_user');
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  /// Update user's last synced time
  Future<void> updateUserSyncTime(DateTime syncTime) async {
    try {
      final user = getCurrentUser();
      if (user != null) {
        final updatedUser = user.copyWith(lastSyncedAt: syncTime);
        await saveUser(updatedUser);
      }
    } catch (e) {
      print('Error updating user sync time: $e');
      rethrow;
    }
  }

  // ==================== TRANSACTION OPERATIONS ====================

  /// Save transaction to local storage
  Future<void> saveTransaction(TransactionModel transaction) async {
    try {
      await _transactionBox.put(transaction.id, transaction);
    } catch (e) {
      print('Error saving transaction: $e');
      rethrow;
    }
  }

  /// Save multiple transactions
  Future<void> saveTransactions(List<TransactionModel> transactions) async {
    try {
      final Map<String, TransactionModel> transactionMap = {
        for (var transaction in transactions) transaction.id: transaction
      };
      await _transactionBox.putAll(transactionMap);
    } catch (e) {
      print('Error saving transactions: $e');
      rethrow;
    }
  }

  /// Get all transactions
  List<TransactionModel> getAllTransactions() {
    try {
      return _transactionBox.values.toList();
    } catch (e) {
      print('Error getting all transactions: $e');
      return [];
    }
  }

  /// Get transaction by ID
  TransactionModel? getTransactionById(String id) {
    try {
      return _transactionBox.get(id);
    } catch (e) {
      print('Error getting transaction by id: $e');
      return null;
    }
  }

  /// Get transactions by user ID
  List<TransactionModel> getTransactionsByUserId(String userId) {
    try {
      return _transactionBox.values
          .where((transaction) => transaction.userId == userId)
          .toList();
    } catch (e) {
      print('Error getting transactions by user id: $e');
      return [];
    }
  }

  /// Get transactions by date range
  List<TransactionModel> getTransactionsByDateRange(
      String userId,
      DateTime startDate,
      DateTime endDate,
      ) {
    try {
      return _transactionBox.values
          .where((transaction) =>
      transaction.userId == userId &&
          transaction.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          transaction.date.isBefore(endDate.add(const Duration(days: 1))))
          .toList();
    } catch (e) {
      print('Error getting transactions by date range: $e');
      return [];
    }
  }

  /// Get transactions by type (income/expense)
  List<TransactionModel> getTransactionsByType(
      String userId,
      TransactionType type,
      ) {
    try {
      return _transactionBox.values
          .where((transaction) =>
      transaction.userId == userId && transaction.type == type)
          .toList();
    } catch (e) {
      print('Error getting transactions by type: $e');
      return [];
    }
  }

  /// Get transactions by category
  List<TransactionModel> getTransactionsByCategory(
      String userId,
      String category,
      ) {
    try {
      return _transactionBox.values
          .where((transaction) =>
      transaction.userId == userId && transaction.category == category)
          .toList();
    } catch (e) {
      print('Error getting transactions by category: $e');
      return [];
    }
  }

  /// Get unsynced transactions
  List<TransactionModel> getUnsyncedTransactions(String userId) {
    try {
      return _transactionBox.values
          .where((transaction) =>
      transaction.userId == userId && !transaction.isSynced)
          .toList();
    } catch (e) {
      print('Error getting unsynced transactions: $e');
      return [];
    }
  }

  /// Update transaction
  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      await _transactionBox.put(transaction.id, transaction);
    } catch (e) {
      print('Error updating transaction: $e');
      rethrow;
    }
  }

  /// Delete transaction
  Future<void> deleteTransaction(String id) async {
    try {
      await _transactionBox.delete(id);
    } catch (e) {
      print('Error deleting transaction: $e');
      rethrow;
    }
  }

  /// Delete all transactions for a user
  Future<void> deleteAllTransactions(String userId) async {
    try {
      final transactions = getTransactionsByUserId(userId);
      for (var transaction in transactions) {
        await _transactionBox.delete(transaction.id);
      }
    } catch (e) {
      print('Error deleting all transactions: $e');
      rethrow;
    }
  }

  /// Mark transaction as synced
  Future<void> markTransactionAsSynced(String id) async {
    try {
      final transaction = getTransactionById(id);
      if (transaction != null) {
        final syncedTransaction = transaction.markAsSynced();
        await updateTransaction(syncedTransaction);
      }
    } catch (e) {
      print('Error marking transaction as synced: $e');
      rethrow;
    }
  }

  // ==================== SETTINGS OPERATIONS ====================

  /// Save theme mode (dark/light)
  Future<void> saveThemeMode(bool isDarkMode) async {
    try {
      await _settingsBox.put('is_dark_mode', isDarkMode);
    } catch (e) {
      print('Error saving theme mode: $e');
      rethrow;
    }
  }

  /// Get theme mode
  bool getThemeMode() {
    try {
      return _settingsBox.get('is_dark_mode', defaultValue: false);
    } catch (e) {
      print('Error getting theme mode: $e');
      return false;
    }
  }

  /// Save last sync time
  Future<void> saveLastSyncTime(DateTime syncTime) async {
    try {
      await _settingsBox.put('last_sync_time', syncTime.toIso8601String());
    } catch (e) {
      print('Error saving last sync time: $e');
      rethrow;
    }
  }

  /// Get last sync time
  DateTime? getLastSyncTime() {
    try {
      final syncTimeString = _settingsBox.get('last_sync_time');
      if (syncTimeString != null) {
        return DateTime.parse(syncTimeString);
      }
      return null;
    } catch (e) {
      print('Error getting last sync time: $e');
      return null;
    }
  }

  /// Save user preference
  Future<void> savePreference(String key, dynamic value) async {
    try {
      await _settingsBox.put(key, value);
    } catch (e) {
      print('Error saving preference: $e');
      rethrow;
    }
  }

  /// Get user preference
  T? getPreference<T>(String key, {T? defaultValue}) {
    try {
      return _settingsBox.get(key, defaultValue: defaultValue) as T?;
    } catch (e) {
      print('Error getting preference: $e');
      return defaultValue;
    }
  }

  // ==================== UTILITY OPERATIONS ====================

  /// Clear all data (for logout)
  Future<void> clearAllData() async {
    try {
      await _userBox.clear();
      await _transactionBox.clear();
      // Don't clear settings box to preserve theme preference
    } catch (e) {
      print('Error clearing all data: $e');
      rethrow;
    }
  }

  /// Get total transaction count
  int getTransactionCount(String userId) {
    try {
      return getTransactionsByUserId(userId).length;
    } catch (e) {
      print('Error getting transaction count: $e');
      return 0;
    }
  }

  /// Check if data exists for user
  bool hasUserData(String userId) {
    try {
      return getTransactionCount(userId) > 0;
    } catch (e) {
      print('Error checking user data: $e');
      return false;
    }
  }

  /// Close all boxes
  Future<void> close() async {
    try {
      await _userBox.close();
      await _transactionBox.close();
      await _settingsBox.close();
    } catch (e) {
      print('Error closing boxes: $e');
      rethrow;
    }
  }
}