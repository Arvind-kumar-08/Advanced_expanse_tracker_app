import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/transaction_model.dart';
import '../../models/user_model.dart';

/// Remote data source for Cloud Firestore
class FirestoreDataSource {
  final FirebaseFirestore _firestore;

  FirestoreDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Collection names
  static const String _usersCollection = 'users';
  static const String _transactionsCollection = 'transactions';

  // ==================== USER OPERATIONS ====================

  /// Save user to Firestore
  Future<void> saveUser(UserModel user) async {
    try {
      await _firestore.collection(_usersCollection).doc(user.uid).set(
        user.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('Failed to save user: ${e.toString()}');
    }
  }

  /// Get user from Firestore
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(userId).get();

      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: ${e.toString()}');
    }
  }

  /// Delete user from Firestore
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete user: ${e.toString()}');
    }
  }

  // ==================== TRANSACTION OPERATIONS ====================

  /// Save transaction to Firestore
  Future<void> saveTransaction(TransactionModel transaction) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(transaction.userId)
          .collection(_transactionsCollection)
          .doc(transaction.id)
          .set(transaction.toMap());
    } catch (e) {
      throw Exception('Failed to save transaction: ${e.toString()}');
    }
  }

  /// Save multiple transactions (batch write)
  Future<void> saveTransactions(List<TransactionModel> transactions) async {
    try {
      final batch = _firestore.batch();

      for (var transaction in transactions) {
        final docRef = _firestore
            .collection(_usersCollection)
            .doc(transaction.userId)
            .collection(_transactionsCollection)
            .doc(transaction.id);

        batch.set(docRef, transaction.toMap());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to save transactions: ${e.toString()}');
    }
  }

  /// Get all transactions for a user
  Future<List<TransactionModel>> getAllTransactions(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_transactionsCollection)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get transactions: ${e.toString()}');
    }
  }

  /// Get transaction by ID
  Future<TransactionModel?> getTransactionById(
      String userId,
      String transactionId,
      ) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_transactionsCollection)
          .doc(transactionId)
          .get();

      if (doc.exists && doc.data() != null) {
        return TransactionModel.fromMap(doc.data()!);
      }
      return null;
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
      final snapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_transactionsCollection)
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data()))
          .toList();
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
      final typeString = type.toString().split('.').last;
      final snapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_transactionsCollection)
          .where('type', isEqualTo: typeString)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get transactions by type: ${e.toString()}');
    }
  }

  /// Stream of transactions (real-time updates)
  Stream<List<TransactionModel>> getTransactionsStream(String userId) {
    try {
      return _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_transactionsCollection)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data()))
          .toList());
    } catch (e) {
      throw Exception('Failed to get transactions stream: ${e.toString()}');
    }
  }

  /// Update transaction
  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(transaction.userId)
          .collection(_transactionsCollection)
          .doc(transaction.id)
          .update(transaction.toMap());
    } catch (e) {
      throw Exception('Failed to update transaction: ${e.toString()}');
    }
  }

  /// Delete transaction
  Future<void> deleteTransaction(String userId, String transactionId) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_transactionsCollection)
          .doc(transactionId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete transaction: ${e.toString()}');
    }
  }

  /// Delete all transactions for a user
  Future<void> deleteAllTransactions(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_transactionsCollection)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete all transactions: ${e.toString()}');
    }
  }

  /// Get transactions after a specific date (for sync)
  Future<List<TransactionModel>> getTransactionsAfterDate(
      String userId,
      DateTime date,
      ) async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_transactionsCollection)
          .where('updatedAt', isGreaterThan: date.toIso8601String())
          .get();

      return snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get transactions after date: ${e.toString()}');
    }
  }
}