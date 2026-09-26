import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../models/group.dart';
import '../../../models/group_member.dart';
import '../../../models/shared_expense.dart';
import '../../../models/settlement.dart';
import '../data/group_repository.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository(ref.watch(databaseProvider));
});

final groupsProvider = FutureProvider<List<Group>>((ref) async {
  final repo = ref.watch(groupRepositoryProvider);
  return repo.getAllGroups();
});

final groupMembersProvider = FutureProvider.family<List<GroupMember>, int>((
  ref,
  groupId,
) async {
  final repo = ref.watch(groupRepositoryProvider);
  return repo.getMembers(groupId);
});

final sharedExpensesProvider = FutureProvider.family<List<SharedExpense>, int>((
  ref,
  groupId,
) async {
  final repo = ref.watch(groupRepositoryProvider);
  return repo.getSharedExpenses(groupId);
});

final groupBalancesProvider = FutureProvider.family<Map<int, double>, int>((
  ref,
  groupId,
) async {
  final repo = ref.watch(groupRepositoryProvider);
  return repo.getBalances(groupId);
});

final groupSettlementsProvider = FutureProvider.family<List<Settlement>, int>((
  ref,
  groupId,
) async {
  final repo = ref.watch(groupRepositoryProvider);
  return repo.getSettlements(groupId);
});
final simplifiedBalancesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((
      ref,
      groupId,
    ) async {
      final repo = ref.watch(groupRepositoryProvider);
      return repo.getSimplifiedBalances(groupId);
    });
