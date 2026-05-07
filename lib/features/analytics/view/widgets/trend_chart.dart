import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../model/analytics_model.dart';
import '../../../../../config/theme/app_pallete.dart';

// Add to pubspec.yaml:
//   fl_chart: ^0.68.0

class TrendChart extends StatefulWidget {
  final List<TrendPoint> trends;
  const TrendChart({super.key, required this.trends});

  @override
  State<TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<TrendChart> {
  int _touchedIndex = -1;

  // Data colors — intentionally fixed; they work in both modes
  static const Color _presentColor = Color(0xFF3b82f6);
  static const Color _tasksColor = Color(0xFF22c55e);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 16),
            child: Row(
              children: [
                _LegendDot(color: _presentColor, label: 'Present'),
                const SizedBox(width: 16),
                _LegendDot(color: _tasksColor, label: 'Tasks done'),
              ],
            ),
          ),

          // Chart
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceBetween,
                maxY: _maxY(),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => cs.surface,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final t = widget.trends[groupIndex];
                      return BarTooltipItem(
                        '${t.date.substring(5)}\n',
                        TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                        children: [
                          TextSpan(
                            text: rodIndex == 0
                                ? '${t.present} present'
                                : '${t.tasksDone} tasks',
                            style: TextStyle(
                              color: rodIndex == 0 ? _presentColor : _tasksColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    setState(() {
                      _touchedIndex =
                          response?.spot?.touchedBarGroupIndex ?? -1;
                    });
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final i = val.toInt();
                        if (i < 0 || i >= widget.trends.length) {
                          return const SizedBox.shrink();
                        }
                        if (i % 3 != 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            widget.trends[i].date.substring(5),
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.4),
                              fontSize: 9,
                            ),
                          ),
                        );
                      },
                      reservedSize: 22,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (val, meta) => Text(
                        val.toInt().toString(),
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.4),
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: cs.outline.withValues(alpha: 0.15),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(show: false),
                barGroups: widget.trends.asMap().entries.map((e) {
                  final i = e.key;
                  final t = e.value;
                  final isTouched = i == _touchedIndex;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: t.present.toDouble(),
                        color: isTouched
                            ? _presentColor.withValues(alpha: 0.6)
                            : _presentColor,
                        width: 5,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3),
                        ),
                      ),
                      BarChartRodData(
                        toY: t.tasksDone.toDouble(),
                        color: isTouched
                            ? _tasksColor.withValues(alpha: 0.6)
                            : _tasksColor,
                        width: 5,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _maxY() {
    if (widget.trends.isEmpty) return 10;
    final maxPresent = widget.trends
        .map((t) => t.present.toDouble())
        .reduce((a, b) => a > b ? a : b);
    final maxTasks = widget.trends
        .map((t) => t.tasksDone.toDouble())
        .reduce((a, b) => a > b ? a : b);
    final mx = maxPresent > maxTasks ? maxPresent : maxTasks;
    return (mx * 1.3).ceilToDouble().clamp(5, double.infinity);
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}