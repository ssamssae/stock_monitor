import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/stock.dart';

/// KRX data.krx.co.kr OTP 기반 현재가·일봉 조회
/// API 실패 시 Yahoo Finance 폴백, 최종 실패 시 mock 반환
class KrxService {
  static const _baseUrl = 'http://data.krx.co.kr';
  static const _otpPath = '/comm/bldAttendant/getJsonData.cmd';
  static const _dataPath = '/comm/bldAttendant/executeSearch.cmd';
  static const _krxHeaders = {
    'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
    'Referer':
        'http://data.krx.co.kr/contents/MDC/MDI/mdiLoader/index.cmd?menuId=MDC0201020201',
    'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
  };
  static const _yahooBase = 'https://query1.finance.yahoo.com/v8/finance/chart';
  static const _yahooHeaders = {'User-Agent': 'Mozilla/5.0'};

  static const _mockPrices = <String, double>{
    '005930': 58900, // 삼성전자
    '000660': 180000, // SK하이닉스
    '035720': 52000, // 카카오
    '035420': 159000, // NAVER
    '005380': 240000, // 현대차
    '051910': 280000, // LG화학
  };

  /// 현재가만 조회 (홈 화면 목록용)
  Future<Stock> fetchStock(Stock stock) async {
    try {
      return await _fetchPriceFromKrx(stock);
    } catch (_) {
      try {
        return await _fetchFromYahoo(stock, range: '5d');
      } catch (_) {
        return _mockFallback(stock);
      }
    }
  }

  /// 현재가 + 1개월 일봉 조회 (상세 화면용)
  Future<Stock> fetchWithCandles(Stock stock) async {
    try {
      final price = await _fetchPriceFromKrx(stock);
      final candles = await _fetchCandlesFromKrx(stock);
      return price.copyWith(candles: candles);
    } catch (_) {
      try {
        return await _fetchFromYahoo(stock, range: '1mo');
      } catch (_) {
        return _mockFallback(stock);
      }
    }
  }

  Future<List<Stock>> fetchAll(List<Stock> stocks) =>
      Future.wait(stocks.map(fetchStock));

  // ── KRX OTP API ──────────────────────────────────────────

  Future<Stock> _fetchPriceFromKrx(Stock stock) async {
    final otp = await _getOtp({
      'bld': 'dbms/MDC/STAT/standard/MDCSTAT01901',
      'mktId': 'STK',
      'trdDd': _kstToday(),
      'isuCd': stock.code,
      'share': '1',
      'money': '1',
      'csvxls_isNo': 'false',
    });

    final dataRes = await http
        .post(
          Uri.parse('$_baseUrl$_dataPath'),
          headers: _krxHeaders,
          body: 'code=$otp',
        )
        .timeout(const Duration(seconds: 5));
    if (dataRes.statusCode != 200) throw Exception('data ${dataRes.statusCode}');

    final rows = jsonDecode(dataRes.body)['output'] as List?;
    if (rows == null || rows.isEmpty) throw Exception('empty');

    final row = rows.first as Map<String, dynamic>;
    final price = _parseNum(row['CLSPRC'] as String? ?? '0');
    final open = _parseNum(row['OPNPRC'] as String? ?? '0');
    final changeRate = open > 0 ? (price - open) / open * 100 : 0.0;
    return stock.copyWith(price: price, changeRate: changeRate);
  }

  Future<List<Candle>> _fetchCandlesFromKrx(Stock stock) async {
    final kst = DateTime.now().toUtc().add(const Duration(hours: 9));
    final endDd = _dateStr(kst);
    final strtDd = _dateStr(kst.subtract(const Duration(days: 40)));

    final otp = await _getOtp({
      'bld': 'dbms/MDC/STAT/standard/MDCSTAT01501',
      'isuCd': stock.code,
      'strtDd': strtDd,
      'endDd': endDd,
      'share': '1',
      'money': '1',
      'csvxls_isNo': 'false',
    });

    final dataRes = await http
        .post(
          Uri.parse('$_baseUrl$_dataPath'),
          headers: _krxHeaders,
          body: 'code=$otp',
        )
        .timeout(const Duration(seconds: 5));
    if (dataRes.statusCode != 200) throw Exception('candle ${dataRes.statusCode}');

    final rows = jsonDecode(dataRes.body)['output'] as List?;
    if (rows == null || rows.isEmpty) throw Exception('candle empty');

    final candles = <Candle>[];
    for (final item in rows.reversed) {
      final row = item as Map<String, dynamic>;
      final dateStr = (row['TRD_DD'] as String? ?? '').replaceAll('/', '');
      final close = _parseNum(row['CLSPRC'] as String? ?? '0');
      if (dateStr.length < 8 || close == 0) continue;
      final year = int.tryParse(dateStr.substring(0, 4)) ?? 0;
      final month = int.tryParse(dateStr.substring(4, 6)) ?? 0;
      final day = int.tryParse(dateStr.substring(6, 8)) ?? 0;
      if (year == 0) continue;
      candles.add(Candle(date: DateTime(year, month, day), close: close));
    }
    return candles;
  }

  Future<String> _getOtp(Map<String, String> params) async {
    final res = await http
        .post(
          Uri.parse('$_baseUrl$_otpPath'),
          headers: _krxHeaders,
          body: _formEncode(params),
        )
        .timeout(const Duration(seconds: 5));
    if (res.statusCode != 200) throw Exception('OTP ${res.statusCode}');

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final output1 = json['result']?['output1'] as List?;
    final otp = output1?.isNotEmpty == true
        ? (output1!.first as Map<String, dynamic>)['OTP'] as String?
        : null;
    if (otp == null) throw Exception('OTP null');
    return otp;
  }

  // ── Yahoo Finance 폴백 ────────────────────────────────────

  Future<Stock> _fetchFromYahoo(Stock stock, {String range = '1mo'}) async {
    final uri = Uri.parse(
        '$_yahooBase/${stock.code}.KS?interval=1d&range=$range');
    final res = await http
        .get(uri, headers: _yahooHeaders)
        .timeout(const Duration(seconds: 5));
    if (res.statusCode != 200) throw Exception('Yahoo ${res.statusCode}');

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final result =
        (data['chart']['result'] as List)[0] as Map<String, dynamic>;
    final meta = result['meta'] as Map<String, dynamic>;

    final price = (meta['regularMarketPrice'] as num).toDouble();
    final prevClose =
        (meta['previousClose'] as num?)?.toDouble() ?? price;
    final changeRate =
        prevClose != 0 ? (price - prevClose) / prevClose * 100 : 0.0;

    final timestamps =
        (result['timestamp'] as List?)?.map((v) => v as int).toList() ?? [];
    final rawCloses = (result['indicators']['quote'][0]['close'] as List?)
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
    return stock.copyWith(price: price, changeRate: changeRate, candles: candles);
  }

  // ── Helpers ───────────────────────────────────────────────

  Stock _mockFallback(Stock stock) => stock.copyWith(
        price: _mockPrices[stock.code] ?? 50000,
        changeRate: 0.0,
      );

  static String _formEncode(Map<String, String> params) => params.entries
      .map((e) =>
          '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
      .join('&');

  static double _parseNum(String s) =>
      double.tryParse(s.replaceAll(',', '')) ?? 0;

  static String _kstToday() {
    final kst = DateTime.now().toUtc().add(const Duration(hours: 9));
    return _dateStr(kst);
  }

  static String _dateStr(DateTime dt) =>
      '${dt.year}'
      '${dt.month.toString().padLeft(2, '0')}'
      '${dt.day.toString().padLeft(2, '0')}';
}
