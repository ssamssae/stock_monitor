import 'package:flutter/material.dart';
import '../models/stock.dart';
import '../services/stock_service.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _watchlist = [
    Stock(code: '005930', name: '삼성전자'),
    Stock(code: '000660', name: 'SK하이닉스'),
    Stock(code: '035420', name: 'NAVER'),
    Stock(code: '005380', name: '현대차'),
    Stock(code: '051910', name: 'LG화학'),
  ];

  final _service = StockService();
  List<Stock> _stocks = _watchlist;
  bool _loading = true;
  String? _error;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final updated = await _service.fetchAll(_watchlist);
      if (mounted) {
        setState(() {
          _stocks = updated;
          _loading = false;
          _lastUpdated = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('관심종목'),
        actions: [
          if (_lastUpdated != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  '${_lastUpdated!.hour.toString().padLeft(2, '0')}:'
                  '${_lastUpdated!.minute.toString().padLeft(2, '0')} 기준',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _fetch,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _stocks == _watchlist) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _stocks == _watchlist) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text('데이터를 불러올 수 없어요', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(_error!, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetch, child: const Text('다시 시도')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetch,
      child: Stack(
        children: [
          ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: _stocks.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) => _StockTile(
              stock: _stocks[i],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DetailScreen(stock: _stocks[i])),
              ),
            ),
          ),
          if (_loading)
            const Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(child: LinearProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class _StockTile extends StatelessWidget {
  final Stock stock;
  final VoidCallback onTap;

  const _StockTile({required this.stock, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final up = stock.changeRate >= 0;
    final color = stock.price == 0
        ? Colors.grey
        : up
            ? Colors.red
            : Colors.blue;

    return ListTile(
      onTap: onTap,
      title: Text(stock.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(stock.code, style: Theme.of(context).textTheme.bodySmall),
      trailing: stock.price == 0
          ? const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_fmt(stock.price)}원',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  '${up ? '+' : ''}${stock.changeRate.toStringAsFixed(2)}%',
                  style: TextStyle(color: color, fontSize: 12),
                ),
              ],
            ),
    );
  }

  String _fmt(double price) {
    if (price >= 10000) {
      return price.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+$)'),
            (m) => '${m[1]},',
          );
    }
    return price.toStringAsFixed(0);
  }
}
