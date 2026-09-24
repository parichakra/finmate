import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../models/transaction.dart';
import '../../../models/category.dart';
import '../data/transaction_repository.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return TransactionRepository(db);
});

// All transactions
final transactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getAllTransactions();
});

// Categories based on type (income / expense)
final categoriesByTypeProvider = FutureProvider.family<List<Category>, String>((
  ref,
  type,
) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getCategoriesForType(type);
});
