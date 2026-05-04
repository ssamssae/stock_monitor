import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/stock.dart';
import '../services/stock_service.dart';

class DetailScreen extends StatefulWidget {
  final Stock stock;

  const DetailScreen({super.key, required this.stock});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final _service = StockService();
  late Stock _stock;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _stock = widget.stock;
    // If stock already has candle data (passed from home), skip re-fetch
    if (_stock.candles.isNotEmpty) {
      _loading = false;
    } else {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final updated = await _service.fetchStock(widget.stock);
      if (mounted) {
        setState(() {
          _stock = updated;
          _loading = false;
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
    final up = _stock.changeRate >= 0;
    final priceColor = _stock.price == 0
        ? Colors.grey
        : up ? Colors.red : Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: Text(_stock.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _fetch,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('불러오기 실패', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ElevatedButton(onPressed: _fetch, child: const Text('다시 시도')),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_stock.code, style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text(
                        _fmt(_stock.price),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            up ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                            color: priceColor,
                            size: 20,
                          ),
                          Text(
                            '${up ? '+' : ''}${_stock.changeRate.toStringAsFixed(2)}%',
                            style: TextStyle(color: priceColor, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '전일 대비',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '1개월 일봉',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 12),
                      _buildChart(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildChart() {
    if (_stock.candles.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('차트 데이터 없음')),
      );
    }

    final spots = _stock.candles.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.close);
    }).toList();

    final prices = _stock.candles.map((c) => c.close).toList();
    final minY = prices.reduce((a, b) => a < b ? a : b);
    final maxY = prices.reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.1;
    final up = _stock.changeRate >= 0;
    final lineColor = up ? Colors.red : Colors.blue;

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: minY - padding,
          maxY: maxY + padding,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.grey.withValues(alpha: 0.2),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (v, _) => Text(
                  _fmtAxis(v),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: (spots.length / 4).ceilToDouble(),
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= _stock.candles.length) return const SizedBox.shrink();
                  final d = _stock.candles[idx].date;
                  return Text(
                    '${d.month}/${d.day}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: lineColor,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: lineColor.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}원';
  }

  String _fmtAxis(double v) {
    if (v >= 100000) return '${(v / 10000).toStringAsFixed(0)}만';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }
}
