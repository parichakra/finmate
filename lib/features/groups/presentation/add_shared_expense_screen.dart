import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/group_member.dart';
import '../providers/group_providers.dart';

class AddSharedExpenseScreen extends ConsumerStatefulWidget {
  final int groupId;

  const AddSharedExpenseScreen({super.key, required this.groupId});

  @override
  ConsumerState<AddSharedExpenseScreen> createState() =>
      _AddSharedExpenseScreenState();
}

class _AddSharedExpenseScreenState
    extends ConsumerState<AddSharedExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  GroupMember? _paidBy;
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_paidBy == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select who paid')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(groupRepositoryProvider);

      await repo.addSharedExpense(
        groupId: widget.groupId,
        description: _descriptionController.text.trim(),
        totalAmount: double.parse(_amountController.text.trim()),
        paidByMemberId: _paidBy!.id!,
        date: _selectedDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      // Refresh data
      ref.invalidate(sharedExpensesProvider(widget.groupId));
      ref.invalidate(groupBalancesProvider(widget.groupId));
      ref.invalidate(groupsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense added successfully')),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Shared Expense'),
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
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'e.g. Dinner, Taxi, Hotel',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Amount
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Total Amount',
                prefixText: 'रु ',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final amount = double.tryParse(v);
                if (amount == null || amount <= 0) return 'Enter valid amount';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Paid By
            membersAsync.when(
              data: (members) {
                // Auto-select "You" if not selected
                if (_paidBy == null && members.isNotEmpty) {
                  final you = members.where((m) => m.isYou).firstOrNull;
                  if (you != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() => _paidBy = you);
                    });
                  }
                }

                return DropdownButtonFormField<GroupMember>(
                  value: _paidBy,
                  decoration: const InputDecoration(labelText: 'Paid by'),
                  items: members.map((m) {
                    return DropdownMenuItem(
                      value: m,
                      child: Text(m.isYou ? 'You' : m.name),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _paidBy = value),
                  validator: (v) => v == null ? 'Please select who paid' : null,
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
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
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            const SizedBox(height: 12),

            // Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'The amount will be split equally among all group members.',
                style: TextStyle(fontSize: 13),
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
                  backgroundColor: AppTheme.expense,
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
                    : const Text('Save Expense'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
