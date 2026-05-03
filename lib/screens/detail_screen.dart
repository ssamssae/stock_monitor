import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/stock.dart';

class DetailScreen extends StatelessWidget {
  final Stock stock;

  const DetailScreen({super.key, required this.stock});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(stock.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(stock.code, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(
              '${stock.price.toStringAsFixed(0)}원',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              '${stock.changeRate >= 0 ? '+' : ''}${stock.changeRate.toStringAsFixed(2)}%',
              style: TextStyle(
                color: stock.changeRate >= 0 ? Colors.red : Colors.blue,
              ),
            ),
            const SizedBox(height: 24),
            const Text('차트'),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(spots: const []),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
