import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_monitor/models/stock.dart';
import 'package:stock_monitor/widgets/portfolio_summary_widget.dart';

void main() {
  testWidgets('shows total value and daily change for watchlist stocks', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PortfolioSummaryWidget(
            stocks: [
              Stock(
                code: '005930',
                name: 'Samsung',
                price: 70000,
                changeRate: 1,
              ),
              Stock(
                code: '000660',
                name: 'SK Hynix',
                price: 140000,
                changeRate: -2,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('포트폴리오 합계'), findsOneWidget);
    expect(find.text('210,000원'), findsOneWidget);
    expect(find.text('-2,164원'), findsOneWidget);
    expect(find.text('-1.02%'), findsOneWidget);
  });

  testWidgets('ignores stocks without a loaded price', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PortfolioSummaryWidget(
            stocks: [
              Stock(
                code: '005930',
                name: 'Samsung',
                price: 70000,
                changeRate: 1,
              ),
              Stock(code: '000660', name: 'SK Hynix'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('70,000원'), findsOneWidget);
    expect(find.text('+693원'), findsOneWidget);
    expect(find.text('+1.00%'), findsOneWidget);
  });
}
