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

  const Stock({
    required this.code,
    required this.name,
    this.price = 0,
    this.changeRate = 0,
    this.candles = const [],
  });

  Stock copyWith({double? price, double? changeRate, List<Candle>? candles}) {
    return Stock(
      code: code,
      name: name,
      price: price ?? this.price,
      changeRate: changeRate ?? this.changeRate,
      candles: candles ?? this.candles,
    );
  }
}
