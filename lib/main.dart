import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const StockMonitorApp());
}

class StockMonitorApp extends StatelessWidget {
  const StockMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '주식 모니터',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routes: {
        '/': (_) => const HomeScreen(),
      },
      initialRoute: '/',
    );
  }
}
