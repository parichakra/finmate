import '../../../core/database/database_helper.dart';
import '../../../models/budget.dart';
import '../../../models/category.dart';

class BudgetRepository {
  final DatabaseHelper _db;

  BudgetRepository(this._db);

  Future<int> createBudget(Budget budget) async {
    return await _db.insertBudget(budget);
  }

  Future<List<Budget>> getActiveBudgets() async {
    return await _db.getActiveBudgets();
  }

  Future<int> updateBudget(Budget budget) async {
    return await _db.updateBudget(budget);
  }

  Future<int> deactivateBudget(int id) async {
    return await _db.deactivateBudget(id);
  }

  Future<double> getSpent(Budget budget) async {
    return await _db.getSpentForBudget(budget);
  }

  Future<List<Category>> getExpenseCategories() async {
    return await _db.getCategoriesByType('expense');
  }
}
