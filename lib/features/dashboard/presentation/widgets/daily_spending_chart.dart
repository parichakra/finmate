import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../providers/dashboard_providers.dart';

class DailySpendingChart extends ConsumerWidget {
  const DailySpendingChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyAsync = ref.watch(dailyExpensesProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Spending – ${DateFormat('MMMM yyyy').format(DateTime.now())}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: dailyAsync.when(
                data: (dailyData) {
                  if (dailyData.isEmpty) {
                    return const Center(
                      child: Text(
                        'No expenses this month',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  final maxY = dailyData.values.reduce((a, b) => a > b ? a : b);
                  final daysInMonth = DateTime(
                    DateTime.now().year,
                    DateTime.now().month + 1,
                    0,
                  ).day;

                  return BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY * 1.2,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '\$${rod.toY.toStringAsFixed(0)}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final day = value.toInt();
                              if (day % 5 == 0 || day == 1) {
                                return Text(
                                  '$day',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                            reservedSize: 28,
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                      barGroups: List.generate(daysInMonth, (index) {
                        final day = index + 1;
                        final amount = dailyData[day] ?? 0;
                        return BarChartGroupData(
                          x: day,
                          barRods: [
                            BarChartRodData(
                              toY: amount,
                              color: AppTheme.expense,
                              width: 6,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
