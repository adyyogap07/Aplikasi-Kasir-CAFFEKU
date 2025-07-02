import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'sales_report_page.dart';

class SalesReportChart extends ConsumerWidget {
  const SalesReportChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportState = ref.watch(dailySalesReportProvider);
    final Color primaryColor = Theme.of(context).primaryColor;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pendapatan 7 Hari Terakhir',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: reportState.when(
                data: (sales) {
                  if (sales.isEmpty) {
                    return const Center(child: Text('Belum ada data penjualan.'));
                  }
                  return BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (sales.map((s) => s.total).reduce((a,b) => a > b ? a : b)) * 1.2, // Atur Y-axis max
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final sale = sales[groupIndex];
                            final amount = NumberFormat.compactCurrency(locale: 'id_ID', symbol: 'Rp').format(sale.total);
                            return BarTooltipItem(
                              '${DateFormat('d MMM').format(sale.date)}\n',
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              children: [
                                TextSpan(
                                  text: amount,
                                  style: const TextStyle(color: Colors.yellow),
                                ),
                              ],
                            );
                          }
                        )
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final date = sales[value.toInt()].date;
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(DateFormat('d/M').format(date), style: const TextStyle(fontSize: 10)),
                               
                              );
                            },
                            reservedSize: 30,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(sales.length, (index) {
                        final sale = sales[index];
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: sale.total,
                              color: primaryColor,
                              width: 16,
                              borderRadius: BorderRadius.circular(4),
                            )
                          ],
                        );
                      }),
                      gridData: const FlGridData(show: false),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Gagal memuat grafik: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
