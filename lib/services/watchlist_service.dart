import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/stock.dart';

class WatchlistService {
  static const _key = 'watchlist_v1';

  static const _defaults = [
    {'code': '005930', 'name': '삼성전자'},
    {'code': '000660', 'name': 'SK하이닉스'},
    {'code': '035420', 'name': 'NAVER'},
    {'code': '005380', 'name': '현대차'},
    {'code': '051910', 'name': 'LG화학'},
  ];

  Future<List<Stock>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      return _defaults
          .map((m) => Stock(code: m['code']!, name: m['name']!))
          .toList();
    }
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list
        .map((m) => Stock(code: m['code'] as String, name: m['name'] as String))
        .toList();
  }

  Future<void> save(List<Stock> stocks) async {
    final prefs = await SharedPreferences.getInstance();
    final data =
        stocks.map((s) => {'code': s.code, 'name': s.name}).toList();
    await prefs.setString(_key, jsonEncode(data));
  }
}
