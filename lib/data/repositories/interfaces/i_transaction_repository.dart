import '../../models/transaction_model.dart';

/// Repository interface for transaction data.
// TODO: Add a FirebaseTransactionRepository implementation for cloud sync.
abstract class ITransactionRepository {
  Future<TransactionModel?> getTransaction(int id);
  Future<List<TransactionModel>> getTransactionsByDailyFloat(int dailyFloatId);
  Future<List<TransactionModel>> getTransactionsByStore(int storeId);
  Future<List<TransactionModel>> getTransactionsByStoreAndDate(
    int storeId,
    String date,
  );
  Future<List<TransactionModel>> getFlaggedTransactions(int storeId);
  Future<int> createTransaction(TransactionModel transaction);
  Future<void> updateTransaction(TransactionModel transaction);
  Future<void> flagTransaction(int id, String reason);
  Future<void> unflagTransaction(int id);

  /// Aggregate totals for a given daily_float_id.
  Future<Map<String, int>> getDailyTotals(int dailyFloatId);

  /// Find an existing transaction with the same composite key.
  /// Returns the first match or null if no duplicate exists.
  Future<TransactionModel?> findDuplicate({
    required int storeId,
    required String referenceNumber,
    required int amount,
    required String transactionType,
  });
}
