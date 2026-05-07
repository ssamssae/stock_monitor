import 'package:flutter/material.dart';

import '../models/stock.dart';

class PortfolioSummaryWidget extends StatelessWidget {
  final List<Stock> stocks;

  const PortfolioSummaryWidget({super.key, required this.stocks});

  @override
  Widget build(BuildContext context) {
    final loadedStocks = stocks.where((stock) => stock.price > 0).toList();
    if (loadedStocks.isEmpty) return const SizedBox.shrink();

    final totalValue = loadedStocks.fold<double>(
      0,
      (sum, stock) => sum + stock.price,
    );
    final totalChange = loadedStocks.fold<double>(
      0,
      (sum, stock) => sum + _dailyChangeAmount(stock),
    );
    final previousTotal = totalValue - totalChange;
    final totalChangeRate = previousTotal == 0
        ? 0
        : (totalChange / previousTotal) * 100;
    final up = totalChange >= 0;
    final changeColor = up ? Colors.red : Colors.blue;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('포트폴리오 합계', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      '${_fmtWon(totalValue)}원',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${up ? '+' : ''}${_fmtWon(totalChange)}원',
                        style: TextStyle(
                          color: changeColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${up ? '+' : ''}${totalChangeRate.toStringAsFixed(2)}%',
                        style: TextStyle(color: changeColor, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static double _dailyChangeAmount(Stock stock) {
    final previousPrice = stock.price / (1 + stock.changeRate / 100);
    return stock.price - previousPrice;
  }

  static String _fmtWon(double price) {
    final rounded = price.round();
    final sign = rounded < 0 ? '-' : '';
    final digits = rounded.abs().toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (match) => '${match[1]},',
    );
    return '$sign$digits';
  }
}
