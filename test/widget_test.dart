import 'package:flutter_test/flutter_test.dart';
import 'package:stock_monitor/models/stock.dart';

void main() {
  test('Stock.copyWith updates fetched market fields and keeps identity', () {
    const stock = Stock(
      code: '005930',
      name: '삼성전자',
      price: 71000,
      changeRate: 0.5,
      targetPrice: 80000,
      dataSource: DataSource.mock,
    );

    final updated = stock.copyWith(
      price: 72500,
      changeRate: -1.25,
      candles: [
        Candle(date: DateTime(2026, 7), close: 72500),
      ],
      dataSource: DataSource.krx,
    );

    expect(updated.code, '005930');
    expect(updated.name, '삼성전자');
    expect(updated.price, 72500);
    expect(updated.changeRate, -1.25);
    expect(updated.targetPrice, 80000);
    expect(updated.dataSource, DataSource.krx);
    expect(updated.candles.single.close, 72500);
  });

  test('Stock.copyWith can clear an existing target price', () {
    const stock = Stock(
      code: '000660',
      name: 'SK하이닉스',
      targetPrice: 160000,
    );

    final updated = stock.copyWith(targetPrice: null);

    expect(updated.targetPrice, isNull);
    expect(updated.code, stock.code);
    expect(updated.name, stock.name);
  });
}
