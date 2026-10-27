import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/bill_model.dart';

class ChartDataPoint {
  final String label;
  final int valuePaise;
  final int billCount;
  final DateTime timestamp;

  ChartDataPoint({
    required this.label,
    required this.valuePaise,
    required this.billCount,
    required this.timestamp,
  });
}

class SalesAnalyticsChart extends StatefulWidget {
  final List<BillModel> bills;

  const SalesAnalyticsChart({super.key, required this.bills});

  @override
  State<SalesAnalyticsChart> createState() => _SalesAnalyticsChartState();
}

class _SalesAnalyticsChartState extends State<SalesAnalyticsChart> {
  bool _showTodayOnly = false;
  int? _selectedBarIndex;

  @override
  Widget build(BuildContext context) {
    final dataPoints = _generateDataPoints();
    final totalSales = dataPoints.fold<int>(0, (sum, p) => sum + p.valuePaise);
    final maxVal = dataPoints.isEmpty ? 0 : dataPoints.map((e) => e.valuePaise).reduce(math.max);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Clean Title and Toggle (7 Days vs Today)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _showTodayOnly ? "Today's Trend" : "7 Days Sales",
                    style: AppText.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.formatPaise(totalSales),
                    style: AppText.amountLarge.copyWith(fontSize: 18, color: AppColors.primaryDark),
                  ),
                ],
              ),
              // Clean 2-Option Pill
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: AppRadius.smAll,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleItem(label: '7 Days', isActive: !_showTodayOnly, onTap: () {
                      setState(() {
                        _showTodayOnly = false;
                        _selectedBarIndex = null;
                      });
                    }),
                    _buildToggleItem(label: 'Today', isActive: _showTodayOnly, onTap: () {
                      setState(() {
                        _showTodayOnly = true;
                        _selectedBarIndex = null;
                      });
                    }),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Selected Point Details (if tapped)
          if (_selectedBarIndex != null &&
              _selectedBarIndex! >= 0 &&
              _selectedBarIndex! < dataPoints.length)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${dataPoints[_selectedBarIndex!].label}: ${CurrencyFormatter.formatPaise(dataPoints[_selectedBarIndex!].valuePaise)} (${dataPoints[_selectedBarIndex!].billCount} bills)',
                style: AppText.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // Clean Bar Chart
          SizedBox(
            height: 110,
            child: dataPoints.isEmpty || totalSales == 0
                ? Center(
                    child: Text('No sales recorded yet', style: AppText.caption),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(dataPoints.length, (index) {
                      final point = dataPoints[index];
                      final ratio = maxVal > 0 ? (point.valuePaise / maxVal) : 0.0;
                      final isSelected = _selectedBarIndex == index;

                      return Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() {
                              _selectedBarIndex = (_selectedBarIndex == index) ? null : index;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      height: math.max(6.0, ratio * 85.0),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primaryDark
                                            : point.valuePaise > 0
                                                ? AppColors.primary
                                                : AppColors.divider,
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  point.label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.smAll,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryDark : Colors.transparent,
          borderRadius: AppRadius.smAll,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  List<ChartDataPoint> _generateDataPoints() {
    final now = DateTime.now();

    if (_showTodayOnly) {
      // 5 clean time buckets today
      final List<ChartDataPoint> points = [];
      final intervals = [9, 12, 15, 18, 21];
      for (int i = 0; i < intervals.length; i++) {
        final hour = intervals[i];
        final nextHour = i == intervals.length - 1 ? 24 : intervals[i + 1];
        final label = hour <= 12 ? '${hour}AM' : '${hour - 12}PM';

        final matching = widget.bills.where((b) {
          final isSameDay = b.createdAt.year == now.year &&
              b.createdAt.month == now.month &&
              b.createdAt.day == now.day;
          return isSameDay && b.createdAt.hour >= hour && b.createdAt.hour < nextHour;
        });

        final sum = matching.fold<int>(0, (acc, b) => acc + b.grandTotal);
        points.add(
          ChartDataPoint(
            label: label,
            valuePaise: sum,
            billCount: matching.length,
            timestamp: DateTime(now.year, now.month, now.day, hour),
          ),
        );
      }
      return points;
    } else {
      // Last 7 days
      final List<ChartDataPoint> points = [];
      for (int i = 6; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        final matching = widget.bills.where((b) {
          return b.createdAt.year == d.year &&
              b.createdAt.month == d.month &&
              b.createdAt.day == d.day;
        });

        final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final label = i == 0 ? 'Today' : dayNames[d.weekday - 1];
        final sum = matching.fold<int>(0, (acc, b) => acc + b.grandTotal);

        points.add(
          ChartDataPoint(
            label: label,
            valuePaise: sum,
            billCount: matching.length,
            timestamp: d,
          ),
        );
      }
      return points;
    }
  }
}
