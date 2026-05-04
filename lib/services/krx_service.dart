import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/stock.dart';

/// KRX data.krx.co.kr OTP API 기반 현재가 조회
/// API 실패(차단·장외 시간) 시 mock 데이터 반환
class KrxService {
  static const _baseUrl = 'http://data.krx.co.kr';
  static const _otpPath = '/comm/bldAttendant/getJsonData.cmd';
  static const _dataPath = '/comm/bldAttendant/executeSearch.cmd';
  static const _headers = {
    'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
    'Referer':
        'http://data.krx.co.kr/contents/MDC/MDI/mdiLoader/index.cmd?menuId=MDC0201020201',
    'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
  };

  static const _mockPrices = <String, double>{
    '005930': 58900, // 삼성전자
    '000660': 180000, // SK하이닉스
    '035720': 52000, // 카카오
    '035420': 159000, // NAVER
    '005380': 240000, // 현대차
    '051910': 280000, // LG화학
  };

  Future<Stock> fetchStock(Stock stock) async {
    try {
      return await _fetchFromKrx(stock);
    } catch (_) {
      return _mockFallback(stock);
    }
  }

  Future<List<Stock>> fetchAll(List<Stock> stocks) =>
      Future.wait(stocks.map(fetchStock));

  Future<Stock> _fetchFromKrx(Stock stock) async {
    // 1단계: OTP 발급
    final otpBody = _formEncode({
      'bld': 'dbms/MDC/STAT/standard/MDCSTAT01901',
      'mktId': 'STK',
      'trdDd': _kstToday(),
      'isuCd': stock.code,
      'share': '1',
      'money': '1',
      'csvxls_isNo': 'false',
    });

    final otpRes = await http
        .post(
          Uri.parse('$_baseUrl$_otpPath'),
          headers: _headers,
          body: otpBody,
        )
        .timeout(const Duration(seconds: 5));

    if (otpRes.statusCode != 200) {
      throw Exception('OTP ${otpRes.statusCode}');
    }

    final otpJson = jsonDecode(otpRes.body) as Map<String, dynamic>;
    final output1 = otpJson['result']?['output1'] as List?;
    final otp = output1 != null && output1.isNotEmpty
        ? (output1.first as Map<String, dynamic>)['OTP'] as String?
        : null;
    if (otp == null) throw Exception('OTP null');

    // 2단계: 실제 데이터 조회
    final dataRes = await http
        .post(
          Uri.parse('$_baseUrl$_dataPath'),
          headers: _headers,
          body: 'code=$otp',
        )
        .timeout(const Duration(seconds: 5));

    if (dataRes.statusCode != 200) {
      throw Exception('data ${dataRes.statusCode}');
    }

    final rows = jsonDecode(dataRes.body)['output'] as List?;
    if (rows == null || rows.isEmpty) throw Exception('empty');

    final row = rows.first as Map<String, dynamic>;
    final price = _parseNum(row['CLSPRC'] as String? ?? '0');
    final open = _parseNum(row['OPNPRC'] as String? ?? '0');
    final changeRate = open > 0 ? (price - open) / open * 100 : 0.0;

    return stock.copyWith(price: price, changeRate: changeRate);
  }

  Stock _mockFallback(Stock stock) => stock.copyWith(
        price: _mockPrices[stock.code] ?? 50000,
        changeRate: 0.0,
      );

  static String _formEncode(Map<String, String> params) => params.entries
      .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
      .join('&');

  static double _parseNum(String s) =>
      double.tryParse(s.replaceAll(',', '')) ?? 0;

  static String _kstToday() {
    final kst = DateTime.now().toUtc().add(const Duration(hours: 9));
    return '${kst.year}'
        '${kst.month.toString().padLeft(2, '0')}'
        '${kst.day.toString().padLeft(2, '0')}';
  }
}
