import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../models/budget.dart';
import '../../../models/category.dart';
import '../data/budget_repository.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(ref.watch(databaseProvider));
});

final activeBudgetsProvider = FutureProvider<List<Budget>>((ref) async {
  final repo = ref.watch(budgetRepositoryProvider);
  return repo.getActiveBudgets();
});

final expenseCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.watch(budgetRepositoryProvider);
  return repo.getExpenseCategories();
});

/// Returns a map of budgetId → spent amount
final budgetSpentProvider = FutureProvider.family<double, Budget>((
  ref,
  budget,
) async {
  final repo = ref.watch(budgetRepositoryProvider);
  return repo.getSpent(budget);
});
