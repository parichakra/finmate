import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/budget.dart';
import '../../../models/category.dart';
import '../providers/budget_providers.dart';

class CreateBudgetScreen extends ConsumerStatefulWidget {
  /// Pass an existing budget to enter edit mode. Null = create mode.
  final Budget? budget;

  const CreateBudgetScreen({super.key, this.budget});

  bool get isEditing => budget != null;

  @override
  ConsumerState<CreateBudgetScreen> createState() => _CreateBudgetScreenState();
}

class _CreateBudgetScreenState extends ConsumerState<CreateBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  Category? _selectedCategory;
  bool _isLoading = false;

  /// The category id to pre-select when the categories list loads.
  /// Only relevant in edit mode.
  int? _preselectedCategoryId;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      final b = widget.budget!;
      _nameController.text = b.name;
      _amountController.text = b.amount.toString();
      _preselectedCategoryId = b.categoryId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(budgetRepositoryProvider);

      if (widget.isEditing) {
        // ── UPDATE ──
        final original = widget.budget!;
        final updated = Budget(
          id: original.id,
          name: _nameController.text.trim(),
          amount: double.parse(_amountController.text.trim()),
          period: original.period,
          startDate: original.startDate,
          endDate: original.endDate,
          categoryId: _selectedCategory?.id,
          isActive: original.isActive,
          createdAt: original.createdAt,
          updatedAt: DateTime.now(),
        );
        await repo.updateBudget(updated);
      } else {
        // ── CREATE ──
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        final budget = Budget(
          name: _nameController.text.trim(),
          amount: double.parse(_amountController.text.trim()),
          period: 'monthly',
          startDate: startOfMonth,
          categoryId: _selectedCategory?.id,
        );
        await repo.createBudget(budget);
      }

      ref.invalidate(activeBudgetsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing
                  ? 'Budget updated successfully'
                  : 'Budget created successfully',
            ),
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
    final categoriesAsync = ref.watch(expenseCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Budget' : 'Create Budget'),
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
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Budget Name',
                hintText: 'e.g. Monthly Budget, Food Budget',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

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
                if (amount == null || amount <= 0) return 'Enter valid amount';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Category (Overall or specific)
            categoriesAsync.when(
              data: (categories) {
                // Pre-select category when list first loads in edit mode.
                if (_selectedCategory == null &&
                    _preselectedCategoryId != null) {
                  final match = categories
                      .where((c) => c.id == _preselectedCategoryId)
                      .firstOrNull;
                  if (match != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _selectedCategory = match);
                    });
                  }
                }
                return DropdownButtonFormField<Category?>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category (optional)',
                    helperText: 'Leave empty for overall monthly budget',
                  ),
                  items: [
                    const DropdownMenuItem<Category?>(
                      value: null,
                      child: Text('Overall (All Expenses)'),
                    ),
                    ...categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat.name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedCategory = value);
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 24),

            if (!widget.isEditing)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'This will create a monthly budget starting from the 1st of the current month.',
                  style: TextStyle(color: Color(0xFF0A0A0A)),
                ),
              ),
            const SizedBox(height: 32),

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
                    : Text(
                        widget.isEditing ? 'Save Changes' : 'Create Budget',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF0A0A0A),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
