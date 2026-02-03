import '../datasources/local/hive_datasources.dart';
import '../datasources/remote/firestore_datasource.dart';
import '../models/user_model.dart';

/// Repository for user profile operations
class UserRepository {
  final HiveDataSource _hiveDataSource;
  final FirestoreDataSource _firestoreDataSource;

  UserRepository({
    required HiveDataSource hiveDataSource,
    required FirestoreDataSource firestoreDataSource,
  })  : _hiveDataSource = hiveDataSource,
        _firestoreDataSource = firestoreDataSource;

  /// Get current user
  Future<UserModel?> getCurrentUser() async {
    try {
      return _hiveDataSource.getCurrentUser();
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  /// Save user
  Future<void> saveUser(UserModel user) async {
    try {
      // Save locally
      await _hiveDataSource.saveUser(user);

      // Sync to cloud
      try {
        await _firestoreDataSource.saveUser(user);
      } catch (e) {
        print('Failed to sync user to cloud: $e');
      }
    } catch (e) {
      throw Exception('Failed to save user: ${e.toString()}');
    }
  }

  /// Update user
  Future<void> updateUser(UserModel user) async {
    try {
      await saveUser(user);
    } catch (e) {
      throw Exception('Failed to update user: ${e.toString()}');
    }
  }

  /// Delete user
  Future<void> deleteUser() async {
    try {
      await _hiveDataSource.deleteUser();
    } catch (e) {
      throw Exception('Failed to delete user: ${e.toString()}');
    }
  }

  /// Sync user from cloud
  Future<void> syncUserFromCloud(String userId) async {
    try {
      final user = await _firestoreDataSource.getUser(userId);
      if (user != null) {
        await _hiveDataSource.saveUser(user);
      }
    } catch (e) {
      throw Exception('Failed to sync user from cloud: ${e.toString()}');
    }
  }

  /// Update last synced time
  Future<void> updateLastSyncTime(DateTime syncTime) async {
    try {
      await _hiveDataSource.updateUserSyncTime(syncTime);
    } catch (e) {
      throw Exception('Failed to update sync time: ${e.toString()}');
    }
  }
}