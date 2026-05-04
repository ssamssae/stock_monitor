import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/stock.dart';

class StockService {
  static const _base = 'https://query1.finance.yahoo.com/v8/finance/chart';
  static const _headers = {'User-Agent': 'Mozilla/5.0'};

  Future<Stock> fetchStock(Stock stock, {String range = '1mo'}) async {
    final uri = Uri.parse('$_base/${stock.code}.KS?interval=1d&range=$range');
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final result = (data['chart']['result'] as List)[0] as Map<String, dynamic>;
    final meta = result['meta'] as Map<String, dynamic>;

    final price = (meta['regularMarketPrice'] as num).toDouble();
    final prevClose = (meta['previousClose'] as num?)?.toDouble() ?? price;
    final changeRate =
        prevClose != 0 ? (price - prevClose) / prevClose * 100 : 0.0;

    final timestamps =
        (result['timestamp'] as List?)?.map((v) => v as int).toList() ?? [];
    final rawCloses =
        (result['indicators']['quote'][0]['close'] as List?)
            ?.map((v) => (v as num?)?.toDouble())
            .toList() ??
        [];

    final candles = <Candle>[];
    for (var i = 0; i < timestamps.length && i < rawCloses.length; i++) {
      final c = rawCloses[i];
      if (c != null) {
        candles.add(Candle(
          date: DateTime.fromMillisecondsSinceEpoch(timestamps[i] * 1000),
          close: c,
        ));
      }
    }

    return stock.copyWith(
      price: price,
      changeRate: changeRate,
      candles: candles,
    );
  }

  Future<List<Stock>> fetchAll(List<Stock> stocks) async {
    return Future.wait(stocks.map(fetchStock));
  }
}
