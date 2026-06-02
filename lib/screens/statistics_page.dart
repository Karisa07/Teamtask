import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../app_theme.dart';
import '../board_provider.dart';
import '../board_repository.dart';

class StatisticsPage extends ConsumerWidget {
  final String boardId;
  final String boardName;

  const StatisticsPage({
    super.key,
    required this.boardId,
    required this.boardName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider(boardId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Estadísticas - $boardName'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stats) {
          final labels = <String>['Por hacer', 'En progreso', 'Completada'];
          final values = <int>[stats.pending, stats.inProgress, stats.completed];
          final colors = <Color>[
            Colors.grey.shade600,
            AppTheme.warningColor,
            AppTheme.successColor,
          ];

          final maxY = values.fold<int>(0, (prev, v) => v > prev ? v : prev);
          final barGroups = List.generate(
            values.length,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i].toDouble(),
                  width: 16,
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  color: colors[i],
                ),
              ],
            ),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Gap(12),
                _KpiCard(stats: stats),
                const Gap(18),
                Text(
                  'Breakdown por estado',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Gap(12),
                _BarChartCard(
                  labels: labels,
                  values: values,
                  barGroups: barGroups,
                  maxY: maxY,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final BoardStats stats;

  const _KpiCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${stats.completed} de ${stats.total} completadas',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              Text(
                '${(stats.percentage * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const Gap(10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: stats.percentage,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
              minHeight: 8,
            ),
          ),
          const Gap(14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _KpiChip(label: 'Por hacer', value: stats.pending, color: Colors.grey.shade600),
              _KpiChip(label: 'En progreso', value: stats.inProgress, color: AppTheme.warningColor),
              _KpiChip(label: 'Completada', value: stats.completed, color: AppTheme.successColor),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _KpiChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const Gap(8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarChartCard extends StatelessWidget {
  final List<String> labels;
  final List<int> values;
  final List<BarChartGroupData> barGroups;
  final int maxY;

  const _BarChartCard({
    required this.labels,
    required this.values,
    required this.barGroups,
    required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    if (values.every((v) => v == 0)) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(child: Text('No hay tareas todavía')),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      height: 280,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY.toDouble() + 1,
          barGroups: barGroups,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[idx],
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true)),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipPadding: const EdgeInsets.all(8),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final idx = group.x.toInt();
                final label = labels[idx];
                final val = values[idx];
                return BarTooltipItem(
                  '$label\n$val',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

