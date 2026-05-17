import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';

class SalesChart extends StatelessWidget {
  final String selectedPeriod;

  const SalesChart({super.key, required this.selectedPeriod});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statistik Penjualan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tren pendapatan periode $selectedPeriod',
                    style: const TextStyle(color: AppTheme.textGrey, fontSize: 13),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.trending_up, color: AppTheme.primaryBlue, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Expanded(
            child: LineChart(
              _mainData(),
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _mainData() {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.withOpacity(0.1),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: _bottomTitleWidgets,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: _leftTitleWidgets,
            reservedSize: 42,
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: 6,
      minY: 0,
      maxY: 6,
      lineBarsData: [
        LineChartBarData(
          // Dummy data spots yang akan disesuaikan nantinya
          spots: const [
            FlSpot(0, 3),
            FlSpot(1, 2.5),
            FlSpot(2, 5),
            FlSpot(3, 3.5),
            FlSpot(4, 4.5),
            FlSpot(5, 3.8),
            FlSpot(6, 5.5),
          ],
          isCurved: true,
          color: AppTheme.primaryBlue,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryBlue.withOpacity(0.2),
                AppTheme.primaryBlue.withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: AppTheme.textGrey,
      fontWeight: FontWeight.w500,
      fontSize: 12,
    );
    Widget text;
    switch (value.toInt()) {
      case 0:
        text = const Text('Sen', style: style);
        break;
      case 2:
        text = const Text('Rab', style: style);
        break;
      case 4:
        text = const Text('Jum', style: style);
        break;
      case 6:
        text = const Text('Min', style: style);
        break;
      default:
        text = const Text('', style: style);
        break;
    }
   return SideTitleWidget(
      meta: meta, // Cukup berikan objek meta-nya secara langsung
      child: text,
    );
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: AppTheme.textGrey,
      fontSize: 11,
    );
    String text;
    switch (value.toInt()) {
      case 1:
        text = '1jt';
        break;
      case 3:
        text = '3jt';
        break;
      case 5:
        text = '5jt';
        break;
      default:
        return Container();
    }
    return Text(text, style: style, textAlign: TextAlign.left);
  }
}