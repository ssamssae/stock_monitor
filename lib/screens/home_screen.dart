import 'package:flutter/material.dart';
import '../models/stock.dart';
import '../services/krx_service.dart';
import '../services/watchlist_service.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = KrxService();
  final _watchlistService = WatchlistService();

  List<Stock> _watchlist = [];
  List<Stock> _stocks = [];
  bool _loading = true;
  String? _error;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final saved = await _watchlistService.load();
    setState(() => _watchlist = saved);
    await _fetch();
  }

  Future<void> _fetch() async {
    if (_watchlist.isEmpty) {
      setState(() {
        _stocks = [];
        _loading = false;
      });
      return;
    }
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

  Future<void> _addStock() async {
    final result = await showDialog<Stock>(
      context: context,
      builder: (_) => const _AddStockDialog(),
    );
    if (result == null || !mounted) return;
    if (_watchlist.any((s) => s.code == result.code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result.code} 은(는) 이미 추가되어 있어요')),
      );
      return;
    }
    setState(() => _watchlist = [..._watchlist, result]);
    await _watchlistService.save(_watchlist);
    await _fetch();
  }

  Future<void> _removeStock(Stock stock) async {
    setState(() {
      _watchlist = _watchlist.where((s) => s.code != stock.code).toList();
      _stocks = _stocks.where((s) => s.code != stock.code).toList();
    });
    await _watchlistService.save(_watchlist);
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
      floatingActionButton: FloatingActionButton(
        onPressed: _addStock,
        tooltip: '종목 추가',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _stocks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _stocks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text('데이터를 불러올 수 없어요',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(_error!, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetch, child: const Text('다시 시도')),
          ],
        ),
      );
    }
    if (_watchlist.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_chart, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text('관심종목을 추가해보세요',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('우측 하단 + 버튼으로 종목 코드를 입력하세요',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
    }

    final displayList = _stocks.isNotEmpty ? _stocks : _watchlist;
    return RefreshIndicator(
      onRefresh: _fetch,
      child: Stack(
        children: [
          ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: displayList.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final stock = displayList[i];
              return Dismissible(
                key: ValueKey(stock.code),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child:
                      const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (_) => _removeStock(stock),
                child: _StockTile(
                  stock: stock,
                  onTap: _stocks.isNotEmpty
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => DetailScreen(stock: stock)),
                          )
                      : null,
                ),
              );
            },
          ),
          if (_loading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

class _AddStockDialog extends StatefulWidget {
  const _AddStockDialog();

  @override
  State<_AddStockDialog> createState() => _AddStockDialogState();
}

class _AddStockDialogState extends State<_AddStockDialog> {
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('종목 추가'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _codeCtrl,
              decoration: const InputDecoration(
                labelText: '종목 코드',
                hintText: '예: 005930',
              ),
              keyboardType: TextInputType.number,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '종목 코드를 입력하세요' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: '종목명',
                hintText: '예: 삼성전자',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '종목명을 입력하세요' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _targetCtrl,
              decoration: const InputDecoration(
                labelText: '목표가 (선택)',
                hintText: '예: 70000',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                if (double.tryParse(v.trim()) == null) return '숫자로 입력하세요';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final targetRaw = _targetCtrl.text.trim();
              Navigator.pop(
                context,
                Stock(
                  code: _codeCtrl.text.trim(),
                  name: _nameCtrl.text.trim(),
                  targetPrice: targetRaw.isEmpty
                      ? null
                      : double.tryParse(targetRaw),
                ),
              );
            }
          },
          child: const Text('추가'),
        ),
      ],
    );
  }
}

class _StockTile extends StatelessWidget {
  final Stock stock;
  final VoidCallback? onTap;

  const _StockTile({required this.stock, this.onTap});

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
      title: Text(stock.name,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle:
          Text(stock.code, style: Theme.of(context).textTheme.bodySmall),
      trailing: stock.price == 0
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (stock.targetPrice != null &&
                        stock.price >= stock.targetPrice!)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Text('⬆️',
                            style: TextStyle(
                                fontSize: 13, color: Colors.green)),
                      ),
                    Text(
                      '${_fmt(stock.price)}원',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
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
