import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';

/// Provider for transaction state management
class TransactionProvider with ChangeNotifier {
  final TransactionRepository _transactionRepository;
  final String userId;

  TransactionProvider({
    required TransactionRepository transactionRepository,
    required this.userId,
  }) : _transactionRepository = transactionRepository {
    loadTransactions();
  }

  // State variables
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSyncing = false;

  // Getters
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSyncing => _isSyncing;

  /// Get recent transactions (last 10)
  List<TransactionModel> get recentTransactions {
    final sorted = List<TransactionModel>.from(_transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(10).toList();
  }

  /// Get income transactions
  List<TransactionModel> get incomeTransactions {
    return _transactions
        .where((t) => t.type == TransactionType.income)
        .toList();
  }

  /// Get expense transactions
  List<TransactionModel> get expenseTransactions {
    return _transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();
  }

  /// Calculate total income
  double get totalIncome {
    return incomeTransactions.fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Calculate total expense
  double get totalExpense {
    return expenseTransactions.fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Calculate balance
  double get balance => totalIncome - totalExpense;

  /// Get category-wise expense data
  Map<String, double> get categoryWiseExpenses {
    final Map<String, double> categoryTotals = {};

    for (var transaction in expenseTransactions) {
      categoryTotals[transaction.category] =
          (categoryTotals[transaction.category] ?? 0) + transaction.amount;
    }

    return categoryTotals;
  }

  /// Get category-wise income data
  Map<String, double> get categoryWiseIncome {
    final Map<String, double> categoryTotals = {};

    for (var transaction in incomeTransactions) {
      categoryTotals[transaction.category] =
          (categoryTotals[transaction.category] ?? 0) + transaction.amount;
    }

    return categoryTotals;
  }

  /// Load all transactions
  Future<void> loadTransactions() async {
    _setLoading(true);
    _clearError();

    try {
      _transactions = await _transactionRepository.getAllTransactions(userId);
      _transactions.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      _setError('Failed to load transactions: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Add new transaction
  Future<bool> addTransaction({
    required double amount,
    required String category,
    required TransactionType type,
    required DateTime date,
    String? note,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final transaction = TransactionModel.create(
        id: const Uuid().v4(),
        userId: userId,
        amount: amount,
        category: category,
        type: type,
        date: date,
        note: note,
      );

      await _transactionRepository.addTransaction(transaction);

      // Add to local list
      _transactions.add(transaction);
      _transactions.sort((a, b) => b.date.compareTo(a.date));

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to add transaction: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Update transaction
  Future<bool> updateTransaction({
    required String id,
    required double amount,
    required String category,
    required TransactionType type,
    required DateTime date,
    String? note,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final index = _transactions.indexWhere((t) => t.id == id);
      if (index == -1) {
        throw Exception('Transaction not found');
      }

      final oldTransaction = _transactions[index];
      final updatedTransaction = oldTransaction.copyWith(
        amount: amount,
        category: category,
        type: type,
        date: date,
        note: note,
        updatedAt: DateTime.now(),
      );

      await _transactionRepository.updateTransaction(updatedTransaction);

      // Update local list
      _transactions[index] = updatedTransaction;
      _transactions.sort((a, b) => b.date.compareTo(a.date));

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update transaction: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Delete transaction
  Future<bool> deleteTransaction(String id) async {
    _setLoading(true);
    _clearError();

    try {
      await _transactionRepository.deleteTransaction(userId, id);

      // Remove from local list
      _transactions.removeWhere((t) => t.id == id);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete transaction: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Get transactions for a specific month
  List<TransactionModel> getTransactionsForMonth(int year, int month) {
    return _transactions.where((t) {
      return t.date.year == year && t.date.month == month;
    }).toList();
  }

  /// Get transactions by category
  List<TransactionModel> getTransactionsByCategory(String category) {
    return _transactions.where((t) => t.category == category).toList();
  }

  /// Get monthly trend data (last N months)
  Map<String, Map<String, double>> getMonthlyTrend(int monthCount) {
    final Map<String, Map<String, double>> monthlyData = {};
    final now = DateTime.now();

    for (int i = 0; i < monthCount; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthTransactions = getTransactionsForMonth(month.year, month.month);

      final income = monthTransactions
          .where((t) => t.type == TransactionType.income)
          .fold(0.0, (sum, t) => sum + t.amount);

      final expense = monthTransactions
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount);

      final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      monthlyData[monthKey] = {
        'income': income,
        'expense': expense,
      };
    }

    return monthlyData;
  }

  /// Sync data with cloud
  Future<bool> syncData() async {
    if (_isSyncing) return false;

    _isSyncing = true;
    _clearError();
    notifyListeners();

    try {
      await _transactionRepository.fullSync(userId);

      // Reload transactions after sync
      await loadTransactions();

      _isSyncing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Sync failed: ${e.toString()}');
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  /// Get last sync time
  DateTime? getLastSyncTime() {
    return _transactionRepository.getLastSyncTime();
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Clear error message manually
  void clearError() {
    _clearError();
    notifyListeners();
  }

  /// Refresh transactions
  Future<void> refresh() async {
    await loadTransactions();
  }
  /// Get transaction by ID
  Future<TransactionModel?> getTransactionById(String id) async {
    try {
      return await _transactionRepository.getTransactionById(id);
    } catch (e) {
      _setError('Failed to get transaction: ${e.toString()}');
      return null;
    }
  }

}