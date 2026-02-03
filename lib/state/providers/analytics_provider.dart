import 'package:flutter/foundation.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';

/// Provider for analytics and reports
class AnalyticsProvider with ChangeNotifier {
  final TransactionRepository _transactionRepository;
  final String userId;

  AnalyticsProvider({
    required TransactionRepository transactionRepository,
    required this.userId,
  }) : _transactionRepository = transactionRepository;

  // State variables
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, double> _categoryWiseExpenses = {};
  Map<String, double> _categoryWiseIncome = {};
  Map<String, Map<String, double>> _monthlyTrend = {};

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, double> get categoryWiseExpenses => _categoryWiseExpenses;
  Map<String, double> get categoryWiseIncome => _categoryWiseIncome;
  Map<String, Map<String, double>> get monthlyTrend => _monthlyTrend;

  /// Load analytics data
  Future<void> loadAnalytics() async {
    _setLoading(true);
    _clearError();

    try {
      // Load category-wise data
      _categoryWiseExpenses =
      await _transactionRepository.getCategoryWiseExpenses(userId);
      _categoryWiseIncome =
      await _transactionRepository.getCategoryWiseIncome(userId);

      // Load monthly trend (last 6 months)
      _monthlyTrend =
      await _transactionRepository.getMonthlyTrend(userId, 6);
    } catch (e) {
      _setError('Failed to load analytics: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Get expense percentage for a category
  double getCategoryExpensePercentage(String category) {
    final total = _categoryWiseExpenses.values.fold(0.0, (sum, val) => sum + val);
    if (total == 0) return 0;
    return ((_categoryWiseExpenses[category] ?? 0) / total) * 100;
  }

  /// Get income percentage for a category
  double getCategoryIncomePercentage(String category) {
    final total = _categoryWiseIncome.values.fold(0.0, (sum, val) => sum + val);
    if (total == 0) return 0;
    return ((_categoryWiseIncome[category] ?? 0) / total) * 100;
  }

  /// Get top spending categories
  List<MapEntry<String, double>> getTopSpendingCategories({int limit = 5}) {
    final sorted = _categoryWiseExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  /// Get top income categories
  List<MapEntry<String, double>> getTopIncomeCategories({int limit = 5}) {
    final sorted = _categoryWiseIncome.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  /// Get transactions for a specific date range
  Future<List<TransactionModel>> getTransactionsByDateRange(
      DateTime startDate,
      DateTime endDate,
      ) async {
    try {
      return await _transactionRepository.getTransactionsByDateRange(
        userId,
        startDate,
        endDate,
      );
    } catch (e) {
      _setError('Failed to get transactions: ${e.toString()}');
      return [];
    }
  }

  /// Get current month summary
  Future<Map<String, double>> getCurrentMonthSummary() async {
    try {
      final now = DateTime.now();
      final firstDay = DateTime(now.year, now.month, 1);
      final lastDay = DateTime(now.year, now.month + 1, 0);

      final transactions = await getTransactionsByDateRange(firstDay, lastDay);

      final income = transactions
          .where((t) => t.type == TransactionType.income)
          .fold(0.0, (sum, t) => sum + t.amount);

      final expense = transactions
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount);

      return {
        'income': income,
        'expense': expense,
        'balance': income - expense,
      };
    } catch (e) {
      _setError('Failed to get month summary: ${e.toString()}');
      return {'income': 0, 'expense': 0, 'balance': 0};
    }
  }

  /// Refresh analytics data
  Future<void> refresh() async {
    await loadAnalytics();
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
}