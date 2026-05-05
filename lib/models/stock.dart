enum DataSource { krx, yahoo, mock }

class Candle {
  final DateTime date;
  final double close;

  const Candle({required this.date, required this.close});
}

class Stock {
  final String code;
  final String name;
  final double price;
  final double changeRate;
  final List<Candle> candles;
  final double? targetPrice;
  final DataSource? dataSource;

  const Stock({
    required this.code,
    required this.name,
    this.price = 0,
    this.changeRate = 0,
    this.candles = const [],
    this.targetPrice,
    this.dataSource,
  });

  Stock copyWith({
    double? price,
    double? changeRate,
    List<Candle>? candles,
    Object? targetPrice = _sentinel,
    DataSource? dataSource,
  }) {
    return Stock(
      code: code,
      name: name,
      price: price ?? this.price,
      changeRate: changeRate ?? this.changeRate,
      candles: candles ?? this.candles,
      targetPrice:
          targetPrice == _sentinel ? this.targetPrice : targetPrice as double?,
      dataSource: dataSource ?? this.dataSource,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Stock &&
          code == other.code &&
          name == other.name &&
          price == other.price &&
          changeRate == other.changeRate &&
          targetPrice == other.targetPrice;

  @override
  int get hashCode =>
      Object.hash(code, name, price, changeRate, targetPrice);
}

// Sentinel value to distinguish "not passed" from null in copyWith.
const Object _sentinel = Object();
