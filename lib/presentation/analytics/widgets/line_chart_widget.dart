import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import 'package:intl/intl.dart';

/// Line chart widget for monthly trend visualization
class LineChartWidget extends StatelessWidget {
  final Map<String, Map<String, double>> data;

  const LineChartWidget({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Income', AppColors.income),
              const SizedBox(width: 24),
              _buildLegendItem('Expense', AppColors.expense),
            ],
          ),
          const SizedBox(height: 24),

          // Chart
          AspectRatio(
            aspectRatio: 1.5,
            child: LineChart(
              _buildLineChartData(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 3,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  LineChartData _buildLineChartData(ThemeData theme) {
    final sortedKeys = data.keys.toList()..sort();
    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];

    for (int i = 0; i < sortedKeys.length; i++) {
      final monthData = data[sortedKeys[i]]!;
      incomeSpots.add(FlSpot(i.toDouble(), monthData['income'] ?? 0));
      expenseSpots.add(FlSpot(i.toDouble(), monthData['expense'] ?? 0));
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 1000,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: theme.dividerColor,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < sortedKeys.length) {
                final monthKey = sortedKeys[value.toInt()];
                final parts = monthKey.split('-');
                if (parts.length == 2) {
                  final month = int.parse(parts[1]);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormatter.getShortMonthName(month),
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 42,
            interval: 5000,
            getTitlesWidget: (value, meta) {
              return Text(
                NumberFormat.compact().format(value),
                style: theme.textTheme.bodySmall,
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
          left: BorderSide(color: theme.dividerColor),
        ),
      ),
      minX: 0,
      maxX: (sortedKeys.length - 1).toDouble(),
      minY: 0,
      lineBarsData: [
        // Income Line
        LineChartBarData(
          spots: incomeSpots,
          isCurved: true,
          color: AppColors.income,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.income.withOpacity(0.1),
          ),
        ),
        // Expense Line
        LineChartBarData(
          spots: expenseSpots,
          isCurved: true,
          color: AppColors.expense,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.expense.withOpacity(0.1),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: theme.cardColor,
          tooltipBorder: BorderSide(color: theme.dividerColor),
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((spot) {
              final isIncome = spot.barIndex == 0;
              return LineTooltipItem(
                '${isIncome ? 'Income' : 'Expense'}\n₹${NumberFormat.compact().format(spot.y)}',
                TextStyle(
                  color: isIncome ? AppColors.income : AppColors.expense,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }
}