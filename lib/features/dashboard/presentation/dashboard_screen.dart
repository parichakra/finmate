import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/transaction.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../providers/dashboard_providers.dart';
import 'widgets/daily_spending_chart.dart';
import 'widgets/category_pie_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(monthlySummaryProvider);
    final recentAsync = ref.watch(recentTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FinMate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(monthlySummaryProvider);
          ref.invalidate(recentTransactionsProvider);
          ref.invalidate(dailyExpensesProvider);
          ref.invalidate(expensesByCategoryProvider);
          ref.invalidate(transactionsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ========== SUMMARY CARDS ==========
            summaryAsync.when(
              data: (summary) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            title: 'Income',
                            amount: Formatters.currency(summary['income'] ?? 0),
                            color: AppTheme.income,
                            icon: Icons.arrow_downward_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            title: 'Expenses',
                            amount: Formatters.currency(
                              summary['expense'] ?? 0,
                            ),
                            color: AppTheme.expense,
                            icon: Icons.arrow_upward_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SummaryCard(
                      title: 'Net Balance',
                      amount: Formatters.currency(summary['net'] ?? 0),
                      color: AppTheme.primary,
                      icon: Icons.account_balance_wallet_outlined,
                      isFullWidth: true,
                    ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Text('Error loading summary: $err'),
            ),

            const SizedBox(height: 24),

            // ========== QUICK ACTIONS ==========
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    label: 'Add Income',
                    icon: Icons.add_circle_outline,
                    color: AppTheme.income,
                    onTap: () => context.pushNamed(
                      'add-transaction',
                      queryParameters: {'type': 'income'},
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionButton(
                    label: 'Add Expense',
                    icon: Icons.remove_circle_outline,
                    color: AppTheme.expense,
                    onTap: () => context.pushNamed(
                      'add-transaction',
                      queryParameters: {'type': 'expense'},
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ========== RECENT TRANSACTIONS ==========
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                TextButton(
                  onPressed: () => context.goNamed('transactions'),
                  child: const Text('See All'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            recentAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No transactions yet.\nAdd your first income or expense!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: transactions.map((tx) {
                    return _RecentTransactionTile(transaction: tx);
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error: $err'),
            ),
            const SizedBox(height: 24),

            // ========== CHARTS ==========
            const DailySpendingChart(),
            const SizedBox(height: 16),
            const CategoryPieChart(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ==================== WIDGETS ====================

class _SummaryCard extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;
  final IconData icon;
  final bool isFullWidth;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: TextStyle(
                fontSize: isFullWidth ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentTransactionTile extends StatelessWidget {
  final Transaction transaction;

  const _RecentTransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final color = isIncome ? AppTheme.income : AppTheme.expense;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: color,
            size: 18,
          ),
        ),
        title: Text(
          transaction.description?.isNotEmpty == true
              ? transaction.description!
              : (isIncome ? 'Income' : 'Expense'),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          DateFormat('dd MMM').format(transaction.date),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Text(
          '${isIncome ? '+' : '-'}${Formatters.currency(transaction.amount)}',
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }
}
