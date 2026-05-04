import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/stock.dart';

class WatchlistService {
  static const _keyV2 = 'watchlist_v2';
  static const _keyV1 = 'watchlist_v1';

  static const _defaults = [
    {'code': '005930', 'name': '삼성전자'},
    {'code': '000660', 'name': 'SK하이닉스'},
    {'code': '035420', 'name': 'NAVER'},
    {'code': '005380', 'name': '현대차'},
    {'code': '051910', 'name': 'LG화학'},
  ];

  Future<List<Stock>> load() async {
    final prefs = await SharedPreferences.getInstance();

    // Try v2 first (has targetPrice).
    final rawV2 = prefs.getString(_keyV2);
    if (rawV2 != null) {
      final list = (jsonDecode(rawV2) as List).cast<Map<String, dynamic>>();
      return list.map((m) => Stock(
            code: m['code'] as String,
            name: m['name'] as String,
            targetPrice: (m['targetPrice'] as num?)?.toDouble(),
          )).toList();
    }

    // Fall back to v1 (no targetPrice).
    final rawV1 = prefs.getString(_keyV1);
    if (rawV1 != null) {
      final list = (jsonDecode(rawV1) as List).cast<Map<String, dynamic>>();
      return list.map((m) => Stock(
            code: m['code'] as String,
            name: m['name'] as String,
          )).toList();
    }

    return _defaults
        .map((m) => Stock(code: m['code']!, name: m['name']!))
        .toList();
  }

  Future<void> save(List<Stock> stocks) async {
    final prefs = await SharedPreferences.getInstance();
    final data = stocks.map((s) => {
          'code': s.code,
          'name': s.name,
          if (s.targetPrice != null) 'targetPrice': s.targetPrice,
        }).toList();
    await prefs.setString(_keyV2, jsonEncode(data));
  }
}
