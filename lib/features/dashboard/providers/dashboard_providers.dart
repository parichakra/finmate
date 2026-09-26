import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/transaction.dart';
import '../../transactions/providers/transaction_providers.dart';

import '../../budgets/providers/budget_providers.dart';

final monthlySummaryProvider = FutureProvider<Map<String, double>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getMonthlySummary();
});

final recentTransactionsProvider = FutureProvider<List<Transaction>>((
  ref,
) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getRecentTransactions(limit: 5);
});

final dailyExpensesProvider = FutureProvider<Map<int, double>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getDailyExpensesThisMonth();
});

final expensesByCategoryProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getExpensesByCategoryThisMonth();
});
// Re-export so dashboard can use it easily
final dashboardBudgetsProvider = activeBudgetsProvider;
