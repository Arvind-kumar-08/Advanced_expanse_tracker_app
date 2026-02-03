import 'package:connectivity_plus/connectivity_plus.dart';
import '../data/repositories/transaction_repository.dart';

/// Service for handling offline/online sync
class SyncService {
  final TransactionRepository _transactionRepository;
  final Connectivity _connectivity;

  SyncService({
    required TransactionRepository transactionRepository,
    Connectivity? connectivity,
  })  : _transactionRepository = transactionRepository,
        _connectivity = connectivity ?? Connectivity();

  /// Check if device is online
  Future<bool> isOnline() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      print('Error checking connectivity: $e');
      return false;
    }
  }

  /// Listen to connectivity changes
  Stream<ConnectivityResult> get connectivityStream {
    return _connectivity.onConnectivityChanged;
  }

  /// Perform sync if online
  Future<bool> syncIfOnline(String userId) async {
    try {
      final online = await isOnline();
      if (!online) {
        print('Device is offline, skipping sync');
        return false;
      }

      await _transactionRepository.fullSync(userId);
      print('Sync completed successfully');
      return true;
    } catch (e) {
      print('Sync failed: $e');
      return false;
    }
  }

  /// Auto-sync on connectivity change
  void setupAutoSync(String userId) {
    connectivityStream.listen((result) {
      if (result != ConnectivityResult.none) {
        print('Device came online, starting auto-sync');
        syncIfOnline(userId);
      }
    });
  }
}