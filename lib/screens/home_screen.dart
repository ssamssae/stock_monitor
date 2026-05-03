import 'package:flutter/material.dart';
import '../models/stock.dart';
import 'detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<Stock> _stocks = [
    Stock(code: '005930', name: '삼성전자', price: 78500, changeRate: 1.2),
    Stock(code: '000660', name: 'SK하이닉스', price: 198000, changeRate: -0.5),
    Stock(code: '035420', name: 'NAVER', price: 182500, changeRate: 0.8),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('관심종목')),
      body: ListView.builder(
        itemCount: _stocks.length,
        itemBuilder: (context, index) {
          final stock = _stocks[index];
          return ListTile(
            title: Text(stock.name),
            subtitle: Text(stock.code),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${stock.price.toStringAsFixed(0)}원'),
                Text(
                  '${stock.changeRate >= 0 ? '+' : ''}${stock.changeRate.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: stock.changeRate >= 0 ? Colors.red : Colors.blue,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DetailScreen(stock: stock)),
            ),
          );
        },
      ),
    );
  }
}
