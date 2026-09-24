import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../providers/dashboard_providers.dart';

class CategoryPieChart extends ConsumerWidget {
  const CategoryPieChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryAsync = ref.watch(expensesByCategoryProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spending by Category',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            categoryAsync.when(
              data: (data) {
                if (data.isEmpty) {
                  return const SizedBox(
                    height: 180,
                    child: Center(
                      child: Text(
                        'No expenses this month',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                final total = data.fold<double>(
                  0,
                  (sum, item) =>
                      sum + ((item['total'] as num?)?.toDouble() ?? 0),
                );

                return Column(
                  children: [
                    SizedBox(
                      height: 180,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: data.asMap().entries.map((entry) {
                            final item = entry.value;
                            final value =
                                (item['total'] as num?)?.toDouble() ?? 0;
                            final percentage = total > 0
                                ? (value / total) * 100
                                : 0;

                            // Parse color from hex or fallback
                            Color color = AppTheme.expense;
                            final colorStr = item['category_color'] as String?;
                            if (colorStr != null && colorStr.startsWith('#')) {
                              try {
                                color = Color(
                                  int.parse(colorStr.replaceFirst('#', '0xFF')),
                                );
                              } catch (_) {}
                            }

                            return PieChartSectionData(
                              value: value,
                              title: percentage >= 8
                                  ? '${percentage.toStringAsFixed(0)}%'
                                  : '',
                              color: color,
                              radius: 50,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Legend
                    ...data.map((item) {
                      final name =
                          item['category_name'] as String? ?? 'Unknown';
                      final value = (item['total'] as num?)?.toDouble() ?? 0;
                      Color color = AppTheme.expense;
                      final colorStr = item['category_color'] as String?;
                      if (colorStr != null && colorStr.startsWith('#')) {
                        try {
                          color = Color(
                            int.parse(colorStr.replaceFirst('#', '0xFF')),
                          );
                        } catch (_) {}
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(name)),
                            Text(
                              Formatters.currency(value),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
              loading: () => const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }
}
