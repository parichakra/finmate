import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/group.dart';
import '../../../models/group_member.dart';
import '../../../models/settlement.dart';
import '../providers/group_providers.dart';

class GroupDetailScreen extends ConsumerWidget {
  final int groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  /// Resolves the current group from the cached provider list.
  Group? _currentGroup(List<Group> groups) =>
      groups.where((g) => g.id == groupId).firstOrNull;

  Future<void> _editGroup(
    BuildContext context,
    WidgetRef ref,
    Group group,
  ) async {
    await context.push('/groups/${group.id}/edit', extra: group);
    // Refresh group name in AppBar after possible update
    ref.invalidate(groupsProvider);
  }

  Future<void> _deleteGroup(
    BuildContext context,
    WidgetRef ref,
    Group group,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Group?'),
        content: Text(
          'Delete "${group.name}"? This will permanently remove all expenses '
          'and settlements in this group. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repo = ref.read(groupRepositoryProvider);
      await repo.deleteGroup(groupId);
      ref.invalidate(groupsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${group.name}" deleted')),
        );
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupsProvider);
    ref.watch(groupMembersProvider(groupId)); // keeps member data warm
    final expensesAsync = ref.watch(sharedExpensesProvider(groupId));
    ref.watch(groupBalancesProvider(groupId)); // keeps balance data warm
    final settlementsAsync = ref.watch(groupSettlementsProvider(groupId));

    return Scaffold(
      appBar: AppBar(
        title: groupAsync.when(
          data: (groups) {
            final group = _currentGroup(groups);
            return Text(group?.name ?? 'Group');
          },
          loading: () => const Text('Group'),
          error: (_, __) => const Text('Group'),
        ),
        actions: [
          groupAsync.when(
            data: (groups) {
              final group = _currentGroup(groups);
              if (group == null) return const SizedBox.shrink();
              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _editGroup(context, ref, group);
                  } else if (value == 'delete') {
                    _deleteGroup(context, ref, group);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Edit Group'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline, color: Colors.red),
                      title: Text(
                        'Delete Group',
                        style: TextStyle(color: Colors.red),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(groupMembersProvider(groupId));
          ref.invalidate(sharedExpensesProvider(groupId));
          ref.invalidate(groupBalancesProvider(groupId));
          ref.invalidate(groupSettlementsProvider(groupId));
          ref.invalidate(simplifiedBalancesProvider(groupId));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ========== BALANCES ==========
            // ========== BALANCES ==========
            const Text(
              'Balances',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            ref
                .watch(simplifiedBalancesProvider(groupId))
                .when(
                  data: (items) {
                    if (items.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green.shade600,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'You are all settled up in this group',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: items.map((item) {
                        final member = item['member'] as GroupMember;
                        final amount = item['amount'] as double;
                        final type = item['type'] as String;
                        final isOwesYou = type == 'owes_you';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  (isOwesYou
                                          ? AppTheme.income
                                          : AppTheme.expense)
                                      .withOpacity(0.15),
                              child: Text(
                                member.name[0].toUpperCase(),
                                style: TextStyle(
                                  color: isOwesYou
                                      ? AppTheme.income
                                      : AppTheme.expense,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              member.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: Text(
                              isOwesYou
                                  ? 'owes you ${Formatters.currency(amount)}'
                                  : 'you owe ${Formatters.currency(amount)}',
                              style: TextStyle(
                                color: isOwesYou
                                    ? AppTheme.income
                                    : AppTheme.expense,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                ),

            const SizedBox(height: 24),

            // ========== QUICK ACTIONS ==========
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/groups/$groupId/add-expense');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Expense'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.expense,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.push('/groups/$groupId/settle');
                    },
                    icon: const Icon(Icons.handshake),
                    label: const Text('Settle Up'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ========== EXPENSES ==========
            const Text(
              'Expenses',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            expensesAsync.when(
              data: (expenses) {
                if (expenses.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No expenses yet.\nAdd the first shared expense!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: expenses.map((expense) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          expense.description,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${expense.paidByName ?? 'Someone'} paid • ${DateFormat('dd MMM').format(expense.date)}',
                        ),
                        trailing: Text(
                          Formatters.currency(expense.totalAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),

            const SizedBox(height: 32),

            // ========== SETTLEMENT HISTORY ==========
            const Text(
              'Settlement History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            settlementsAsync.when(
              data: (settlements) {
                if (settlements.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No settlements yet.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: settlements.map((settlement) {
                    return _SettlementTile(settlement: settlement);
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ==================== WIDGETS ====================

class _BalanceTile extends StatelessWidget {
  final GroupMember member;
  final double balance;

  const _BalanceTile({required this.member, required this.balance});

  @override
  Widget build(BuildContext context) {
    final isPositive = balance > 0.01;
    final isNegative = balance < -0.01;
    final isSettled = !isPositive && !isNegative;

    Color color;
    String text;

    if (isSettled) {
      color = Colors.grey;
      text = 'settled up';
    } else if (isPositive) {
      color = AppTheme.income;
      text = member.isYou
          ? 'you are owed ${Formatters.currency(balance)}'
          : 'owes you ${Formatters.currency(balance)}';
    } else {
      color = AppTheme.expense;
      text = member.isYou
          ? 'you owe ${Formatters.currency(balance.abs())}'
          : 'you owe ${Formatters.currency(balance.abs())}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Text(
            member.name[0].toUpperCase(),
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          member.isYou ? 'You' : member.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _SettlementTile extends StatelessWidget {
  final Settlement settlement;

  const _SettlementTile({required this.settlement});

  @override
  Widget build(BuildContext context) {
    final fromName = settlement.fromMemberName ?? 'Someone';
    final toName = settlement.toMemberName ?? 'Someone';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withOpacity(0.15),
          child: const Icon(Icons.handshake, color: AppTheme.primary, size: 20),
        ),
        title: Text(
          '$fromName paid $toName',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          DateFormat('dd MMM yyyy').format(settlement.date) +
              (settlement.notes != null ? ' • ${settlement.notes}' : ''),
        ),
        trailing: Text(
          Formatters.currency(settlement.amount),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: AppTheme.primary,
          ),
        ),
      ),
    );
  }
}
