import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/group_member.dart';
import '../providers/group_providers.dart';

class SettleUpScreen extends ConsumerStatefulWidget {
  final int groupId;

  const SettleUpScreen({super.key, required this.groupId});

  @override
  ConsumerState<SettleUpScreen> createState() => _SettleUpScreenState();
}

class _SettleUpScreenState extends ConsumerState<SettleUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  GroupMember? _fromMember;
  GroupMember? _toMember;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fromMember == null || _toMember == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both members')),
      );
      return;
    }

    if (_fromMember!.id == _toMember!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('From and To cannot be the same person')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(groupRepositoryProvider);

      await repo.addSettlement(
        groupId: widget.groupId,
        fromMemberId: _fromMember!.id!,
        toMemberId: _toMember!.id!,
        amount: double.parse(_amountController.text.trim()),
        date: _selectedDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      // Refresh all related data
      ref.invalidate(groupBalancesProvider(widget.groupId));
      ref.invalidate(groupSettlementsProvider(widget.groupId));
      ref.invalidate(sharedExpensesProvider(widget.groupId));
      ref.invalidate(groupsProvider);

      // Also refresh personal transactions (because settlement may create income/expense)
      // You can invalidate transactionsProvider if you have it imported

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settlement recorded successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(groupMembersProvider(widget.groupId));
    final balancesAsync = ref.watch(groupBalancesProvider(widget.groupId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settle Up'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Current Balances Summary
            balancesAsync.when(
              data: (balances) {
                return membersAsync.when(
                  data: (members) {
                    final nonZeroBalances = members.where((m) {
                      final bal = balances[m.id] ?? 0;
                      return bal.abs() > 0.01;
                    }).toList();

                    if (nonZeroBalances.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 12),
                            Text('Everyone is settled up!'),
                          ],
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Balances',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...nonZeroBalances.map((member) {
                          final balance = balances[member.id] ?? 0;
                          final isPositive = balance > 0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(member.isYou ? 'You' : member.name),
                                Text(
                                  isPositive
                                      ? 'is owed ${Formatters.currency(balance)}'
                                      : 'owes ${Formatters.currency(balance.abs())}',
                                  style: TextStyle(
                                    color: isPositive
                                        ? AppTheme.income
                                        : AppTheme.expense,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const Divider(height: 32),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // From Member
            membersAsync.when(
              data: (members) {
                return DropdownButtonFormField<GroupMember>(
                  value: _fromMember,
                  decoration: const InputDecoration(
                    labelText: 'From (Who is paying)',
                    prefixIcon: Icon(Icons.arrow_upward),
                  ),
                  items: members.map((m) {
                    return DropdownMenuItem(
                      value: m,
                      child: Text(m.isYou ? 'You' : m.name),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _fromMember = value),
                  validator: (v) => v == null ? 'Required' : null,
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 16),

            // To Member
            membersAsync.when(
              data: (members) {
                return DropdownButtonFormField<GroupMember>(
                  value: _toMember,
                  decoration: const InputDecoration(
                    labelText: 'To (Who is receiving)',
                    prefixIcon: Icon(Icons.arrow_downward),
                  ),
                  items: members.map((m) {
                    return DropdownMenuItem(
                      value: m,
                      child: Text(m.isYou ? 'You' : m.name),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _toMember = value),
                  validator: (v) => v == null ? 'Required' : null,
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            // Amount
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: 'रु ',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final amount = double.tryParse(v);
                if (amount == null || amount <= 0) {
                  return 'Enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date'),
              subtitle: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g. Paid via esewa / cash',
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Record Settlement'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
