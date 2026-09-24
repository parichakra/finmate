import '../../../core/database/database_helper.dart';
import '../../../models/transaction.dart';
import '../../../models/category.dart';

class TransactionRepository {
  final DatabaseHelper _db;

  TransactionRepository(this._db);

  Future<int> addTransaction(Transaction transaction) async {
    return await _db.insertTransaction(transaction);
  }

  Future<List<Transaction>> getAllTransactions() async {
    return await _db.getAllTransactions();
  }

  Future<int> updateTransaction(Transaction transaction) async {
    return await _db.updateTransaction(transaction);
  }

  Future<int> deleteTransaction(int id) async {
    return await _db.softDeleteTransaction(id);
  }

  Future<List<Category>> getCategoriesForType(String type) async {
    return await _db.getCategoriesByType(type);
  }

  Future<Map<String, double>> getMonthlySummary() async {
    return await _db.getMonthlySummary();
  }

  Future<List<Transaction>> getRecentTransactions({int limit = 5}) async {
    return await _db.getRecentTransactions(limit: limit);
  }

  Future<Map<int, double>> getDailyExpensesThisMonth() async {
    return await _db.getDailyExpensesThisMonth();
  }

  Future<List<Map<String, dynamic>>> getExpensesByCategoryThisMonth() async {
    return await _db.getExpensesByCategoryThisMonth();
  }
}
